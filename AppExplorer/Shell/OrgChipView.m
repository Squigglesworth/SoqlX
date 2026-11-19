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

#import "OrgChipView.h"
#import "DesignTokens.h"

static const CGFloat kMarkSize = 10.0;

@implementation OrgChipView

-(instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        _kind = SXOrgKindProduction;
    }
    return self;
}

-(BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }
-(BOOL)mouseDownCanMoveWindow { return NO; }

// MARK: Setters

-(void)refresh {
    [self invalidateIntrinsicContentSize];
    NSString *label = self.label.length ? self.label : @"";
    if (self.detail.length) {
        self.toolTip = label.length ? [NSString stringWithFormat:@"%@, %@", label, self.detail] : self.detail;
    } else {
        self.toolTip = label.length ? label : nil;
    }
    self.needsDisplay = YES;
}

-(void)setKind:(SXOrgKind)kind {
    _kind = kind;
    [self refresh];
}

-(void)setLabel:(NSString *)label {
    _label = [label copy];
    [self refresh];
}

-(void)setDetail:(NSString *)detail {
    _detail = [detail copy];
    [self refresh];
}

-(void)setColor:(NSColor *)color {
    _color = color;
    [self refresh];
}

// MARK: Geometry

-(NSDictionary *)kindAttributes {
    return @{ NSFontAttributeName: [SXTokens bodyStrong], NSForegroundColorAttributeName: [SXTokens ink] };
}

-(NSDictionary *)labelAttributes {
    return @{ NSFontAttributeName: [SXTokens caption], NSForegroundColorAttributeName: [SXTokens inkMuted] };
}

-(NSSize)intrinsicContentSize {
    NSSize kindSize = [SXOrgKindWord(self.kind) sizeWithAttributes:[self kindAttributes]];
    CGFloat w = SXSpace2 + kMarkSize + SXSpace1 + ceil(kindSize.width);
    if (self.label.length) {
        NSSize labelSize = [self.label sizeWithAttributes:[self labelAttributes]];
        w += SXSpace1 + ceil(labelSize.width);
    }
    if (self.color) {
        w += SXSpace1 + kMarkSize;
    }
    w += SXSpace2;
    return NSMakeSize(w, SXControlSM);
}

// MARK: Drawing

-(void)drawChip {
    NSRect bounds = self.bounds;
    CGFloat h = NSHeight(bounds);

    NSColor *accent;
    switch (self.kind) {
        case SXOrgKindProduction: accent = [SXTokens danger]; break;
        case SXOrgKindSandbox:    accent = [SXTokens success]; break;
        default:                  accent = [SXTokens accentInk]; break;
    }

    // Pill: fill (Production only) and 1pt border (dashed for Developer and Trial).
    CGFloat radius = MIN(SXRadiusPill, h / 2.0);
    NSBezierPath *pill = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(bounds, 0.5, 0.5) xRadius:radius yRadius:radius];
    if (self.kind == SXOrgKindProduction) {
        [[SXTokens dangerSoft] setFill];
        [pill fill];
    }
    pill.lineWidth = 1.0;
    if (self.kind == SXOrgKindDeveloper || self.kind == SXOrgKindTrial) {
        CGFloat pattern[2] = { 3.0, 2.0 };
        [pill setLineDash:pattern count:2 phase:0.0];
    }
    [accent setStroke];
    [pill stroke];

    CGFloat x = SXSpace2;
    CGFloat midY = NSMidY(bounds);

    // Mark: square, ring or diamond.
    NSRect mark = NSMakeRect(x, midY - kMarkSize / 2.0, kMarkSize, kMarkSize);
    switch (self.kind) {
        case SXOrgKindProduction: {
            [accent setFill];
            NSRectFill(mark);
            break;
        }
        case SXOrgKindSandbox: {
            NSBezierPath *ring = [NSBezierPath bezierPathWithOvalInRect:NSInsetRect(mark, 1.0, 1.0)];
            ring.lineWidth = 1.5;
            [accent setStroke];
            [ring stroke];
            break;
        }
        default: {
            NSBezierPath *d = [NSBezierPath bezierPath];
            [d moveToPoint:NSMakePoint(NSMidX(mark), NSMinY(mark))];
            [d lineToPoint:NSMakePoint(NSMaxX(mark), NSMidY(mark))];
            [d lineToPoint:NSMakePoint(NSMidX(mark), NSMaxY(mark))];
            [d lineToPoint:NSMakePoint(NSMinX(mark), NSMidY(mark))];
            [d closePath];
            [accent setFill];
            [d fill];
            break;
        }
    }
    x += kMarkSize + SXSpace1;

    // Kind word.
    NSString *word = SXOrgKindWord(self.kind);
    NSDictionary *kindAttrs = [self kindAttributes];
    NSSize kindSize = [word sizeWithAttributes:kindAttrs];
    [word drawAtPoint:NSMakePoint(x, midY - kindSize.height / 2.0) withAttributes:kindAttrs];
    x += ceil(kindSize.width);

    // Label.
    if (self.label.length) {
        x += SXSpace1;
        NSDictionary *labelAttrs = [self labelAttributes];
        NSSize labelSize = [self.label sizeWithAttributes:labelAttrs];
        [self.label drawAtPoint:NSMakePoint(x, midY - labelSize.height / 2.0) withAttributes:labelAttrs];
        x += ceil(labelSize.width);
    }

    // Colour dot.
    if (self.color) {
        x += SXSpace1;
        NSBezierPath *dot = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(x, midY - kMarkSize / 2.0, kMarkSize, kMarkSize)];
        [self.color setFill];
        [dot fill];
    }
}

-(void)drawRect:(NSRect)dirtyRect {
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        [self drawChip];
    }];
}

// MARK: Mouse

-(void)mouseDown:(NSEvent *)event {
    // Swallow so mouseUp: arrives here rather than dragging the window.
}

-(void)mouseUp:(NSEvent *)event {
    NSPoint p = [self convertPoint:event.locationInWindow fromView:nil];
    if (NSPointInRect(p, self.bounds) && self.action) {
        [NSApp sendAction:self.action to:self.target from:self];
    }
}

@end
