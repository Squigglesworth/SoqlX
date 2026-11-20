# Phase 4: the sidebar (object tree)

Status: in progress. Verified only when built and screenshotted on a Mac.

## What changes, in one screen

```
┌ sidebar (260 default, user-resizable) ─┐
│ [ Filter objects and fields   ] [≡]    │  search field + filter menu button, pinned to the top
│ RECENT                                 │  group row; objects you ran queries against, this org
│   ▪ Opportunity                        │  not expandable: a jump list
│   ▪ Account                            │
│ ALL OBJECTS              412 of 1,038  │  group row; count shows when filters hide objects
│ ▸ ▪ Account                            │  flat 16pt icon in a fixed box, text never overlaps
│ ▾ ▪ Contact                            │
│       AccountId          → Account     │  fields: mono name left, type right (ink-subtle)
│       Email              email(80)     │
└────────────────────────────────────────┘
```

- Filter menu (checkmark items): Standard objects, Custom objects, Custom metadata types, Platform
  events, separator, Show system objects (Feed, History, Share, ChangeEvent), Show non-queryable
  objects, separator, Reset filters. Persisted app-wide; every window follows. The button turns
  `accent-ink` when the filter is not the default.
- Text filter matches object and field API names and labels.
- Selection: `accent-soft` rounded fill, semibold text. Hover: `surface-raised`.
- Hover text on objects and fields, with the facts first and the capabilities under "Metadata:".
  The schema view's tooltips use the same text. Completions keep their shorter `documentation`.
- Recent: the top-level FROM object of each successful query, most recent first, 8 per org,
  stored per Organization Id.

Out of scope: drag to insert, badges, a density setting (phase 5), text size (phase 5).

## Decisions and their reasons

- Platform events are not queryable, so "Show non-queryable" never hides them; their own checkbox does.
- `deprecatedAndHidden` objects count as system objects.
- `LoginHistory` is not a system object even though it ends in History; admins query it.
- Recent entries are not expandable. NSOutlineView needs each item to appear once, and an object
  in both groups with expanded fields would put the same field items in the tree twice.
- Field "description" is not in the describe API; the hover shows the inline help text instead.
- Defaults: Standard, Custom and Metadata on; Platform events, system and non-queryable off.

## Files and interfaces

### `AppExplorer/SObjectKinds.h/.m` (new; app + test targets)
```objc
typedef NS_ENUM(NSInteger, SXObjectKind) {
    SXObjectKindStandard, SXObjectKindCustom, SXObjectKindMetadata, SXObjectKindPlatformEvent
};
@interface SObjectKinds : NSObject
// Suffixes are matched case-insensitively. __mdt -> Metadata; __e -> PlatformEvent; custom flag,
// customSetting flag, or any other "__" suffix (__c __x __b __kav __Share __History __Feed
// __ChangeEvent ...) -> Custom; else Standard.
+(SXObjectKind)kindForName:(NSString *)name custom:(BOOL)custom customSetting:(BOOL)customSetting;
// "Standard object" "Custom object" "Custom setting" "Custom metadata type" "Platform event"
// "External object" (__x) "Big object" (__b); system companions: "Field history" (…History),
// "Feed" (…Feed), "Sharing" (…Share), "Change event" (…ChangeEvent).
+(NSString *)kindDescriptionForName:(NSString *)name custom:(BOOL)custom customSetting:(BOOL)customSetting;
// Name ends in Feed, History, Share or ChangeEvent (and is longer than the suffix), except LoginHistory.
+(BOOL)isSystemObjectName:(NSString *)name;
@end
```

### `AppExplorer/SidebarFilter.h/.m` (new; app + test targets)
```objc
extern NSString *const SidebarFilterDefaultsKey;   // @"SidebarFilter", a dictionary of the six BOOLs
@interface SidebarFilter : NSObject <NSCopying>
@property (assign) BOOL showStandard, showCustom, showMetadata, showPlatformEvents, showSystem, showNonQueryable;
+(instancetype)defaultFilter;
+(instancetype)filterFromDefaults:(NSUserDefaults *)defaults;   // missing keys take the default values
-(void)saveToDefaults:(NSUserDefaults *)defaults;
-(BOOL)isDefault;
-(BOOL)isEqual:(id)other;  -(NSUInteger)hash;
// deprecatedAndHidden or isSystemObjectName -> needs showSystem; then the kind's toggle;
// then !queryable needs showNonQueryable unless the kind is PlatformEvent.
-(BOOL)includesName:(NSString *)name custom:(BOOL)custom customSetting:(BOOL)customSetting
          queryable:(BOOL)queryable deprecatedAndHidden:(BOOL)deprecatedAndHidden;
@end
```

### `AppExplorer/RecentObjects.h/.m` (new; app + test targets)
```objc
extern NSString *const RecentObjectsDefaultsKey;   // @"RecentSObjects", {orgId: [names, most recent first]}
@interface RecentObjects : NSObject
+(void)useDefaults:(NSUserDefaults *)defaults;     // tests; nil restores standardUserDefaults
+(NSUInteger)limit;                                // 8
+(NSArray<NSString *> *)namesForOrgId:(NSString *)orgId;          // never nil
+(void)recordName:(NSString *)name forOrgId:(NSString *)orgId;    // front, case-insensitive dedupe, trim; empty -> no-op
// The object after the first FROM that is outside parentheses and string literals; nil when none
// or when the text is SOSL (starts with FIND).
+(NSString *)primaryObjectInQuery:(NSString *)soql;
@end
```

### `AppExplorer/DescribeExtras.h/.m` (edit; already in both targets)
```objc
@interface ZKDescribeGlobalSObject (Hover)
-(NSString *)hoverTextWithDescribe:(nullable ZKDescribeSObject *)describe;   // describe adds counts
@end
@interface ZKDescribeField (Hover)
-(NSString *)hoverText;
@end
```
Object format (lines omitted when empty; a blank line before "Metadata:"):
```
Account                                   label (labelPlural not shown)
API name: Account
Kind: Standard object · key prefix 001
Fields: 64 · child relationships: 41      only with a describe

Metadata:
Query: queryable, searchable              or "not queryable"
Edit: create, update, delete, undelete    the ones that are YES; "read only" when none
Flags: custom setting, feed tracking, triggers, mergeable   only the YES ones; line omitted if none
```
Field format:
```
Annual Revenue
API name: AnnualRevenue
Type: currency(18,0)                      the existing typeDescription ("reference to Account")
Help text: …                              inlineHelpText
Values: a, b, c, +N more                  as documentation does today
Formula: …

Metadata:
Query: filterable, sortable, groupable · not aggregatable    YES ones, then "not" + NO ones, of these four
Edit: create and update | create only | update only | read only   then ", required" when !nillable && createable && !defaultedOnCreate
Flags: custom, formula, auto number, external id, unique, id lookup, name field, encrypted
```

### `AppExplorer/SidebarItems.h/.m` (new; app target)
```objc
@interface SidebarGroup : NSObject
+(instancetype)groupWithIdentifier:(NSString *)identifier title:(NSString *)title;
@property (copy, readonly) NSString *identifier;   // @"recent" or @"all"
@property (copy, readonly) NSString *title;        // "Recent", "All objects"
@property (copy) NSString *detail;                 // "412 of 1,038", or nil
@end
@interface SidebarRecentItem : NSObject
+(instancetype)itemWithSObject:(ZKDescribeGlobalSObject *)sobject;
@property (strong, readonly) ZKDescribeGlobalSObject *sobject;
@end
```

### `AppExplorer/HighlightTextFieldCell.h/.m` (rewrite; the sidebar's only cell)
```objc
typedef NS_ENUM(NSInteger, SidebarRowStyle) { SidebarRowObject, SidebarRowField, SidebarRowGroup };
@interface HighlightTextFieldCell : NSTextFieldCell
@property (assign) SidebarRowStyle rowStyle;
@property (strong) NSImage *icon;         // object rows: drawn in a 16x16 box, vertically centred,
                                          // clipped to SXRadiusXS corners; the box is reserved even
                                          // when nil so names line up
@property (copy) NSString *detailText;    // right-aligned: field type, group count
@property (assign) BOOL standout;         // filter match: accent-soft rounded fill behind the name, accent-ink text
@property (assign) BOOL dimmed;           // object not yet described: ink-muted
@property (assign) BOOL selectedRow;      // semibold
@end
```
Drawing (`drawWithFrame:inView:` fully custom, ignores backgroundStyle; `highlightColorWithFrame:` nil):
- Object: icon at x+SXSpace1, name at x+SXSpace1+16+SXSpace2, `body` (or `bodyStrong` when selected), `ink`.
- Field: name in `data` (`dataStrong` when selected) `inkMuted`; detail in `mono:11 weight:regular` `inkSubtle`,
  right-aligned with SXSpace2 padding; name truncates before it.
- Group: title uppercase with `labelAttributes`, `inkSubtle`, bottom-aligned with SXSpace1 below; detail
  right-aligned in `caption` `inkSubtle`.
- Text vertically centred (groups excepted), truncating tail.

### `AppExplorer/SidebarOutlineView.h/.m` (new; app target; Explorer.xib outline 1387 `customClass`)
```objc
@interface SidebarOutlineView : NSOutlineView
@property (readonly) NSInteger hoveredRow;   // -1 when none
@end
```
- `awakeFromNib`: selection style regular, `backgroundColor` surface, intercell (0,0), indentation 14,
  `allowsExpansionToolTips` NO, `floatsGroupRows` NO, `rowHeight` SXRowCompact, focus ring none.
- `highlightSelectionInClipRect:`: `accent-soft` rounded rect (SXRadiusSM) inset SXSpace1 horizontally, 1 vertically.
- `drawBackgroundInClipRect:`: super, then the hovered row in `surface-raised` (not selected, not group rows).
- Tracking area (mouseMoved, mouseExited, activeInKeyWindow|inVisibleRect) updates `hoveredRow` and redraws both rows.

### `AppExplorer/DataSources.h/.m` (edit; orchestrator)
- Root children: `recentGroup` (only when it has entries after the text filter) then `allGroup`.
- `outlineView:isGroupItem:` YES for SidebarGroup; `shouldSelectItem:` NO for groups.
- Expandable: groups, ZKDescribeGlobalSObject. Not: SidebarRecentItem, fields.
- `@property (copy) NSString *orgId;` setter reloads recents; `prefsChanged:` re-reads the
  SidebarFilter and the recents from standard defaults and refilters only when either changed.
- `-(id)modelItemForItem:(id)item;` SidebarRecentItem -> its sobject; SidebarGroup -> nil; else item.
- `-(SidebarFilter *)categoryFilter;` current filter.
- Text filter matches labels too. `allGroup.detail` = "N of M" when filters hide anything, "M" otherwise.
- `outlineView:toolTipForCell:rect:tableColumn:item:mouseLocation:` returns the hover texts.
- `dataCellForTableColumn:` nil column -> a separate group cell for group rows, nil otherwise.
- Every reload expands both groups.

### `AppExplorer/Explorer.m` (edit; orchestrator)
- `installSidebarChrome` from `installShell`: move the search field (found by its action) into the
  sidebar pane above the tree with a filter button (SF Symbol `line.3.horizontal.decrease.circle`)
  beside it; grow the split view up into the band the old search field and view switcher used;
  set the sidebar to SXSidebarWidth when no autosaved split exists.
- Filter menu actions save a modified `SidebarFilter` to standard defaults.
- `describeItemClicked:`, `selectedSObjectChanged:`, `selectedSObjectName` read the item through
  `modelItemForItem:` and do nothing for groups / no selection.
- Successful query: `RecentObjects primaryObjectInQuery:`; if describable and the org id is known,
  record it. `loadOrgInfo` sets `descDataSource.orgId` (nil first on re-login).
- `SchemaView.m` tooltips use the hover texts.

## Tests
- `SObjectKindsTests.m`: kinds for Account, Foo__c, Foo__mdt, Foo__e, Foo__x, a custom-setting name,
  Foo__History (Custom); descriptions; system names (AccountHistory, AccountFeed, AccountShare,
  AccountChangeEvent, Foo__History, Foo__Share) yes; LoginHistory, Account, History, Share no.
- `SidebarFilterTests.m`: default values and isDefault; round trip through a private suite; missing
  keys give defaults; includes table (system needs showSystem, deprecated needs showSystem, kind
  toggles, non-queryable hidden by default, platform event shown though not queryable, isEqual/copy).
- `RecentObjectsTests.m`: record order, case-insensitive dedupe, limit 8, per-org separation, empty
  names ignored; primaryObjectInQuery: simple, uppercase FROM, newline whitespace, subquery in the
  select list, semi-join in WHERE, string literal containing " from x", FIND -> nil, no FROM -> nil.
- `HelpDocsTests.m` additions: Account hover has "API name: Account", "Metadata:" after the facts,
  "Query: queryable"; Contact.AccountId hover has "Type: reference to Account" and "Metadata:".

## Steps
1. (delegated, Sonnet) SObjectKinds, SidebarFilter, RecentObjects, hover categories + all tests.
2. (delegated, Sonnet) SidebarItems, HighlightTextFieldCell rewrite, SidebarOutlineView.
3. (orchestrator) DataSources, Explorer, SchemaView, xib customClass, pbxproj.
4. Independent review (Opus) of the whole diff; build, tests and screenshots on the Mac.
