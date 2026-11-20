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

extern NSString *const SidebarFilterDefaultsKey;   // @"SidebarFilter", a dictionary of the six BOOLs

@interface SidebarFilter : NSObject <NSCopying>
@property (assign) BOOL showStandard;
@property (assign) BOOL showCustom;
@property (assign) BOOL showMetadata;
@property (assign) BOOL showPlatformEvents;
@property (assign) BOOL showSystem;
@property (assign) BOOL showNonQueryable;

+(instancetype)defaultFilter;
// Missing keys take the default values.
+(instancetype)filterFromDefaults:(NSUserDefaults *)defaults;
-(void)saveToDefaults:(NSUserDefaults *)defaults;
-(BOOL)isDefault;

// deprecatedAndHidden or a system object name needs showSystem; then the kind's toggle;
// then !queryable needs showNonQueryable unless the kind is a platform event.
-(BOOL)includesName:(NSString *)name custom:(BOOL)custom customSetting:(BOOL)customSetting
          queryable:(BOOL)queryable deprecatedAndHidden:(BOOL)deprecatedAndHidden;
@end

NS_ASSUME_NONNULL_END
