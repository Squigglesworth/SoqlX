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

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

// The placeholder in a snippet's text that gets replaced with the SObject
// currently selected in the sidebar (or a default) when the snippet is inserted.
extern NSString *const SnippetSObjectPlaceholder;

// A single reusable query, loaded from the bundled snippets.json or from the
// user's own snippets file.
@interface SoqlSnippet : NSObject
@property (strong, nonatomic) NSString *name;        // menu title
@property (strong, nonatomic) NSString *category;    // submenu the snippet is grouped under
@property (strong, nonatomic) NSString *summary;     // one line description, shown as the menu item tooltip
@property (strong, nonatomic) NSString *soql;        // the query text, may contain {SObject}
@property (assign, nonatomic) BOOL userDefined;      // came from the user's file rather than the bundle

// Builds a snippet from its JSON dictionary form. Returns nil and sets error if
// required keys (name, soql) are missing. "soql" may be a string or an array of lines.
+(nullable instancetype)snippetFromDictionary:(NSDictionary*)d error:(NSError **)error;

// The query text with {SObject} replaced. If sobject is nil/empty, "Account" is used.
-(NSString*)soqlForSObject:(nullable NSString*)sobject;
@end

// Loads and merges the bundled snippets with the user's own snippets file, and
// builds the Query > Insert Snippet menu from them.
@interface SnippetLibrary : NSObject

+(instancetype)shared;

// Parses an array of snippet dictionaries from JSON. Exposed for tests.
+(nullable NSArray<SoqlSnippet*>*)snippetsFromData:(NSData*)data userDefined:(BOOL)userDefined error:(NSError **)error;

// Where the user's snippets live: ~/Library/Application Support/SoqlX/snippets.json
+(NSURL*)userSnippetsURL;

// Re-reads the bundled and user snippet files.
-(void)reload;
// Replaces the loaded snippets with this list (for tests).
-(void)useSnippets:(NSArray<SoqlSnippet*>*)snippets;

// All snippets, bundled first then user defined, in file order.
@property (readonly, strong, nonatomic) NSArray<SoqlSnippet*> *snippets;
// Category names in the order they should appear in the menu.
@property (readonly, strong, nonatomic) NSArray<NSString*> *categories;
// Non-nil if the user's snippets file exists but couldn't be read or parsed.
@property (readonly, strong, nonatomic, nullable) NSError *userSnippetsError;

-(NSArray<SoqlSnippet*>*)snippetsInCategory:(NSString*)category;

// Creates the user's snippets file with a worked example if it doesn't exist yet,
// and returns its URL. Returns nil and sets error if the file couldn't be created.
-(nullable NSURL*)ensureUserSnippetsFile:(NSError **)error;

// Replaces the contents of menu with one submenu per category. Each snippet item
// sends action to the first responder with the SoqlSnippet as its representedObject.
-(void)populateMenu:(NSMenu*)menu action:(SEL)action;

@end

NS_ASSUME_NONNULL_END
