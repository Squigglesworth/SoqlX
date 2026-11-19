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
#import "OrgSettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConfirmDeleteDialog : NSObject

+(NSString *)phraseForCount:(NSUInteger)count;                                // "DELETE 3"
+(BOOL)typed:(nullable NSString *)typed matchesPhraseForCount:(NSUInteger)count;   // trimmed, case-insensitive
+(NSString *)titleForCount:(NSUInteger)count objectName:(NSString *)name;     // "Delete 3 Account records?" / "Delete 1 Account record?"
+(BOOL)needsConfirmationForCount:(NSUInteger)count kind:(SXOrgKind)kind;

// Shows an NSAlert sheet on window. Production: an accessory text field; the destructive button
// stays disabled until the typed phrase matches. completion(YES) only when confirmed. When no
// confirmation is needed, completion(YES) is called immediately and nothing is shown.
+(void)confirmDeleteOf:(NSUInteger)count objectName:(NSString *)name kind:(SXOrgKind)kind
                window:(NSWindow *)window completion:(void (^)(BOOL confirmed))completion;

@end

NS_ASSUME_NONNULL_END
