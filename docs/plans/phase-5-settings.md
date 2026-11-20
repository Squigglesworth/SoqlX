# Phase 5: Settings page (replaces the Preferences window)

Status: in progress. Verified only when built and screenshotted on a Mac.

## What changes

- The rail's Settings item, and the app menu's "Settings…" (⌘,), show a Settings page inside the
  window. It covers the sidebar, work area, inspector and status band; the rail and title bar stay.
  Picking Query, Schema or Apex on the rail leaves it.
- Layout per the design system's SettingsPage: a 208pt section list on the left, one scrolling
  column on the right capped at 680pt. Clicking a section scrolls the column; the list follows the
  scroll. Every row is a bold title, one plain sentence, and one right-aligned control. Settings save
  on change. Protections that can't be turned off show an "Always on" badge.
- Sections, in order: Start Here, Appearance, Query, Safety, Apex, Connections, Release notes, About.
- The status band gets "SoqlX Rebooted 5.0 · What's new" on its right; clicking it opens Settings at
  Release notes.
- The old Preferences window is no longer opened (left in MainMenu.xib, removed in the release phase).

### Rows
- **Start Here**: a short walkthrough (log in, pick an object, run, read results, download) and tips
  (hover objects and fields, ⌘-click Ids, double-click an object to build a query, snippets, filter
  menu and Recent, include deleted, typed delete confirmation, org label/colour/read-only, refresh
  metadata, one tab per org).
- **Appearance**: Theme (System / Light / Dark, segmented) · Density (Compact / Comfortable,
  segmented) · Text size (Small / Default / Large / Larger, popup; results, sidebar and details) ·
  Editor font (label + "Change…", the SOQL and Apex editors) · Hide empty properties in Details.
- **Query**: Syntax highlighting · Completion popups (disabled when highlighting is off) · Uppercase
  keywords (same) · Sort fields in the sidebar · Sort fields in generated queries · Use component
  address fields in generated queries · Recent queries to keep (10 / 25 / 50).
- **Safety**: Typed confirmation in Production ("Always on") · Trial orgs count as Production
  ("Always on") · Ask before every delete, in every org (check, new) · a sentence pointing at
  Connections for per-org read-only and delete protection.
- **Apex**: Beep on unbalanced braces. (Log levels stay above the Apex editor.)
- **Connections**: Consumer key (text field, saved on end editing; empty means the built-in app) ·
  then, for each org seen at login, a subheading "<label or name> · <kind> · <host>" and rows: Label
  (text field), Colour (colour well + Clear), Type (Detected / Production / Sandbox / Developer /
  Trial), Prevent deleting, Read-only, and "Forget this org".
- **Release notes**: newest version first, a heading per version and a bulleted list.
- **About**: version and build · credits (Simon Fell's original SoqlX, Sparkle, ZKSforce, Inter,
  JetBrains Mono) · Check for updates at startup · Quit when the last window closes.

## Files and interfaces

### `AppExplorer/Shell/SettingsPageView.h/.m` (new; app target) — delegated
```objc
@interface SettingsPageView : NSView
@property (copy) NSString *pageTitle;                       // drawn once in titleLarge
-(void)addSection:(NSString *)identifier title:(NSString *)title;   // nav item + h2 heading
// Title in bodyStrong ink, text in caption inkMuted (wraps), control right-aligned and vertically
// centred; nil control gives a text-only row. Min height 56, 1pt `line` underneath.
-(void)addRowInSection:(NSString *)identifier title:(NSString *)title text:(NSString *)text control:(nullable NSView *)control;
-(void)addSubheading:(NSString *)text inSection:(NSString *)identifier;   // heading font, SXSpace4 above
-(void)addProse:(NSString *)text inSection:(NSString *)identifier;        // body, ink, wraps
-(void)addBullets:(NSArray<NSString *> *)items inSection:(NSString *)identifier;  // "•" hanging indent
-(void)addView:(NSView *)view inSection:(NSString *)identifier;           // full column width
-(void)removeContentOfSection:(NSString *)identifier;                    // keeps the heading
-(void)scrollToSection:(NSString *)identifier;
@property (readonly, copy) NSString *visibleSection;
+(NSView *)badgeWithText:(NSString *)text;   // sx-badge--accent: accent-soft fill, accent-ink border, label font
@end
```

### `AppExplorer/SettingsContent.h/.m` (new; app + test targets) — delegated
```objc
@interface SettingsTopic : NSObject
@property (copy) NSString *title;  @property (copy) NSString *body;
@end
@interface ReleaseNote : NSObject
@property (copy) NSString *version;  @property (copy) NSString *date;  // "November 2026"
@property (copy) NSArray<NSString *> *items;
@end
@interface SettingsContent : NSObject
+(NSArray<SettingsTopic *> *)startHereSteps;
+(NSArray<SettingsTopic *> *)tips;
+(NSArray<ReleaseNote *> *)releaseNotes;          // newest first; first is 5.0
+(NSString *)versionString;                       // CFBundleShortVersionString of the app bundle, "5.0" fallback
+(NSString *)buildString;                         // CFBundleVersion, same fallback
+(NSString *)footerTitle;                         // "SoqlX Rebooted 5.0 · What's new"
@end
```

### `AppExplorer/OrgSettings.h/.m` (edit) — delegated
New stored fields, written only by `recordOrgInfo:`, never by the user:
```objc
@property (copy, readonly) NSString *lastKnownName;
@property (copy, readonly) NSString *lastKnownHost;
@property (copy, readonly) NSString *detectedKindWord;   // SXOrgKindWord of info.kind
+(void)recordOrgInfo:(OrgInfo *)info;   // stores the three, keeps user fields, saves only when something changed
```

### `AppExplorer/SettingsController.h/.m` (new; app target) — delegated
```objc
extern NSString *const SettingsSectionStartHere, *const SettingsSectionAppearance, *const SettingsSectionQuery,
    *const SettingsSectionSafety, *const SettingsSectionApex, *const SettingsSectionConnections,
    *const SettingsSectionReleaseNotes, *const SettingsSectionAbout;
@interface SettingsController : NSObject
-(instancetype)initWithPage:(SettingsPageView *)page;   // builds every section
-(void)refreshConnections;   // rebuilds the Connections section from OrgSettings; called each time Settings opens
@end
```
Boolean and popup rows bind to `[NSUserDefaultsController sharedUserDefaultsController]` `values.<key>`
so they save on change. Theme writes PREF_APPEARANCE and calls `[AppDelegate applyAppearancePreference]`.
Editor font label binds to the AppDelegate's `editFontLabel`; "Change…" sends `showFontPrefs:` to it.
Org rows write through `OrgSettings` and `save`.

### Edits (orchestrator)
- `Prefs.h/.m`: `PREF_DENSITY` @"Density" ("compact" | "comfortable"), `PREF_TEXT_SCALE` @"TextScale"
  (double: 0.9, 1.0, 1.15, 1.3), `PREF_CONFIRM_ALL_DELETES` @"ConfirmDeletesEverywhere" (bool). Registered in AppDelegate.
- `DesignTokens.h/.m`: `+(CGFloat)textScale` (clamped 0.8–1.5), `+(NSFont *)scaled:(NSFont *)f`,
  `+(CGFloat)rowHeight` (28 compact, 36 comfortable). Results cells, sidebar cells and the results
  font use `scaled:`; sidebar and results row heights use `rowHeight`; both refresh on defaults change.
- `ConfirmDeleteDialog`: `confirmDeleteOf:...` asks whenever `PREF_CONFIRM_ALL_DELETES` is set.
- `ShellView`: `@property (nonatomic, strong) NSView *pageView;` non-nil covers everything right of the rail.
- `Explorer`: `-(void)showSettingsSection:(NSString *)identifier;` (nil keeps the position), rail tag 3,
  leaving Settings on tags 0–2, `OrgSettings recordOrgInfo:` in `loadOrgInfo`, the footer version link.
- `AppDelegate showPreferences:` opens Settings in the main window (a new window if none);
  MainMenu.xib item 129 becomes "Settings…" with that action.

## Tests
- `SettingsContentTests.m`: release notes non-empty, newest first, each with a version and items; first
  version equals `versionString` when run inside the app; start-here steps and tips non-empty with titles
  and bodies; footerTitle contains the version.
- `OrgSettingsTests.m` additions: `recordOrgInfo:` stores name/host/kind, keeps label/colour/toggles,
  and an unchanged second record does not post `OrgSettingsDidChangeNotification`.
- `DesignTokensTests.m`: textScale default 1, clamps 0.5 → 0.8 and 3 → 1.5, rowHeight 28 / 36, `scaled:` multiplies size.

## Steps
1. (delegated, parallel) SettingsPageView · SettingsContent + OrgSettings + tests · SettingsController.
2. (orchestrator) prefs, tokens, scaling, ShellView, Explorer, AppDelegate, MainMenu.xib, pbxproj.
3. Independent review of the whole diff (Opus); build, tests and screenshots on the Mac.
