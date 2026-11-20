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
#import "RecentObjects.h"

@interface RecentObjectsTests : XCTestCase
@property (strong) NSUserDefaults *suite;
@end

@implementation RecentObjectsTests

static NSString *const kRecentSuite = @"SoqlXRecentObjectsTests";

-(void)setUp {
    [super setUp];
    self.suite = [[NSUserDefaults alloc] initWithSuiteName:kRecentSuite];
    [self.suite removePersistentDomainForName:kRecentSuite];
    [RecentObjects useDefaults:self.suite];
}

-(void)tearDown {
    [self.suite removePersistentDomainForName:kRecentSuite];
    [RecentObjects useDefaults:nil];
    self.suite = nil;
    [super tearDown];
}

-(void)testOrder {
    XCTAssertEqualObjects([RecentObjects namesForOrgId:@"o1"], @[]);
    [RecentObjects recordName:@"Account" forOrgId:@"o1"];
    [RecentObjects recordName:@"Contact" forOrgId:@"o1"];
    XCTAssertEqualObjects([RecentObjects namesForOrgId:@"o1"], (@[@"Contact", @"Account"]));
}

-(void)testCaseInsensitiveDedupe {
    [RecentObjects recordName:@"Account" forOrgId:@"o1"];
    [RecentObjects recordName:@"Contact" forOrgId:@"o1"];
    [RecentObjects recordName:@"account" forOrgId:@"o1"];
    XCTAssertEqualObjects([RecentObjects namesForOrgId:@"o1"], (@[@"account", @"Contact"]));
}

-(void)testLimit {
    XCTAssertEqual([RecentObjects limit], (NSUInteger)8);
    for (int i = 0; i < 12; i++) {
        [RecentObjects recordName:[NSString stringWithFormat:@"Obj%d", i] forOrgId:@"o1"];
    }
    NSArray *names = [RecentObjects namesForOrgId:@"o1"];
    XCTAssertEqual(names.count, (NSUInteger)8);
    XCTAssertEqualObjects(names.firstObject, @"Obj11");
    XCTAssertEqualObjects(names.lastObject, @"Obj4");
}

-(void)testPerOrg {
    [RecentObjects recordName:@"Account" forOrgId:@"o1"];
    [RecentObjects recordName:@"Lead" forOrgId:@"o2"];
    XCTAssertEqualObjects([RecentObjects namesForOrgId:@"o1"], @[@"Account"]);
    XCTAssertEqualObjects([RecentObjects namesForOrgId:@"o2"], @[@"Lead"]);
}

-(void)testEmptyIgnoredAndTrimmed {
    [RecentObjects recordName:@"" forOrgId:@"o1"];
    [RecentObjects recordName:@"  \n" forOrgId:@"o1"];
    XCTAssertEqualObjects([RecentObjects namesForOrgId:@"o1"], @[]);
    [RecentObjects recordName:@"  Account " forOrgId:@"o1"];
    XCTAssertEqualObjects([RecentObjects namesForOrgId:@"o1"], @[@"Account"]);
}

-(void)testPrimaryObjectSimple {
    XCTAssertEqualObjects([RecentObjects primaryObjectInQuery:@"select Id from Account"], @"Account");
    XCTAssertEqualObjects([RecentObjects primaryObjectInQuery:@"SELECT Id FROM Account WHERE Name = 'x'"], @"Account");
    XCTAssertEqualObjects([RecentObjects primaryObjectInQuery:@"  select Id, Name from Contact limit 5  "], @"Contact");
}

-(void)testPrimaryObjectWhitespace {
    XCTAssertEqualObjects([RecentObjects primaryObjectInQuery:@"select Id\nFROM\n\tOpportunity\nwhere x = 1"], @"Opportunity");
}

-(void)testPrimaryObjectSubqueryInSelect {
    NSString *q = @"SELECT Id, (SELECT Id FROM Contacts) FROM Account";
    XCTAssertEqualObjects([RecentObjects primaryObjectInQuery:q], @"Account");
}

-(void)testPrimaryObjectSemiJoin {
    NSString *q = @"SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact)";
    XCTAssertEqualObjects([RecentObjects primaryObjectInQuery:q], @"Account");
}

-(void)testPrimaryObjectStringLiteral {
    NSString *q = @"SELECT Id, 'a from x' FROM Lead";
    XCTAssertEqualObjects([RecentObjects primaryObjectInQuery:q], @"Lead");
    NSString *q2 = @"SELECT Id FROM Case WHERE Subject = 'it\\'s from y'";
    XCTAssertEqualObjects([RecentObjects primaryObjectInQuery:q2], @"Case");
}

-(void)testPrimaryObjectIdentifierContainingFrom {
    XCTAssertEqualObjects([RecentObjects primaryObjectInQuery:@"SELECT Id, afrom, from__c FROM Account"], @"Account");
}

-(void)testPrimaryObjectNil {
    XCTAssertNil([RecentObjects primaryObjectInQuery:@"FIND {foo} IN ALL FIELDS RETURNING Account(Id)"]);
    XCTAssertNil([RecentObjects primaryObjectInQuery:@"find\n{foo}"]);
    XCTAssertNil([RecentObjects primaryObjectInQuery:@"SELECT Id"]);
    XCTAssertNil([RecentObjects primaryObjectInQuery:@""]);
    XCTAssertNil([RecentObjects primaryObjectInQuery:@"SELECT Id FROM "]);
}

-(void)testFindPrefixIsNotSosl {
    XCTAssertEqualObjects([RecentObjects primaryObjectInQuery:@"SELECT Id FROM Finding"], @"Finding");
}

@end
