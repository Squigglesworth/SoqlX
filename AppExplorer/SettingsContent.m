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

#import "SettingsContent.h"

@implementation SettingsTopic
@end

@implementation ReleaseNote
@end

static SettingsTopic *Topic(NSString *title, NSString *body) {
    SettingsTopic *t = [[SettingsTopic alloc] init];
    t.title = title;
    t.body = body;
    return t;
}

static ReleaseNote *Note(NSString *version, NSString *date, NSArray<NSString *> *items) {
    ReleaseNote *n = [[ReleaseNote alloc] init];
    n.version = version;
    n.date = date;
    n.items = items;
    return n;
}

static NSString *BundleString(NSString *key) {
    NSBundle *b = [NSBundle mainBundle];
    if (![[b.bundlePath pathExtension] isEqualToString:@"app"]) return @"5.0";
    id v = b.infoDictionary[key];
    if ([v isKindOfClass:[NSString class]] && [v length] > 0) return v;
    return @"5.0";
}

@implementation SettingsContent

+(NSArray<SettingsTopic *> *)startHereSteps {
    return @[
        Topic(@"Log in",
              @"Log in to an org from the login sheet. Each org opens in its own window tab. The chip at the top right shows the org type: Production, Sandbox, Developer or Trial."),
        Topic(@"Find an object",
              @"Type in the filter field above the sidebar to narrow the list. The Recent group shows objects you queried in this org. The filter menu adds custom metadata, platform events and system objects."),
        Topic(@"Build a query",
              @"Double-click an object to write a SELECT with all its fields. Double-click a field to add it to the query. Completions appear as you type."),
        Topic(@"Run it",
              @"Press ⌘R, or click Run below the editor. Tick \"Include deleted and archived\" to query the Recycle Bin too."),
        Topic(@"Read and edit results",
              @"Click a cell to edit it when the org allows it. Ids are links. ⌘-click an Id to open the record in Salesforce. Nulls show as null."),
        Topic(@"Download",
              @"Click Download Results to save the rows as a CSV file."),
    ];
}

+(NSArray<SettingsTopic *> *)tips {
    return @[
        Topic(@"Hover for details",
              @"Hover an object or field in the sidebar to see its label, API name, type and help text. It also shows what you can do with it under Metadata."),
        Topic(@"Hover in the Schema view",
              @"The Schema view shows the same hover details for objects and fields."),
        Topic(@"Insert Snippet",
              @"Use Insert Snippet in the Query menu to start from a common query shape."),
        Topic(@"Refresh after Setup changes",
              @"The refresh button above the sidebar describes the org again. Use it after you add fields in Setup."),
        Topic(@"Details panel",
              @"Details, at the top right, shows everything about the selected object or field."),
        Topic(@"Label and colour your orgs",
              @"Give each org a label and colour in Settings, Connections. Then you can't mix up Production and a sandbox."),
        Topic(@"Read-only orgs",
              @"Mark an org Read-only to block edits, deletes and anonymous Apex."),
        Topic(@"Deleting in Production",
              @"Deleting in Production asks you to type DELETE and the number of records first."),
        Topic(@"Recent queries",
              @"Recent, at the top right, lists your recent queries."),
        Topic(@"One tab per org",
              @"Each org has its own window tab. Press ⌘` or use the tab bar to switch."),
    ];
}

+(NSArray<ReleaseNote *> *)releaseNotes {
    return @[
        Note(@"5.0", @"November 2026", @[
            @"New look: the SoqlX Rebooted design system, in light and dark.",
            @"A nav rail and a docked Details panel.",
            @"An org chip showing Production, Sandbox, Developer or Trial, with a label and colour you set per org.",
            @"Per-org Read-only and Prevent deleting.",
            @"Typed delete confirmation in Production.",
            @"An \"Include deleted and archived\" checkbox.",
            @"Ids are links. Null cells and row stripes are easier to read.",
            @"A Download Results button.",
            @"A Recent group and object filters in the sidebar.",
            @"Hover details on objects and fields.",
            @"Documentation in completions, and a snippet library.",
            @"Log in with your own connected app (web server flow with PKCE). Saved logins survive refresh token rotation.",
            @"A Settings page with Start Here.",
        ]),
        Note(@"4.x", @"2023", @[
            @"The original SoqlX by Simon Fell. See github.com/superfell/soqlx for its history.",
        ]),
    ];
}

+(NSString *)versionString {
    return BundleString(@"CFBundleShortVersionString");
}

+(NSString *)buildString {
    return BundleString(@"CFBundleVersion");
}

+(NSString *)footerTitle {
    return [NSString stringWithFormat:@"SoqlX Rebooted %@ · What's new", [self versionString]];
}

@end
