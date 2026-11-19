# Phase 2: the shell (rail, title bar, org chip, tabs, inspector)

Status: in progress. Verified only when it builds and is screenshotted on a Mac.

## Approach

The main window (`AppExplorer/Base.lproj/Explorer.xib`, window id 290, content view id 291) is laid
out with fixed frames and autoresizing masks, no Auto Layout. Rather than rework the xib, the shell
is built in code and the existing content view is re-parented inside it. Outlets, bindings and the
tokenizer are untouched. Layout inside the old content view keeps working because its subviews
resize relative to it.

```
window.contentView = ShellView
  ┌ title bar (44pt, full-size content view, traffic lights inset) ──────────────────────┐
  │ "SoqlX Rebooted"        [Recent] [Details]                               (OrgChip)   │
  ├──────┬──────────────────────────────────────────────────────────┬──────────────────┤
  │ Nav  │ old content view 291 (sidebar | tab view) unchanged      │ inspector (320)  │
  │ Rail │ except: segmented controls 592 and 87x-3E-Ucd hidden     │ = Details table  │
  │ 64pt │                                                          │ moved from panel │
  └──────┴──────────────────────────────────────────────────────────┴──────────────────┘
```

Native window tabs: `tabbingMode = NSWindowTabbingModePreferred`, one `tabbingIdentifier` for all org
windows, so each org login becomes a tab titled with the org's label.

## Files and interfaces

### `AppExplorer/OrgSettings.h/.m` (new; app + test targets)

```objc
typedef NS_ENUM(NSInteger, SXOrgKind) { SXOrgKindProduction, SXOrgKindSandbox, SXOrgKindDeveloper, SXOrgKindTrial };
NSString *SXOrgKindWord(SXOrgKind kind);            // "Production" "Sandbox" "Developer" "Trial"
SXOrgKind SXOrgKindFromWord(NSString *word, BOOL *ok);

// What the org tells us at login (SELECT Id, Name, IsSandbox, OrganizationType, TrialExpirationDate FROM Organization).
@interface OrgInfo : NSObject
@property (copy) NSString *orgId;            // 15/18 char Id as returned
@property (copy) NSString *name;             // Organization.Name
@property (copy) NSString *organizationType; // "Enterprise Edition", "Developer Edition", ...
@property (copy) NSString *instanceHost;     // e.g. russellbrownme.my.salesforce.com
@property (assign) BOOL isSandbox;
@property (strong) NSDate *trialExpiration;  // nil when not a trial
+(SXOrgKind)kindForType:(NSString *)organizationType isSandbox:(BOOL)isSandbox trialExpiration:(NSDate *)trialExpiration;
-(SXOrgKind)kind;                            // kindForType: on self
@end
// Rules: isSandbox -> Sandbox; type contains "Developer" -> Developer; trialExpiration != nil -> Trial; else Production.

// Per-org, user-set, persisted in NSUserDefaults under "OrgSettings" as {orgId: {label, colorHex, kindOverride, preventDelete, readOnly}}.
@interface OrgSettings : NSObject
@property (copy, readonly) NSString *orgId;
@property (copy) NSString *label;          // nil/empty = use the org name
@property (copy) NSString *colorHex;       // "#RRGGBB" or nil
@property (copy) NSString *kindOverride;   // an SXOrgKindWord, or nil to use the detected kind
@property (assign) BOOL preventDelete;
@property (assign) BOOL readOnly;          // readOnly implies preventDelete (getter returns YES when readOnly)
+(instancetype)settingsForOrgId:(NSString *)orgId;   // never nil; unsaved defaults when nothing stored
-(void)save;
+(void)removeSettingsForOrgId:(NSString *)orgId;
+(NSArray<NSString*>*)allOrgIds;
+(void)useDefaults:(NSUserDefaults *)defaults;        // tests; nil restores standardUserDefaults
-(NSString *)displayLabelForOrgName:(NSString *)orgName;   // label, else orgName, else orgId
-(SXOrgKind)effectiveKindFor:(OrgInfo *)info;              // kindOverride if valid else info.kind
-(NSColor *)color;                                         // parsed colorHex or nil
@end
```

### `AppExplorer/Shell/NavRailView.h/.m` (new; app target)

`NavRailView : NSView`, 64pt wide, fills the height below the title bar. Background `SXTokens.ground`,
1pt `line` on its right edge. Items are 56x56, 24pt template icon above an 11pt label (`SXTokens.label`
font, not uppercased). Active item: `accentSoft` fill, 1pt `accentInk` border, `ink` text and icon,
`SXRadiusSM` corners. Inactive: `inkMuted`. Hover: `surfaceRaised` fill.

```objc
@interface NavRailView : NSView
-(void)addItemWithTitle:(NSString *)title image:(NSImage *)image tag:(NSInteger)tag pinToBottom:(BOOL)bottom;
@property (assign) NSInteger selectedTag;          // setting it redraws; does not fire the action
@property (weak) id target;  @property (assign) SEL action;   // sent on click with the view as sender
@end
```

### `AppExplorer/Shell/OrgChipView.h/.m` (new; app target)

`OrgChipView : NSView`, pill (`SXRadiusPill`), height `SXControlSM` (24), `intrinsicContentSize` from its
text. Content left to right: a 10pt mark, the kind word (`bodyStrong`), then the label (`caption`,
`inkMuted`), then a 10pt colour dot when `color` is set.

- Production: `dangerSoft` fill, 1pt solid `danger` border, square mark in `danger`.
- Sandbox: no fill, 1pt solid `success` border, ring mark in `success`.
- Developer and Trial: no fill, 1pt dashed `accentInk` border, diamond mark in `accentInk`
  (Trial uses the word "Trial").

```objc
@interface OrgChipView : NSView
@property (assign) SXOrgKind kind;
@property (copy) NSString *label;      // org label or name
@property (copy) NSString *detail;     // my domain host, in the tooltip
@property (strong) NSColor *color;     // user colour or nil
@property (weak) id target;  @property (assign) SEL action;   // click (org switcher later)
@end
```

### `AppExplorer/Shell/ShellView.h/.m` (new; app target)

```objc
@interface ShellView : NSView
-(instancetype)initWithContentView:(NSView *)content;   // re-parents content; sets up Auto Layout
@property (readonly) NavRailView *rail;
@property (readonly) OrgChipView *orgChip;
@property (readonly) NSButton *recentToggle;     // bordered=NO, template "history" icon + "Recent"
@property (readonly) NSButton *detailsToggle;    // bordered=NO, template "panel-right" icon + "Details"
@property (readonly) NSView *inspectorContainer; // 0 or SXInspectorWidth wide
@property (readonly) NSTextField *inspectorTitle;
@property (nonatomic) BOOL inspectorVisible;
-(void)setInspectorVisible:(BOOL)visible animated:(BOOL)animated;
@end
```
Title bar: `SXTitlebarHeight` tall, `ground` background, 1pt `line` underneath, product name at x=78
(traffic lights) in `bodyStrong`. Rail on the left below it. Inspector column on the right, `surface`
background, 1pt `line` on its left, header row (`inspectorTitle`, `heading` font) above the container.

### Integration (edits)

- `AppExplorer/AppDelegate.m` `SoqlXWindowController windowDidLoad`: title hidden, transparent
  titlebar, full-size content view, `tabbingMode` preferred, `tabbingIdentifier` "SoqlXRebootedOrg";
  then `[self.explorer installShell]`.
- `AppExplorer/Explorer.h/.m`: `@property (strong) ShellView *shell; @property (strong) OrgInfo *orgInfo;`
  `-(void)installShell;` (wrap content view, hide 592 and 87x-3E-Ucd via the outlets
  `soqlSchemaApexSelector` / `detailsRecentSelector`, MaxYEdge content border 0, rail items Query/Schema/
  Apex tags 0/1/2 + Settings tag 3 pinned, rail action `selectViewFromRail:` which selects the tab view
  item; toggles call `detailsController.windowVisible` / `queryListController.windowVisible`; KVO in
  `observeValueForKeyPath:` updates the toggles' state instead of the old segmented control).
  `postLogin:` additionally runs the Organization query, builds `orgInfo`, and calls `updateOrgChip`.
  `titleUserInfo` returns the org label (or name) plus " · <file>" when a file is open; no username.
  Settings (tag 3) opens the existing Preferences window for now (`showFontPrefs:`-style action on
  the app delegate is not it; use `[NSApp sendAction:@selector(showPreferences:) ...]` only if such a
  selector exists, otherwise open the Preferences window via the menu item's action target).
- `AppExplorer/BaseUserBasedController.h`: declare `-(void)setWindowVisible:(BOOL)v updateWindow:(BOOL)u;`
  so subclasses can override it.
- `AppExplorer/DetailsController.h/.m`: `@property (weak) ShellView *inspectorHost;` override
  `setWindowVisible:updateWindow:` to call super with `updateWindow:NO` and then
  `[inspectorHost setInspectorVisible:v animated:YES]`; in `setDataSource:` also set
  `inspectorHost.inspectorTitle.stringValue = self.title`.
  `Explorer installShell` moves `detailsController.detailsTable.enclosingScrollView` into
  `shell.inspectorContainer` (pinned to all edges) and sets `detailsController.inspectorHost = shell`.
- Icons: `AppExplorer/Media.xcassets/icon.<name>.imageset` from the design system SVGs (query, schema,
  apex, settings, history, panel-right), template rendering.
- `project.pbxproj`: new sources (app: Shell/*.m, OrgSettings.m; tests: OrgSettings.m, OrgSettingsTests.m).

## Tests (`AppExplorer/SoqlXplorerTests/OrgSettingsTests.m`)

- `kindForType:` table: sandbox beats everything; "Developer Edition" -> Developer; trial date -> Trial;
  "Enterprise Edition" with nothing else -> Production; nil type -> Production.
- Round trip through a private `NSUserDefaults` suite: save, re-read, `allOrgIds`, remove.
- `settingsForOrgId:` for an unknown org returns defaults (no label, no colour, both toggles off).
- `readOnly` forces `preventDelete` to read YES; turning readOnly off restores the stored value.
- `displayLabelForOrgName:` precedence and `effectiveKindFor:` with a valid, invalid and nil override.
- `color` parses "#D6A21E" and returns nil for garbage.

## Verification on the Mac

`scripts/run-debug.sh`; then: rail switches views; Details toggle slides the inspector in and out and
the details table shows the selected object; Recent still opens its panel; the chip shows the kind
word and the org name; a second login opens as a tab; Light and Dark both read. Then
`xcodebuild ... test` with the new test file passing.

## Steps

1. OrgSettings model + tests. (delegated, scoped)
2. Icons into the asset catalog. (orchestrator)
3. NavRailView, OrgChipView, ShellView. (delegated, scoped)
4. Integration edits + pbxproj. (orchestrator)
5. Independent review of the full diff for ARC/compile issues, then build on the Mac.
