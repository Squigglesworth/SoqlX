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

#import "ResultTextCell.h"
#import "DesignTokens.h"
#import "SalesforceIds.h"

@implementation ResultTextCell

-(instancetype)initTextCell:(NSString *)string {
    self = [super initTextCell:string];
    if (self) {
        self.lineBreakMode = NSLineBreakByTruncatingTail;
        self.editable = YES;
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return self;
}

-(BOOL)isLinkValue {
    return self.linkColumn && [SalesforceIds looksLikeId:self.objectValue];
}

-(NSAttributedString *)styledValue {
    id v = self.objectValue;
    NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
    ps.lineBreakMode = NSLineBreakByTruncatingTail;
    NSString *text;
    NSDictionary *attrs;
    if (v == nil || v == [NSNull null]) {
        text = @"null";
        attrs = @{ NSFontAttributeName: [SXTokens scaled:[SXTokens data]],
                   NSForegroundColorAttributeName: [SXTokens inkSubtle],
                   NSParagraphStyleAttributeName: ps };
    } else if ([self isLinkValue]) {
        text = (NSString *)v;
        attrs = @{ NSFontAttributeName: [SXTokens scaled:[SXTokens data]],
                   NSForegroundColorAttributeName: [SXTokens link],
                   NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                   NSParagraphStyleAttributeName: ps };
    } else if ([v isKindOfClass:[NSNumber class]]) {
        ps.alignment = NSTextAlignmentRight;
        text = [(NSNumber *)v stringValue];
        attrs = @{ NSFontAttributeName: [SXTokens scaled:[SXTokens data]],
                   NSForegroundColorAttributeName: [SXTokens ink],
                   NSParagraphStyleAttributeName: ps };
    } else if ([v isKindOfClass:[NSDate class]]) {
        text = [v description];
        attrs = @{ NSFontAttributeName: [SXTokens scaled:[SXTokens data]],
                   NSForegroundColorAttributeName: [SXTokens ink],
                   NSParagraphStyleAttributeName: ps };
    } else {
        text = [v isKindOfClass:[NSString class]] ? (NSString *)v : [v description];
        attrs = @{ NSFontAttributeName: [SXTokens scaled:[SXTokens body]],
                   NSForegroundColorAttributeName: [SXTokens ink],
                   NSParagraphStyleAttributeName: ps };
    }
    return [[NSAttributedString alloc] initWithString:text attributes:attrs];
}

-(void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSAttributedString *attributed = [self styledValue];
    if (self.backgroundStyle == NSBackgroundStyleEmphasized) {
        NSMutableAttributedString *m = [attributed mutableCopy];
        [m addAttribute:NSForegroundColorAttributeName value:[NSColor alternateSelectedControlTextColor] range:NSMakeRange(0, m.length)];
        attributed = m;
    }
    NSRect r = [self titleRectForBounds:cellFrame];
    void (^draw)(void) = ^{
        CGFloat h = ceil([attributed size].height);
        NSRect dest = r;
        if (h < r.size.height) {
            dest.origin.y += floor((r.size.height - h) / 2.0);
            dest.size.height = h;
        }
        [attributed drawWithRect:dest
                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine];
    };
    NSAppearance *appearance = controlView.effectiveAppearance;
    if (appearance != nil) {
        [appearance performAsCurrentDrawingAppearance:draw];
    } else {
        draw();
    }
}

@end
