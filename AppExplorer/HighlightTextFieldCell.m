// Copyright (c) 2009,2013 Simon Fell
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

#import "HighlightTextFieldCell.h"
#import "DesignTokens.h"

static const CGFloat kIconSize = 16.0;

@implementation HighlightTextFieldCell

-(id)copyWithZone:(NSZone *)zone {
    HighlightTextFieldCell *c = [super copyWithZone:zone];
    // NSCell copies ivars bitwise without retaining. Add the retain the copy owns, then
    // assign, which releases the stale bitwise value.
    (void)CFBridgingRetain(_icon);
    c->_icon = _icon;
    (void)CFBridgingRetain(_detailText);
    c->_detailText = [_detailText copy];
    c->_rowStyle = _rowStyle;
    c->_standout = _standout;
    c->_dimmed = _dimmed;
    c->_selectedRow = _selectedRow;
    return c;
}

-(NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    return nil;
}

-(NSDictionary *)attributesWithFont:(NSFont *)font color:(NSColor *)color {
    NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
    ps.lineBreakMode = NSLineBreakByTruncatingTail;
    return @{ NSFontAttributeName: font,
              NSForegroundColorAttributeName: color,
              NSParagraphStyleAttributeName: ps };
}

static const NSStringDrawingOptions kDrawOptions = NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine;

static NSSize measure(NSString *s, NSDictionary *attrs) {
    NSRect r = [s boundingRectWithSize:NSMakeSize(100000.0, 100000.0) options:kDrawOptions attributes:attrs];
    return NSMakeSize(ceil(NSWidth(r)), ceil(NSHeight(r)));
}

-(void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSAppearance *appearance = controlView.effectiveAppearance ?: NSApp.effectiveAppearance;
    [appearance performAsCurrentDrawingAppearance:^{
        [self drawContentInFrame:cellFrame];
    }];
}

-(void)drawContentInFrame:(NSRect)frame {
    NSString *name = self.stringValue ?: @"";
    NSString *detail = self.detailText;
    CGFloat left = NSMinX(frame) + (self.rowStyle == SidebarRowGroup ? SXSpace2 : SXSpace1);
    CGFloat right = NSMaxX(frame) - SXSpace2;

    NSDictionary *nameAttrs;
    NSDictionary *detailAttrs;
    switch (self.rowStyle) {
        case SidebarRowGroup: {
            NSMutableDictionary *a = [[SXTokens labelAttributes] mutableCopy];
            a[NSForegroundColorAttributeName] = [SXTokens inkSubtle];
            NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
            ps.lineBreakMode = NSLineBreakByTruncatingTail;
            a[NSParagraphStyleAttributeName] = ps;
            nameAttrs = a;
            name = name.localizedUppercaseString;
            detailAttrs = [self attributesWithFont:[SXTokens caption] color:[SXTokens inkSubtle]];
            break;
        }
        case SidebarRowField: {
            NSColor *c = self.standout ? [SXTokens accentInk] : [SXTokens inkMuted];
            nameAttrs = [self attributesWithFont:(self.selectedRow ? [SXTokens dataStrong] : [SXTokens data]) color:c];
            detailAttrs = [self attributesWithFont:[SXTokens mono:11 weight:400] color:[SXTokens inkSubtle]];
            break;
        }
        case SidebarRowObject:
        default: {
            NSColor *c = self.dimmed ? [SXTokens inkMuted] : [SXTokens ink];
            if (self.standout) c = [SXTokens accentInk];
            nameAttrs = [self attributesWithFont:(self.selectedRow ? [SXTokens bodyStrong] : [SXTokens body]) color:c];
            detailAttrs = [self attributesWithFont:[SXTokens caption] color:[SXTokens inkSubtle]];
            break;
        }
    }

    if (self.rowStyle == SidebarRowObject) {
        NSRect box = NSMakeRect(left, floor(NSMidY(frame) - kIconSize / 2.0), kIconSize, kIconSize);
        if (self.icon != nil) {
            NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
            [ctx saveGraphicsState];
            [[NSBezierPath bezierPathWithRoundedRect:box xRadius:SXRadiusXS yRadius:SXRadiusXS] addClip];
            [self.icon drawInRect:box fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
            [ctx restoreGraphicsState];
        }
        left += kIconSize + SXSpace2;
    }

    // The detail gets its measured width, the name gets the rest.
    if (detail.length > 0) {
        NSSize ds = measure(detail, detailAttrs);
        CGFloat maxDetail = MAX(0.0, (right - left) * 0.6);
        CGFloat dw = MIN(ds.width, maxDetail);
        NSRect dr = NSMakeRect(right - dw, 0, dw, ds.height);
        dr.origin.y = [self textYInFrame:frame height:ds.height];
        [detail drawWithRect:dr options:kDrawOptions attributes:detailAttrs];
        right -= dw + SXSpace2;
    }

    CGFloat avail = MAX(0.0, right - left);
    if (avail <= 0.0 || name.length == 0) return;
    NSSize ns = measure(name, nameAttrs);
    CGFloat nw = MIN(ns.width, avail);
    CGFloat ny = [self textYInFrame:frame height:ns.height];

    if (self.standout && self.rowStyle != SidebarRowGroup) {
        CGFloat h = MIN(ns.height + 2.0, NSHeight(frame) - 2.0);
        NSRect bg = NSMakeRect(left - SXSpace1, floor(NSMidY(frame) - h / 2.0), nw + 2.0 * SXSpace1, h);
        [[SXTokens accentSoft] setFill];
        [[NSBezierPath bezierPathWithRoundedRect:bg xRadius:SXRadiusSM yRadius:SXRadiusSM] fill];
    }

    [name drawWithRect:NSMakeRect(left, ny, nw, ns.height) options:kDrawOptions attributes:nameAttrs];
}

// Groups sit at the bottom of the row, everything else is vertically centred.
-(CGFloat)textYInFrame:(NSRect)frame height:(CGFloat)h {
    if (self.rowStyle == SidebarRowGroup) {
        return NSMaxY(frame) - SXSpace1 - h;
    }
    return floor(NSMidY(frame) - h / 2.0);
}

@end
