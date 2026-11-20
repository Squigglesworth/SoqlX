// Copyright (c) 2012-2015,2018,2019 Simon Fell
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

#import "AppDelegate.h"
#import "Explorer.h"
#import "Prefs.h"
#import <Sparkle/Sparkle.h>
#import "ZKSforceClient.h"
#import "ZKLoginController.h"
#import "ZKUserInfo.h"
#import "SessionIdAuthInfo.h"
#import "Defaults.h"
#import "TStamp.h"
#import "SnippetLibrary.h"
#import "DesignTokens.h"

@interface ZKOAuthInfo(params)
+(NSDictionary*)decodeParams:(NSString*)fragment error:(NSError **)err;
@end


@implementation AppDelegate

@synthesize editFont, editFontLabel;

+ (void)initialize {
    [TStamp class];
    NSMutableDictionary * defaults = [NSMutableDictionary dictionary];
    defaults[@"details"] = @NO;
    defaults[@"soql"] = @"select id, firstname, lastname from contact";
    
    defaults[DEF_SERVERS] = @[LOGIN_LOGIN, LOGIN_TEST];
    defaults[PREF_QUERY_SORT_FIELDS] = @YES;
    defaults[PREF_SKIP_ADDRESS_FIELDS] = @NO;
    defaults[PREF_TEXT_SIZE] = @11;
    defaults[PREF_SORTED_FIELD_LIST] = @YES;
    defaults[PREF_QUIT_ON_LAST_WINDOW_CLOSE] = @YES;
    defaults[PREF_MAX_RECENT_QUERIES] = @10;
    defaults[PREF_FILTER_EMPY_PROPS] = @YES;
    defaults[PREF_SOQL_SYNTAX_HIGHLIGHTING] = @YES;
    defaults[PREF_SOQL_POPUP_COMPLETIONS] = @YES;
    defaults[PREF_SOQL_UPPERCASE_KEYWORDS] = @YES;
    defaults[PREF_BRACES_MISMATCH_BEEP] = @YES;
    defaults[PREF_APPEARANCE] = @"system";
    defaults[PREF_DENSITY] = @"compact";
    defaults[PREF_TEXT_SCALE] = @1.0;
    defaults[PREF_CONFIRM_ALL_DELETES] = @NO;
    defaults[DEF_LOGIN_MRU] = @[];
    
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs registerDefaults:defaults];
    NSFont *font = nil;
    if ([defs integerForKey:PREF_TEXT_SIZE] > 0) {
        double fontSize = [defs doubleForKey:PREF_TEXT_SIZE];
        font = [NSFont userFixedPitchFontOfSize:fontSize];
        if (font == nil) {
            font = [NSFont monospacedDigitSystemFontOfSize:fontSize weight:NSFontWeightRegular];
        }
        NSLog(@"Migrating edit font size %f to font %@", [defs doubleForKey:PREF_TEXT_SIZE], font);
        [NSFont setUserFixedPitchFont:font];
        [defs setObject:@0 forKey:PREF_TEXT_SIZE];
    } else {
        // AppKit stores the user's fixed pitch font choice under NSFixedPitchFont. If there isn't one,
        // the user has never picked a font, so default to the design system's code face.
        if ([defs objectForKey:@"NSFixedPitchFont"] == nil && [SXTokens bundledFontsAvailable]) {
            [NSFont setUserFixedPitchFont:[SXTokens code]];
        }
        font = [NSFont userFixedPitchFontOfSize:0];
        NSLog(@"Using edit font %@", font);
    }
}

// MARK: - Appearance

+(void)applyAppearancePreference {
    NSString *pref = [[NSUserDefaults standardUserDefaults] stringForKey:PREF_APPEARANCE];
    NSAppearance *a = nil;
    if ([pref isEqualToString:@"light"]) {
        a = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    } else if ([pref isEqualToString:@"dark"]) {
        a = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    }
    NSApp.appearance = a;   // nil follows the system setting
}

- (IBAction)setAppearanceFromMenu:(id)sender {
    NSInteger tag = [sender respondsToSelector:@selector(tag)] ? [sender tag] : 0;
    NSString *pref = tag == 1 ? @"light" : tag == 2 ? @"dark" : @"system";
    [[NSUserDefaults standardUserDefaults] setObject:pref forKey:PREF_APPEARANCE];
    [AppDelegate applyAppearancePreference];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    if (item.action == @selector(setAppearanceFromMenu:)) {
        NSString *pref = [[NSUserDefaults standardUserDefaults] stringForKey:PREF_APPEARANCE];
        NSInteger current = [pref isEqualToString:@"light"] ? 1 : [pref isEqualToString:@"dark"] ? 2 : 0;
        item.state = item.tag == current ? NSControlStateValueOn : NSControlStateValueOff;
    }
    return YES;
}

-(instancetype)init {
    self = [super init];
    self.isOpeningFromUrl = NO;
    self.windowControllers = [[NSMutableArray alloc] init];
    [self setEditFontLabelFrom:[NSFont userFixedPitchFontOfSize:0]];
    return self;
}


- (IBAction)launchHelp:(id)sender {
    NSString *help = [NSBundle mainBundle].infoDictionary[@"ZKHelpUrl"];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:help]];
}

// Settings… (⌘,) and the rail's Settings item show the Settings page in the main window.
// The old Preferences window (prefsWindow) is no longer opened.
- (IBAction)showPreferences:(id)sender {
    SoqlXWindowController *target = nil;
    id main = NSApp.mainWindow.windowController;
    if ([main isKindOfClass:[SoqlXWindowController class]]) {
        target = main;
    } else {
        target = self.windowControllers.lastObject;
    }
    if (target == nil) {
        [self openNewWindow:sender];
        target = self.windowControllers.lastObject;
    }
    [target.window makeKeyAndOrderFront:sender];
    [target.explorer showSettingsSection:nil];
}

// MARK: - Query > Insert Snippet

// We're the delegate of the Insert Snippet submenu, so the snippet list (including the
// user's own snippets file) is re-read each time the menu is opened. No restart needed
// after editing the file.
- (void)menuNeedsUpdate:(NSMenu *)menu {
    SnippetLibrary *lib = [SnippetLibrary shared];
    [lib reload];
    [lib populateMenu:menu action:@selector(insertSnippet:)];
}

// Without this, AppKit calls menuNeedsUpdate: (and so re-reads the snippets file) on every
// key press while it looks for key equivalents. None of the snippet items have one.
- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id *)target action:(SEL *)action {
    return NO;
}

- (IBAction)editUserSnippets:(id)sender {
    NSError *err = nil;
    NSURL *url = [[SnippetLibrary shared] ensureUserSnippetsFile:&err];
    if (url == nil) {
        NSAlert *alert = [NSAlert alertWithError:err];
        alert.messageText = @"Unable to create the snippets file";
        [alert runModal];
        return;
    }
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[url]];
}

// If the version of the app has changed, then reset any pref setting that is overriding the API version from
// the default (as a new version likely means we've moved API versions anyway)
-(void)resetApiVersionOverrideIfAppVersionChanged {
    NSDictionary *plist = [NSBundle mainBundle].infoDictionary;
    NSString * currentVersionString = plist[@"CFBundleVersion"];
    float currentVersion = currentVersionString == nil ? 0.0f : currentVersionString.floatValue;
    float lastRun = [[NSUserDefaults standardUserDefaults] floatForKey:@"LastAppVersionRun"];
    if (currentVersion > lastRun) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"zkApiVersion"];
        [[NSUserDefaults standardUserDefaults] setFloat:currentVersion forKey:@"LastAppVersionRun"];
    }
}

// will return the first window that has a login sheet showing, or will create a new one.
-(SoqlXWindowController*)findOrOpenWindowAtLogin {
    for (SoqlXWindowController *c in self.windowControllers) {
        if ([c isWindowLoaded] && c.explorer.loginSheetIsOpen && c.explorer.queryFilename == nil) {
            return c;
        }
    }
    SoqlXWindowController *controller = [[SoqlXWindowController alloc] initWithWindowControllers:self.windowControllers];
    [controller showWindow:self];
    [controller.explorer showLogin:self];
    return controller;
}

-(void)openSoqlXURL:(NSURL *)url {
    NSString *server = [url.host lowercaseString];
    if (!([server hasSuffix:@".salesforce.com"] || [server hasSuffix:@".force.com"])) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Invalid SoqlX URL";
        alert.informativeText = @"supplied server must be a .salesforce.com or .force.com address";
        alert.alertStyle = NSAlertStyleWarning;
        [alert runModal];
        return;
    }
    if (![url.path hasPrefix:@"/sid/"]) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Invalid SoqlX URL";
        alert.informativeText = @"expected to be soqlx://{salesforceServer}/sid/{sessionId}";
        alert.alertStyle = NSAlertStyleWarning;
        [alert runModal];
        return;
    }
    NSString *sid = [url.path substringFromIndex:6]; // remove /sid/ prefix
    [self openWithSession:sid host:url.host andVersion:DEFAULT_API_VERSION];
}

-(void)openOAuthResponse:(NSURL *)url {
    NSError *err = nil;
    NSDictionary *params = nil;
    if (url.fragment.length == 0) {
        // https://help.salesforce.com/s/articleView?id=sf.remoteaccess_oauth_flow_errors.htm&type=5
        // says an error callback for the user-agent flow should use the fragment, but it in practice
        // it appears to send a query string (but does use a fragment in the success case)
        params = [ZKOAuthInfo decodeParams:url.query error:&err];
    } else {
        params = [ZKOAuthInfo decodeParams:url.fragment error:&err];
    }
    if (err != nil) {
        [[NSAlert alertWithError:err] runModal];
        return;
    }
    NSString *controllerId = params[@"state"];
    if (controllerId != nil) {
        for (SoqlXWindowController *wc in self.windowControllers) {
            if ([controllerId isEqualToString:wc.controllerId]) {
                [wc completeOAuthLogin:url];
                return;
            }
        }
    }
    NSLog(@"Unable to find window controller with id %@ in oauth callback", controllerId);
    [[self findOrOpenWindowAtLogin] completeOAuthLogin:url];
}

-(void)openWithSession:(NSString *)sid host:(NSString *)host andVersion:(int)apiVersion {
    NSURL *instanceUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/services/Soap/u/%d.0", host, apiVersion]];
    SessionIdAuthInfo *auth = [[SessionIdAuthInfo alloc] initWithUrl:instanceUrl sessionId:sid];
    ZKSforceClient *c = [[ZKSforceClient alloc] init];
    [c setClientId:[ZKLoginController appClientId]];
    c.authenticationInfo = auth;

    // If the app was just stated to deal with this URL then openUrls is called before appDidFinishLaunching
    // so stop the default window from being opened.
    self.isOpeningFromUrl = YES;
    
    // This call is used to validate that we were given a valid client, and that the auth info is usable.
    [c currentUserInfoWithFailBlock:^(NSError *result) {
        if ([result.userInfo[ZKSoapFaultCodeKey] hasSuffix:@":UNSUPPORTED_API_VERSION"]) {
            NSLog(@"Login failed with %@ on API Version %d, retrying with version %d", result, apiVersion, apiVersion-1);
            [self openWithSession:sid host:host andVersion:apiVersion-1];
            return;
        }
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Invalid parameters";
        alert.informativeText = result.localizedDescription;
        alert.alertStyle = NSAlertStyleWarning;
        [alert runModal];
        
    } completeBlock:^(ZKUserInfo *result) {
        SoqlXWindowController *controller = [[SoqlXWindowController alloc] initWithWindowControllers:self.windowControllers];
        [controller showWindowForClient:c];
        [self.windowControllers makeObjectsPerformSelector:@selector(closeLoginPanelIfOpen:) withObject:self];
    }];
}

-(void)openFileURL:(NSURL *)url {
    // If the app was just stated to deal with this URL then openUrls is called before appDidFinishLaunching.
    // Any window controller we create here will prevent the default one in applicationDidFinishLaunching being
    // created.
    
    // If all the logged in windows are for the same userID, open a new window with the same userID.
    ZKSforceClient *user = nil;
    for (SoqlXWindowController *c in self.windowControllers) {
        if ([c isWindowLoaded] && c.explorer.isLoggedIn) {
            ZKUserInfo *t = c.explorer.sforce.cachedUserInfo;
            ZKUserInfo *p = [user cachedUserInfo];
            if (user == nil || ([p.userId isEqualToString:t.userId] &&
                                [p.organizationId isEqualToString:t.organizationId])) {
                user = c.explorer.sforce;
            } else {
                user = nil;
                break;
            }
        }
    }
    if (user != nil) {
        NSLog(@"Will open new window for %@", user.cachedUserInfo.userName);
        SoqlXWindowController *controller = [[SoqlXWindowController alloc] initWithWindowControllers:self.windowControllers];
        [controller window];
        [controller showWindowForClient:user];
        [controller.explorer load:url];
        return;
    }
    // If there's an existing window that has the login sheet showing, and no asscoicated URL
    // we'll update that one instead of opening a new one.
    [[self findOrOpenWindowAtLogin].explorer load:url];
}

-(void)application:(NSApplication *)application openURLs:(NSArray<NSURL *> *)urls {
    for (NSURL *url in urls) {
        if ([url.absoluteString hasPrefix:@"soqlx://oauth/"]) {
            [self openOAuthResponse:url];
        } else if ([url.scheme isEqualToString:@"soqlx"]) {
            [self openSoqlXURL:url];
        } else if ([url.scheme isEqualToString:@"file"]) {
            [self openFileURL:url];
        } else {
            NSLog(@"Unexpected URL received %@", url.absoluteString);
        }
    }
}

-(void)applicationWillFinishLaunching:(NSNotification *)notification {
    [AppDelegate applyAppearancePreference];
}

-(void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self resetApiVersionOverrideIfAppVersionChanged];
    if (self.windowControllers.count == 0 && !self.isOpeningFromUrl) {
        [self openNewWindow:self];
    }
    
    // If the updater is going to restart the app, we need to close the login sheet if its currently open.
    [[SUUpdater sharedUpdater] setDelegate:self];
}

-(void)openNewWindow:(id)sender {
    SoqlXWindowController *controller = [[SoqlXWindowController alloc] initWithWindowControllers:self.windowControllers];
    [controller showWindow:sender];
    [controller.explorer showLogin:sender];
}

- (void)openNewWindowForOAuthCredential:(id)sender {
    Credential *c = [sender representedObject];
    SoqlXWindowController *controller = [[SoqlXWindowController alloc] initWithWindowControllers:self.windowControllers];
    [controller showWindow:sender];
    [controller.explorer loginWithOAuthToken:c];
}

// Sparkle : SUUpdaterDelegate - Called immediately before relaunching.
- (void)updaterWillRelaunchApplication:(SUUpdater *)updater {
    [self.windowControllers makeObjectsPerformSelector:@selector(closeLoginPanelIfOpen:) withObject:updater];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return [[NSUserDefaults standardUserDefaults] boolForKey:PREF_QUIT_ON_LAST_WINDOW_CLOSE];
}

-(IBAction)showFontPrefs:(id)sender {
    NSFontManager *fm = [NSFontManager sharedFontManager];
    [fm setTarget:self];
    [fm setSelectedFont:self.editFont isMultiple:NO];
    [fm orderFrontFontPanel:self];
}

- (void)changeFont:(nullable NSFontManager *)sender {
    NSFont *newFont = [sender convertFont:self.editFont];
    [self setEditFontLabelFrom:newFont];
    [[self.windowControllers valueForKey:@"explorer"] makeObjectsPerformSelector:@selector(changeEditFont:) withObject:sender];
}

-(void)setEditFontLabelFrom:(NSFont *)f {
    self.editFont = f;
    self.editFontLabel = [NSString stringWithFormat:@"%.1f pt %@", f.pointSize, f.displayName];
}

- (NSFontPanelModeMask)validModesForFontPanel:(NSFontPanel *)fontPanel {
    return NSFontPanelModeMaskFace | NSFontPanelModeMaskSize | NSFontPanelModeMaskCollection;
}

@end

@implementation SoqlXWindowController

@synthesize explorer, controllers;

-(instancetype)initWithWindowControllers:(NSMutableArray *)c {
    self = [super initWithWindowNibName:@"Explorer"];
    self.controllers = c;
    [c addObject:self];
    return self;
}

-(void)showWindowForClient:(ZKSforceClient*)client {
    [self window];    // forces Nib to be loaded, which'll set the explorer outlet/property
    [self.explorer useClient:client];
    [self showWindow:self];
}

-(void)completeOAuthLogin:(NSURL *)url {
    if (self.explorer == nil) {
        [self window];    // forces Nib to be loaded, which'll set the explorer outlet/property
        [self showWindow:self];
    }
    [self.explorer completeOAuthLogin:url];
}

-(void)closeLoginPanelIfOpen:(id)sender {
    [self.explorer closeLoginPanelIfOpen:sender];
}

-(void)windowDidLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:self.window];
    // The shell draws its own title bar area (product name, panel toggles, org chip), so hide the
    // system title and let content extend under the title bar. Every org window joins one tab group.
    NSWindow *w = self.window;
    w.titleVisibility = NSWindowTitleHidden;
    w.titlebarAppearsTransparent = YES;
    w.tabbingMode = NSWindowTabbingModePreferred;
    w.tabbingIdentifier = @"SoqlXRebootedOrg";
    [self.explorer installShell];
}

-(void)windowWillClose:(id)sender {
    // when the window gets closed, remove ourselves from the list of window controllers.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.controllers removeObject:self];
}

-(NSString *)controllerId {
    return self.explorer.loginController.controllerId;
}

@end
