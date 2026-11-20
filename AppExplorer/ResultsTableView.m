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

#import "ResultsTableView.h"
#import "DesignTokens.h"

@implementation ResultsTableView

-(instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) _stripesRows = YES;
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) _stripesRows = YES;
    return self;
}

-(void)setStripesRows:(BOOL)stripesRows {
    _stripesRows = stripesRows;
    [self setNeedsDisplay:YES];
}

-(void)drawBackgroundInClipRect:(NSRect)clipRect {
    [super drawBackgroundInClipRect:clipRect];
    if (!self.stripesRows) return;
    CGFloat pitch = self.rowHeight + self.intercellSpacing.height;
    if (pitch <= 0) return;
    [[SXTokens surfaceSunken] setFill];
    // Real rows first, then the same rhythm continues below the last one.
    NSRange rows = [self rowsInRect:clipRect];
    for (NSUInteger r = rows.location; r < NSMaxRange(rows); r++) {
        if (r % 2 == 1) NSRectFill(NSIntersectionRect([self rectOfRow:(NSInteger)r], clipRect));
    }
    NSInteger count = self.numberOfRows;
    CGFloat y = count > 0 ? NSMaxY([self rectOfRow:count - 1]) : 0;
    NSInteger r = count;
    if (y < NSMinY(clipRect)) {
        NSInteger skip = (NSInteger)floor((NSMinY(clipRect) - y) / pitch);
        y += skip * pitch;
        r += skip;
    }
    for (; y < NSMaxY(clipRect); y += pitch, r++) {
        if (r % 2 == 1) NSRectFill(NSIntersectionRect(NSMakeRect(NSMinX(clipRect), y, NSWidth(clipRect), pitch), clipRect));
    }
}

@end
