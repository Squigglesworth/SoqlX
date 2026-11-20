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
#import "SObjectKinds.h"

@interface SObjectKindsTests : XCTestCase
@end

@implementation SObjectKindsTests

-(void)testKinds {
    XCTAssertEqual([SObjectKinds kindForName:@"Account" custom:NO customSetting:NO], SXObjectKindStandard);
    XCTAssertEqual([SObjectKinds kindForName:@"Foo__c" custom:YES customSetting:NO], SXObjectKindCustom);
    XCTAssertEqual([SObjectKinds kindForName:@"Foo__mdt" custom:YES customSetting:NO], SXObjectKindMetadata);
    XCTAssertEqual([SObjectKinds kindForName:@"FOO__MDT" custom:NO customSetting:NO], SXObjectKindMetadata);
    XCTAssertEqual([SObjectKinds kindForName:@"Foo__e" custom:YES customSetting:NO], SXObjectKindPlatformEvent);
    XCTAssertEqual([SObjectKinds kindForName:@"Foo__x" custom:YES customSetting:NO], SXObjectKindCustom);
    XCTAssertEqual([SObjectKinds kindForName:@"Settings" custom:NO customSetting:YES], SXObjectKindCustom);
    XCTAssertEqual([SObjectKinds kindForName:@"Foo__History" custom:NO customSetting:NO], SXObjectKindCustom);
    XCTAssertEqual([SObjectKinds kindForName:@"Foo__kav" custom:NO customSetting:NO], SXObjectKindCustom);
}

-(void)testDescriptions {
    XCTAssertEqualObjects([SObjectKinds kindDescriptionForName:@"Account" custom:NO customSetting:NO], @"Standard object");
    XCTAssertEqualObjects([SObjectKinds kindDescriptionForName:@"Foo__c" custom:YES customSetting:NO], @"Custom object");
    XCTAssertEqualObjects([SObjectKinds kindDescriptionForName:@"Settings__c" custom:YES customSetting:YES], @"Custom setting");
    XCTAssertEqualObjects([SObjectKinds kindDescriptionForName:@"Foo__mdt" custom:YES customSetting:NO], @"Custom metadata type");
    XCTAssertEqualObjects([SObjectKinds kindDescriptionForName:@"Foo__e" custom:YES customSetting:NO], @"Platform event");
    XCTAssertEqualObjects([SObjectKinds kindDescriptionForName:@"Foo__x" custom:YES customSetting:NO], @"External object");
    XCTAssertEqualObjects([SObjectKinds kindDescriptionForName:@"Foo__b" custom:YES customSetting:NO], @"Big object");
    XCTAssertEqualObjects([SObjectKinds kindDescriptionForName:@"AccountHistory" custom:NO customSetting:NO], @"Field history");
    XCTAssertEqualObjects([SObjectKinds kindDescriptionForName:@"AccountFeed" custom:NO customSetting:NO], @"Feed");
    XCTAssertEqualObjects([SObjectKinds kindDescriptionForName:@"AccountShare" custom:NO customSetting:NO], @"Sharing");
    XCTAssertEqualObjects([SObjectKinds kindDescriptionForName:@"AccountChangeEvent" custom:NO customSetting:NO], @"Change event");
    XCTAssertEqualObjects([SObjectKinds kindDescriptionForName:@"LoginHistory" custom:NO customSetting:NO], @"Standard object");
}

-(void)testSystemNames {
    for (NSString *n in @[@"AccountHistory", @"AccountFeed", @"AccountShare", @"AccountChangeEvent", @"Foo__History", @"Foo__Share"]) {
        XCTAssertTrue([SObjectKinds isSystemObjectName:n], @"%@", n);
    }
    for (NSString *n in @[@"LoginHistory", @"Account", @"History", @"Share", @"Feed", @"ChangeEvent"]) {
        XCTAssertFalse([SObjectKinds isSystemObjectName:n], @"%@", n);
    }
}

@end
