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
    if (self) _stripesColumns = YES;
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) _stripesColumns = YES;
    return self;
}

-(void)setStripesColumns:(BOOL)stripesColumns {
    _stripesColumns = stripesColumns;
    [self setNeedsDisplay:YES];
}

// Columns are added, removed and resized as results arrive; the stripes follow them.
-(void)tile {
    [super tile];
    [self setNeedsDisplay:YES];
}

-(void)drawBackgroundInClipRect:(NSRect)clipRect {
    [super drawBackgroundInClipRect:clipRect];
    if (!self.stripesColumns) return;
    NSIndexSet *cols = [self columnIndexesInRect:clipRect];
    if (cols.count == 0) return;
    [[SXTokens surfaceSunken] setFill];
    for (NSUInteger c = cols.firstIndex; c <= cols.lastIndex; c++) {
        if (c % 2 == 0) continue;
        NSRect r = [self rectOfColumn:(NSInteger)c];
        // Down the whole view, past the last row, so short results still read as columns.
        r.origin.y = NSMinY(clipRect);
        r.size.height = NSHeight(clipRect);
        NSRectFill(NSIntersectionRect(r, clipRect));
    }
}

@end
