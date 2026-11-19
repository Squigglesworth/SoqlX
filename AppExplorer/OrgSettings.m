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

#import "OrgSettings.h"

static NSString *const kOrgSettingsKey = @"OrgSettings";
static NSString *const kLabelKey = @"label";
static NSString *const kColorHexKey = @"colorHex";
static NSString *const kKindOverrideKey = @"kindOverride";
static NSString *const kPreventDeleteKey = @"preventDelete";
static NSString *const kReadOnlyKey = @"readOnly";

static NSUserDefaults *sDefaultsOverride = nil;

static NSUserDefaults *OrgSettingsDefaults(void) {
    return sDefaultsOverride ? sDefaultsOverride : [NSUserDefaults standardUserDefaults];
}

NSString *SXOrgKindWord(SXOrgKind kind) {
    switch (kind) {
        case SXOrgKindSandbox:   return @"Sandbox";
        case SXOrgKindDeveloper: return @"Developer";
        case SXOrgKindTrial:     return @"Trial";
        case SXOrgKindProduction:
        default:                 return @"Production";
    }
}

SXOrgKind SXOrgKindFromWord(NSString *word, BOOL *ok) {
    if (ok) *ok = YES;
    if ([word isKindOfClass:[NSString class]]) {
        if ([word caseInsensitiveCompare:@"Production"] == NSOrderedSame) return SXOrgKindProduction;
        if ([word caseInsensitiveCompare:@"Sandbox"] == NSOrderedSame) return SXOrgKindSandbox;
        if ([word caseInsensitiveCompare:@"Developer"] == NSOrderedSame) return SXOrgKindDeveloper;
        if ([word caseInsensitiveCompare:@"Trial"] == NSOrderedSame) return SXOrgKindTrial;
    }
    if (ok) *ok = NO;
    return SXOrgKindProduction;
}

@implementation OrgInfo

+(SXOrgKind)kindForType:(NSString *)organizationType isSandbox:(BOOL)isSandbox trialExpiration:(NSDate *)trialExpiration {
    if (isSandbox) return SXOrgKindSandbox;
    if (organizationType.length > 0 &&
        [organizationType rangeOfString:@"Developer" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        return SXOrgKindDeveloper;
    }
    if (trialExpiration != nil) return SXOrgKindTrial;
    return SXOrgKindProduction;
}

-(SXOrgKind)kind {
    return [OrgInfo kindForType:self.organizationType isSandbox:self.isSandbox trialExpiration:self.trialExpiration];
}

@end

@interface OrgSettings ()
@property (copy, readwrite) NSString *orgId;
@property (assign) BOOL storedPreventDelete;
@end

@implementation OrgSettings

+(void)useDefaults:(NSUserDefaults *)defaults {
    sDefaultsOverride = defaults;
}

+(NSDictionary *)storedDictionary {
    id d = [OrgSettingsDefaults() objectForKey:kOrgSettingsKey];
    return [d isKindOfClass:[NSDictionary class]] ? d : @{};
}

+(instancetype)settingsForOrgId:(NSString *)orgId {
    OrgSettings *s = [[OrgSettings alloc] init];
    s.orgId = orgId ? orgId : @"";
    id stored = [self storedDictionary][s.orgId];
    if ([stored isKindOfClass:[NSDictionary class]]) {
        NSDictionary *d = stored;
        id v = d[kLabelKey];
        if ([v isKindOfClass:[NSString class]] && [v length] > 0) s.label = v;
        v = d[kColorHexKey];
        if ([v isKindOfClass:[NSString class]] && [v length] > 0) s.colorHex = v;
        v = d[kKindOverrideKey];
        if ([v isKindOfClass:[NSString class]] && [v length] > 0) s.kindOverride = v;
        v = d[kPreventDeleteKey];
        if ([v respondsToSelector:@selector(boolValue)]) s.storedPreventDelete = [v boolValue];
        v = d[kReadOnlyKey];
        if ([v respondsToSelector:@selector(boolValue)]) s.readOnly = [v boolValue];
    }
    return s;
}

-(BOOL)preventDelete {
    return self.readOnly ? YES : self.storedPreventDelete;
}

-(void)setPreventDelete:(BOOL)preventDelete {
    self.storedPreventDelete = preventDelete;
}

-(void)save {
    NSMutableDictionary *all = [[OrgSettings storedDictionary] mutableCopy];
    all[self.orgId] = @{
        kLabelKey: self.label ? self.label : @"",
        kColorHexKey: self.colorHex ? self.colorHex : @"",
        kKindOverrideKey: self.kindOverride ? self.kindOverride : @"",
        kPreventDeleteKey: @(self.storedPreventDelete),
        kReadOnlyKey: @(self.readOnly)
    };
    [OrgSettingsDefaults() setObject:all forKey:kOrgSettingsKey];
}

+(void)removeSettingsForOrgId:(NSString *)orgId {
    if (orgId == nil) return;
    NSMutableDictionary *all = [[self storedDictionary] mutableCopy];
    if (all[orgId] == nil) return;
    [all removeObjectForKey:orgId];
    [OrgSettingsDefaults() setObject:all forKey:kOrgSettingsKey];
}

+(NSArray<NSString*>*)allOrgIds {
    return [[[self storedDictionary] allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

-(NSString *)displayLabelForOrgName:(NSString *)orgName {
    if (self.label.length > 0) return self.label;
    if (orgName.length > 0) return orgName;
    return self.orgId;
}

-(SXOrgKind)effectiveKindFor:(OrgInfo *)info {
    if (self.kindOverride.length > 0) {
        BOOL ok = NO;
        SXOrgKind k = SXOrgKindFromWord(self.kindOverride, &ok);
        if (ok) return k;
    }
    return info ? [info kind] : SXOrgKindProduction;
}

-(NSColor *)color {
    NSString *hex = self.colorHex;
    if (hex.length != 7 || [hex characterAtIndex:0] != '#') return nil;
    unsigned int rgb = 0;
    for (NSUInteger i = 1; i < 7; i++) {
        unichar c = [hex characterAtIndex:i];
        unsigned int digit;
        if (c >= '0' && c <= '9') digit = c - '0';
        else if (c >= 'a' && c <= 'f') digit = c - 'a' + 10;
        else if (c >= 'A' && c <= 'F') digit = c - 'A' + 10;
        else return nil;
        rgb = (rgb << 4) | digit;
    }
    return [NSColor colorWithSRGBRed:((rgb >> 16) & 0xFF) / 255.0
                               green:((rgb >> 8) & 0xFF) / 255.0
                                blue:(rgb & 0xFF) / 255.0
                               alpha:1.0];
}

@end
