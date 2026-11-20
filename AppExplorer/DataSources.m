// Copyright (c) 2006,2014,2016,2018,2019,2020 Simon Fell
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

#import "DataSources.h"
#import <ZKSforce/ZKSforce.h>
#import "HighlightTextFieldCell.h"
#import "ZKDescribeThemeItem+ZKFindResource.h"
#import "Prefs.h"
#import "ZKXsdAnyType.h"
#import "Describer.h"
#import "DescribeExtras.h"
#import "SidebarFilter.h"
#import "SidebarItems.h"
#import "RecentObjects.h"

@interface DescribeListDataSource ()
-(void)updateFilter;
-(void)prefsChanged:(NSNotification *)notif;
@property Describer *describer;
@property (strong,nonatomic) DescriberDelegates *delegates;
@property (strong) SidebarFilter *categoryFilter;
@property (strong) SidebarGroup *recentGroup;
@property (strong) SidebarGroup *allGroup;
@property (copy) NSArray<NSString*> *recentNames;
@property (copy) NSArray<SidebarRecentItem*> *recentItems;
@property (strong) NSMutableDictionary<NSString*,SidebarRecentItem*> *recentItemCache;
@property (strong) HighlightTextFieldCell *groupCell;
@end


@interface ZKDescribeField (ZKDataSourceHelpers)
-(BOOL)fieldMatchesFilter:(NSString *)filter;
-(NSString *)defaultValueAsString;
@end

@implementation ZKDescribeField (Filtering)

-(BOOL)fieldMatchesFilter:(NSString *)filter {
    if (filter.length == 0) return NO;
    return [self.name rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound ||
           [self.label rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound;
}

-(NSString *)defaultValueAsString {
    NSObject *dv = [[self defaultValue] value];
    return dv == nil ? @"" : dv.description;
}

@end

@implementation DescribeListDataSource

- (instancetype)init {
    self = [super init];
    fieldSortOrder = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
    self.describer = [[Describer alloc] init];
    self.delegates = [DescriberDelegates new];
    self.categoryFilter = [SidebarFilter filterFromDefaults:[NSUserDefaults standardUserDefaults]];
    self.recentGroup = [SidebarGroup groupWithIdentifier:@"recent" title:@"Recent"];
    self.allGroup = [SidebarGroup groupWithIdentifier:@"all" title:@"All objects"];
    self.recentNames = @[];
    self.recentItems = @[];
    self.recentItemCache = [NSMutableDictionary dictionary];
    self.groupCell = [[HighlightTextFieldCell alloc] initTextCell:@""];
    self.groupCell.rowStyle = SidebarRowGroup;
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addDelegate:(NSObject<DescriberDelegate>*)d {
    [self.delegates addDelegate:d];
}

-(void)prefsChanged:(NSNotification *)notif {
    // Any window's filter menu, or a query in another window of this org, lands here.
    SidebarFilter *f = [SidebarFilter filterFromDefaults:[NSUserDefaults standardUserDefaults]];
    NSArray<NSString*> *recents = self.orgId.length > 0 ? [RecentObjects namesForOrgId:self.orgId] : @[];
    if (![f isEqual:self.categoryFilter] || ![recents isEqualToArray:self.recentNames]) {
        self.categoryFilter = f;
        self.recentNames = recents;
        [self updateFilter];
    }
    [self reloadOutline];
}

-(void)reloadOutline {
    [outlineView reloadData];
    [outlineView expandItem:self.recentGroup];
    [outlineView expandItem:self.allGroup];
}

-(void)setOrgId:(NSString *)orgId {
    _orgId = [orgId copy];
    self.recentNames = _orgId.length > 0 ? [RecentObjects namesForOrgId:_orgId] : @[];
    [self updateFilter];
    [self reloadOutline];
}

-(id)modelItemForItem:(id)item {
    if ([item isKindOfClass:[SidebarRecentItem class]]) return [(SidebarRecentItem *)item sobject];
    if ([item isKindOfClass:[SidebarGroup class]]) return nil;
    return item;
}

- (void)setTypes:(ZKDescribeGlobalTheme *)t view:(NSOutlineView *)ov {
    outlineView = ov;
    [self initializeWithTheme:t];
}

- (void)refreshDescribes:(ZKDescribeGlobalTheme*)t view:(NSOutlineView *)ov {
    outlineView = ov;
    [self.describer stop];
    self.describer = [[Describer alloc] init];
    [self initializeWithTheme:t];
}

- (void)initializeWithTheme:(ZKDescribeGlobalTheme*)t {
    types = t.global.sobjects;
    describes = [[NSMutableDictionary alloc] init];
    sortedDescribes = [[NSMutableDictionary alloc] init];
    icons = [[NSMutableDictionary alloc] init];
    
    NSMutableDictionary *byname = [NSMutableDictionary dictionary];
    for (ZKDescribeGlobalSObject *o in types)
        byname[o.name.lowercaseString] = o;
        
    descGlobalSobjects = byname;
    [self.recentItemCache removeAllObjects];
    
    NSString *sid = sforce.sessionId;
    for (ZKDescribeThemeItem *r in t.theme.themeItems) {
        ZKDescribeIcon *i = [r iconWithHeight:16 theme:@"theme3"];
        [i fetchIconUsingSessionId:sid whenCompleteDo:^(NSImage *img) {
            NSString *tn = r.name.lowercaseString;
            self->icons[tn] = img;
            [self->outlineView reloadItem:byname[tn]];
            SidebarRecentItem *recent = self.recentItemCache[tn];
            if (recent != nil) [self->outlineView reloadItem:recent];
        }];
    }
    [self.describer describe:t withClient:sforce andDelegate:self];
    [self updateFilter];
}

- (NSImage *)iconForType:(NSString *)type {
    return [icons valueForKey:type.lowercaseString];
}

- (void)setSforce:(ZKSforceClient *)sf {
    sforce = sf;
}

- (NSUInteger)describedCount {
    return describes.count;
}

- (NSUInteger)totalCount {
    return types.count;
}

-(void)setFilteredTypes:(NSArray<ZKDescribeGlobalSObject*> *)t recents:(NSArray<SidebarRecentItem*> *)r {
    BOOL changed = ![filteredTypes isEqualToArray:t] || ![self.recentItems isEqualToArray:r];
    filteredTypes = t;
    self.recentItems = r;
    if (changed)
        [self reloadOutline];
}

-(BOOL)textFilterIncludesType:(ZKDescribeGlobalSObject *)type {
    if (filter.length == 0)
        return YES;
    if ([type.name rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound ||
        [type.label rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound)
        return YES; // easy, the name or label contains the filter clause
    if (![self hasDescribe:type.name])
        return NO;    // we haven't described it yet
    for (ZKDescribeField *f in [self cachedDescribe:type.name].fields) {
        if ([f fieldMatchesFilter:filter])
            return YES;
    }
    return NO;
}

-(BOOL)categoryFilterIncludesType:(ZKDescribeGlobalSObject *)type {
    return [self.categoryFilter includesName:type.name
                                      custom:type.custom
                               customSetting:type.customSetting
                                   queryable:type.queryable
                         deprecatedAndHidden:type.deprecatedAndHidden];
}

-(SidebarRecentItem *)recentItemForType:(ZKDescribeGlobalSObject *)type {
    NSString *k = type.name.lowercaseString;
    SidebarRecentItem *item = self.recentItemCache[k];
    if (item == nil) {
        item = [SidebarRecentItem itemWithSObject:type];
        self.recentItemCache[k] = item;
    }
    return item;
}

-(void)updateFilter {
    NSMutableArray *ft = [NSMutableArray arrayWithCapacity:types.count];
    for (ZKDescribeGlobalSObject *type in types) {
        if ([self categoryFilterIncludesType:type] && [self textFilterIncludesType:type])
            [ft addObject:type];
    }
    // Recent entries skip the category filter (you used them), but honour the text filter.
    NSMutableArray *recents = [NSMutableArray arrayWithCapacity:self.recentNames.count];
    for (NSString *name in self.recentNames) {
        ZKDescribeGlobalSObject *type = descGlobalSobjects[name.lowercaseString];
        if (type != nil && [self textFilterIncludesType:type])
            [recents addObject:[self recentItemForType:type]];
    }
    NSNumberFormatter *nf = [NSNumberFormatter new];
    nf.numberStyle = NSNumberFormatterDecimalStyle;
    NSString *total = [nf stringFromNumber:@(types.count)];
    self.allGroup.detail = ft.count == types.count ? total
        : [NSString stringWithFormat:@"%@ of %@", [nf stringFromNumber:@(ft.count)], total];
    [self setFilteredTypes:ft recents:recents];
}

- (NSString *)filter {
    return filter;
}

- (void)setFilter:(NSString *)filterValue {
    filter = [filterValue copy];
    [self updateFilter];
}

- (void)prioritizeDescribe:(NSString *)type {
    [self.describer prioritize:type];
}

- (NSArray<ZKDescribeGlobalSObject*> *)SObjects {
    return types;
}

- (BOOL)isTypeDescribable:(NSString *)type {
    return nil != descGlobalSobjects[type.lowercaseString];
}

- (BOOL)hasDescribe:(NSString *)type {
    return nil != describes[type.lowercaseString];
}

-(ZKDescribeSObject *)cachedDescribe:(NSString *)type {
    return describes[type.lowercaseString];
}

- (void)describe:(NSString *)type
       failBlock:(ZKFailWithErrorBlock)failBlock
   completeBlock:(ZKCompleteDescribeSObjectBlock)completeBlock {

    NSString *t = type.lowercaseString;
    ZKDescribeSObject * d = describes[t];
    if (d != nil || ![self isTypeDescribable:t]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completeBlock(d);
        });
        return;
    }
    [sforce describeSObject:type
                  failBlock:failBlock
              completeBlock:^(ZKDescribeSObject *result) {
      // this is always called on the main thread, can fiddle with the cache directly
      [self addDescribesToCache:@[result]];
      completeBlock(result);
    }];
}

- (void)enumerateDescribes:(NSArray<NSString*> *)types
                 failBlock:(ZKFailWithErrorBlock)failBlock
             describeBlock:(void(^)(ZKDescribeSObject *desc, BOOL isLast, BOOL *stop))describeBlock {

    NSMutableSet<NSString*> *todo = [NSMutableSet setWithArray:types];
    [todo minusSet:[NSSet setWithArray:describes.allKeys]];
    for (NSString *name in todo) {
        [self.describer prioritize:name];
    }
    void(^__block next)(int idx) = nil;
    next = ^(int idx) {
        [self describe:types[idx] failBlock:failBlock completeBlock:^(ZKDescribeSObject *result) {
            BOOL stop = NO;
            BOOL last = idx >= types.count-1;
            describeBlock(result, last, &stop);
            if ((!stop) && (!last)) {
                next(idx+1);
            } else {
                next = nil;
            }
        }];
    };
    next(0);
}

-(void)addDescribesToCache:(NSArray<ZKDescribeSObject*> *)newDescribes {
    for (ZKDescribeSObject *d in newDescribes) {
        NSString *k = d.name.lowercaseString;
        if (self->describes[k] == nil) {
            self->describes[k] = d;
            self->sortedDescribes[k] = [d.fields sortedArrayUsingDescriptors:@[fieldSortOrder]];
        }
        [outlineView reloadItem:descGlobalSobjects[k] reloadChildren:YES];
    }
    [self updateFilter];
}

-(void)stopBackgroundDescribe {
    [self.describer stop];
}

// DescriberDelegate
-(void)described:(NSArray<ZKDescribeSObject*> *)sobjects {
    [self addDescribesToCache:sobjects];
    [self.delegates described:sobjects];
}

-(void)describe:(NSString *)sobject failed:(NSError *)err {
    [self.delegates describe:sobject failed:err];
}

// for use in an table view
- (NSInteger)numberOfRowsInTableView:(NSTableView *)v {
    return filteredTypes.count;
}

- (id)tableView:(NSTableView *)view objectValueForTableColumn:(NSTableColumn *)tc row:(int)rowIdx {
    return [filteredTypes[rowIdx] name];
}

// for use in an outline view
-(NSArray *)rootItems {
    return self.recentItems.count > 0 ? @[self.recentGroup, self.allGroup] : @[self.allGroup];
}

-(NSArray<ZKDescribeField*> *)fieldsOf:(ZKDescribeGlobalSObject *)item {
    BOOL isSorted = [[NSUserDefaults standardUserDefaults] boolForKey:PREF_SORTED_FIELD_LIST];
    if (isSorted) {
        NSArray *sorted = sortedDescribes[item.name.lowercaseString];
        if (sorted != nil) return sorted;
    }
    return [self cachedDescribe:item.name].fields;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil) return [self rootItems].count;
    if (item == self.recentGroup) return self.recentItems.count;
    if (item == self.allGroup) return filteredTypes.count;
    if ([item isKindOfClass:[ZKDescribeGlobalSObject class]]) return [self fieldsOf:item].count;
    return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item  {
    return item == nil || [item isKindOfClass:[SidebarGroup class]] || [item isKindOfClass:[ZKDescribeGlobalSObject class]];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) return [self rootItems][index];
    if (item == self.recentGroup) return self.recentItems[index];
    if (item == self.allGroup) return filteredTypes[index];
    return [self fieldsOf:item][index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    if ([item isKindOfClass:[SidebarGroup class]]) return [(SidebarGroup *)item title];
    id model = [self modelItemForItem:item];
    return [model respondsToSelector:@selector(name)] ? [model name] : nil;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return [item isKindOfClass:[SidebarGroup class]];
}

-(BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    return ![item isKindOfClass:[SidebarGroup class]];
}

// The type column of a field row: "→ Account", "email(80)", "currency(18,2)", "boolean".
-(NSString *)sidebarTypeOf:(ZKDescribeField *)f {
    if ([f.type isEqualToString:@"reference"] && f.referenceTo.count > 0) {
        if (f.referenceTo.count == 1) return [NSString stringWithFormat:@"→ %@", f.referenceTo[0]];
        return [NSString stringWithFormat:@"→ %@ +%lu", f.referenceTo[0], (unsigned long)(f.referenceTo.count - 1)];
    }
    NSSet *withLength = [NSSet setWithArray:@[@"string", @"textarea", @"email", @"phone", @"url", @"encryptedstring"]];
    if ([withLength containsObject:f.type] && f.length > 0)
        return [NSString stringWithFormat:@"%@(%ld)", f.type, (long)f.length];
    NSSet *withScale = [NSSet setWithArray:@[@"double", @"currency", @"percent"]];
    if ([withScale containsObject:f.type])
        return [NSString stringWithFormat:@"%@(%ld,%ld)", f.type, (long)f.precision, (long)f.scale];
    return f.type;
}

-(NSCell *)outlineView:(NSOutlineView *)ov dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if (tableColumn == nil) {
        // A full-width cell is asked for once per row; only group rows use one.
        if (![item isKindOfClass:[SidebarGroup class]]) return nil;
        HighlightTextFieldCell *g = self.groupCell;
        g.stringValue = [(SidebarGroup *)item title];
        g.detailText = [(SidebarGroup *)item detail];
        return g;
    }
    HighlightTextFieldCell *c = tableColumn.dataCell;
    c.icon = nil;
    c.detailText = nil;
    c.standout = NO;
    c.dimmed = NO;
    NSInteger row = [ov rowForItem:item];
    c.selectedRow = row >= 0 && [ov isRowSelected:row];

    if ([item isKindOfClass:[SidebarGroup class]]) {
        c.rowStyle = SidebarRowGroup;
        c.detailText = [(SidebarGroup *)item detail];
        return c;
    }
    id model = [self modelItemForItem:item];
    if ([model isKindOfClass:[ZKDescribeGlobalSObject class]]) {
        NSString *name = [model name];
        c.rowStyle = SidebarRowObject;
        c.icon = [self iconForType:name];
        c.dimmed = ![self hasDescribe:name];

    } else if ([model isKindOfClass:[ZKDescribeField class]]) {
        c.rowStyle = SidebarRowField;
        c.detailText = [self sidebarTypeOf:model];
        c.standout = [model fieldMatchesFilter:filter];
    }
    return c;
}

-(CGFloat)outlineView:(NSOutlineView *)ov heightOfRowByItem:(id)item {
    if ([item isKindOfClass:[SidebarGroup class]]) {
        return ov.rowHeight + 4;
    }
    return ov.rowHeight;
}

-(NSString *)outlineView:(NSOutlineView *)ov toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect
             tableColumn:(NSTableColumn *)tableColumn item:(id)item mouseLocation:(NSPoint)mouseLocation {
    id model = [self modelItemForItem:item];
    if ([model isKindOfClass:[ZKDescribeGlobalSObject class]]) {
        return [model hoverTextWithDescribe:[self cachedDescribe:[model name]]];
    }
    if ([model isKindOfClass:[ZKDescribeField class]]) {
        return [model hoverText];
    }
    return nil;
}

@end

@implementation Row

+(instancetype) row:(NSString *)l val:(NSString *)v {
    Row *r = [[self alloc] init];
    r.label = l;
    r.val = v;
    r.isEmpty = v.length == 0;
    return r;
}

+(instancetype) titleRow:(NSAttributedString *)l val:(NSString*)v {
    Row *r = [[self alloc] init];
    r.label = l;
    r.val = v;
    r.isEmpty = NO;
    return r;
}

@end

@interface DetailDataSource()
@property NSArray<Row*> *allRows;
@property NSArray<Row*> *activeRows;
@end

@implementation DetailDataSource

-(instancetype) init {
    self = [super init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applyFilter)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)applyFilter {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:PREF_FILTER_EMPY_PROPS]) {
        NSPredicate *p = [NSPredicate predicateWithFormat:@"isEmpty=NO"];
        self.activeRows = [self.allRows filteredArrayUsingPredicate:p];
    } else {
        self.activeRows = self.allRows;
    }
    if (self.onChange != nil) {
        self.onChange(self);
    }
}

// for use in a table view
-(NSInteger)numberOfRowsInTableView:(NSTableView *)view {
    return self.activeRows.count;
}

-(id)tableView:(NSTableView *)view objectValueForTableColumn:(NSTableColumn *)tc row:(NSInteger)rowIdx {
    if ([tc.identifier isEqualToString:@"title"]) {
        return self.activeRows[rowIdx].label;
    }
    return self.activeRows[rowIdx].val;
}

@end

@implementation SObjectDataSource

- (instancetype)initWithDescribe:(ZKDescribeSObject *)s {
    self = [super init];
    sobject = s;
    NSMutableArray<Row*> *items = [NSMutableArray arrayWithObjects:
                                   [Row row:@"Name"             val: s.name],
                                   [Row row:@"Label"            val: s.label],
                                   [Row row:@"PluralLabel"      val: s.labelPlural],
                                   [Row row:@"Key Prefix"       val: s.keyPrefix],
                                   [Row row:@"Custom"           val: s.custom ? @"Yes" : @""],
                                   [Row row:@"Custom Setting"   val: s.customSetting ? @"Yes" : @""],
                                   [Row row:@"Createable"       val: s.createable ? @"Yes" : @""],
                                   [Row row:@"Updateable"       val: s.updateable ? @"Yes" : @""],
                                   [Row row:@"Deep Cloneable"   val: s.deepCloneable ? @"Yes" : @""],
                                   [Row row:@"Activateable"     val: s.activateable ? @"Yes" : @""],
                                   [Row row:@"Deletable"        val: s.deletable ? @"Yes" : @""],
                                   [Row row:@"Undeletable"      val: s.undeletable ? @"Yes" : @""],
                                   [Row row:@"Mergeable"        val: s.mergeable ? @"Yes" : @""],
                                   [Row row:@"Queryable"        val: s.queryable ? @"Yes" : @""],
                                   [Row row:@"Retrieveable"     val: s.retrieveable ? @"Yes" : @""],
                                   [Row row:@"ID Enabled"       val: s.idEnabled ? @"Yes" : @""],
                                   [Row row:@"Searchable"       val: s.searchable ? @"Yes" : @""],
                                   [Row row:@"Layoutable"       val: s.layoutable ? @"Yes" : @""],
                                   [Row row:@"Compact Layoutable"       val: s.compactLayoutable ? @"Yes" : @""],
                                   [Row row:@"Search Layoutable"       val: s.searchLayoutable ? @"Yes" : @""],
                                   [Row row:@"Replicateable"    val: s.replicateable ? @"Yes" : @""],
                                   [Row row:@"Triggerable"      val: s.triggerable ? @"Yes" : @""],
                                   [Row row:@"MRU Enabled"      val: s.mruEnabled ? @"Yes" : @""],
                                   [Row row:@"Feed Enabled"     val: s.feedEnabled ? @"Yes" : @""],
                                   [Row row:@"Has Subtypes"     val: s.hasSubtypes ? @"Yes" : @""],
                                   [Row row:@"Is Subtype"       val: s.isSubtype ? @"Yes" : @""],
                                   [Row row:@"Is Interface"     val: s.isInterface ? @"Yes" : @""],
                                   [Row row:@"Implemented By"   val: s.implementedBy],
                                   [Row row:@"Implements Interfaces"    val: s.implementsInterfaces],
                                   [Row row:@"Default Implementation"   val: s.defaultImplementation],
                                   [Row row:@"Associate Entity Type"    val: s.associateEntityType],
                                   [Row row:@"Associate Parent Entity"  val: s.associateParentEntity],
                                   [Row row:@"Data Translation Enabled" val: s.dataTranslationEnabled ? @"Yes" : @""],
                                   [Row row:@"Deprecated And Hidden"    val: s.deprecatedAndHidden ? @"Yes" : @""],
                                   [Row row:@"URL for Edit"     val: s.urlEdit],
                                   [Row row:@"URL for Detail"   val: s.urlDetail],
                                   [Row row:@"URL for New"      val: s.urlNew],
                                nil];

    NSArray *cr = s.childRelationships;
    if (cr.count > 0) {
        NSString *sectionTitle = [NSString stringWithFormat:@"Relationships to %@", s.name];
        NSAttributedString *boldTitle = [[NSAttributedString alloc] initWithString:sectionTitle attributes:@{NSFontAttributeName: [NSFont boldSystemFontOfSize:11]}];
        [items addObject:[Row titleRow:boldTitle val:@""]];
        for (ZKChildRelationship *r in cr) {
            [items addObject:[Row row:[NSString stringWithFormat:@"%@.%@", r.childSObject, r.field] val:r.relationshipName]];
        }
    }
    self.allRows = items;
    [self applyFilter];
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"SObject : %@", sobject.name];
}

@end

@implementation SObjectFieldDataSource

- (instancetype)initWithDescribe:(ZKDescribeField *)f {
    self = [super init];
    field = f;
    NSArray *items = @[[Row row:@"Name"         val: f.name],
               [Row row:@"Label"                val: f.label],
               [Row row:@"Type"                 val: f.type],
               [Row row:@"Soap Type"            val: f.soapType],
               [Row row:@"Custom"               val: f.custom? @"Yes" : @""],
               [Row row:@"Help Text"            val: f.inlineHelpText],
               [Row row:@"Length"               val: fmtInt(f.length)],
               [Row row:@"Digits"               val: fmtInt(f.digits)],
               [Row row:@"Scale"                val: fmtInt(f.scale)],
               [Row row:@"Precision"            val: fmtInt(f.precision)],
               [Row row:@"Byte Length"          val: fmtInt(f.byteLength)],
               [Row row:@"High Scale Number"    val: f.highScaleNumber? @"Yes" : @""],
               [Row row:@"Default Value"        val: f.defaultValueAsString],
               [Row row:@"Encrypted"            val: f.encrypted? @"Yes" : @""],
               [Row row:@"Createable"           val: f.createable? @"Yes" : @""],
               [Row row:@"Updatable"            val: f.updateable? @"Yes" : @""],
               [Row row:@"Cascade Delete"       val: f.cascadeDelete? @"Yes" : @""],
               [Row row:@"Restricted Delete"    val: f.restrictedDelete? @"Yes" : @""],
               [Row row:@"Defaulted On Create"  val: f.defaultedOnCreate? @"Yes" : @""],
               [Row row:@"Calculated"           val: f.calculated? @"Yes" : @""],
               [Row row:@"AutoNumber"           val: f.autoNumber? @"Yes" : @""],
               [Row row:@"Unique"               val: f.unique? @"Yes" : @""],
               [Row row:@"Case Sensitive"       val: f.caseSensitive? @"Yes" : @""],
               [Row row:@"Name Pointing"        val: f.namePointing? @"Yes" : @""],
               [Row row:@"Sortable"             val: f.sortable? @"Yes" : @""],
               [Row row:@"Groupable"            val: f.groupable? @"Yes" : @""],
               [Row row:@"Aggregatable"         val: f.aggregatable? @"Yes" : @""],
               [Row row:@"Permissionable"       val: f.permissionable? @"Yes" : @""],
               [Row row:@"External Id"          val: f.externalId? @"Yes" : @""],
               [Row row:@"ID Lookup"            val: f.idLookup? @"Yes" : @""],
               [Row row:@"Filterable"           val: f.filterable? @"Yes" : @""],
               [Row row:@"HTML Formatted"       val: f.htmlFormatted? @"Yes" : @""],
               [Row row:@"Name Field"           val: f.nameField? @"Yes" : @""],
               [Row row:@"Nillable"             val: f.nillable? @"Yes" : @""],
               [Row row:@"Compound FieldName"   val: f.compoundFieldName],
               [Row row:@"Name Pointing"        val: f.namePointing? @"Yes" : @""],
               [Row row:@"Mask"                 val: f.mask],
               [Row row:@"Mask Type"            val: f.maskType],
               [Row row:@"Extra TypeInfo"       val: f.extraTypeInfo],
               [Row row:@"Reference To"         val: [f.referenceTo componentsJoinedByString:@", "]],
               [Row row:@"Relationship Name"    val: f.relationshipName],
               [Row row:@"Polymorphic Foreign Key"   val: f.polymorphicForeignKey? @"Yes" : @""],
               [Row row:@"Reference Target Field"    val: f.referenceTargetField],
               [Row row:@"Dependent Picklist"   val: f.dependentPicklist? @"Yes" : @""],
               [Row row:@"Controller Name"      val: f.controllerName],
               [Row row:@"Restricted Picklist"  val: f.restrictedPicklist? @"Yes" : @""],
               [Row row:@"Query By Distance"    val: f.queryByDistance? @"Yes" : @""],
               [Row row:@"Value Formula"        val: f.calculatedFormula],
               [Row row:@"Default Formula"      val: f.defaultValueFormula],
               [Row row:@"Formula Treat Null as Zero"   val: f.formulaTreatNullNumberAsZero? @"Yes" : @""],
               [Row row:@"AI Prediction Field"          val: f.aiPredictionField? @"Yes" : @""],
               [Row row:@"Data Translation Enabled"     val: f.dataTranslationEnabled? @"Yes" : @""],
               [Row row:@"Deprecated And Hidden"        val: f.deprecatedAndHidden? @"Yes" : @""],
               [Row row:@"Extra Type Info"              val: f.extraTypeInfo],
               [Row row:@"Search Prefilterable"         val: f.searchPrefilterable? @"Yes" : @""],
               [Row row:@"Relationship Order (CJOs)"             val: fmtInt(f.relationshipOrder)],
               [Row row:@"Write Requires Read on Master (CJOs)"  val: f.writeRequiresMasterRead? @"Yes" : @""],
               [Row row:@"Display Location in Decimal"           val: f.displayLocationInDecimal? @"Yes" : @""],
               ];
    
    self.allRows = items;
    [self applyFilter];
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Field : %@.%@", field.sobject.name, field.name];
}

NSString *fmtInt(NSInteger v) {
    return v == 0 ? @"": [[NSNumber numberWithInteger:v] stringValue];
}

@end

@implementation NoSelection 

-(BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex {
    return NO;
}

@end

