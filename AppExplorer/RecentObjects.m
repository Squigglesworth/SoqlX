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

#import "RecentObjects.h"

NSString *const RecentObjectsDefaultsKey = @"RecentSObjects";

static NSUserDefaults *sRecentDefaultsOverride = nil;

static NSUserDefaults *RecentDefaults(void) {
    return sRecentDefaultsOverride != nil ? sRecentDefaultsOverride : [NSUserDefaults standardUserDefaults];
}

static BOOL isIdentChar(unichar c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_';
}

static BOOL isSpaceChar(unichar c) {
    return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == 0x0B || c == 0x0C;
}

@implementation RecentObjects

+(void)useDefaults:(NSUserDefaults *)defaults {
    sRecentDefaultsOverride = defaults;
}

+(NSUInteger)limit {
    return 8;
}

+(NSDictionary *)storedDictionary {
    id d = [RecentDefaults() objectForKey:RecentObjectsDefaultsKey];
    return [d isKindOfClass:[NSDictionary class]] ? d : @{};
}

+(NSArray<NSString *> *)namesForOrgId:(NSString *)orgId {
    id v = self.storedDictionary[orgId];
    if (![v isKindOfClass:[NSArray class]]) {
        return @[];
    }
    NSMutableArray<NSString *> *r = [NSMutableArray array];
    for (id n in (NSArray *)v) {
        if ([n isKindOfClass:[NSString class]]) {
            [r addObject:n];
        }
    }
    return r;
}

+(void)recordName:(NSString *)name forOrgId:(NSString *)orgId {
    NSString *trimmed = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0 || orgId.length == 0) {
        return;
    }
    NSMutableArray<NSString *> *names = [NSMutableArray arrayWithObject:trimmed];
    for (NSString *n in [self namesForOrgId:orgId]) {
        if ([n caseInsensitiveCompare:trimmed] != NSOrderedSame) {
            [names addObject:n];
        }
    }
    while (names.count > [self limit]) {
        [names removeLastObject];
    }
    NSMutableDictionary *all = [self.storedDictionary mutableCopy];
    all[orgId] = names;
    [RecentDefaults() setObject:all forKey:RecentObjectsDefaultsKey];
}

+(NSString *)primaryObjectInQuery:(NSString *)soql {
    NSString *trimmed = [soql stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSUInteger len = trimmed.length;
    if (len >= 5 && [trimmed rangeOfString:@"find" options:NSCaseInsensitiveSearch | NSAnchoredSearch].location != NSNotFound &&
        isSpaceChar([trimmed characterAtIndex:4])) {
        return nil;
    }
    NSInteger depth = 0;
    BOOL inString = NO;
    for (NSUInteger i = 0; i < len; i++) {
        unichar c = [trimmed characterAtIndex:i];
        if (inString) {
            if (c == '\\') {
                i++;
            } else if (c == '\'') {
                inString = NO;
            }
            continue;
        }
        if (c == '\'') {
            inString = YES;
        } else if (c == '(') {
            depth++;
        } else if (c == ')') {
            if (depth > 0) depth--;
        } else if (depth == 0 && (c == 'f' || c == 'F') && i + 4 <= len) {
            if ([trimmed compare:@"from" options:NSCaseInsensitiveSearch range:NSMakeRange(i, 4)] != NSOrderedSame) {
                continue;
            }
            if (i > 0 && isIdentChar([trimmed characterAtIndex:i - 1])) {
                continue;
            }
            if (i + 4 < len && isIdentChar([trimmed characterAtIndex:i + 4])) {
                continue;
            }
            NSUInteger j = i + 4;
            while (j < len && isSpaceChar([trimmed characterAtIndex:j])) j++;
            NSUInteger start = j;
            while (j < len && isIdentChar([trimmed characterAtIndex:j])) j++;
            if (j == start) {
                return nil;
            }
            return [trimmed substringWithRange:NSMakeRange(start, j - start)];
        }
    }
    return nil;
}

@end
