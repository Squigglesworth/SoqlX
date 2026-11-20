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

#import "SXControls.h"
#import "DesignTokens.h"
#import <objc/runtime.h>

typedef NS_ENUM(NSInteger, SXButtonVariant) {
    SXButtonVariantDefault = 0,
    SXButtonVariantPrimary,
    SXButtonVariantDanger,
    SXButtonVariantGhost,
    SXButtonVariantTeal
};

static const void *kSXVariantKey = &kSXVariantKey;

@implementation SXControls

+(SXButtonVariant)variantOfButton:(NSButton *)button {
    NSNumber *n = objc_getAssociatedObject(button, kSXVariantKey);
    return n == nil ? SXButtonVariantDefault : (SXButtonVariant)n.integerValue;
}

+(NSAttributedString *)centredTitle:(NSString *)title color:(NSColor *)color {
    NSMutableParagraphStyle *para = [[NSMutableParagraphStyle alloc] init];
    para.alignment = NSTextAlignmentCenter;
    NSDictionary *attrs = @{ NSFontAttributeName: [SXTokens bodyStrong],
                             NSForegroundColorAttributeName: color,
                             NSParagraphStyleAttributeName: para };
    return [[NSAttributedString alloc] initWithString:(title ?: @"") attributes:attrs];
}

+(void)setTitle:(NSString *)title onButton:(NSButton *)button {
    switch ([self variantOfButton:button]) {
        case SXButtonVariantPrimary:
            button.attributedTitle = [self centredTitle:title color:button.enabled ? [SXTokens onAccent] : [SXTokens inkSubtle]];
            break;
        case SXButtonVariantDanger:
            button.attributedTitle = [self centredTitle:title color:button.enabled ? [SXTokens onDanger] : [SXTokens inkSubtle]];
            break;
        case SXButtonVariantTeal:
            // surface reads as dark on the light dark-mode teal and light on the deep light-mode teal.
            button.attributedTitle = [self centredTitle:title color:button.enabled ? [SXTokens surface] : [SXTokens inkSubtle]];
            break;
        case SXButtonVariantGhost:
        case SXButtonVariantDefault:
        default:
            button.title = title ?: @"";
            break;
    }
    [button sizeToFit];
}

+(NSButton *)buttonWithVariant:(SXButtonVariant)variant title:(NSString *)title target:(id)target action:(SEL)action {
    NSButton *b = [NSButton buttonWithTitle:(title ?: @"") target:target action:action];
    objc_setAssociatedObject(b, kSXVariantKey, @(variant), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.controlSize = NSControlSizeRegular;
    switch (variant) {
        case SXButtonVariantPrimary:
            b.bezelStyle = NSBezelStyleRounded;
            b.bezelColor = [SXTokens accent];
            break;
        case SXButtonVariantDanger:
            b.bezelStyle = NSBezelStyleRounded;
            b.bezelColor = [SXTokens danger];
            break;
        case SXButtonVariantTeal:
            b.bezelStyle = NSBezelStyleRounded;
            b.bezelColor = [SXTokens link];
            break;
        case SXButtonVariantGhost:
            b.bordered = NO;
            b.contentTintColor = [SXTokens inkMuted];
            b.font = [SXTokens body];
            break;
        case SXButtonVariantDefault:
        default:
            b.bezelStyle = NSBezelStyleRounded;
            b.font = [SXTokens body];
            break;
    }
    [self setTitle:title onButton:b];   // applies attributed title and sizeToFit
    return b;
}

+(NSButton *)primaryButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    return [self buttonWithVariant:SXButtonVariantPrimary title:title target:target action:action];
}

+(NSButton *)defaultButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    return [self buttonWithVariant:SXButtonVariantDefault title:title target:target action:action];
}

+(NSButton *)dangerButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    return [self buttonWithVariant:SXButtonVariantDanger title:title target:target action:action];
}

+(NSButton *)tealButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    return [self buttonWithVariant:SXButtonVariantTeal title:title target:target action:action];
}

+(NSButton *)ghostButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    return [self buttonWithVariant:SXButtonVariantGhost title:title target:target action:action];
}

+(NSButton *)checkboxWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    NSButton *b = [NSButton checkboxWithTitle:(title ?: @"") target:target action:action];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.font = [SXTokens body];
    [b sizeToFit];
    return b;
}

+(NSTextField *)labelWithString:(NSString *)s font:(NSFont *)f color:(NSColor *)c {
    NSTextField *l = [NSTextField labelWithString:(s ?: @"")];
    l.translatesAutoresizingMaskIntoConstraints = NO;
    l.font = f;
    l.textColor = c;
    [l sizeToFit];
    return l;
}

@end
