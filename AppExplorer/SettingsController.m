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

#import "SettingsController.h"
#import <Sparkle/Sparkle.h>
#import "Shell/SettingsPageView.h"
#import "SettingsContent.h"
#import "OrgSettings.h"
#import "Prefs.h"
#import "AppDelegate.h"
#import "Shell/SXControls.h"
#import "DesignTokens.h"

NSString *const SettingsSectionStartHere = @"start-here";
NSString *const SettingsSectionAppearance = @"appearance";
NSString *const SettingsSectionQuery = @"query";
NSString *const SettingsSectionSafety = @"safety";
NSString *const SettingsSectionApex = @"apex";
NSString *const SettingsSectionConnections = @"connections";
NSString *const SettingsSectionReleaseNotes = @"release-notes";
NSString *const SettingsSectionAbout = @"about";

static NSString *const kConsumerKeyDefault = @"OAuthConsumerKey";

// Target for a control: runs a block. Owned by SettingsController.
@interface SettingsAction : NSObject
@property (copy) void (^block)(id sender);
-(void)fire:(id)sender;
@end

@implementation SettingsAction
-(void)fire:(id)sender {
    if (self.block) {
        self.block(sender);
    }
}
@end

@interface SettingsController () <NSTextFieldDelegate>
@property (weak) SettingsPageView *page;
@property (strong) NSMutableArray<SettingsAction *> *actions;      // static controls
@property (strong) NSMutableArray<SettingsAction *> *orgActions;   // rebuilt with Connections
@property (strong) NSSegmentedControl *themeControl;
@property (strong) NSSegmentedControl *densityControl;
@property (strong) NSPopUpButton *textSizeControl;
@end

@implementation SettingsController

-(instancetype)initWithPage:(SettingsPageView *)page {
    self = [super init];
    if (self) {
        _page = page;
        _actions = [NSMutableArray array];
        _orgActions = [NSMutableArray array];
        page.pageTitle = @"Settings";
        [self buildStartHere];
        [self buildAppearance];
        [self buildQuery];
        [self buildSafety];
        [self buildApex];
        [page addSection:SettingsSectionConnections title:@"Connections"];
        [self refreshConnections];
        [self buildReleaseNotes];
        [self buildAbout];
    }
    return self;
}

// MARK: - Helpers

-(SettingsAction *)actionIn:(NSMutableArray<SettingsAction *> *)store block:(void (^)(id sender))block {
    SettingsAction *a = [[SettingsAction alloc] init];
    a.block = block;
    [store addObject:a];
    return a;
}

-(NSButton *)checkboxBoundTo:(NSString *)key {
    NSButton *b = [SXControls checkboxWithTitle:@"" target:nil action:nil];
    [b bind:NSValueBinding
   toObject:[NSUserDefaultsController sharedUserDefaultsController]
withKeyPath:[@"values." stringByAppendingString:key]
    options:nil];
    return b;
}

// Sparkle keeps this setting itself; the old Preferences key (SUCheckAtStartup) was never read.
-(NSButton *)updatesCheckbox {
    NSButton *b = [SXControls checkboxWithTitle:@"" target:nil action:nil];
    [b bind:NSValueBinding toObject:[SUUpdater sharedUpdater] withKeyPath:@"automaticallyChecksForUpdates" options:nil];
    return b;
}

-(NSSegmentedControl *)segmentedWithLabels:(NSArray<NSString *> *)labels selected:(NSInteger)selected action:(SettingsAction *)a {
    NSSegmentedControl *s = [NSSegmentedControl segmentedControlWithLabels:labels
                                                              trackingMode:NSSegmentSwitchTrackingSelectOne
                                                                    target:a
                                                                    action:@selector(fire:)];
    s.segmentStyle = NSSegmentStyleRounded;
    s.controlSize = NSControlSizeRegular;
    s.translatesAutoresizingMaskIntoConstraints = NO;
    if (selected >= 0 && selected < (NSInteger)labels.count) {
        s.selectedSegment = selected;
    }
    return s;
}

-(NSPopUpButton *)popupWithTitles:(NSArray<NSString *> *)titles selected:(NSInteger)selected action:(SettingsAction *)a {
    NSPopUpButton *p = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    p.translatesAutoresizingMaskIntoConstraints = NO;
    p.controlSize = NSControlSizeRegular;
    [p addItemsWithTitles:titles];
    if (selected >= 0 && selected < (NSInteger)titles.count) {
        [p selectItemAtIndex:selected];
    }
    p.target = a;
    p.action = @selector(fire:);
    return p;
}

-(NSTextField *)textFieldWithValue:(nullable NSString *)value placeholder:(nullable NSString *)placeholder width:(CGFloat)width action:(SettingsAction *)a {
    NSTextField *t = [[NSTextField alloc] initWithFrame:NSZeroRect];
    t.translatesAutoresizingMaskIntoConstraints = NO;
    t.editable = YES;
    t.selectable = YES;
    t.bezeled = YES;
    t.bezelStyle = NSTextFieldSquareBezel;
    t.drawsBackground = YES;
    t.controlSize = NSControlSizeRegular;
    t.stringValue = value ?: @"";
    t.placeholderString = placeholder;
    t.usesSingleLineMode = YES;
    t.cell.sendsActionOnEndEditing = YES;
    t.target = a;
    t.action = @selector(fire:);
    [t.widthAnchor constraintEqualToConstant:width].active = YES;
    return t;
}

-(NSButton *)plainCheckboxOn:(BOOL)on enabled:(BOOL)enabled action:(SettingsAction *)a {
    NSButton *b = [SXControls checkboxWithTitle:@"" target:a action:@selector(fire:)];
    b.state = on ? NSControlStateValueOn : NSControlStateValueOff;
    b.enabled = enabled;
    return b;
}

// MARK: - Start Here

-(void)buildStartHere {
    SettingsPageView *page = self.page;
    NSString *s = SettingsSectionStartHere;
    [page addSection:s title:@"Start Here"];
    [page addProse:@"A quick tour of SoqlX: log in, find an object, run a query and take the results with you." inSection:s];
    NSInteger n = 1;
    for (SettingsTopic *step in [SettingsContent startHereSteps]) {
        [page addSubheading:[NSString stringWithFormat:@"%ld. %@", (long)n, step.title] inSection:s];
        [page addProse:step.body inSection:s];
        n++;
    }
    [page addSubheading:@"Tips" inSection:s];
    NSMutableArray<NSString *> *tips = [NSMutableArray array];
    for (SettingsTopic *tip in [SettingsContent tips]) {
        [tips addObject:[NSString stringWithFormat:@"%@: %@", tip.title, tip.body]];
    }
    [page addBullets:tips inSection:s];
}

// MARK: - Appearance

-(void)buildAppearance {
    SettingsPageView *page = self.page;
    NSString *s = SettingsSectionAppearance;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [page addSection:s title:@"Appearance"];

    // Theme
    NSString *theme = [ud stringForKey:PREF_APPEARANCE];
    NSInteger themeIdx = [theme isEqualToString:@"light"] ? 1 : [theme isEqualToString:@"dark"] ? 2 : 0;
    SettingsAction *themeAction = [self actionIn:self.actions block:^(id sender) {
        NSInteger i = [(NSSegmentedControl *)sender selectedSegment];
        NSString *v = i == 1 ? @"light" : i == 2 ? @"dark" : @"system";
        [[NSUserDefaults standardUserDefaults] setObject:v forKey:PREF_APPEARANCE];
        [AppDelegate applyAppearancePreference];
    }];
    [page addRowInSection:s title:@"Theme"
                     text:@"Choose whether SoqlX follows the system appearance or always uses light or dark."
                  control:(self.themeControl = [self segmentedWithLabels:@[@"System", @"Light", @"Dark"] selected:themeIdx action:themeAction])];

    // Density
    NSString *density = [ud stringForKey:PREF_DENSITY];
    NSInteger densityIdx = [density isEqualToString:@"comfortable"] ? 1 : 0;
    SettingsAction *densityAction = [self actionIn:self.actions block:^(id sender) {
        NSInteger i = [(NSSegmentedControl *)sender selectedSegment];
        [[NSUserDefaults standardUserDefaults] setObject:(i == 1 ? @"comfortable" : @"compact") forKey:PREF_DENSITY];
    }];
    [page addRowInSection:s title:@"Density"
                     text:@"Sets how much space rows in the results and the sidebar take."
                  control:(self.densityControl = [self segmentedWithLabels:@[@"Compact", @"Comfortable"] selected:densityIdx action:densityAction])];

    // Text size
    static const double scales[] = {0.9, 1.0, 1.15, 1.3};
    double current = 1.0;
    if ([ud objectForKey:PREF_TEXT_SCALE] != nil) {
        current = [ud doubleForKey:PREF_TEXT_SCALE];
    }
    NSInteger scaleIdx = 1;
    for (NSInteger i = 0; i < 4; i++) {
        if (fabs(scales[i] - current) < 0.001) {
            scaleIdx = i;
        }
    }
    SettingsAction *scaleAction = [self actionIn:self.actions block:^(id sender) {
        NSInteger i = [(NSPopUpButton *)sender indexOfSelectedItem];
        if (i >= 0 && i < 4) {
            [[NSUserDefaults standardUserDefaults] setDouble:scales[i] forKey:PREF_TEXT_SCALE];
        }
    }];
    [page addRowInSection:s title:@"Text size"
                     text:@"Scales the text in the results, the sidebar and the details panel."
                  control:(self.textSizeControl = [self popupWithTitles:@[@"Small", @"Default", @"Large", @"Larger"] selected:scaleIdx action:scaleAction])];

    // Editor font
    AppDelegate *delegate = (AppDelegate *)NSApp.delegate;
    NSTextField *fontLabel = [SXControls labelWithString:@"" font:[NSFont systemFontOfSize:NSFont.systemFontSize] color:NSColor.secondaryLabelColor];
    if ([delegate respondsToSelector:@selector(editFontLabel)]) {
        [fontLabel bind:NSValueBinding toObject:delegate withKeyPath:@"editFontLabel" options:nil];
    }
    NSButton *change = [SXControls defaultButtonWithTitle:@"Change…" target:delegate action:@selector(showFontPrefs:)];
    NSStackView *fontStack = [NSStackView stackViewWithViews:@[fontLabel, change]];
    fontStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    fontStack.spacing = 12;
    fontStack.alignment = NSLayoutAttributeCenterY;
    fontStack.translatesAutoresizingMaskIntoConstraints = NO;
    [page addRowInSection:s title:@"Editor font"
                     text:@"Sets the font used in the SOQL and Apex editors."
                  control:fontStack];

    [page addRowInSection:s title:@"Hide empty properties"
                     text:@"Leaves out fields with no value in the details panel."
                  control:[self checkboxBoundTo:PREF_FILTER_EMPY_PROPS]];
}

// MARK: - Query

-(void)buildQuery {
    SettingsPageView *page = self.page;
    NSString *s = SettingsSectionQuery;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [page addSection:s title:@"Query"];

    [page addRowInSection:s title:@"Syntax highlighting"
                     text:@"Colours keywords, strings and numbers in the SOQL editor."
                  control:[self checkboxBoundTo:PREF_SOQL_SYNTAX_HIGHLIGHTING]];

    NSString *enabledPath = [@"values." stringByAppendingString:PREF_SOQL_SYNTAX_HIGHLIGHTING];
    NSUserDefaultsController *udc = [NSUserDefaultsController sharedUserDefaultsController];

    NSButton *completions = [self checkboxBoundTo:PREF_SOQL_POPUP_COMPLETIONS];
    [completions bind:NSEnabledBinding toObject:udc withKeyPath:enabledPath options:nil];
    [page addRowInSection:s title:@"Completion popups"
                     text:@"Shows a list of matching fields and objects while you type a query."
                  control:completions];

    NSButton *upper = [self checkboxBoundTo:PREF_SOQL_UPPERCASE_KEYWORDS];
    [upper bind:NSEnabledBinding toObject:udc withKeyPath:enabledPath options:nil];
    [page addRowInSection:s title:@"Uppercase keywords"
                     text:@"Turns SELECT, FROM, WHERE and other keywords to capitals as you type."
                  control:upper];

    [page addRowInSection:s title:@"Sort fields in the sidebar"
                     text:@"Lists an object's fields alphabetically instead of in the order Salesforce returns them."
                  control:[self checkboxBoundTo:PREF_SORTED_FIELD_LIST]];
    [page addRowInSection:s title:@"Sort fields in generated queries"
                     text:@"Puts the fields in queries SoqlX writes for you in alphabetical order."
                  control:[self checkboxBoundTo:PREF_QUERY_SORT_FIELDS]];
    [page addRowInSection:s title:@"Use component address fields"
                     text:@"Includes the parts of an address, such as street and city, in generated queries."
                  control:[self checkboxBoundTo:PREF_SKIP_ADDRESS_FIELDS]];

    NSArray<NSNumber *> *counts = @[@10, @25, @50];
    NSMutableArray<NSString *> *titles = [NSMutableArray array];
    for (NSNumber *n in counts) {
        [titles addObject:n.stringValue];
    }
    NSInteger cur = [ud integerForKey:PREF_MAX_RECENT_QUERIES];
    NSInteger idx = (NSInteger)[counts indexOfObject:@(cur)];
    if (idx == NSNotFound) {
        idx = 1;
    }
    SettingsAction *a = [self actionIn:self.actions block:^(id sender) {
        NSInteger i = [(NSPopUpButton *)sender indexOfSelectedItem];
        if (i >= 0 && i < (NSInteger)counts.count) {
            [[NSUserDefaults standardUserDefaults] setInteger:counts[i].integerValue forKey:PREF_MAX_RECENT_QUERIES];
        }
    }];
    [page addRowInSection:s title:@"Recent queries to keep"
                     text:@"Sets how many recently run queries the Recent menu remembers."
                  control:[self popupWithTitles:titles selected:idx action:a]];
}

// MARK: - Safety

-(void)buildSafety {
    SettingsPageView *page = self.page;
    NSString *s = SettingsSectionSafety;
    [page addSection:s title:@"Safety"];
    [page addRowInSection:s title:@"Typed confirmation in Production"
                     text:@"Deleting from a Production org asks you to type DELETE and the number of records first."
                  control:[SettingsPageView badgeWithText:@"Always on"]];
    [page addRowInSection:s title:@"Trial orgs count as Production"
                     text:@"Trial orgs get the same delete protection as Production orgs, including the typed confirmation."
                  control:[SettingsPageView badgeWithText:@"Always on"]];
    [page addRowInSection:s title:@"Ask before every delete"
                     text:@"Asks for confirmation before any delete, in every org, not only in Production."
                  control:[self checkboxBoundTo:PREF_CONFIRM_ALL_DELETES]];
    [page addRowInSection:s title:@"Per-org protection"
                     text:@"Read-only and delete protection for a single org are set under Connections."
                  control:nil];
}

// MARK: - Apex

-(void)buildApex {
    SettingsPageView *page = self.page;
    NSString *s = SettingsSectionApex;
    [page addSection:s title:@"Apex"];
    [page addRowInSection:s title:@"Beep on unbalanced braces"
                     text:@"Plays a sound when the braces in the Apex editor do not match."
                  control:[self checkboxBoundTo:PREF_BRACES_MISMATCH_BEEP]];
}

// MARK: - Connections

-(void)syncAppearanceControls {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *theme = [ud stringForKey:PREF_APPEARANCE];
    self.themeControl.selectedSegment = [theme isEqualToString:@"light"] ? 1 : [theme isEqualToString:@"dark"] ? 2 : 0;
    self.densityControl.selectedSegment = [[ud stringForKey:PREF_DENSITY] isEqualToString:@"comfortable"] ? 1 : 0;
    static const double scales[] = {0.9, 1.0, 1.15, 1.3};
    double current = [ud objectForKey:PREF_TEXT_SCALE] != nil ? [ud doubleForKey:PREF_TEXT_SCALE] : 1.0;
    NSInteger idx = 1;
    for (NSInteger i = 0; i < 4; i++) {
        if (fabs(scales[i] - current) < 0.001) idx = i;
    }
    [self.textSizeControl selectItemAtIndex:idx];
}

-(void)refreshConnections {
    SettingsPageView *page = self.page;
    if (!page) {
        return;
    }
    // Commit a label or consumer key being typed before its field is rebuilt.
    [page.window makeFirstResponder:nil];
    NSString *s = SettingsSectionConnections;
    [page removeContentOfSection:s];
    [self.orgActions removeAllObjects];

    NSString *key = [[NSUserDefaults standardUserDefaults] stringForKey:kConsumerKeyDefault];
    SettingsAction *keyAction = [self actionIn:self.orgActions block:^(id sender) {
        NSString *v = [[(NSTextField *)sender stringValue] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        [(NSTextField *)sender setStringValue:v];
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        if (v.length == 0) {
            [ud removeObjectForKey:kConsumerKeyDefault];
        } else {
            [ud setObject:v forKey:kConsumerKeyDefault];
        }
    }];
    NSTextField *keyField = [self textFieldWithValue:key placeholder:@"Built-in SoqlX app" width:280 action:keyAction];
    [page addRowInSection:s title:@"Consumer key"
                     text:@"Use your own connected app to log in. Leave it empty to use the built-in SoqlX app."
                  control:keyField];

    NSMutableArray<NSString *> *ids = [[OrgSettings allOrgIds] mutableCopy] ?: [NSMutableArray array];
    NSMutableDictionary<NSString *, NSString *> *names = [NSMutableDictionary dictionary];
    for (NSString *orgId in ids) {
        OrgSettings *o = [OrgSettings settingsForOrgId:orgId];
        NSString *n = o.label.length ? o.label : (o.lastKnownName.length ? o.lastKnownName : orgId);
        names[orgId] = n;
    }
    [ids sortUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        return [names[a] caseInsensitiveCompare:names[b]];
    }];

    if (ids.count == 0) {
        [page addProse:@"Log in to an org and it shows up here." inSection:s];
        return;
    }
    for (NSString *orgId in ids) {
        [self addOrgBlockForId:orgId name:names[orgId]];
    }
}

-(void)addOrgBlockForId:(NSString *)orgId name:(NSString *)name {
    SettingsPageView *page = self.page;
    NSString *s = SettingsSectionConnections;
    OrgSettings *settings = [OrgSettings settingsForOrgId:orgId];

    NSMutableArray<NSString *> *parts = [NSMutableArray arrayWithObject:name];
    NSString *kindWord = settings.kindOverride.length ? settings.kindOverride : settings.detectedKindWord;
    if (kindWord.length) {
        [parts addObject:kindWord];
    }
    if (settings.lastKnownHost.length) {
        [parts addObject:settings.lastKnownHost];
    }
    [page addSubheading:[parts componentsJoinedByString:@" · "] inSection:s];

    // Label
    SettingsAction *labelAction = [self actionIn:self.orgActions block:^(id sender) {
        NSString *v = [[(NSTextField *)sender stringValue] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        OrgSettings *o = [OrgSettings settingsForOrgId:orgId];
        o.label = v.length ? v : nil;
        [o save];
    }];
    NSTextField *labelField = [self textFieldWithValue:settings.label placeholder:settings.lastKnownName width:220 action:labelAction];
    [page addRowInSection:s title:@"Label"
                     text:@"The name shown for this org in the window. Leave it empty to use the org's own name."
                  control:labelField];

    // Colour
    NSColorWell *well = [[NSColorWell alloc] initWithFrame:NSMakeRect(0, 0, 44, 24)];
    well.translatesAutoresizingMaskIntoConstraints = NO;
    [well.widthAnchor constraintEqualToConstant:44].active = YES;
    [well.heightAnchor constraintEqualToConstant:24].active = YES;
    NSColor *existing = [settings color];
    well.color = existing ?: NSColor.clearColor;
    SettingsAction *wellAction = [self actionIn:self.orgActions block:^(id sender) {
        NSColor *c = [[(NSColorWell *)sender color] colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
        if (!c) {
            return;
        }
        int r = (int)lround(c.redComponent * 255.0);
        int g = (int)lround(c.greenComponent * 255.0);
        int b = (int)lround(c.blueComponent * 255.0);
        OrgSettings *o = [OrgSettings settingsForOrgId:orgId];
        o.colorHex = [NSString stringWithFormat:@"#%02X%02X%02X", r, g, b];
        [o save];
    }];
    well.target = wellAction;
    well.action = @selector(fire:);
    SettingsAction *clearAction = [self actionIn:self.orgActions block:^(id sender) {
        OrgSettings *o = [OrgSettings settingsForOrgId:orgId];
        o.colorHex = nil;
        [o save];
        well.color = NSColor.clearColor;
    }];
    NSButton *clear = [SXControls defaultButtonWithTitle:@"Clear" target:clearAction action:@selector(fire:)];
    clear.controlSize = NSControlSizeSmall;
    NSStackView *colourStack = [NSStackView stackViewWithViews:@[well, clear]];
    colourStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    colourStack.spacing = 8;
    colourStack.alignment = NSLayoutAttributeCenterY;
    colourStack.translatesAutoresizingMaskIntoConstraints = NO;
    [page addRowInSection:s title:@"Colour"
                     text:@"Tints this org's window so it is easy to tell apart from the others."
                  control:colourStack];

    // Type
    NSString *detected = settings.detectedKindWord.length ? settings.detectedKindWord : @"unknown";
    NSArray<NSString *> *kinds = @[SXOrgKindWord(SXOrgKindProduction), SXOrgKindWord(SXOrgKindSandbox),
                                   SXOrgKindWord(SXOrgKindDeveloper), SXOrgKindWord(SXOrgKindTrial)];
    NSMutableArray<NSString *> *titles = [NSMutableArray arrayWithObject:[NSString stringWithFormat:@"Detected (%@)", detected]];
    [titles addObjectsFromArray:kinds];
    NSInteger sel = 0;
    if (settings.kindOverride.length) {
        BOOL ok = NO;
        SXOrgKind k = SXOrgKindFromWord(settings.kindOverride, &ok);
        if (ok) {
            sel = 1 + (NSInteger)k;
        }
    }
    SettingsAction *typeAction = [self actionIn:self.orgActions block:^(id sender) {
        NSInteger i = [(NSPopUpButton *)sender indexOfSelectedItem];
        OrgSettings *o = [OrgSettings settingsForOrgId:orgId];
        o.kindOverride = (i <= 0 || i > (NSInteger)kinds.count) ? nil : kinds[i - 1];
        [o save];
    }];
    [page addRowInSection:s title:@"Type"
                     text:@"Overrides the kind of org SoqlX detected, which decides how careful it is about deletes."
                  control:[self popupWithTitles:titles selected:sel action:typeAction]];

    // Prevent deleting and Read-only
    __block NSButton *preventBox = nil;
    SettingsAction *preventAction = [self actionIn:self.orgActions block:^(id sender) {
        OrgSettings *o = [OrgSettings settingsForOrgId:orgId];
        o.preventDelete = [(NSButton *)sender state] == NSControlStateValueOn;
        [o save];
    }];
    preventBox = [self plainCheckboxOn:settings.preventDelete enabled:!settings.readOnly action:preventAction];
    SettingsAction *readOnlyAction = [self actionIn:self.orgActions block:^(id sender) {
        BOOL on = [(NSButton *)sender state] == NSControlStateValueOn;
        OrgSettings *o = [OrgSettings settingsForOrgId:orgId];
        o.readOnly = on;
        [o save];
        if (on) {
            preventBox.state = NSControlStateValueOn;
            preventBox.enabled = NO;
        } else {
            preventBox.state = o.preventDelete ? NSControlStateValueOn : NSControlStateValueOff;
            preventBox.enabled = YES;
        }
    }];
    NSButton *readOnlyBox = [self plainCheckboxOn:settings.readOnly enabled:YES action:readOnlyAction];
    if (settings.readOnly) {
        preventBox.state = NSControlStateValueOn;
    }
    [page addRowInSection:s title:@"Prevent deleting"
                     text:@"Blocks deleting records in this org. Always on while the org is read-only."
                  control:preventBox];
    [page addRowInSection:s title:@"Read-only"
                     text:@"Stops SoqlX from changing anything in this org, including deletes and edits."
                  control:readOnlyBox];

    // Forget
    __weak typeof(self) weakSelf = self;
    SettingsAction *forgetAction = [self actionIn:self.orgActions block:^(id sender) {
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = [NSString stringWithFormat:@"Forget %@?", name];
        alert.informativeText = @"This removes the label, colour and protection settings saved for this org. You can log in again at any time.";
        [alert addButtonWithTitle:@"Forget"];
        [alert addButtonWithTitle:@"Cancel"];
        void (^done)(NSModalResponse) = ^(NSModalResponse r) {
            if (r == NSAlertFirstButtonReturn) {
                [OrgSettings removeSettingsForOrgId:orgId];
                [weakSelf refreshConnections];
            }
        };
        NSWindow *w = strongSelf.page.window;
        if (w) {
            [alert beginSheetModalForWindow:w completionHandler:done];
        } else {
            done([alert runModal]);
        }
    }];
    NSButton *forget = [SXControls defaultButtonWithTitle:@"Forget this org" target:forgetAction action:@selector(fire:)];
    [page addRowInSection:s title:@"Forget this org"
                     text:@"Removes everything SoqlX saved about this org."
                  control:forget];
}

// MARK: - Release notes

-(void)buildReleaseNotes {
    SettingsPageView *page = self.page;
    NSString *s = SettingsSectionReleaseNotes;
    [page addSection:s title:@"Release notes"];
    for (ReleaseNote *note in [SettingsContent releaseNotes]) {
        [page addSubheading:[NSString stringWithFormat:@"%@ · %@", note.version, note.date] inSection:s];
        [page addBullets:note.items inSection:s];
    }
}

// MARK: - About

-(void)buildAbout {
    SettingsPageView *page = self.page;
    NSString *s = SettingsSectionAbout;
    [page addSection:s title:@"About"];
    [page addProse:[NSString stringWithFormat:@"SoqlX Rebooted %@ (build %@)", [SettingsContent versionString], [SettingsContent buildString]] inSection:s];
    [page addProse:@"Built on SoqlX by Simon Fell. Uses ZKSforce, Sparkle, Inter and JetBrains Mono." inSection:s];

    SettingsAction *link = [self actionIn:self.actions block:^(id sender) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/superfell/soqlx"]];
    }];
    NSButton *linkButton = [SXControls ghostButtonWithTitle:@"github.com/superfell/soqlx" target:link action:@selector(fire:)];
    [page addRowInSection:s title:@"Source code"
                     text:@"SoqlX is open source. The code and issue tracker live on GitHub."
                  control:linkButton];

    [page addRowInSection:s title:@"Check for updates at startup"
                     text:@"Looks for a newer version of SoqlX each time the app starts."
                  control:[self updatesCheckbox]];
    [page addRowInSection:s title:@"Quit when the last window closes"
                     text:@"Quits SoqlX when you close its last window instead of leaving it running."
                  control:[self checkboxBoundTo:PREF_QUIT_ON_LAST_WINDOW_CLOSE]];
}

@end
