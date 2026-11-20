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

#import "SidebarFilter.h"
#import "SObjectKinds.h"

NSString *const SidebarFilterDefaultsKey = @"SidebarFilter";

@implementation SidebarFilter

+(instancetype)defaultFilter {
    SidebarFilter *f = [[SidebarFilter alloc] init];
    f.showStandard = YES;
    f.showCustom = YES;
    f.showMetadata = YES;
    f.showPlatformEvents = NO;
    f.showSystem = NO;
    f.showNonQueryable = NO;
    return f;
}

+(instancetype)filterFromDefaults:(NSUserDefaults *)defaults {
    SidebarFilter *f = [self defaultFilter];
    id stored = [defaults objectForKey:SidebarFilterDefaultsKey];
    if (![stored isKindOfClass:[NSDictionary class]]) {
        return f;
    }
    NSDictionary *d = stored;
    id v;
    if ((v = d[@"standard"]) != nil)       f.showStandard = [v boolValue];
    if ((v = d[@"custom"]) != nil)         f.showCustom = [v boolValue];
    if ((v = d[@"metadata"]) != nil)       f.showMetadata = [v boolValue];
    if ((v = d[@"platformEvents"]) != nil) f.showPlatformEvents = [v boolValue];
    if ((v = d[@"system"]) != nil)         f.showSystem = [v boolValue];
    if ((v = d[@"nonQueryable"]) != nil)   f.showNonQueryable = [v boolValue];
    return f;
}

-(void)saveToDefaults:(NSUserDefaults *)defaults {
    NSDictionary *d = @{
        @"standard": @(self.showStandard),
        @"custom": @(self.showCustom),
        @"metadata": @(self.showMetadata),
        @"platformEvents": @(self.showPlatformEvents),
        @"system": @(self.showSystem),
        @"nonQueryable": @(self.showNonQueryable),
    };
    [defaults setObject:d forKey:SidebarFilterDefaultsKey];
}

-(BOOL)isDefault {
    return [self isEqual:[SidebarFilter defaultFilter]];
}

-(BOOL)isEqual:(id)other {
    if (self == other) return YES;
    if (![other isKindOfClass:[SidebarFilter class]]) return NO;
    SidebarFilter *o = other;
    return self.showStandard == o.showStandard && self.showCustom == o.showCustom &&
        self.showMetadata == o.showMetadata && self.showPlatformEvents == o.showPlatformEvents &&
        self.showSystem == o.showSystem && self.showNonQueryable == o.showNonQueryable;
}

-(NSUInteger)hash {
    return (self.showStandard ? 1 : 0) | (self.showCustom ? 2 : 0) | (self.showMetadata ? 4 : 0) |
        (self.showPlatformEvents ? 8 : 0) | (self.showSystem ? 16 : 0) | (self.showNonQueryable ? 32 : 0);
}

-(id)copyWithZone:(NSZone *)zone {
    SidebarFilter *f = [[SidebarFilter alloc] init];
    f.showStandard = self.showStandard;
    f.showCustom = self.showCustom;
    f.showMetadata = self.showMetadata;
    f.showPlatformEvents = self.showPlatformEvents;
    f.showSystem = self.showSystem;
    f.showNonQueryable = self.showNonQueryable;
    return f;
}

-(BOOL)includesName:(NSString *)name custom:(BOOL)custom customSetting:(BOOL)customSetting
          queryable:(BOOL)queryable deprecatedAndHidden:(BOOL)deprecatedAndHidden {
    if ((deprecatedAndHidden || [SObjectKinds isSystemObjectName:name]) && !self.showSystem) {
        return NO;
    }
    SXObjectKind kind = [SObjectKinds kindForName:name custom:custom customSetting:customSetting];
    switch (kind) {
        case SXObjectKindStandard:      if (!self.showStandard) return NO; break;
        case SXObjectKindCustom:        if (!self.showCustom) return NO; break;
        case SXObjectKindMetadata:      if (!self.showMetadata) return NO; break;
        case SXObjectKindPlatformEvent: if (!self.showPlatformEvents) return NO; break;
    }
    if (!queryable && kind != SXObjectKindPlatformEvent && !self.showNonQueryable) {
        return NO;
    }
    return YES;
}

@end
