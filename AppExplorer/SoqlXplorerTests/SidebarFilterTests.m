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
#import "SidebarFilter.h"

@interface SidebarFilterTests : XCTestCase
@property (strong) NSUserDefaults *suite;
@end

@implementation SidebarFilterTests

static NSString *const kFilterSuite = @"SoqlXSidebarFilterTests";

-(void)setUp {
    [super setUp];
    self.suite = [[NSUserDefaults alloc] initWithSuiteName:kFilterSuite];
    [self.suite removePersistentDomainForName:kFilterSuite];
}

-(void)tearDown {
    [self.suite removePersistentDomainForName:kFilterSuite];
    self.suite = nil;
    [super tearDown];
}

-(BOOL)f:(SidebarFilter*)f name:(NSString*)n custom:(BOOL)c setting:(BOOL)cs queryable:(BOOL)q hidden:(BOOL)h {
    return [f includesName:n custom:c customSetting:cs queryable:q deprecatedAndHidden:h];
}

-(void)testDefaults {
    SidebarFilter *f = [SidebarFilter defaultFilter];
    XCTAssertTrue(f.showStandard);
    XCTAssertTrue(f.showCustom);
    XCTAssertTrue(f.showMetadata);
    XCTAssertFalse(f.showPlatformEvents);
    XCTAssertFalse(f.showSystem);
    XCTAssertFalse(f.showNonQueryable);
    XCTAssertTrue([f isDefault]);
    f.showSystem = YES;
    XCTAssertFalse([f isDefault]);
}

-(void)testRoundTrip {
    SidebarFilter *f = [SidebarFilter defaultFilter];
    f.showStandard = NO;
    f.showPlatformEvents = YES;
    f.showNonQueryable = YES;
    [f saveToDefaults:self.suite];
    SidebarFilter *g = [SidebarFilter filterFromDefaults:self.suite];
    XCTAssertEqualObjects(f, g);
    XCTAssertFalse(g.showStandard);
    XCTAssertTrue(g.showPlatformEvents);
    XCTAssertTrue(g.showNonQueryable);
}

-(void)testMissingKeysTakeDefaults {
    XCTAssertTrue([[SidebarFilter filterFromDefaults:self.suite] isDefault]);
    [self.suite setObject:@{@"standard": @NO} forKey:SidebarFilterDefaultsKey];
    SidebarFilter *f = [SidebarFilter filterFromDefaults:self.suite];
    XCTAssertFalse(f.showStandard);
    XCTAssertTrue(f.showCustom);
    XCTAssertTrue(f.showMetadata);
    XCTAssertFalse(f.showSystem);
    [self.suite setObject:@"junk" forKey:SidebarFilterDefaultsKey];
    XCTAssertTrue([[SidebarFilter filterFromDefaults:self.suite] isDefault]);
}

-(void)testIncludes {
    SidebarFilter *f = [SidebarFilter defaultFilter];
    XCTAssertTrue([self f:f name:@"Account" custom:NO setting:NO queryable:YES hidden:NO]);
    XCTAssertTrue([self f:f name:@"Foo__c" custom:YES setting:NO queryable:YES hidden:NO]);
    XCTAssertTrue([self f:f name:@"Foo__mdt" custom:YES setting:NO queryable:YES hidden:NO]);
    XCTAssertFalse([self f:f name:@"Foo__e" custom:YES setting:NO queryable:NO hidden:NO], @"platform events off by default");
    XCTAssertFalse([self f:f name:@"AccountHistory" custom:NO setting:NO queryable:YES hidden:NO], @"system needs showSystem");
    XCTAssertFalse([self f:f name:@"Old" custom:NO setting:NO queryable:YES hidden:YES], @"deprecated needs showSystem");
    XCTAssertFalse([self f:f name:@"Hidden" custom:NO setting:NO queryable:NO hidden:NO], @"non-queryable hidden by default");
    XCTAssertTrue([self f:f name:@"LoginHistory" custom:NO setting:NO queryable:YES hidden:NO]);

    f.showSystem = YES;
    XCTAssertTrue([self f:f name:@"AccountHistory" custom:NO setting:NO queryable:YES hidden:NO]);
    XCTAssertTrue([self f:f name:@"Old" custom:NO setting:NO queryable:YES hidden:YES]);
    XCTAssertFalse([self f:f name:@"Old" custom:NO setting:NO queryable:NO hidden:YES], @"still non-queryable");
    f.showNonQueryable = YES;
    XCTAssertTrue([self f:f name:@"Old" custom:NO setting:NO queryable:NO hidden:YES]);

    f.showCustom = NO;
    XCTAssertFalse([self f:f name:@"Foo__c" custom:YES setting:NO queryable:YES hidden:NO]);
    f.showStandard = NO;
    XCTAssertFalse([self f:f name:@"Account" custom:NO setting:NO queryable:YES hidden:NO]);
    f.showMetadata = NO;
    XCTAssertFalse([self f:f name:@"Foo__mdt" custom:YES setting:NO queryable:YES hidden:NO]);
}

-(void)testPlatformEventShownThoughNotQueryable {
    SidebarFilter *f = [SidebarFilter defaultFilter];
    f.showPlatformEvents = YES;
    XCTAssertFalse(f.showNonQueryable);
    XCTAssertTrue([self f:f name:@"Foo__e" custom:YES setting:NO queryable:NO hidden:NO]);
}

-(void)testEqualityAndCopy {
    SidebarFilter *a = [SidebarFilter defaultFilter];
    SidebarFilter *b = [a copy];
    XCTAssertEqualObjects(a, b);
    XCTAssertEqual(a.hash, b.hash);
    XCTAssertNotEqual(a, b);
    b.showSystem = YES;
    XCTAssertNotEqualObjects(a, b);
    XCTAssertFalse(a.showSystem, @"copy is independent");
}

@end
