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

#import "SObjectKinds.h"

@implementation SObjectKinds

static BOOL hasSuffixCI(NSString *name, NSString *suffix) {
    return [name rangeOfString:suffix options:NSCaseInsensitiveSearch | NSAnchoredSearch | NSBackwardsSearch].location != NSNotFound;
}

+(SXObjectKind)kindForName:(NSString *)name custom:(BOOL)custom customSetting:(BOOL)customSetting {
    if (hasSuffixCI(name, @"__mdt")) return SXObjectKindMetadata;
    if (hasSuffixCI(name, @"__e")) return SXObjectKindPlatformEvent;
    if (custom || customSetting || [name containsString:@"__"]) return SXObjectKindCustom;
    return SXObjectKindStandard;
}

+(NSString *)systemSuffixForName:(NSString *)name {
    if (![self isSystemObjectName:name]) return nil;
    for (NSString *s in @[@"ChangeEvent", @"History", @"Feed", @"Share"]) {
        if ([name hasSuffix:s]) return s;
    }
    return nil;
}

+(NSString *)kindDescriptionForName:(NSString *)name custom:(BOOL)custom customSetting:(BOOL)customSetting {
    if (hasSuffixCI(name, @"__mdt")) return @"Custom metadata type";
    if (hasSuffixCI(name, @"__e")) return @"Platform event";
    if (hasSuffixCI(name, @"__x")) return @"External object";
    if (hasSuffixCI(name, @"__b")) return @"Big object";
    NSString *sys = [self systemSuffixForName:name];
    if (sys != nil) {
        if ([sys isEqualToString:@"ChangeEvent"]) return @"Change event";
        if ([sys isEqualToString:@"History"]) return @"Field history";
        if ([sys isEqualToString:@"Feed"]) return @"Feed";
        return @"Sharing";
    }
    if (customSetting) return @"Custom setting";
    if ([self kindForName:name custom:custom customSetting:customSetting] == SXObjectKindCustom) return @"Custom object";
    return @"Standard object";
}

+(BOOL)isSystemObjectName:(NSString *)name {
    if ([name isEqualToString:@"LoginHistory"]) return NO;
    for (NSString *s in @[@"ChangeEvent", @"History", @"Feed", @"Share"]) {
        if (name.length > s.length && [name hasSuffix:s]) return YES;
    }
    return NO;
}

@end
