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

typedef NS_ENUM(NSInteger, SXObjectKind) {
    SXObjectKindStandard,
    SXObjectKindCustom,
    SXObjectKindMetadata,
    SXObjectKindPlatformEvent
};

@interface SObjectKinds : NSObject

// Suffixes are matched case-insensitively. __mdt is Metadata, __e is PlatformEvent. The custom flag,
// the customSetting flag, or any other "__" in the name (__c __x __b __kav __Share __History ...)
// is Custom. Everything else is Standard.
+(SXObjectKind)kindForName:(NSString *)name custom:(BOOL)custom customSetting:(BOOL)customSetting;

// "Standard object" "Custom object" "Custom setting" "Custom metadata type" "Platform event"
// "External object" "Big object", or for system companions "Field history" "Feed" "Sharing" "Change event".
+(NSString *)kindDescriptionForName:(NSString *)name custom:(BOOL)custom customSetting:(BOOL)customSetting;

// Name ends in Feed, History, Share or ChangeEvent (and is longer than the suffix), except LoginHistory.
+(BOOL)isSystemObjectName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
