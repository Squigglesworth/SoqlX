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

// Factories for design-system controls. All are plain NSButton / NSTextField so keyboard
// and accessibility behaviour come for free. Colours and fonts come from SXTokens.
// Every factory sets translatesAutoresizingMaskIntoConstraints = NO and calls sizeToFit.
@interface SXControls : NSObject

+(NSButton *)primaryButtonWithTitle:(NSString *)title target:(nullable id)target action:(nullable SEL)action;   // accent fill, on-accent bodyStrong title; caller sets keyEquivalent
+(NSButton *)defaultButtonWithTitle:(NSString *)title target:(nullable id)target action:(nullable SEL)action;   // rounded bezel, body font
+(NSButton *)dangerButtonWithTitle:(NSString *)title target:(nullable id)target action:(nullable SEL)action;    // danger fill, on-danger title
+(NSButton *)ghostButtonWithTitle:(NSString *)title target:(nullable id)target action:(nullable SEL)action;     // borderless, ink-muted
+(NSButton *)checkboxWithTitle:(NSString *)title target:(nullable id)target action:(nullable SEL)action;
+(NSTextField *)labelWithString:(NSString *)s font:(NSFont *)f color:(NSColor *)c;
+(void)setTitle:(NSString *)title onButton:(NSButton *)button;   // re-applies the variant's attributed title

@end

NS_ASSUME_NONNULL_END
