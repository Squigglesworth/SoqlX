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
#import "SettingsContent.h"

@interface SettingsContentTests : XCTestCase
@end

@implementation SettingsContentTests

-(void)testReleaseNotes {
    NSArray<ReleaseNote *> *notes = [SettingsContent releaseNotes];
    XCTAssertGreaterThan(notes.count, (NSUInteger)0);
    for (ReleaseNote *n in notes) {
        XCTAssertGreaterThan(n.version.length, (NSUInteger)0);
        XCTAssertGreaterThan(n.date.length, (NSUInteger)0);
        XCTAssertGreaterThan(n.items.count, (NSUInteger)0);
        for (NSString *item in n.items) XCTAssertGreaterThan(item.length, (NSUInteger)0);
    }
    XCTAssertEqualObjects(notes.firstObject.version, @"5.0");
}

-(void)testStartHereSteps {
    NSArray<SettingsTopic *> *steps = [SettingsContent startHereSteps];
    XCTAssertGreaterThan(steps.count, (NSUInteger)0);
    for (SettingsTopic *t in steps) {
        XCTAssertGreaterThan(t.title.length, (NSUInteger)0);
        XCTAssertGreaterThan(t.body.length, (NSUInteger)0);
    }
}

-(void)testTips {
    NSArray<SettingsTopic *> *tips = [SettingsContent tips];
    XCTAssertGreaterThan(tips.count, (NSUInteger)0);
    for (SettingsTopic *t in tips) {
        XCTAssertGreaterThan(t.title.length, (NSUInteger)0);
        XCTAssertGreaterThan(t.body.length, (NSUInteger)0);
    }
}

-(void)testVersionAndFooter {
    XCTAssertGreaterThan([SettingsContent versionString].length, (NSUInteger)0);
    XCTAssertGreaterThan([SettingsContent buildString].length, (NSUInteger)0);
    NSString *footer = [SettingsContent footerTitle];
    XCTAssertTrue([footer containsString:[SettingsContent versionString]]);
    XCTAssertTrue([footer containsString:@"What's new"]);
}

@end
