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

#import <Foundation/Foundation.h>
#import "SoqlToken.h"

NS_ASSUME_NONNULL_BEGIN

// Static reference documentation for the parts of SOQL/SOSL that aren't
// described by the org's metadata: keywords, operators and date literals.
// Functions are documented alongside their definitions in SoqlFunction.
@interface SoqlDocs : NSObject

// Returns a short description of the keyword, operator, or date literal in txt,
// or nil if there's nothing to say about it. Matching is case insensitive and
// for date literals ignores any trailing :n (e.g. LAST_N_DAYS:7 -> LAST_N_DAYS).
+(nullable NSString*)docFor:(NSString*)txt type:(TokenType)type;

// Every keyword/operator/literal that has documentation, in no particular order.
// Primarily for tests.
+(NSArray<NSString*>*)documentedTerms;

@end

NS_ASSUME_NONNULL_END
