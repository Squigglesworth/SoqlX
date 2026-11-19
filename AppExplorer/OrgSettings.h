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

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SXOrgKind) {
    SXOrgKindProduction,
    SXOrgKindSandbox,
    SXOrgKindDeveloper,
    SXOrgKindTrial
};

// "Production" "Sandbox" "Developer" "Trial"
NSString *SXOrgKindWord(SXOrgKind kind);
// Case-insensitive. Sets *ok (if non-NULL) to NO for an unknown word, and returns Production.
SXOrgKind SXOrgKindFromWord(NSString * _Nullable word, BOOL * _Nullable ok);

// What the org tells us at login (SELECT Id, Name, IsSandbox, OrganizationType, TrialExpirationDate FROM Organization).
@interface OrgInfo : NSObject
@property (copy, nullable) NSString *orgId;            // 15/18 char Id as returned
@property (copy, nullable) NSString *name;             // Organization.Name
@property (copy, nullable) NSString *organizationType; // "Enterprise Edition", "Developer Edition", ...
@property (copy, nullable) NSString *instanceHost;     // e.g. example.my.salesforce.com
@property (assign) BOOL isSandbox;
@property (strong, nullable) NSDate *trialExpiration;  // nil when not a trial

// Rules: isSandbox -> Sandbox; type contains "Developer" -> Developer; trialExpiration != nil -> Trial; else Production.
+(SXOrgKind)kindForType:(nullable NSString *)organizationType isSandbox:(BOOL)isSandbox trialExpiration:(nullable NSDate *)trialExpiration;
-(SXOrgKind)kind;
@end

// Per-org, user-set settings, persisted in NSUserDefaults under "OrgSettings"
// as {orgId: {label, colorHex, kindOverride, preventDelete, readOnly}}.
@interface OrgSettings : NSObject
@property (copy, readonly) NSString *orgId;
@property (copy, nullable) NSString *label;          // nil/empty = use the org name
@property (copy, nullable) NSString *colorHex;       // "#RRGGBB" or nil
@property (copy, nullable) NSString *kindOverride;   // an SXOrgKindWord, or nil to use the detected kind
@property (assign) BOOL preventDelete;
@property (assign) BOOL readOnly;                    // readOnly implies preventDelete (getter returns YES when readOnly)

// Never nil; unsaved defaults when nothing is stored.
+(instancetype)settingsForOrgId:(NSString *)orgId;
-(void)save;
+(void)removeSettingsForOrgId:(NSString *)orgId;
+(NSArray<NSString*>*)allOrgIds;
// For tests. nil restores standardUserDefaults.
+(void)useDefaults:(nullable NSUserDefaults *)defaults;

// label, else orgName, else orgId
-(NSString *)displayLabelForOrgName:(nullable NSString *)orgName;
// kindOverride if valid, else info.kind
-(SXOrgKind)effectiveKindFor:(nullable OrgInfo *)info;
// Parsed colorHex, or nil.
-(nullable NSColor *)color;
@end

NS_ASSUME_NONNULL_END
