// Copyright (c) 2006-2015,2018,2019,2021 Simon Fell
//
// Permission is hereby granted, free of charge, to any person obtaining a 
// copy of this software and associated documentation files (the "Software"), 
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, 
// and/or sell copies of the Software, and to permit persons to whom the 
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included 
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
// THE SOFTWARE.
//

#import "Explorer.h"
#import "ReportDocument.h"
#import "DetailsController.h"
#import "ZKLoginController.h"
#import "EditableQueryResultWrapper.h"
#import "QueryResultTable.h"
#import "QueryListController.h"
#import "ApexController.h"
#import <ZKSforce/ZKSforce.h>
#import "ResultsSaver.h"
#import "BulkDelete.h"
#import "SearchQueryResult.h"
#import "ZKDescribeThemeItem+ZKFindResource.h"
#import "Prefs.h"
#import "AppDelegate.h"
#import "SoqlTokenizer.h"
#import "ZKTextView.h"
#import "SnippetLibrary.h"
#import "Shell/ShellView.h"
#import "Shell/NavRailView.h"
#import "Shell/OrgChipView.h"
#import "OrgSettings.h"
#import "DesignTokens.h"

static NSString *soqlTabId = @"soql";
static NSString *schemaTabId = @"schema";
static NSString *apexTabId = @"Apex";

static CGFloat MIN_PANE_SIZE = 128.0f;
static NSString *KEYPATH_WINDOW_VISIBLE = @"windowVisible";

@interface Explorer ()
- (IBAction)postLogin:(id)sender;
- (void)closeLoginPanelIfOpen:(id)sender;

@property (copy) NSString *soqlString;

- (void)colorize;

- (void)collapseChildTableView;
- (void)openChildTableView;

@property (strong) NSMutableArray *selectedFields;
@property (strong) NSString *selectedObjectName;

@property (strong) ZKSforceClient *sforce;
@property (strong) SoqlTokenizer *colorizer;
@property (strong) ZKLoginController *loginController;
@end


@implementation Explorer

@synthesize sforce, statusText, schemaViewIsActive, apiCallCountText;
@synthesize selectedObjectName, selectedFields;
@synthesize isQuerying, isEditing;

+(NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *paths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"canQueryMore"])
        return [paths setByAddingObjectsFromArray:@[@"rootResults.queryResult"]];
    if ([key isEqualToString:@"titleUserInfo"])
        return [paths setByAddingObjectsFromArray:@[@"sforce", @"queryFilename", @"apexFilename", @"selectedTabViewIdentifier", @"orgInfo"]];
    if ([key isEqualToString:@"hasSelectedForDelete"])
        return [paths setByAddingObjectsFromArray:@[@"rootResults.hasCheckedRows"]];
    return paths;
}

- (void)awakeFromNib {
    [myWindow setContentBorderThickness:28.0 forEdge:NSMinYEdge];     
    [myWindow setContentBorderThickness:28.0 forEdge:NSMaxYEdge];     
    myWindow.delegate = self;
    soql.enabledTextCheckingTypes = 0;
    
    soqlSchemaTabs.delegate = self;
    [soqlHeader setHeaderText:@"Query"];
    self.statusText = @"";
    
    [progress setUsesThreadedAnimation:YES];
    describeList.doubleAction = @selector(describeItemClicked:);    
    rootTableView.target = self;
    rootTableView.doubleAction = @selector(queryResultDoubleClicked:);
    self.rootResults = [[QueryResultTable alloc] initForTableView:rootTableView];
    self.rootResults.delegate = self;
    self.childResults = [[QueryResultTable alloc] initForTableView:childTableView];
    self.childResults.delegate = self;
    [self collapseChildTableView];
    
    queryListController.delegate = self;
    [queryListController addObserver:self forKeyPath:KEYPATH_WINDOW_VISIBLE options:NSKeyValueObservingOptionNew context:nil];
    [detailsController addObserver:self forKeyPath:KEYPATH_WINDOW_VISIBLE options:NSKeyValueObservingOptionNew context:nil];
    
    [self setSoqlString:[[NSUserDefaults standardUserDefaults] stringForKey:@"soql"]];
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:PREF_SOQL_SYNTAX_HIGHLIGHTING
                                                options:0
                                               context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:PREF_SOQL_UPPERCASE_KEYWORDS
                                                options:0
                                               context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:PREF_SOQL_POPUP_COMPLETIONS
                                                options:0
                                               context:nil];
}

- (void)dealloc {
    [detailsController removeObserver:self forKeyPath:KEYPATH_WINDOW_VISIBLE];
    [queryListController removeObserver:self forKeyPath:KEYPATH_WINDOW_VISIBLE];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:PREF_SOQL_SYNTAX_HIGHLIGHTING];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:PREF_SOQL_UPPERCASE_KEYWORDS];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:PREF_SOQL_POPUP_COMPLETIONS];
    NSLog(@"Explorer dealloc");
}

- (void)windowWillClose:(NSNotification *)notification {
    [descDataSource stopBackgroundDescribe];
}

- (void)changeEditFont:(id)sender; {
    soql.textStorage.font = [sender convertFont:soql.textStorage.font];
    [NSFont setUserFixedPitchFont:soql.textStorage.font];
    [apexController changeEditFont:sender];
}

-(void)updateCallCount:(ZKSforceClient *)c {
    ZKLimitInfoHeader *h = c.lastLimitInfoHeader;
    ZKLimitInfo *api = [h limitInfoOfType:@"API REQUESTS"];
    NSString *newVal = (api == nil) ? nil : [NSString stringWithFormat:@"Org API calls %ld/%ld", (long)[api current], (long)[api limit]];
    double fraction = (api == nil || [api limit] <= 0) ? 0 : (double)[api current] / (double)[api limit];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.apiCallCountText = newVal;
        self.apiCallsFraction = fraction;
    });
}

- (void)collapseChildTableView {
    if (![soqlTextSplitView isSubviewCollapsed:childTableView.superview.superview]) {
        NSRect viewFrame = childTableView.superview.superview.frame;
        uncollapsedDividerPosition = viewFrame.origin.y + viewFrame.size.height;
        [soqlTextSplitView setPosition:[soqlTextSplitView maxPossiblePositionOfDividerAtIndex:1] ofDividerAtIndex:1];
    }
}

- (void)openChildTableView {
    if ([soqlTextSplitView isSubviewCollapsed:childTableView.superview.superview]) {
        CGFloat p = [soqlTextSplitView maxPossiblePositionOfDividerAtIndex:1] - MIN_PANE_SIZE;
        [soqlTextSplitView setPosition:p ofDividerAtIndex:1];
    }
}

// MARK:- Login

-(void)initLoginController {
    if (self.loginController == nil) {
        self.loginController = [[ZKLoginController alloc] init];
        self.loginController.delegate = self;
        NSNumber *apiVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"zkApiVersion"];
        if (apiVersion != nil) {
            self.loginController.preferedApiVersion = apiVersion.intValue;
        }
    }
}

-(void)loginWithOAuthToken:(Credential*)cred {
    [self initLoginController];
    [self.loginController loginWithOAuthToken:cred window:myWindow];
}

-(void)completeOAuthLogin:(NSURL *)oauthCallbackUrl {
    [self initLoginController];
    [self.loginController completeOAuthLogin:oauthCallbackUrl window:myWindow];
}

- (IBAction)showLogin:(id)sender {
    [self initLoginController];
    [self.loginController showLoginSheet:myWindow];
}

-(void)loginControllerLoginCancelled:(ZKLoginController *)controller {
    self.loginController = nil;
    [myWindow close];
}

-(void)loginController:(ZKLoginController *)controller loginCompleted:(ZKSforceClient *)client {
    self.loginController = nil;
    [self useClient:client];
}

- (void)useClient:(ZKSforceClient *)client {
    [self closeLoginPanelIfOpen:self];
    self.sforce = client;
    self.sforce.delegate = self;
    self.loginController = nil;
    [self postLogin:self];
}

-(void)closeLoginPanelIfOpen:(id)sender {
    [self.loginController cancelLogin:sender];
}

-(BOOL)loginSheetIsOpen {
    return self.loginController != nil;
}

-(BOOL)isLoggedIn {
    return [sforce loggedIn];
}

-(void)updateProgress:(BOOL)show {
    progress.doubleValue = show ? 50 : 0;
    if (show)
        [progress startAnimation:self];
    else
        [progress stopAnimation:self];
    progress.hidden = !show;
    [progress display];
}

-(ZKFailWithErrorBlock)errorHandler {
    return ^(NSError *err) {
        [self updateProgress:NO];
        [[NSAlert alertWithError:err] runModal];
        self.isEditing = NO;
        self.isQuerying = NO;
    };
}

-(void)describe:(NSString *)sobject failed:(NSError *)err {
    // describe failed after a number of attempts.
    NSAlert *a = [[NSAlert alloc] init];
    a.messageText = @"Describe API Call failled";
    a.informativeText = [NSString stringWithFormat:@"The describeSobject API call for %@ failed after multiple attempts. Detailed object information for this object will not be available. This is likely a Salesforce bug. The last error was %@", sobject, err.description];
    [a addButtonWithTitle:@"Close"];
    [a runModal];
}

- (IBAction)postLogin:(id)sender {
    [sforce currentUserInfoWithFailBlock:[self errorHandler] completeBlock:^(ZKUserInfo *userInfo) {
        NSString *msg = [NSString stringWithFormat:@"Welcome %@ (instance:%@)",
                         [userInfo fullName],
                         [self.sforce serverHostAbbriviation]];
        self.statusText = msg;
        NSString *userId = [userInfo userId];
        self->queryListController.prefsPrefix = userId;
        self->detailsController.prefsPrefix = userId;
    }];
    [self loadOrgInfo];

    DescribeListDataSource *dds = [[DescribeListDataSource alloc] init];
    descDataSource = dds;
    [descDataSource addDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectedSObjectChanged:)
                                                 name:NSOutlineViewSelectionDidChangeNotification
                                               object:describeList];
    self.rootResults.describer = ^ZKDescribeSObject *(NSString *type) {
        ZKDescribeSObject *o = [dds cachedDescribe:type];
        if (o == nil) {
            [dds prioritizeDescribe:type];
        }
        return o;
    };
    self.childResults.describer = self.rootResults.describer;
    [apexController setSforceClient:sforce];
    [descDataSource setSforce:sforce];
    describeList.dataSource = descDataSource;
    describeList.delegate = descDataSource;
    [describeList reloadData];

    self.colorizer = [SoqlTokenizer new];
    DLDDescriber *dld = [DLDDescriber describer:descDataSource];
    dld.onNewDescribe = ^() {
        [self.colorizer color];
    };
    [dds addDelegate:dld];
    self.colorizer.describer = dld;
    self.colorizer.view = soql;
    soql.textStorage.delegate = self.colorizer;
    soql.delegate = self.colorizer;
    

    [schemaController setDescribeDataSource:descDataSource];
    [self colorize];
    [self updateProgress:NO];
    [self willChangeValueForKey:@"isLoggedIn"];
    [self didChangeValueForKey:@"isLoggedIn"];
    [self.rootResults setQueryResult:nil];
    [self.childResults setQueryResult:nil];

    [sforce describeGlobalThemeWithFailBlock:^(NSError *result) {
        [[NSAlert alertWithError:result] runModal];
    } completeBlock:^(ZKDescribeGlobalTheme *result) {
        [self willChangeValueForKey:@"SObjects"];
        [self->descDataSource setTypes:result view:self->describeList];
        [self didChangeValueForKey:@"SObjects"];
    }];
}

// MARK:- Describe/Metadata

- (void)refreshMetadata:(id)sender {
    [sforce describeGlobalThemeWithFailBlock:^(NSError *result) {
        [[NSAlert alertWithError:result] runModal];
    } completeBlock:^(ZKDescribeGlobalTheme *result) {
        [self willChangeValueForKey:@"SObjects"];
        [self.describeDataSource refreshDescribes:result view:self->describeList];
        [self.colorizer color];
        [self didChangeValueForKey:@"SObjects"];
    }];
}

-(void)highlightItemInSideBar:(id)sender {
    NSLog(@"highlight Item in side bar %@", sender);
}

- (DescribeListDataSource *)describeDataSource {
    return descDataSource;
}

- (NSArray *)SObjects {
    return [descDataSource SObjects];
}

- (void)described:(nonnull NSArray<ZKDescribeSObject *> *)sobjects {
    NSString *msg = [NSString stringWithFormat:@"Described %lu/%lu SObjects",
                     (unsigned long)descDataSource.describedCount,
                     (unsigned long)descDataSource.totalCount];
    [self setStatusText:msg];
}

- (void)colorize {
    [self.colorizer color];
}

-(NSString *)removeSuffix:(NSString *)suffix from:(NSString *)src {
    if ([src hasSuffix:suffix])
        return [src substringToIndex:src.length - suffix.length];
    return src;
}

-(void)addSuffixes:(NSString *)prefix suffixes:(NSArray *)suffixes to:(NSMutableSet *)col {
    for (NSString *s in suffixes)
        [col addObject:[prefix stringByAppendingString:s]];
}

- (IBAction)describeItemClicked:(id)sender {
    if(selectedFields == nil) {
        selectedFields = [[NSMutableArray alloc] init];
    }
    ZKDescribeSObject * d;
    id selectedItem = [describeList itemAtRow:describeList.selectedRow];
    
    if ([selectedItem isKindOfClass:[ZKDescribeField class]]) {
        if (![selectedObjectName isEqualToString:((ZKDescribeGlobalSObject *)[selectedItem sobject]).name]) {
            [selectedFields removeAllObjects];
        }
        self.selectedObjectName = ((ZKDescribeGlobalSObject *)[selectedItem sobject]).name;
        if ([selectedFields containsObject:selectedItem]) {
            [selectedFields removeObject:selectedItem];
        } else {
            [selectedFields addObject:selectedItem];
        }
        
    } else {
        self.selectedObjectName = [selectedItem name];
        d = [descDataSource cachedDescribe:selectedObjectName];
        [selectedFields removeAllObjects];
        [selectedFields addObjectsFromArray:d.fields];
    }
    
    NSMutableString * query = [NSMutableString string];
    [query appendString:@"select"];
    
    NSArray *fields = [selectedFields copy];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:PREF_QUERY_SORT_FIELDS]) {
        NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
        fields = [fields sortedArrayUsingDescriptors:@[sd]];
    }
    // There's no point selecting both the compound address field,and its component parts, do one or the other.
    BOOL useComponentFields = [[NSUserDefaults standardUserDefaults] boolForKey:PREF_SKIP_ADDRESS_FIELDS];
    if (useComponentFields) {
            // easy case, just skip the compound fields
        fields = [fields filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"not (type in { 'address','location'})"]];
    } else {
        // more work, calculate set of the component field names to skip, based on the name of the compound Field + the standard trailers
        NSMutableSet *fieldsToSkip = [NSMutableSet set];
        for (ZKDescribeField * f in [fields filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type=='address' || type=='location'"]]) {
            NSArray *lsuffixes = @[@"Longitude", @"Latitude"];
            NSArray *lcsuffixes= @[@"__Longitude__s", @"__Latitude__s"];
            NSArray *asuffixes = @[@"City", @"Country", @"CountryCode", @"State", @"StateCode", @"PostalCode", @"Street"];
            NSString *prefix = f.name;
            prefix = [self removeSuffix:@"__c" from:prefix];
            prefix = [self removeSuffix:@"Address" from:prefix];
            [self addSuffixes:prefix suffixes:lsuffixes to:fieldsToSkip];
            if ([f.type isEqualToString:@"address"])
                [self addSuffixes:prefix suffixes:asuffixes to:fieldsToSkip];
            if (f.custom)
                [self addSuffixes:prefix suffixes:lcsuffixes to:fieldsToSkip];
        }
        fields = [fields filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"not (name in %@)", fieldsToSkip]];
    }

    for (ZKDescribeField *f in fields)
        [query appendFormat:@" %@,", f.name];
    NSRange lastChar = {query.length-1, 1};
    [query deleteCharactersInRange:lastChar];
    [query appendFormat:@" from %@", selectedObjectName];
    [self setSoqlString:query];
}

- (IBAction)filterSObjectListView:(id)sender {
    [descDataSource setFilter:[sender stringValue]];
}

// When the user selected an sobject we don't have a describe for, we'll do a describe in the background
// then re-update the UI/data sources.
-(void)asyncSelectedSObjectChanged:(NSString *)sobjectType {
    [self updateProgress:YES];
    [detailsController setDataSource:nil];
    NSInteger selectedRow = describeList.selectedRow;
    [self->descDataSource describe:sobjectType
                         failBlock:[self errorHandler]
                     completeBlock:^(ZKDescribeSObject *result) {
                        [self updateProgress:NO];
                        // the describe completed, and this item is still selected update it.
                        if (selectedRow == self->describeList.selectedRow) {
                            [self selectedSObjectChanged:self];
                        }
                     }];
}

- (IBAction)selectedSObjectChanged:(id)sender {
    id selectedItem = [describeList itemAtRow:describeList.selectedRow];
    DetailDataSource *dataSource = nil;
    if ([selectedItem isKindOfClass:[ZKDescribeGlobalSObject class]]) {
        // sobject
        if (![descDataSource hasDescribe:[selectedItem name]]) {
            [self asyncSelectedSObjectChanged:[selectedItem name]];
            return;
        }
        ZKDescribeSObject *desc = [descDataSource cachedDescribe:[selectedItem name]];
        dataSource = [[SObjectDataSource alloc] initWithDescribe:desc];
        [detailsController setIcon:[descDataSource iconForType:[selectedItem name]]];
        if (self.schemaViewIsActive) {
            [schemaController setSchemaViewToSObject:desc];
        }
    } else {
        // field
        dataSource = [[SObjectFieldDataSource alloc] initWithDescribe:selectedItem];
        [detailsController setIcon:nil];
    }
    [detailsController setDataSource:dataSource];
}

- (NSString *)selectedSObjectName {
    id selectedItem = [describeList itemAtRow:describeList.selectedRow];
    if ([selectedItem isKindOfClass:[NSString class]]) {
        // sobject name
        return selectedItem;
        
    } else if ([selectedItem isKindOfClass:[ZKDescribeGlobalSObject class]]) {
        // sobject desc
        return [selectedItem name];
        
    } else if ([selectedItem isKindOfClass:[ZKDescribeField class]]) {
        // field
        return ((ZKDescribeField *)selectedItem).sobject.name;
    }
    // unknown
    NSLog(@"selected item from describeList of unexpected type %@ %@", selectedItem, [selectedItem class]);
    return selectedItem;
}

// MARK:- Query

- (void)setSoqlString:(NSString *)str {
    NSAttributedString *s = [[NSAttributedString alloc]
                             initWithString:str
                             attributes:@{
                                          NSForegroundColorAttributeName: [NSColor textColor]
                                                                         }];
    [soql.textStorage setAttributedString:s];
    soql.textStorage.font = [(AppDelegate*)[NSApp delegate] editFont];
    [self colorize];
}

- (void)queryTextListView:(QueryTextListView *)listView itemClicked:(QueryTextListViewItem *)item {
    NSString *t = item.text;
    if (t == nil || t.length == 0) return;
    [self setSoqlString:t];
}

- (IBAction)insertSnippet:(id)sender {
    SoqlSnippet *snippet = nil;
    if ([sender respondsToSelector:@selector(representedObject)]) {
        snippet = [sender representedObject];
    }
    if (![snippet isKindOfClass:[SoqlSnippet class]]) {
        NSLog(@"insertSnippet: called without a SoqlSnippet as the representedObject");
        return;
    }
    // {SObject} in the snippet becomes whatever is selected in the sidebar, if anything.
    NSString *text = [snippet soqlForSObject:[self selectedSObjectName]];
    [soqlSchemaTabs selectTabViewItemWithIdentifier:soqlTabId];
    [myWindow makeFirstResponder:soql];
    NSString *existing = [self soqlString];
    NSRange target = soql.selectedRange;
    if ([[existing stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
        // editor is empty (or just whitespace), replace the lot.
        target = NSMakeRange(0, existing.length);
    } else if (target.length == 0 && target.location > 0 && target.location <= existing.length) {
        // inserting mid-text, make sure the snippet starts on its own line.
        unichar prev = [existing characterAtIndex:target.location-1];
        if (prev != '\n' && prev != '\r') {
            text = [@"\n" stringByAppendingString:text];
        }
    }
    // insertText:replacementRange: goes through the normal editing path, so undo and the
    // syntax colorizer both see the change.
    [soql insertText:text replacementRange:target];
}

- (NSString *)soqlString {
    return soql.textStorage.string;
}

- (void)setRowsLoadedStatusText:(ZKQueryResult *)qr timing:(NSString *)time {
    self.statusText = [NSString stringWithFormat:@"loaded %ld of %ld total rows %@", (unsigned long)[qr records].count, (long)[qr size], time];
}

- (NSString *)execTimeSince:(NSDate *)started {
    return [NSString stringWithFormat:@"(in %.0f ms)", [[NSDate date] timeIntervalSinceDate:started] * 1000];
}

- (void)permformQuery:(BOOL)useQueryAll {
    [self updateProgress:YES];
    self.isQuerying = YES;
    [queryListController addQuery:[self soqlString]];
    [[NSUserDefaults standardUserDefaults] setObject:[self soqlString] forKey:@"soql"];

    NSString *query = [[self soqlString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSDate *started = [NSDate date];
    ZKCompleteQueryResultBlock cb = ^(ZKQueryResult *qr) {
        [self updateProgress:NO];
        self.isQuerying = NO;
        NSString *time = [self execTimeSince:started];
        if ([qr size] > 0) {
            if ([qr records].count == 0) {
                self.statusText = [NSString stringWithFormat:@"Count query result is %ld rows %@", (long)[qr size], time];
                [self.rootResults setQueryResult:nil];
                [self.childResults setQueryResult:nil];
            } else {
                self.rootResults.queryResult = qr;
                [self.childResults setQueryResult:nil];
                [self setRowsLoadedStatusText:qr timing:time];
            }
        } else {
            self.statusText = [NSString stringWithFormat:@"Query returned 0 rows %@", time];
            [self.rootResults setQueryResult:nil];
            [self.childResults setQueryResult:nil];
        }
    };
    if ([query.lowercaseString hasPrefix:@"find "]) {
        [sforce search:query failBlock:[self errorHandler] completeBlock:^(ZKSearchResult *searchResult) {
            ZKQueryResult *qr = [SearchQueryResult searchQueryResults:searchResult];
            cb(qr);
        }];
    } else if (useQueryAll) {
        [sforce queryAll:query failBlock:[self errorHandler] completeBlock:cb];
    } else {
        [sforce query:query failBlock:[self errorHandler] completeBlock:cb];
    }
}

- (IBAction)executeQuery:(id)sender {
    [self permformQuery:NO];
}

- (IBAction)executeQueryAll:(id)sender {
    [self permformQuery:YES];
}

- (BOOL)canQueryMore {
    return [self.rootResults.queryResult queryLocator] != nil;
}

- (IBAction)queryMore:(id)sender {
    [self updateProgress:YES];
    self.isQuerying = YES;
    NSDate *started = [NSDate date];
    [sforce queryMore:[self.rootResults.queryResult queryLocator]
            failBlock:[self errorHandler]
        completeBlock:^(ZKQueryResult *next) {
            NSString *execTime = [self execTimeSince:started];
            [self.rootResults addQueryMoreResults:next];
            [self setRowsLoadedStatusText:self.rootResults.queryResult timing:execTime];
            [self updateProgress:NO];
            self.isQuerying = NO;
        }];
}

- (IBAction)queryResultDoubleClicked:(id)sender {
    NSInteger cc = [sender clickedColumn];
    NSInteger cr = [sender clickedRow];
    if (cc > -1 && cr > -1) {
        NSTableColumn *c = rootTableView.tableColumns[cc];
        NSObject *val = [[self.rootResults.queryResult records][[sender clickedRow]] fieldValue:c.identifier];
        if ([val isKindOfClass:[ZKQueryResult class]]) {
            ZKQueryResult *qr = (ZKQueryResult *)val;
            [self openChildTableView];
            self.childResults.queryResult = qr;
        } else {
            [rootTableView editColumn:[sender clickedColumn] row:[sender clickedRow] withEvent:nil select:YES]; 
        }
    }
}

-(NSString *)titleUserInfo {
    NSString *doc = @"SoqlX Rebooted";
    BOOL hasFile = NO;
    if ([self.selectedTabViewIdentifier isEqualToString:soqlTabId] && self.queryFilename != nil) {
        doc = self.queryFilename.lastPathComponent;
        doc = [doc substringToIndex:doc.length - self.queryFilename.pathExtension.length - 1];
        hasFile = YES;
    } else if ([self.selectedTabViewIdentifier isEqualToString:apexTabId] && self.apexFilename != nil) {
        doc = self.apexFilename.lastPathComponent;
        doc = [doc substringToIndex:doc.length - self.apexFilename.pathExtension.length - 1];
        hasFile = YES;
    }
    if (self.sforce == nil) {
        return doc;
    }
    // The window title is hidden; this is the tab title. Per the design system the org identity is
    // the label (or org name), never the username; the OrgChip carries the detail.
    NSString *org = nil;
    if (self.orgInfo != nil) {
        org = [[OrgSettings settingsForOrgId:self.orgInfo.orgId] displayLabelForOrgName:self.orgInfo.name];
    } else {
        org = [sforce cachedUserInfo].organizationName ?: [sforce serverHostAbbriviation];
    }
    return hasFile ? [NSString stringWithFormat:@"%@ \u00b7 %@", org, doc] : org;
}

// MARK:- Shell (title bar, nav rail, org chip, inspector)

- (void)installShell {
    if (self.shell != nil || myWindow == nil) {
        return;
    }
    NSView *content = myWindow.contentView;
    // Detach the nib's content view from the window before re-parenting it inside the shell.
    myWindow.contentView = [[NSView alloc] initWithFrame:content.frame];
    ShellView *shell = [[ShellView alloc] initWithContentView:content];
    myWindow.contentView = shell;
    // The shell draws its own status band; the window's content borders are no longer needed.
    [myWindow setContentBorderThickness:0 forEdge:NSMaxYEdge];
    [myWindow setContentBorderThickness:0 forEdge:NSMinYEdge];
    myWindow.backgroundColor = [SXTokens ground];
    self.shell = shell;

    // Product name, panel toggles and the org chip live in a unified toolbar, so window tabs
    // and sheets attach below them and the title bar drags and zooms as usual.
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"SoqlXShellToolbar"];
    toolbar.delegate = self;
    toolbar.displayMode = NSToolbarDisplayModeIconOnly;
    toolbar.allowsUserCustomization = NO;
    toolbar.showsBaselineSeparator = NO;
    myWindow.toolbar = toolbar;
    myWindow.toolbarStyle = NSWindowToolbarStyleUnified;

    // The rail replaces the segmented view switcher; the title bar toggles replace the Details/Recent one.
    self.soqlSchemaApexSelector.hidden = YES;
    self.detailsRecentSelector.hidden = YES;

    NavRailView *rail = shell.rail;
    [rail addItemWithTitle:@"Query"    image:[NSImage imageNamed:@"icon.query"]    tag:0 pinToBottom:NO];
    [rail addItemWithTitle:@"Schema"   image:[NSImage imageNamed:@"icon.schema"]   tag:1 pinToBottom:NO];
    [rail addItemWithTitle:@"Apex"     image:[NSImage imageNamed:@"icon.apex"]     tag:2 pinToBottom:NO];
    [rail addItemWithTitle:@"Settings" image:[NSImage imageNamed:@"icon.settings"] tag:3 pinToBottom:YES];
    rail.target = self;
    rail.action = @selector(selectViewFromRail:);
    rail.selectedTag = [self railTagForTabIdentifier:soqlSchemaTabs.selectedTabViewItem.identifier];

    shell.recentToggle.target = self;
    shell.recentToggle.action = @selector(toggleRecentPanel:);
    shell.detailsToggle.target = self;
    shell.detailsToggle.action = @selector(toggleInspector:);

    [detailsController dockInInspector:shell];
    [self updatePanelToggles];
    [self updateOrgChip];
}

// MARK: NSToolbarDelegate

static NSString *const ShellItemProduct = @"sx.product";
static NSString *const ShellItemRecent  = @"sx.recent";
static NSString *const ShellItemDetails = @"sx.details";
static NSString *const ShellItemOrgChip = @"sx.orgchip";

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return @[ShellItemProduct, NSToolbarFlexibleSpaceItemIdentifier, ShellItemRecent, ShellItemDetails,
             NSToolbarFlexibleSpaceItemIdentifier, ShellItemOrgChip];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [self toolbarDefaultItemIdentifiers:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)identifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSView *view = nil;
    NSString *label = @"";
    if ([identifier isEqualToString:ShellItemProduct]) {
        view = self.shell.productLabel;  label = @"SoqlX Rebooted";
    } else if ([identifier isEqualToString:ShellItemRecent]) {
        view = self.shell.recentToggle;  label = @"Recent";
    } else if ([identifier isEqualToString:ShellItemDetails]) {
        view = self.shell.detailsToggle; label = @"Details";
    } else if ([identifier isEqualToString:ShellItemOrgChip]) {
        view = self.shell.orgChip;       label = @"Org";
    } else {
        return nil;
    }
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
    item.view = view;
    item.label = label;
    item.paletteLabel = label;
    item.visibilityPriority = [identifier isEqualToString:ShellItemOrgChip] ? NSToolbarItemVisibilityPriorityHigh : NSToolbarItemVisibilityPriorityStandard;
    return item;
}

- (NSInteger)railTagForTabIdentifier:(NSString *)identifier {
    if ([identifier isEqualToString:schemaTabId]) return 1;
    if ([identifier isEqualToString:apexTabId]) return 2;
    return 0;
}

- (void)selectViewFromRail:(id)sender {
    NSInteger tag = self.shell.rail.selectedTag;
    switch (tag) {
        case 1: [soqlSchemaTabs selectTabViewItemWithIdentifier:schemaTabId]; break;
        case 2: [soqlSchemaTabs selectTabViewItemWithIdentifier:apexTabId]; break;
        case 3:
            // Settings isn't a view yet; open Preferences and leave the rail on the current view.
            [NSApp sendAction:@selector(showPreferences:) to:nil from:self];
            self.shell.rail.selectedTag = [self railTagForTabIdentifier:soqlSchemaTabs.selectedTabViewItem.identifier];
            break;
        default: [soqlSchemaTabs selectTabViewItemWithIdentifier:soqlTabId]; break;
    }
}

- (void)toggleRecentPanel:(id)sender {
    queryListController.windowVisible = !queryListController.windowVisible;
}

- (void)toggleInspector:(id)sender {
    detailsController.windowVisible = !detailsController.windowVisible;
}

- (void)updatePanelToggles {
    if (self.shell == nil) return;
    BOOL details = detailsController.windowVisible;
    BOOL recent = queryListController.windowVisible;
    self.shell.detailsToggle.contentTintColor = details ? [SXTokens accentInk] : [SXTokens inkMuted];
    self.shell.recentToggle.contentTintColor = recent ? [SXTokens accentInk] : [SXTokens inkMuted];
    self.shell.detailsToggle.state = details ? NSControlStateValueOn : NSControlStateValueOff;
    self.shell.recentToggle.state = recent ? NSControlStateValueOn : NSControlStateValueOff;
}

- (void)loadOrgInfo {
    // Clear any previous org's identity first so a re-login never shows the wrong org (or kind).
    self.orgInfo = nil;
    [self updateOrgChip];
    NSString *q = @"SELECT Id, Name, IsSandbox, OrganizationType, TrialExpirationDate FROM Organization";
    [sforce query:q failBlock:^(NSError *err) {
        NSLog(@"Unable to read the Organization record: %@", err);
    } completeBlock:^(ZKQueryResult *qr) {
        ZKSObject *o = qr.records.firstObject;
        if (o == nil) return;
        OrgInfo *info = [OrgInfo new];
        info.orgId = [o fieldValue:@"Id"];
        info.name = [o fieldValue:@"Name"];
        info.organizationType = [o fieldValue:@"OrganizationType"];
        info.isSandbox = [o boolValue:@"IsSandbox"];
        info.trialExpiration = [o dateTimeValue:@"TrialExpirationDate"];
        info.instanceHost = self.sforce.serverUrl.host;
        self.orgInfo = info;
        [self updateOrgChip];
    }];
}

- (void)updateOrgChip {
    OrgChipView *chip = self.shell.orgChip;
    if (chip == nil) return;
    if (self.orgInfo == nil) {
        chip.hidden = YES;
        return;
    }
    OrgSettings *settings = [OrgSettings settingsForOrgId:self.orgInfo.orgId];
    chip.kind = [settings effectiveKindFor:self.orgInfo];
    chip.label = [settings displayLabelForOrgName:self.orgInfo.name];
    chip.detail = self.orgInfo.instanceHost;
    chip.color = [settings color];
    chip.hidden = NO;
    // The toolbar sizes the item from the view's frame, so keep it in step with the content.
    NSSize sz = chip.intrinsicContentSize;
    chip.frame = NSMakeRect(chip.frame.origin.x, chip.frame.origin.y, sz.width, sz.height);
}

// MARK:- File load/save

-(NSError *)loadQuery:(NSURL *)url {
    NSError *err = nil;
    NSString *soql = [[NSString alloc] initWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&err];
    if (err != nil) {
        self.queryFilename = nil;
    } else {
        self.queryFilename = url;
        self.soqlString = soql;
        [self.soqlSchemaApexSelector selectSegmentWithTag:0];
        [soqlSchemaTabs selectTabViewItemWithIdentifier:soqlTabId];
    }
    return err;
}

-(NSError *)loadApex:(NSURL *)url {
    NSError *err = nil;
    NSString *apex = [[NSString alloc] initWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&err];
    if (err != nil) {
        self.apexFilename = nil;
    } else {
        self.apexFilename = url;
        apexController.apex = apex;
        [self.soqlSchemaApexSelector selectSegmentWithTag:2];
        [soqlSchemaTabs selectTabViewItemWithIdentifier:apexTabId];
    }
    return err;
}

-(NSError *)loadFromURLType:(NSURL *)url {
    NSString *type;
    NSError *error;
    if ([url getResourceValue:&type forKey:NSURLTypeIdentifierKey error:&error]) {
        if ([[NSWorkspace sharedWorkspace] type:type conformsToType:@"com.pocketsoap.anon.apex"]) {
            return [self loadApex:url];
        }
    }
    return [self loadQuery:url];
}

-(void)load:(NSURL *)url {
    NSError *err = [self loadFromURLType:url];
    if (err != nil) {
        NSAlert *alert = [NSAlert alertWithError:err];
        [alert runModal];
    }
}

// Called via "Open..." Menu item
-(void)open:(id)sender {
    NSOpenPanel *o = [NSOpenPanel openPanel];
    o.allowsOtherFileTypes = YES;
    o.allowedFileTypes = @[@"com.pocketsoap.soql", @"com.pocketsoap.anon.apex"];
    [o beginSheetModalForWindow:myWindow completionHandler:^(NSModalResponse result) {
        if (result != NSModalResponseOK) {
            return;
        }
        NSError *err = [self loadFromURLType:o.URL];
        if (err != nil) {
            [o orderOut:nil];
            NSAlert *alert = [NSAlert alertWithError:err];
            [alert beginSheetModalForWindow:self->myWindow completionHandler:^(NSModalResponse returnCode) {}];
        }
    }];
}

-(void)saveQuery:(NSSavePanel *)s {
    if (self.queryFilename == nil) {
        s.nameFieldStringValue = @"query.soql";
    } else {
        s.nameFieldStringValue = self.queryFilename.lastPathComponent;
    }
    s.allowedFileTypes= @[@"com.pocketsoap.soql"];
    [s beginSheetModalForWindow:myWindow completionHandler:^(NSModalResponse result) {
        if (result != NSModalResponseOK) {
            return;
        }
        NSError *err = nil;
        if ([[self soqlString] writeToURL:s.URL atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
            self.queryFilename = s.URL;
        } else {
            [s orderOut:nil];
            NSAlert *alert = [NSAlert alertWithError:err];
            [alert beginSheetModalForWindow:self->myWindow completionHandler:^(NSModalResponse returnCode) {}];
        }
    }];
}

-(void)saveApex:(NSSavePanel *)s {
    if (self.apexFilename == nil) {
        s.nameFieldStringValue = @"apex.aapx";
    } else {
        s.nameFieldStringValue = self.apexFilename.lastPathComponent;
    }
    s.allowedFileTypes = @[@"com.pocketsoap.anon.apex"];
    [s beginSheetModalForWindow:myWindow completionHandler:^(NSModalResponse result) {
        if (result != NSModalResponseOK) {
            return;
        }
        NSError *err = nil;
        if ([self->apexController.apex writeToURL:s.URL atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
            self.apexFilename = s.URL;
        } else {
            [s orderOut:nil];
            NSAlert *alert = [NSAlert alertWithError:err];
            [alert beginSheetModalForWindow:self->myWindow completionHandler:^(NSModalResponse returnCode) {}];
        }
    }];
}

// Called via "Save" Menu item
-(void)save:(id)sender {
    NSSavePanel *s = [NSSavePanel savePanel];
    s.allowsOtherFileTypes = YES;
    s.extensionHidden = NO;
    s.canSelectHiddenExtension = YES;

    if ([soqlSchemaTabs.selectedTabViewItem.identifier isEqualToString:apexTabId]) {
        [self saveApex:s];
        return;
    }
    [self saveQuery:s];
}

// Called via "Save Query Results" Menu item
-(void)saveQueryResults:(id)sender {
    ResultsSaver *saver = [[ResultsSaver alloc] initWithResults:self.rootResults client:sforce];
    [saver save:myWindow];
}

// MARK:- Data Edit/Delete

// this is called by the menu to see if items should be enabled. This is an addition to the
// check that the target implements the selector.
-(BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)i {
    SEL theAction = [i action];
    if (theAction == @selector(save:)) {
        return ![self schemaViewIsActive];
    }
    if (theAction == @selector(saveQueryResults:)) {
        return (self.rootResults.queryResult.size > 0) && ![self schemaViewIsActive];
    }
    if (theAction == @selector(executeQuery:)) {
        return [self isLoggedIn];
    }
    if (theAction == @selector(executeQueryAll:)) {
        return [self isLoggedIn];
    }
    if (theAction == @selector(queryMore:)) {
        return [self canQueryMore];
    }
    return YES;
}

- (BOOL)hasSelectedForDelete {    
    return self.rootResults.hasCheckedRows;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == detailsController) {
        [self.detailsRecentSelector setSelected:[change[NSKeyValueChangeNewKey] boolValue] forSegment:0];
        [self updatePanelToggles];
    } else if (object == queryListController) {
        [self.detailsRecentSelector setSelected:[change[NSKeyValueChangeNewKey] boolValue] forSegment:1];
        [self updatePanelToggles];
    } else if (object == [NSUserDefaults standardUserDefaults]) {
        [self colorize];
    }
}

- (IBAction)updateDetailsRecentSelection:(id)sender {
    detailsController.windowVisible = [sender isSelectedForSegment:0];
    queryListController.windowVisible = [sender isSelectedForSegment:1];
}

- (IBAction)deleteCheckedRows:(id)sender {
    BulkDelete *bd = [[BulkDelete alloc] initWithClient:sforce];
    [bd performBulkDelete:self.rootResults window:myWindow];
}

- (void)dataChangedOnObject:(ZKSObject *)anObject field:(NSString *)fieldName value:(id)newValue {
    id existingVal = [anObject fieldValue:fieldName];
    if ([existingVal isEqualToString:newValue]) return;
    if (existingVal == nil && [newValue length] == 0) return;
    self.statusText = [NSString stringWithFormat:@"Updating field %@ on row with Id %@", fieldName, [anObject id]];
    ZKSObject *update = [ZKSObject withTypeAndId:[anObject type] sfId:[anObject id]];
    [update setFieldValue:newValue field:fieldName];
    [self updateProgress:YES];
    self.isEditing = YES;
    [sforce update:@[update] failBlock:[self errorHandler] completeBlock:^(NSArray *result) {
        ZKSaveResult *sr = result[0];
        [self updateProgress:NO];
        self.isEditing = NO;
        if (sr.success) {
            self.statusText = [NSString stringWithFormat:@"Updated field %@ on row with Id %@", fieldName, [anObject id]];
            [anObject setFieldValue:newValue field:fieldName];
            [self->rootTableView reloadData];
            [self->childTableView reloadData];
        } else {
            NSAlert *a = [[NSAlert alloc] init];
            a.messageText = sr.message;
            a.informativeText = sr.statusCode;
            [a runModal];
        }
    }];
}

- (IBAction)generateReportForSelection:(id)sender {
    NSString *sobjectName = [self selectedSObjectName];
    if (sobjectName == nil) return;
    ReportDocument *d = [[ReportDocument alloc] init];
    [d makeWindowControllers];
    [d showWindows];
    [d setSObjectType:sobjectName andDataSource:[self describeDataSource]];
}

-(NSString *)idOfSelectedRowInTableVew:(NSTableView *)tv primaryIdOnly:(BOOL)primaryIdOnly {
    NSInteger r = tv.clickedRow;
    NSInteger c = tv.clickedColumn;
    if (r >= 0 && c >= 0) {
        NSTableColumn *tc = tv.tableColumns[c];
        if (primaryIdOnly 
            || (![tc.identifier hasSuffix:@"Id"]) 
            || ([[tv.dataSource tableView:tv objectValueForTableColumn:tc row:r] length] != 18) ) {
            tc = [tv tableColumnWithIdentifier:@"Id"];
        }
        if (tc != nil) {
            NSString *theId = [tv.dataSource tableView:tv objectValueForTableColumn:tc row:r];
            if (theId.length == 18) 
                return theId;
        }
    }
    return nil;
}

// MARK:- Delegate impls

// NSTabView delegate
- (void)tabView:(NSTabView *)tab didSelectTabViewItem:(NSTabViewItem *)item {
    if ([item.identifier isEqualToString:schemaTabId]) {
        [self setSchemaViewIsActive:YES];
        [self selectedSObjectChanged:self];
    } else {
        [self setSchemaViewIsActive:NO];
    }
    self.selectedTabViewIdentifier = item.identifier;
    if (self.shell != nil) {
        self.shell.rail.selectedTag = [self railTagForTabIdentifier:item.identifier];
    }
}

// NSSplitView delegate
- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset {
    return proposedMin + MIN_PANE_SIZE;
}

- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset {
    return proposedMax - MIN_PANE_SIZE;
}

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview {
    return subview == childTableView.superview.superview;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex {
    return dividerIndex == 1 && [self splitView:splitView canCollapseSubview:subview];
}

// ZKBaseClientDelegate
-(void)client:(ZKBaseClient *)client
  sentRequest:(NSString *)payload
        named:(NSString *)callName
           to:(NSURL *)destination
 withResponse:(ZKElement *)response
        error:(NSError *)error
           in:(NSTimeInterval)time {

    [self updateCallCount:(ZKSforceClient *)client];
}

@end

