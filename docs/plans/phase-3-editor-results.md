# Phase 3: editor and results per the design system

Status: in progress. Verified only when built and screenshotted on a Mac.

## What changes, in one screen

- Editor footer (36pt, under the SOQL text view): **Run** as the one mustard button (⌘R), a
  checkbox **Include deleted and archived** (replaces Query All), and the last message.
- Results footer (32pt, under the results grid): **Query more** (default button, shown only when
  there is more), and **Delete N records** (danger, right-aligned, enabled only with a selection
  and only when the org allows deletes).
- Delete goes through `ConfirmDeleteDialog`: typed phrase "DELETE N" in Production; plain confirm
  elsewhere for more than one record; a single record in a non-Production org deletes directly.
- Per-org safety (`OrgSettings`): `preventDelete` disables the delete button and blocks the action;
  `readOnly` also blocks in-grid edits and anonymous Apex, with a sentence saying why.
- Grid: no zebra stripes, 28pt rows, `surface` background; null cells show the word `null` in
  `ink-subtle`; Id values are drawn as links in `link` colour and open the record in the org on
  ⌘-click (tooltip says so); Ids, numbers and dates in the mono `data` font.
- Empty state inside the results panel: before the first run ("Press ⌘R to run the query above")
  and after a zero-row result ("Query returned 0 rows in N ms").
- Editor: keywords and operators drawn in the bold face of the edit font as well as `accent-ink`.

Out of scope: a line-number gutter, wavy error underline, undo toast, the Apex view (phase 7).

## Files and interfaces

### `AppExplorer/Shell/SXControls.h/.m` (new; app target)
Factories for design-system controls, all plain NSButton/NSTextField so keyboard and accessibility
come free. Colours and fonts from `SXTokens`.
```objc
@interface SXControls : NSObject
+(NSButton *)primaryButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action;   // bezelColor accent, attributedTitle on-accent bodyStrong, keyEquivalent set by caller
+(NSButton *)defaultButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action;   // rounded bezel, body font
+(NSButton *)dangerButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action;    // bezelColor danger, on-danger text
+(NSButton *)ghostButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action;     // bordered NO, ink-muted
+(NSButton *)checkboxWithTitle:(NSString *)title target:(id)target action:(SEL)action;
+(NSTextField *)labelWithString:(NSString *)s font:(NSFont *)f color:(NSColor *)c;
+(void)setTitle:(NSString *)title onButton:(NSButton *)button;   // re-applies the variant's attributed title
@end
```
Buttons are `controlSize` regular, height `SXControlMD` via a height constraint only when the caller
uses Auto Layout; factories set `translatesAutoresizingMaskIntoConstraints = NO`.

### `AppExplorer/Shell/EmptyStateView.h/.m` (new; app target)
Left-aligned, `surface` background, padding `SXSpace6`: eyebrow (`label` attrs, uppercase), title
(`title` font, `ink`), body (`body`, `ink-muted`), optional one default button.
```objc
@interface EmptyStateView : NSView
@property (copy) NSString *eyebrow;  @property (copy) NSString *title;  @property (copy) NSString *body;
-(void)setActionTitle:(NSString *)title target:(id)target action:(SEL)action;   // nil title removes it
@end
```

### `AppExplorer/Shell/ConfirmDeleteDialog.h/.m` (new; app + test targets)
```objc
@interface ConfirmDeleteDialog : NSObject
+(NSString *)phraseForCount:(NSUInteger)count;                 // "DELETE 3"
+(BOOL)typed:(NSString *)typed matchesPhraseForCount:(NSUInteger)count;   // trimmed, case-insensitive
+(NSString *)titleForCount:(NSUInteger)count objectName:(NSString *)name; // "Delete 3 Account records?" / "Delete 1 Account record?"
+(BOOL)needsConfirmationForCount:(NSUInteger)count kind:(SXOrgKind)kind;  // Production: always; else count > 1
// Shows an NSAlert sheet on window. Production: an accessory text field; the destructive button
// stays disabled until the typed phrase matches. completion(YES) only when confirmed.
+(void)confirmDeleteOf:(NSUInteger)count objectName:(NSString *)name kind:(SXOrgKind)kind
                window:(NSWindow *)window completion:(void (^)(BOOL confirmed))completion;
@end
```
Alert copy: title as above; informative "They go to the Recycle Bin and can be restored for 15
days." Buttons: "Delete N records" (danger, first) and "Cancel" (second, Escape). The alert's first
button gets `hasDestructiveAction = YES`. The text field delegate enables the button on match.

### `AppExplorer/SalesforceIds.h/.m` (new; app + test targets)
```objc
@interface SalesforceIds : NSObject
+(BOOL)looksLikeId:(id)value;                          // NSString of 15 or 18 [A-Za-z0-9], case-sensitive check only on length/charset
+(NSURL *)recordURLForId:(NSString *)sfId host:(NSString *)host;   // https://<host>/<id>, nil if either is empty
@end
```

### `AppExplorer/ResultTextCell.h/.m` (new; app + test targets)
`ResultTextCell : NSTextFieldCell`. The data cell for every result column.
- `objectValue == nil` → draws "null" in `ink-subtle`, `data` font; not editable-looking.
- `SalesforceIds looksLikeId:` → text in `link` colour, underlined, `data` font.
- NSNumber → `data` font, right aligned. NSDate → `data` font. Otherwise `body` font, `ink`.
- `drawInteriorWithFrame:inView:` applies the above by setting `attributedStringValue` from
  `objectValue` before calling super; nothing else overridden. `-(BOOL)isLinkValue` helper.

### Edits: `AppExplorer/EditableQueryResultWrapper.h/.m`
- Delegate protocol gains `@optional -(BOOL)allowsEditing;` consulted in `allowEdit:` (NO blocks).
- `@property (copy) NSString *instanceHost;` for record URLs.
- `@property (readonly) NSUInteger checkedRowCount;` (count of `row.checked`), KVO-notified wherever
  `hasCheckedRows` is (same will/didChange pairs).
- `-(void)tableClicked:(id)sender`: if `[NSApp currentEvent].modifierFlags & NSEventModifierFlagCommand`
  and the clicked cell value `looksLikeId`, open `recordURLForId:host:` with NSWorkspace.
- `tableView:dataCellForTableColumn:row:` keeps returning the child-result image cell; otherwise the
  column's own data cell (which `QueryResultTable` now sets to a `ResultTextCell`), and for Id values
  sets the cell's toolTip? (no: cells have no tooltip; `tableView:toolTipForCell:rect:tableColumn:row:mouseLocation:`
  returns "⌘-click to open in Salesforce" for Id values).

### Edits: `AppExplorer/QueryResultTable.h/.m`
- `setTableColumn:toIdentifier:label:width:` sets `c.dataCell = [[ResultTextCell alloc] initTextCell:@""]`
  with `editable = YES`.
- `initForTableView:` styles the table: `usesAlternatingRowBackgroundColors = NO`,
  `gridStyleMask = NSTableViewGridNone`, `rowHeight = SXRowCompact`, `backgroundColor = SXTokens.surface`,
  `intercellSpacing = (3, 0)`, `selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular`,
  and `table.target = nil; table.action = nil` left alone; `updateTable` sets `table.target = wrapper`,
  `table.action = @selector(tableClicked:)`.
- Pass-throughs: `@property (copy) NSString *instanceHost` (forwarded to each new wrapper) and
  `@property (readonly) NSUInteger checkedRowCount` (KVO forwarded like `hasCheckedRows`).
- Existing tests must keep passing: `initForTableView:` with a bare table, two system columns first,
  no delegate/describer.

### Edits: `AppExplorer/SoqlTokenizer.h/.m`
- `@property (strong, nonatomic) NSFont *baseFont;` set by the Explorer whenever the edit font is set.
- `removeAttributes:` also re-applies `baseFont` over the whole range when non-nil.
- `applyTokens:` for TTKeyword/TTOperator additionally adds `NSFontAttributeName` = bold variant of
  `baseFont` (`[[NSFontManager sharedFontManager] convertFont:baseFont toHaveTrait:NSBoldFontMask]`),
  cached until `baseFont` changes.

### Edits: `AppExplorer/ApexController.h/.m`
- `@property (copy) NSString *(^executionBlockedReason)(void);` If set and it returns a string,
  `executeApex:` shows an NSAlert with that string and returns.

### Edits: `AppExplorer/Explorer.h/.m` (orchestrator)
- `installQueryChrome` (called from `installShell`): hides buttons 927/931/932/1350 and separator
  1410 via new outlets? No new outlets: find them by walking `soql.enclosingScrollView.superview`
  (the box content view) and hiding every `NSButton` and `NSBox` subview; shrink the editor scroll
  view to leave 36pt at the bottom; add `editorFooter` (NSView, surface-sunken, 1pt line on top) with
  Run (primary, keyEquivalent "\r" with ⌘), the checkbox (bound to a new `includeDeleted` BOOL
  property), and `editorMessage` label bound to `statusText`.
  Wrap the root results scroll view (pane 1 of `soqlTextSplitView`) in a container: scroll view
  fills it minus a 32pt `resultsFooter` (Query more default button bound hidden←!canQueryMore,
  Delete danger button title←`deleteButtonTitle`, enabled←`hasSelectedForDelete`); `EmptyStateView`
  overlays the scroll view, shown when `rootResults.queryResult == nil` or has 0 records.
- `executeQuery:` uses `self.includeDeleted`; `executeQueryAll:` stays for the menu.
- New properties: `includeDeleted` (BOOL), `deleteButtonTitle` (depends on
  `rootResults.checkedRowCount`), `deletesAllowed`, `writesAllowed` (depend on `orgInfo`).
  `hasSelectedForDelete` = checked rows > 0 AND `deletesAllowed`.
- `deleteCheckedRows:`: if !deletesAllowed → alert "Deleting is turned off for this org in Settings."
  else `ConfirmDeleteDialog confirmDeleteOf:...` then the existing `BulkDelete`.
- `allowsEditing` (wrapper delegate) returns `writesAllowed`; `apexController.executionBlockedReason`
  returns "This org is read-only in Settings." when !writesAllowed.
- `rootResults.instanceHost = orgInfo.instanceHost` once org info loads; also `sforce.serverUrl.host`
  right after login.
- Empty state updates in the query completion block and on `setQueryResult:`.

## Tests
- `SalesforceIdsTests.m`: 15/18 char Ids pass, 14/19 fail, non-alphanumerics fail, NSNumber fails,
  URL built as `https://host/id`, nil for empty host.
- `ConfirmDeleteDialogTests.m`: phrase, matching (trim, case), titles singular/plural, needsConfirmation
  table (Production 1 → YES; Sandbox 1 → NO; Sandbox 2 → YES; Developer 5 → YES; Trial 1 → YES).
- `QRWrapperTest.m` additions: `checkedRowCount` after `setChecksOnAllRows`, `allowsEditing` NO blocks
  `allowEdit:` (via `control:textShouldBeginEditing:` returning NO with a stub delegate).

## Steps
1. (delegated) SXControls, EmptyStateView, ConfirmDeleteDialog + its tests.
2. (delegated) SalesforceIds + tests, ResultTextCell, wrapper and QueryResultTable edits + QRWrapperTest additions.
3. (orchestrator) tokenizer bold keywords, ApexController guard, Explorer integration, pbxproj.
4. Independent review of the whole diff; build and screenshots on the Mac; tests.
