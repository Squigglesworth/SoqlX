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

#import "NavRailView.h"
#import "DesignTokens.h"

static const CGFloat kRailWidth = 64.0;
static const CGFloat kItemSize = 56.0;
static const CGFloat kIconSize = 24.0;

// One rail entry; lightweight, drawn by the rail itself.
@interface NavRailItem : NSObject
@property (copy) NSString *title;
@property (strong) NSImage *image;
@property (assign) NSInteger tag;
@property (assign) BOOL bottom;
@property (assign) NSRect rect;   // tracking/hit rect in rail coordinates, set by layoutItems
@end

@implementation NavRailItem
@end

@interface NavRailView ()
@property (strong) NSMutableArray<NavRailItem *> *items;
@property (weak) NavRailItem *hoverItem;
@property (weak) NavRailItem *pressedItem;
@property (strong) NSTrackingArea *railTrackingArea;
@end

@implementation NavRailView

-(instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _items = [NSMutableArray array];
        _selectedTag = 0;
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return self;
}

// Flipped so item layout reads top to bottom.
-(BOOL)isFlipped { return YES; }

-(BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }

-(NSSize)intrinsicContentSize {
    return NSMakeSize(kRailWidth, NSViewNoIntrinsicMetric);
}

-(void)addItemWithTitle:(NSString *)title image:(NSImage *)image tag:(NSInteger)tag pinToBottom:(BOOL)bottom {
    NavRailItem *item = [[NavRailItem alloc] init];
    item.title = title ?: @"";
    item.image = image;
    item.tag = tag;
    item.bottom = bottom;
    [self.items addObject:item];
    [self layoutItems];
    [self updateTrackingAreas];
    self.needsDisplay = YES;
}

-(void)setSelectedTag:(NSInteger)selectedTag {
    _selectedTag = selectedTag;
    self.needsDisplay = YES;
}

// Computes each item's rect: top items stack downward, bottom items stack upward.
-(void)layoutItems {
    CGFloat x = floor((NSWidth(self.bounds) - kItemSize) / 2.0);
    CGFloat step = kItemSize + SXSpace1;
    CGFloat topY = SXSpace2;
    CGFloat bottomY = NSHeight(self.bounds) - SXSpace2 - kItemSize;
    for (NavRailItem *item in self.items) {
        if (item.bottom) {
            item.rect = NSMakeRect(x, bottomY, kItemSize, kItemSize);
            bottomY -= step;
        } else {
            item.rect = NSMakeRect(x, topY, kItemSize, kItemSize);
            topY += step;
        }
    }
}

-(void)setFrameSize:(NSSize)newSize {
    [super setFrameSize:newSize];
    [self layoutItems];
    self.needsDisplay = YES;
}

-(NavRailItem *)itemAtPoint:(NSPoint)p {
    for (NavRailItem *item in self.items) {
        if (NSPointInRect(p, item.rect)) return item;
    }
    return nil;
}

// MARK: Tracking

-(void)updateTrackingAreas {
    [super updateTrackingAreas];
    if (self.railTrackingArea) {
        [self removeTrackingArea:self.railTrackingArea];
    }
    self.railTrackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                         options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect)
                                                           owner:self
                                                        userInfo:nil];
    [self addTrackingArea:self.railTrackingArea];
}

-(void)setHover:(NavRailItem *)item {
    if (item != self.hoverItem) {
        self.hoverItem = item;
        self.needsDisplay = YES;
    }
}

-(void)mouseEntered:(NSEvent *)event {
    [self setHover:[self itemAtPoint:[self convertPoint:event.locationInWindow fromView:nil]]];
}

-(void)mouseMoved:(NSEvent *)event {
    [self setHover:[self itemAtPoint:[self convertPoint:event.locationInWindow fromView:nil]]];
}

-(void)mouseExited:(NSEvent *)event {
    [self setHover:nil];
}

// MARK: Mouse

-(void)mouseDown:(NSEvent *)event {
    self.pressedItem = [self itemAtPoint:[self convertPoint:event.locationInWindow fromView:nil]];
}

-(void)mouseUp:(NSEvent *)event {
    NavRailItem *pressed = self.pressedItem;
    self.pressedItem = nil;
    if (!pressed) return;
    NavRailItem *upItem = [self itemAtPoint:[self convertPoint:event.locationInWindow fromView:nil]];
    if (upItem != pressed) return;
    self.selectedTag = pressed.tag;
    if (self.action) {
        [NSApp sendAction:self.action to:self.target from:self];
    }
}

// MARK: Drawing

// Returns a copy of the template image filled with the colour (SourceAtop keeps its alpha).
-(NSImage *)tintedImage:(NSImage *)image color:(NSColor *)color {
    NSSize size = NSMakeSize(kIconSize, kIconSize);
    return [NSImage imageWithSize:size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        [image drawInRect:dstRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
        [color set];
        NSRectFillUsingOperation(dstRect, NSCompositingOperationSourceAtop);
        return YES;
    }];
}

-(void)drawRail {
    [[SXTokens ground] setFill];
    NSRectFill(self.bounds);

    // 1pt line on the trailing edge.
    [[SXTokens line] setFill];
    NSRectFill(NSMakeRect(NSMaxX(self.bounds) - 1.0, 0, 1.0, NSHeight(self.bounds)));

    NSMutableParagraphStyle *para = [[NSMutableParagraphStyle alloc] init];
    para.alignment = NSTextAlignmentCenter;
    para.lineBreakMode = NSLineBreakByTruncatingTail;

    for (NavRailItem *item in self.items) {
        NSRect r = item.rect;
        BOOL selected = (item.tag == self.selectedTag);
        BOOL hover = (item == self.hoverItem);

        if (selected) {
            NSBezierPath *p = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(r, 0.5, 0.5) xRadius:SXRadiusSM yRadius:SXRadiusSM];
            [[SXTokens accentSoft] setFill];
            [p fill];
            [[SXTokens accentInk] setStroke];
            p.lineWidth = 1.0;
            [p stroke];
        } else if (hover) {
            NSBezierPath *p = [NSBezierPath bezierPathWithRoundedRect:r xRadius:SXRadiusSM yRadius:SXRadiusSM];
            [[SXTokens surfaceRaised] setFill];
            [p fill];
        }

        NSColor *tint = selected ? [SXTokens ink] : [SXTokens inkMuted];

        if (item.image) {
            NSRect iconRect = NSMakeRect(NSMidX(r) - kIconSize / 2.0, r.origin.y + 8.0, kIconSize, kIconSize);
            NSImage *tinted = [self tintedImage:item.image color:tint];
            [tinted drawInRect:iconRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
        }

        NSDictionary *attrs = @{ NSFontAttributeName: [SXTokens label],
                                 NSForegroundColorAttributeName: tint,
                                 NSParagraphStyleAttributeName: para };
        NSRect textRect = NSMakeRect(r.origin.x + 2.0, r.origin.y + 8.0 + kIconSize + SXSpace1, r.size.width - 4.0, 16.0);
        [item.title drawInRect:textRect withAttributes:attrs];
    }
}

-(void)drawRect:(NSRect)dirtyRect {
    [self layoutItems];
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        [self drawRail];
    }];
}

@end
