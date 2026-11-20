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

NS_ASSUME_NONNULL_BEGIN

extern NSString *const RecentObjectsDefaultsKey;   // @"RecentSObjects", {orgId: [names, most recent first]}

@interface RecentObjects : NSObject
// For tests. nil restores standardUserDefaults.
+(void)useDefaults:(nullable NSUserDefaults *)defaults;
+(NSUInteger)limit;
// Never nil.
+(NSArray<NSString *> *)namesForOrgId:(NSString *)orgId;
// Goes to the front, case-insensitive dedupe, trimmed; an empty name is a no-op.
+(void)recordName:(NSString *)name forOrgId:(NSString *)orgId;
// The object after the first FROM that is outside parentheses and string literals; nil when none
// or when the text is SOSL (starts with FIND).
+(nullable NSString *)primaryObjectInQuery:(NSString *)soql;
@end

NS_ASSUME_NONNULL_END
