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
#import <Cocoa/Cocoa.h>
#import "ConfirmDeleteDialog.h"

@interface ConfirmDeleteDialogTests : XCTestCase
@end

@implementation ConfirmDeleteDialogTests

-(void)testPhrase {
    XCTAssertEqualObjects([ConfirmDeleteDialog phraseForCount:3], @"DELETE 3");
    XCTAssertEqualObjects([ConfirmDeleteDialog phraseForCount:1], @"DELETE 1");
}

-(void)testMatching {
    XCTAssertTrue([ConfirmDeleteDialog typed:@"DELETE 3" matchesPhraseForCount:3]);
    XCTAssertTrue([ConfirmDeleteDialog typed:@"delete 3" matchesPhraseForCount:3]);
    XCTAssertTrue([ConfirmDeleteDialog typed:@"  Delete 3 \n" matchesPhraseForCount:3]);
    XCTAssertFalse([ConfirmDeleteDialog typed:@"DELETE 4" matchesPhraseForCount:3]);
    XCTAssertFalse([ConfirmDeleteDialog typed:@"DELETE" matchesPhraseForCount:3]);
    XCTAssertFalse([ConfirmDeleteDialog typed:@"DELETE  3" matchesPhraseForCount:3]);
    XCTAssertFalse([ConfirmDeleteDialog typed:@"" matchesPhraseForCount:3]);
    XCTAssertFalse([ConfirmDeleteDialog typed:nil matchesPhraseForCount:3]);
}

-(void)testTitles {
    XCTAssertEqualObjects([ConfirmDeleteDialog titleForCount:3 objectName:@"Account"], @"Delete 3 Account records?");
    XCTAssertEqualObjects([ConfirmDeleteDialog titleForCount:1 objectName:@"Account"], @"Delete 1 Account record?");
}

-(void)testNeedsConfirmationTable {
    XCTAssertTrue([ConfirmDeleteDialog needsConfirmationForCount:1 kind:SXOrgKindProduction]);
    XCTAssertFalse([ConfirmDeleteDialog needsConfirmationForCount:1 kind:SXOrgKindSandbox]);
    XCTAssertTrue([ConfirmDeleteDialog needsConfirmationForCount:2 kind:SXOrgKindSandbox]);
    XCTAssertTrue([ConfirmDeleteDialog needsConfirmationForCount:5 kind:SXOrgKindDeveloper]);
    XCTAssertTrue([ConfirmDeleteDialog needsConfirmationForCount:1 kind:SXOrgKindTrial]);
}

-(void)testNoConfirmationCompletesImmediately {
    __block BOOL called = NO;
    __block BOOL result = NO;
    [ConfirmDeleteDialog confirmDeleteOf:1 objectName:@"Account" kind:SXOrgKindSandbox window:(NSWindow * _Nonnull)nil
                              completion:^(BOOL confirmed) { called = YES; result = confirmed; }];
    XCTAssertTrue(called);
    XCTAssertTrue(result);
}

@end
