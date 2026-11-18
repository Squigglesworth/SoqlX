// Copyright (c) 2025 SoqlX contributors
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

#import "SnippetLibrary.h"

NSString *const SnippetSObjectPlaceholder = @"{SObject}";
static NSString *const SnippetErrorDomain = @"SoqlXSnippets";
static NSString *const DefaultCategory = @"My Snippets";

@interface SoqlSnippet()
+(NSError*)error:(NSString*)msg;
@end

@implementation SoqlSnippet

+(NSError*)error:(NSString*)msg {
    return [NSError errorWithDomain:SnippetErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: msg}];
}

+(instancetype)snippetFromDictionary:(NSDictionary*)d error:(NSError **)error {
    if (![d isKindOfClass:[NSDictionary class]]) {
        if (error) *error = [self error:@"Each snippet should be a JSON object with name, category, summary and soql keys"];
        return nil;
    }
    NSString *name = d[@"name"];
    if (![name isKindOfClass:[NSString class]] || name.length == 0) {
        if (error) *error = [self error:@"Snippet is missing its \"name\""];
        return nil;
    }
    id soql = d[@"soql"];
    NSString *soqlText = nil;
    if ([soql isKindOfClass:[NSString class]]) {
        soqlText = soql;
    } else if ([soql isKindOfClass:[NSArray class]]) {
        for (id line in (NSArray*)soql) {
            if (![line isKindOfClass:[NSString class]]) {
                if (error) *error = [self error:[NSString stringWithFormat:@"Snippet \"%@\": every line of \"soql\" should be a string", name]];
                return nil;
            }
        }
        soqlText = [(NSArray*)soql componentsJoinedByString:@"\n"];
    }
    if (soqlText.length == 0) {
        if (error) *error = [self error:[NSString stringWithFormat:@"Snippet \"%@\" is missing its \"soql\" (a string, or an array of lines)", name]];
        return nil;
    }
    SoqlSnippet *s = [SoqlSnippet new];
    s.name = name;
    s.soql = soqlText;
    NSString *cat = d[@"category"];
    s.category = [cat isKindOfClass:[NSString class]] && cat.length > 0 ? cat : DefaultCategory;
    NSString *summary = d[@"summary"];
    s.summary = [summary isKindOfClass:[NSString class]] ? summary : @"";
    return s;
}

-(NSString*)soqlForSObject:(NSString*)sobject {
    NSString *obj = sobject.length > 0 ? sobject : @"Account";
    return [self.soql stringByReplacingOccurrencesOfString:SnippetSObjectPlaceholder withString:obj];
}

-(NSString*)description {
    return [NSString stringWithFormat:@"%@ / %@", self.category, self.name];
}

@end


@interface SnippetLibrary()
@property (strong, nonatomic) NSArray<SoqlSnippet*> *snippets;
@property (strong, nonatomic) NSArray<NSString*> *categories;
@property (strong, nonatomic) NSError *userSnippetsError;
@end

@implementation SnippetLibrary

+(instancetype)shared {
    static SnippetLibrary *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [SnippetLibrary new];
        [instance reload];
    });
    return instance;
}

-(instancetype)init {
    self = [super init];
    self.snippets = @[];
    self.categories = @[];
    return self;
}

+(NSArray<SoqlSnippet*>*)snippetsFromData:(NSData*)data userDefined:(BOOL)userDefined error:(NSError **)error {
    NSError *jsonErr = nil;
    id root = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonErr];
    if (root == nil) {
        if (error) *error = jsonErr;
        return nil;
    }
    // accept either a bare array, or {"snippets": [...]}
    if ([root isKindOfClass:[NSDictionary class]]) {
        root = ((NSDictionary*)root)[@"snippets"];
    }
    if (![root isKindOfClass:[NSArray class]]) {
        if (error) *error = [SoqlSnippet error:@"The snippets file should contain a JSON array of snippets"];
        return nil;
    }
    NSMutableArray<SoqlSnippet*> *result = [NSMutableArray arrayWithCapacity:[root count]];
    for (id item in (NSArray*)root) {
        NSError *itemErr = nil;
        SoqlSnippet *s = [SoqlSnippet snippetFromDictionary:item error:&itemErr];
        if (s == nil) {
            if (error) *error = itemErr;
            return nil;
        }
        s.userDefined = userDefined;
        [result addObject:s];
    }
    return result;
}

+(NSURL*)userSnippetsURL {
    NSURL *appSupport = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                               inDomain:NSUserDomainMask
                                                      appropriateForURL:nil
                                                                 create:NO
                                                                  error:nil];
    return [[appSupport URLByAppendingPathComponent:@"SoqlX" isDirectory:YES] URLByAppendingPathComponent:@"snippets.json"];
}

-(NSArray<SoqlSnippet*>*)loadBundledSnippets {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"snippets" withExtension:@"json"];
    if (url == nil) {
        NSLog(@"snippets.json is missing from the app bundle");
        return @[];
    }
    NSError *err = nil;
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&err];
    NSArray<SoqlSnippet*> *s = data == nil ? nil : [SnippetLibrary snippetsFromData:data userDefined:NO error:&err];
    if (s == nil) {
        NSLog(@"Unable to load bundled snippets: %@", err);
        return @[];
    }
    return s;
}

-(NSArray<SoqlSnippet*>*)loadUserSnippets {
    NSURL *url = [SnippetLibrary userSnippetsURL];
    if (![[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
        self.userSnippetsError = nil;
        return @[];
    }
    NSError *err = nil;
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&err];
    NSArray<SoqlSnippet*> *s = data == nil ? nil : [SnippetLibrary snippetsFromData:data userDefined:YES error:&err];
    if (s == nil) {
        NSLog(@"Unable to load user snippets from %@: %@", url.path, err);
        self.userSnippetsError = err;
        return @[];
    }
    self.userSnippetsError = nil;
    return s;
}

-(void)reload {
    NSMutableArray<SoqlSnippet*> *all = [NSMutableArray array];
    [all addObjectsFromArray:[self loadBundledSnippets]];
    [all addObjectsFromArray:[self loadUserSnippets]];
    [self useSnippets:all];
}

-(void)useSnippets:(NSArray<SoqlSnippet*>*)snippets {
    NSMutableArray<NSString*> *cats = [NSMutableArray array];
    for (SoqlSnippet *s in snippets) {
        if (![cats containsObject:s.category]) {
            [cats addObject:s.category];
        }
    }
    self.snippets = [NSArray arrayWithArray:snippets];
    self.categories = cats;
}

-(NSArray<SoqlSnippet*>*)snippetsInCategory:(NSString*)category {
    NSMutableArray<SoqlSnippet*> *r = [NSMutableArray array];
    for (SoqlSnippet *s in self.snippets) {
        if ([s.category isEqualToString:category]) {
            [r addObject:s];
        }
    }
    return r;
}

-(NSURL*)ensureUserSnippetsFile:(NSError **)error {
    NSURL *url = [SnippetLibrary userSnippetsURL];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:url.path]) {
        return url;
    }
    if (![fm createDirectoryAtURL:[url URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:error]) {
        return nil;
    }
    NSArray *starter = @[
        @{
            @"category": DefaultCategory,
            @"name":     @"Example: my open opportunities",
            @"summary":  @"Edit or delete this example. Use {SObject} anywhere to insert the object selected in the sidebar.",
            @"soql":     @[@"SELECT Id, Name, StageName, CloseDate, Amount",
                           @"FROM Opportunity",
                           @"WHERE IsClosed = false AND OwnerId = '{YourUserId}'",
                           @"ORDER BY CloseDate",
                           @"LIMIT 50"],
        },
    ];
    NSData *data = [NSJSONSerialization dataWithJSONObject:starter options:NSJSONWritingPrettyPrinted error:error];
    if (data == nil) {
        return nil;
    }
    if (![data writeToURL:url options:NSDataWritingAtomic error:error]) {
        return nil;
    }
    return url;
}

-(NSMenuItem*)menuItemFor:(SoqlSnippet*)s action:(SEL)action {
    NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:s.name action:action keyEquivalent:@""];
    mi.representedObject = s;
    mi.target = nil;    // first responder
    if (s.summary.length > 0) {
        mi.toolTip = s.summary;
    }
    return mi;
}

-(void)populateMenu:(NSMenu*)menu action:(SEL)action {
    [menu removeAllItems];
    for (NSString *cat in self.categories) {
        NSMenuItem *catItem = [[NSMenuItem alloc] initWithTitle:cat action:nil keyEquivalent:@""];
        NSMenu *sub = [[NSMenu alloc] initWithTitle:cat];
        for (SoqlSnippet *s in [self snippetsInCategory:cat]) {
            [sub addItem:[self menuItemFor:s action:action]];
        }
        catItem.submenu = sub;
        [menu addItem:catItem];
    }
    if (self.categories.count > 0) {
        [menu addItem:[NSMenuItem separatorItem]];
    }
    if (self.userSnippetsError != nil) {
        NSMenuItem *err = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"My Snippets couldn't be read: %@", self.userSnippetsError.localizedDescription]
                                                     action:nil keyEquivalent:@""];
        err.enabled = NO;
        [menu addItem:err];
    }
    NSMenuItem *edit = [[NSMenuItem alloc] initWithTitle:@"Edit My Snippets…" action:@selector(editUserSnippets:) keyEquivalent:@""];
    edit.target = nil;
    edit.toolTip = @"Reveals your snippets.json file, creating it with an example if needed. Changes are picked up the next time the menu is opened.";
    [menu addItem:edit];
}

@end
