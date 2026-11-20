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
#import "DesignTokens.h"
#import "Prefs.h"

// Text size and density read the standard defaults; each test removes what it set, which
// leaves the registered defaults (or nothing) in place.
@interface DesignTokensTests : XCTestCase
@end

@implementation DesignTokensTests

-(void)tearDown {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d removeObjectForKey:PREF_TEXT_SCALE];
    [d removeObjectForKey:PREF_DENSITY];
}

-(void)testTextScaleDefaultAndClamp {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setObject:@1.0 forKey:PREF_TEXT_SCALE];
    XCTAssertEqualWithAccuracy([SXTokens textScale], 1.0, 0.001);
    [d setObject:@0.5 forKey:PREF_TEXT_SCALE];
    XCTAssertEqualWithAccuracy([SXTokens textScale], 0.8, 0.001);
    [d setObject:@3 forKey:PREF_TEXT_SCALE];
    XCTAssertEqualWithAccuracy([SXTokens textScale], 1.5, 0.001);
}

-(void)testScaledMultipliesSize {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    NSFont *base = [NSFont systemFontOfSize:12];
    [d setObject:@1.0 forKey:PREF_TEXT_SCALE];
    XCTAssertEqualWithAccuracy([SXTokens scaled:base].pointSize, 12, 0.01);
    [d setObject:@1.5 forKey:PREF_TEXT_SCALE];
    XCTAssertEqualWithAccuracy([SXTokens scaled:base].pointSize, 18, 0.01);
}

-(void)testRowHeightFollowsDensity {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setObject:@"compact" forKey:PREF_DENSITY];
    XCTAssertEqualWithAccuracy([SXTokens rowHeight], SXRowCompact, 0.01);
    [d setObject:@"comfortable" forKey:PREF_DENSITY];
    XCTAssertEqualWithAccuracy([SXTokens rowHeight], SXRowComfortable, 0.01);
}

@end
