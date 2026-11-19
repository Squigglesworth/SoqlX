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
#import "OrgSettings.h"

@interface OrgSettingsTests : XCTestCase
@property (strong) NSUserDefaults *suite;
@end

@implementation OrgSettingsTests

static NSString *const kSuiteName = @"SoqlXOrgSettingsTests";

-(void)setUp {
    [super setUp];
    self.suite = [[NSUserDefaults alloc] initWithSuiteName:kSuiteName];
    [self.suite removePersistentDomainForName:kSuiteName];
    [OrgSettings useDefaults:self.suite];
}

-(void)tearDown {
    [self.suite removePersistentDomainForName:kSuiteName];
    [OrgSettings useDefaults:nil];
    self.suite = nil;
    [super tearDown];
}

-(void)testKindWords {
    XCTAssertEqualObjects(SXOrgKindWord(SXOrgKindProduction), @"Production");
    XCTAssertEqualObjects(SXOrgKindWord(SXOrgKindSandbox), @"Sandbox");
    XCTAssertEqualObjects(SXOrgKindWord(SXOrgKindDeveloper), @"Developer");
    XCTAssertEqualObjects(SXOrgKindWord(SXOrgKindTrial), @"Trial");
    BOOL ok = NO;
    XCTAssertEqual(SXOrgKindFromWord(@"sANDbox", &ok), SXOrgKindSandbox);
    XCTAssertTrue(ok);
    XCTAssertEqual(SXOrgKindFromWord(@"TRIAL", &ok), SXOrgKindTrial);
    XCTAssertTrue(ok);
    XCTAssertEqual(SXOrgKindFromWord(@"bogus", &ok), SXOrgKindProduction);
    XCTAssertFalse(ok);
    XCTAssertEqual(SXOrgKindFromWord(nil, &ok), SXOrgKindProduction);
    XCTAssertFalse(ok);
    XCTAssertEqual(SXOrgKindFromWord(@"bogus", NULL), SXOrgKindProduction);
}

-(void)testKindForType {
    NSDate *trial = [NSDate dateWithTimeIntervalSinceNow:86400];
    XCTAssertEqual([OrgInfo kindForType:@"Developer Edition" isSandbox:YES trialExpiration:trial], SXOrgKindSandbox);
    XCTAssertEqual([OrgInfo kindForType:@"Enterprise Edition" isSandbox:YES trialExpiration:nil], SXOrgKindSandbox);
    XCTAssertEqual([OrgInfo kindForType:@"Developer Edition" isSandbox:NO trialExpiration:nil], SXOrgKindDeveloper);
    XCTAssertEqual([OrgInfo kindForType:@"developer edition" isSandbox:NO trialExpiration:trial], SXOrgKindDeveloper);
    XCTAssertEqual([OrgInfo kindForType:@"Enterprise Edition" isSandbox:NO trialExpiration:trial], SXOrgKindTrial);
    XCTAssertEqual([OrgInfo kindForType:@"Enterprise Edition" isSandbox:NO trialExpiration:nil], SXOrgKindProduction);
    XCTAssertEqual([OrgInfo kindForType:nil isSandbox:NO trialExpiration:nil], SXOrgKindProduction);

    OrgInfo *info = [[OrgInfo alloc] init];
    info.organizationType = @"Enterprise Edition";
    info.isSandbox = YES;
    XCTAssertEqual([info kind], SXOrgKindSandbox);
}

-(void)testUnknownOrgReturnsDefaults {
    OrgSettings *s = [OrgSettings settingsForOrgId:@"00Dxx0000000001"];
    XCTAssertNotNil(s);
    XCTAssertEqualObjects(s.orgId, @"00Dxx0000000001");
    XCTAssertNil(s.label);
    XCTAssertNil(s.colorHex);
    XCTAssertNil(s.kindOverride);
    XCTAssertFalse(s.preventDelete);
    XCTAssertFalse(s.readOnly);
    XCTAssertNil([s color]);
    XCTAssertEqual([[OrgSettings allOrgIds] count], (NSUInteger)0);
}

-(void)testRoundTrip {
    OrgSettings *s = [OrgSettings settingsForOrgId:@"00Dxx0000000001"];
    s.label = @"Acme prod";
    s.colorHex = @"#D6A21E";
    s.kindOverride = @"Sandbox";
    s.preventDelete = YES;
    s.readOnly = NO;
    [s save];

    OrgSettings *other = [OrgSettings settingsForOrgId:@"00Dxx0000000002"];
    other.label = @"Other";
    [other save];

    OrgSettings *r = [OrgSettings settingsForOrgId:@"00Dxx0000000001"];
    XCTAssertEqualObjects(r.label, @"Acme prod");
    XCTAssertEqualObjects(r.colorHex, @"#D6A21E");
    XCTAssertEqualObjects(r.kindOverride, @"Sandbox");
    XCTAssertTrue(r.preventDelete);
    XCTAssertFalse(r.readOnly);

    NSArray *ids = [OrgSettings allOrgIds];
    XCTAssertEqual(ids.count, (NSUInteger)2);
    XCTAssertTrue([ids containsObject:@"00Dxx0000000001"]);
    XCTAssertTrue([ids containsObject:@"00Dxx0000000002"]);

    [OrgSettings removeSettingsForOrgId:@"00Dxx0000000001"];
    ids = [OrgSettings allOrgIds];
    XCTAssertEqualObjects(ids, @[@"00Dxx0000000002"]);
    OrgSettings *gone = [OrgSettings settingsForOrgId:@"00Dxx0000000001"];
    XCTAssertNil(gone.label);
    XCTAssertFalse(gone.preventDelete);
}

-(void)testReadOnlyForcesPreventDelete {
    OrgSettings *s = [OrgSettings settingsForOrgId:@"00Dxx0000000001"];
    s.preventDelete = NO;
    s.readOnly = YES;
    XCTAssertTrue(s.preventDelete);
    [s save];
    OrgSettings *r = [OrgSettings settingsForOrgId:@"00Dxx0000000001"];
    XCTAssertTrue(r.readOnly);
    XCTAssertTrue(r.preventDelete);
    r.readOnly = NO;
    XCTAssertFalse(r.preventDelete);

    s.preventDelete = YES;
    s.readOnly = NO;
    XCTAssertTrue(s.preventDelete);
}

-(void)testDisplayLabel {
    OrgSettings *s = [OrgSettings settingsForOrgId:@"00Dxx0000000001"];
    XCTAssertEqualObjects([s displayLabelForOrgName:@"Acme"], @"Acme");
    XCTAssertEqualObjects([s displayLabelForOrgName:nil], @"00Dxx0000000001");
    XCTAssertEqualObjects([s displayLabelForOrgName:@""], @"00Dxx0000000001");
    s.label = @"";
    XCTAssertEqualObjects([s displayLabelForOrgName:@"Acme"], @"Acme");
    s.label = @"Mine";
    XCTAssertEqualObjects([s displayLabelForOrgName:@"Acme"], @"Mine");
    XCTAssertEqualObjects([s displayLabelForOrgName:nil], @"Mine");
}

-(void)testEffectiveKind {
    OrgInfo *info = [[OrgInfo alloc] init];
    info.organizationType = @"Enterprise Edition";
    OrgSettings *s = [OrgSettings settingsForOrgId:@"00Dxx0000000001"];
    XCTAssertEqual([s effectiveKindFor:info], SXOrgKindProduction);
    s.kindOverride = @"sandbox";
    XCTAssertEqual([s effectiveKindFor:info], SXOrgKindSandbox);
    s.kindOverride = @"nonsense";
    XCTAssertEqual([s effectiveKindFor:info], SXOrgKindProduction);
    info.isSandbox = YES;
    XCTAssertEqual([s effectiveKindFor:info], SXOrgKindSandbox);
    s.kindOverride = nil;
    XCTAssertEqual([s effectiveKindFor:info], SXOrgKindSandbox);
}

-(void)testColorParsing {
    OrgSettings *s = [OrgSettings settingsForOrgId:@"00Dxx0000000001"];
    s.colorHex = @"#D6A21E";
    NSColor *c = [s color];
    XCTAssertNotNil(c);
    NSColor *rgb = [c colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    XCTAssertEqualWithAccuracy(rgb.redComponent, 0xD6 / 255.0, 0.001);
    XCTAssertEqualWithAccuracy(rgb.greenComponent, 0xA2 / 255.0, 0.001);
    XCTAssertEqualWithAccuracy(rgb.blueComponent, 0x1E / 255.0, 0.001);

    s.colorHex = @"#d6a21e";
    XCTAssertNotNil([s color]);
    for (NSString *bad in @[@"", @"D6A21E", @"#D6A21", @"#D6A21E0", @"#GGGGGG", @"red"]) {
        s.colorHex = bad;
        XCTAssertNil([s color], @"%@", bad);
    }
    s.colorHex = nil;
    XCTAssertNil([s color]);
}

@end
