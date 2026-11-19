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

#import <XCTest/XCTest.h>
#import "SalesforceIds.h"

@interface SalesforceIdsTests : XCTestCase
@end

@implementation SalesforceIdsTests

-(void)testLooksLikeId {
    XCTAssertTrue([SalesforceIds looksLikeId:@"001000000000001"]);
    XCTAssertTrue([SalesforceIds looksLikeId:@"001000000000001AAA"]);
    XCTAssertTrue([SalesforceIds looksLikeId:@"0010000000abcDEFgh"]);
    XCTAssertFalse([SalesforceIds looksLikeId:@"00100000000001"]);     // 14
    XCTAssertFalse([SalesforceIds looksLikeId:@"0010000000000001AAA"]); // 19
    XCTAssertFalse([SalesforceIds looksLikeId:@"001000000000-01"]);
    XCTAssertFalse([SalesforceIds looksLikeId:@"001 00000000001"]);
    XCTAssertFalse([SalesforceIds looksLikeId:@""]);
    XCTAssertFalse([SalesforceIds looksLikeId:nil]);
    XCTAssertFalse([SalesforceIds looksLikeId:@(123456789012345)]);
    XCTAssertFalse([SalesforceIds looksLikeId:[NSNull null]]);
}

-(void)testRecordURL {
    NSURL *u = [SalesforceIds recordURLForId:@"001000000000001" host:@"na1.salesforce.com"];
    XCTAssertEqualObjects(u.absoluteString, @"https://na1.salesforce.com/001000000000001");
    XCTAssertNil([SalesforceIds recordURLForId:@"001000000000001" host:@""]);
    XCTAssertNil([SalesforceIds recordURLForId:@"001000000000001" host:nil]);
    XCTAssertNil([SalesforceIds recordURLForId:@"" host:@"na1.salesforce.com"]);
    XCTAssertNil([SalesforceIds recordURLForId:nil host:@"na1.salesforce.com"]);
}

-(void)testIsIdColumn {
    XCTAssertTrue([SalesforceIds isIdColumn:@"Id"]);
    XCTAssertTrue([SalesforceIds isIdColumn:@"OwnerId"]);
    XCTAssertTrue([SalesforceIds isIdColumn:@"Account.OwnerId"]);
    XCTAssertFalse([SalesforceIds isIdColumn:@"Name"]);
    XCTAssertFalse([SalesforceIds isIdColumn:@"Account.Name"]);
    XCTAssertFalse([SalesforceIds isIdColumn:@""]);
    XCTAssertFalse([SalesforceIds isIdColumn:nil]);
}

@end
