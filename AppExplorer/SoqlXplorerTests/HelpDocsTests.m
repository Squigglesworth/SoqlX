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

#import <XCTest/XCTest.h>
#import <ZKSforce/ZKSforce.h>
#import "SoqlDocs.h"
#import "SoqlFunction.h"
#import "Completion.h"
#import "DescribeExtras.h"
#import "SnippetLibrary.h"
#import "CaseInsensitiveStringKey.h"

// Tests for the in-app help: keyword/function docs on completions, describe
// based field/object docs, and the query snippet library.
@interface HelpDocsTests : XCTestCase
@end

@implementation HelpDocsTests

-(NSString*)testsDir {
    NSString *thisFile = [NSString stringWithUTF8String:__FILE__];
    return [thisFile stringByDeletingLastPathComponent];
}

-(NSArray<ZKDescribeSObject*>*)describes {
    NSString *descFile = [[self testsDir] stringByAppendingPathComponent:@"describes.xml"];
    NSData *descData = [NSData dataWithContentsOfFile:descFile];
    ZKElement *root = [ZKParser parseData:descData];
    ZKXmlDeserializer *deser = [[ZKXmlDeserializer alloc] initWithXmlElement:root];
    return [deser complexTypeArrayFromElements:@"describe" cls:[ZKDescribeSObject class]];
}

-(ZKDescribeSObject*)describe:(NSString*)name {
    for (ZKDescribeSObject *o in [self describes]) {
        if ([o.name isEqualToString:name]) {
            return o;
        }
    }
    return nil;
}

-(ZKDescribeField*)field:(NSString*)name on:(ZKDescribeSObject*)o {
    for (ZKDescribeField *f in o.fields) {
        if ([f.name isEqualToString:name]) {
            return f;
        }
    }
    return nil;
}

// MARK: - keyword / operator / literal docs

-(void)testKeywordDocs {
    XCTAssertNotNil([SoqlDocs docFor:@"LIMIT" type:TTKeyword]);
    XCTAssertNotNil([SoqlDocs docFor:@"order   by" type:TTKeyword], @"should be case and whitespace insensitive");
    XCTAssertNotNil([SoqlDocs docFor:@"LIKE" type:TTOperator]);
    XCTAssertNotNil([SoqlDocs docFor:@"NOT IN" type:TTOperator]);
    XCTAssertNotNil([SoqlDocs docFor:@"LAST_N_DAYS:7" type:TTLiteralNamedDateTime], @"trailing :n should be ignored");
    XCTAssertNotNil([SoqlDocs docFor:@"today" type:TTLiteralNamedDateTime]);
    XCTAssertNotNil([SoqlDocs docFor:@"TRUE" type:TTLiteralBoolean]);
    XCTAssertNil([SoqlDocs docFor:@"Name" type:TTField]);
    XCTAssertNil([SoqlDocs docFor:@"" type:TTKeyword]);
    XCTAssertNil([SoqlDocs docFor:@"NotAKeyword" type:TTKeyword]);
    XCTAssertTrue([SoqlDocs documentedTerms].count > 80);
}

-(void)testEveryDocHasASignatureLineAndDescription {
    for (NSString *term in [SoqlDocs documentedTerms]) {
        NSString *doc = [SoqlDocs docFor:term type:0];
        XCTAssertNotNil(doc, @"%@", term);
        NSArray *lines = [doc componentsSeparatedByString:@"\n"];
        XCTAssertTrue(lines.count >= 2, @"%@ should have a signature line and a description: %@", term, doc);
    }
}

-(void)testCompletionsPickUpKeywordDocs {
    Completion *c = [Completion txt:@"TRACKING" type:TTKeyword];
    XCTAssertTrue([c.documentation containsString:@"UPDATE TRACKING"]);
    Completion *op = [Completion txt:@"INCLUDES" type:TTOperator];
    XCTAssertTrue(op.documentation.length > 0);
    Completion *f = [Completion txt:@"Name" type:TTField];
    XCTAssertNil(f.documentation);
}

-(void)testLazyDocumentationProvider {
    Completion *c = [Completion txt:@"Account" type:TTSObject];
    XCTAssertNil(c.documentation);
    __block int calls = 0;
    c.documentationProvider = ^NSString*{
        calls++;
        return @"built";
    };
    XCTAssertEqualObjects(@"built", c.documentation);
    XCTAssertEqualObjects(@"built", c.documentation);
    XCTAssertEqual(1, calls, @"provider should only be called once");
}

// MARK: - function docs

-(void)testEveryFunctionIsDocumented {
    NSDictionary<CaseInsensitiveStringKey*,SoqlFunction*> *all = [SoqlFunction all];
    XCTAssertTrue(all.count > 20);
    for (SoqlFunction *f in all.allValues) {
        XCTAssertTrue(f.doc.length > 0, @"%@ has no doc", f.name);
        XCTAssertTrue([f.signature hasPrefix:f.name.uppercaseString], @"%@ signature is %@", f.name, f.signature);
        XCTAssertTrue([f.documentation containsString:f.doc], @"%@", f.name);
    }
    SoqlFunction *cy = all[[CaseInsensitiveStringKey of:@"calendar_year"]];
    XCTAssertEqualObjects(@"CALENDAR_YEAR(field|function)", cy.signature);
    SoqlFunction *dist = all[[CaseInsensitiveStringKey of:@"distance"]];
    XCTAssertEqualObjects(@"DISTANCE(field, function, string)", dist.signature);
    SoqlFunction *count = all[[CaseInsensitiveStringKey of:@"count"]];
    XCTAssertTrue([count.signature containsString:@"COUNT()"]);
}

-(void)testFunctionCompletionCarriesDocs {
    ZKDescribeSObject *acc = [self describe:@"Account"];
    XCTAssertNotNil(acc);
    SoqlFunction *fmt = [SoqlFunction all][[CaseInsensitiveStringKey of:@"format"]];
    Completion *c = [fmt completionOn:acc];
    XCTAssertTrue([c.documentation hasPrefix:@"FORMAT("], @"%@", c.documentation);
    XCTAssertTrue([c.documentation containsString:fmt.doc]);
}

// MARK: - describe docs

-(void)testFieldDocumentation {
    ZKDescribeSObject *contact = [self describe:@"Contact"];
    XCTAssertNotNil(contact);
    ZKDescribeField *name = [self field:@"Name" on:contact];
    XCTAssertNotNil(name);
    NSString *doc = [name documentation];
    XCTAssertTrue([doc hasPrefix:@"Name"], @"%@", doc);
    XCTAssertTrue([doc containsString:@"string"], @"%@", doc);
    XCTAssertEqualObjects(doc, name.completion.documentation, @"the completion should carry the field docs");

    ZKDescribeField *accId = [self field:@"AccountId" on:contact];
    XCTAssertNotNil(accId);
    XCTAssertTrue([[accId documentation] containsString:@"reference to Account"], @"%@", [accId documentation]);
}

-(void)testSObjectDocumentation {
    ZKDescribeSObject *acc = [self describe:@"Account"];
    NSString *doc = [acc documentation];
    XCTAssertTrue([doc hasPrefix:@"Account"], @"%@", doc);
    XCTAssertTrue([doc containsString:@"fields"], @"%@", doc);
}

-(void)testRelationshipCompletionsCarryDocs {
    ZKDescribeSObject *contact = [self describe:@"Contact"];
    NSArray<Completion*> *rels = [contact parentRelCompletions];
    XCTAssertTrue(rels.count > 0);
    BOOL found = NO;
    for (Completion *c in rels) {
        if ([c.displayText isEqualToString:@"Account"]) {
            found = YES;
            XCTAssertTrue([c.documentation containsString:@"Account"], @"%@", c.documentation);
            XCTAssertEqualObjects(@"Account.Id", c.finalInsertionText);
        }
    }
    XCTAssertTrue(found);
}

// MARK: - snippets

-(NSData*)bundledSnippetsData {
    NSString *path = [[[self testsDir] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"snippets.json"];
    return [NSData dataWithContentsOfFile:path];
}

-(void)testBundledSnippetsLoad {
    NSData *data = [self bundledSnippetsData];
    XCTAssertNotNil(data, @"snippets.json should be next to the app sources");
    NSError *err = nil;
    NSArray<SoqlSnippet*> *snippets = [SnippetLibrary snippetsFromData:data userDefined:NO error:&err];
    XCTAssertNil(err);
    XCTAssertTrue(snippets.count >= 30);
    NSMutableSet<NSString*> *names = [NSMutableSet set];
    for (SoqlSnippet *s in snippets) {
        XCTAssertTrue(s.name.length > 0);
        XCTAssertTrue(s.category.length > 0, @"%@ needs a category", s.name);
        XCTAssertTrue(s.summary.length > 0, @"%@ needs a summary", s.name);
        XCTAssertTrue(s.soql.length > 0, @"%@ needs a query", s.name);
        XCTAssertFalse(s.userDefined);
        XCTAssertFalse([names containsObject:s.name], @"duplicate snippet name %@", s.name);
        [names addObject:s.name];
        XCTAssertFalse([[s soqlForSObject:@"Case"] containsString:SnippetSObjectPlaceholder], @"%@", s.name);
    }
}

-(void)testSnippetParsing {
    NSError *err = nil;
    NSData *missingSoql = [@"[{\"name\":\"x\"}]" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertNil([SnippetLibrary snippetsFromData:missingSoql userDefined:YES error:&err]);
    XCTAssertNotNil(err);

    err = nil;
    NSData *notJson = [@"nope" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertNil([SnippetLibrary snippetsFromData:notJson userDefined:YES error:&err]);
    XCTAssertNotNil(err);

    err = nil;
    NSData *wrapped = [@"{\"snippets\":[{\"name\":\"x\",\"soql\":[\"SELECT Id\",\"FROM {SObject}\"]}]}" dataUsingEncoding:NSUTF8StringEncoding];
    NSArray<SoqlSnippet*> *s = [SnippetLibrary snippetsFromData:wrapped userDefined:YES error:&err];
    XCTAssertNil(err);
    XCTAssertEqual(1, (int)s.count);
    SoqlSnippet *sn = s[0];
    XCTAssertEqualObjects(@"My Snippets", sn.category, @"user snippets without a category go in a default one");
    XCTAssertTrue(sn.userDefined);
    XCTAssertEqualObjects(@"SELECT Id\nFROM Contact", [sn soqlForSObject:@"Contact"]);
    XCTAssertEqualObjects(@"SELECT Id\nFROM Account", [sn soqlForSObject:nil], @"no selected object falls back to Account");
}

-(void)testPopulateMenu {
    NSError *err = nil;
    NSArray<SoqlSnippet*> *snippets = [SnippetLibrary snippetsFromData:[self bundledSnippetsData] userDefined:NO error:&err];
    XCTAssertNil(err);
    SnippetLibrary *lib = [SnippetLibrary new];
    [lib useSnippets:snippets];
    XCTAssertTrue(lib.categories.count >= 5);
    XCTAssertEqualObjects(@"Basics", lib.categories[0], @"categories keep file order");

    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Insert Snippet"];
    [lib populateMenu:menu action:@selector(insertSnippet:)];
    // one item per category, a separator, and Edit My Snippets
    XCTAssertEqual((NSInteger)lib.categories.count + 2, menu.numberOfItems);
    NSMenuItem *first = menu.itemArray[0];
    XCTAssertEqualObjects(@"Basics", first.title);
    XCTAssertNotNil(first.submenu);
    XCTAssertEqual((NSInteger)[lib snippetsInCategory:@"Basics"].count, first.submenu.numberOfItems);
    NSMenuItem *item = first.submenu.itemArray[0];
    XCTAssertTrue([item.representedObject isKindOfClass:[SoqlSnippet class]]);
    XCTAssertEqualObjects(@"insertSnippet:", NSStringFromSelector(item.action));
    XCTAssertNil(item.target, @"should go to the first responder");
    XCTAssertEqualObjects(@"Edit My Snippets…", menu.itemArray.lastObject.title);
}

@end
