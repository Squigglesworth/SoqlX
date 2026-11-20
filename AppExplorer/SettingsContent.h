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

// One titled paragraph: a Start Here step or a tip.
@interface SettingsTopic : NSObject
@property (copy) NSString *title;
@property (copy) NSString *body;
@end

@interface ReleaseNote : NSObject
@property (copy) NSString *version;
@property (copy) NSString *date;   // "November 2026"
@property (copy) NSArray<NSString *> *items;
@end

@interface SettingsContent : NSObject
+(NSArray<SettingsTopic *> *)startHereSteps;
+(NSArray<SettingsTopic *> *)tips;
+(NSArray<ReleaseNote *> *)releaseNotes;   // newest first; first is 5.0
+(NSString *)versionString;                // CFBundleShortVersionString, "5.0" fallback
+(NSString *)buildString;                  // CFBundleVersion, "5.0" fallback
+(NSString *)footerTitle;                  // "SoqlX Rebooted 5.0 · What's new"
@end

NS_ASSUME_NONNULL_END
