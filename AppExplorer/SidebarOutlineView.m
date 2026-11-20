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

#import "SidebarOutlineView.h"
#import "DesignTokens.h"

@interface SidebarOutlineView ()
@property (readwrite) NSInteger hoveredRow;
@property (strong) NSTrackingArea *sidebarTrackingArea;
@end

@implementation SidebarOutlineView

-(instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) _hoveredRow = -1;
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) _hoveredRow = -1;
    return self;
}

-(void)awakeFromNib {
    [super awakeFromNib];
    self.style = NSTableViewStyleFullWidth;
    self.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;
    self.backgroundColor = [SXTokens surface];
    self.intercellSpacing = NSMakeSize(0, 0);
    self.indentationPerLevel = 14.0;
    self.floatsGroupRows = NO;
    self.rowHeight = [SXTokens rowHeight];
    self.focusRingType = NSFocusRingTypeNone;
}

-(void)updateTrackingAreas {
    [super updateTrackingAreas];
    if (self.sidebarTrackingArea != nil) {
        [self removeTrackingArea:self.sidebarTrackingArea];
    }
    NSTrackingAreaOptions opts = NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect;
    self.sidebarTrackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:opts owner:self userInfo:nil];
    [self addTrackingArea:self.sidebarTrackingArea];
}

-(void)setHoverRow:(NSInteger)row {
    NSInteger old = self.hoveredRow;
    if (old == row) return;
    self.hoveredRow = row;
    if (old >= 0) [self setNeedsDisplayInRect:[self rectOfRow:old]];
    if (row >= 0) [self setNeedsDisplayInRect:[self rectOfRow:row]];
}

-(void)mouseMoved:(NSEvent *)event {
    [super mouseMoved:event];
    NSPoint p = [self convertPoint:event.locationInWindow fromView:nil];
    [self setHoverRow:[self rowAtPoint:p]];
}

-(void)mouseExited:(NSEvent *)event {
    [super mouseExited:event];
    [self setHoverRow:-1];
}

// The row under a still pointer changes when the content moves under it.
-(void)refreshHoverFromPointer {
    if (self.window == nil) return;
    NSPoint p = [self convertPoint:self.window.mouseLocationOutsideOfEventStream fromView:nil];
    [self setHoverRow:NSPointInRect(p, self.visibleRect) ? [self rowAtPoint:p] : -1];
}

-(void)scrollWheel:(NSEvent *)event {
    [super scrollWheel:event];
    [self refreshHoverFromPointer];
}

-(void)expandItem:(id)item expandChildren:(BOOL)expandChildren {
    [super expandItem:item expandChildren:expandChildren];
    [self refreshHoverFromPointer];
}

-(void)collapseItem:(id)item collapseChildren:(BOOL)collapseChildren {
    [super collapseItem:item collapseChildren:collapseChildren];
    [self refreshHoverFromPointer];
}

-(void)reloadData {
    [super reloadData];
    [self setHoverRow:-1];
}

-(void)highlightSelectionInClipRect:(NSRect)clipRect {
    [self.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop) {
        NSRect r = [self rectOfRow:(NSInteger)row];
        if (!NSIntersectsRect(r, clipRect)) return;
        NSRect fill = NSInsetRect(r, SXSpace1, 1.0);
        [[SXTokens accentSoft] setFill];
        [[NSBezierPath bezierPathWithRoundedRect:fill xRadius:SXRadiusSM yRadius:SXRadiusSM] fill];
    }];
}

-(void)drawBackgroundInClipRect:(NSRect)clipRect {
    [super drawBackgroundInClipRect:clipRect];
    NSInteger row = self.hoveredRow;
    if (row < 0 || row >= self.numberOfRows) return;
    if ([self isRowSelected:row]) return;
    if ([self.delegate respondsToSelector:@selector(outlineView:isGroupItem:)]) {
        id item = [self itemAtRow:row];
        if (item != nil && [self.delegate outlineView:self isGroupItem:item]) return;
    }
    NSRect r = [self rectOfRow:row];
    if (!NSIntersectsRect(r, clipRect)) return;
    NSRect fill = NSInsetRect(r, SXSpace1, 1.0);
    [[SXTokens surfaceRaised] setFill];
    [[NSBezierPath bezierPathWithRoundedRect:fill xRadius:SXRadiusSM yRadius:SXRadiusSM] fill];
}

@end
