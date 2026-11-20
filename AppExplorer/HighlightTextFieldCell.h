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

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, SidebarRowStyle) {
    SidebarRowObject,
    SidebarRowField,
    SidebarRowGroup
};

// The sidebar's only cell. Draws everything itself and ignores backgroundStyle,
// so the table's selection never changes its colours.
@interface HighlightTextFieldCell : NSTextFieldCell

@property (assign) SidebarRowStyle rowStyle;
// Object rows: drawn in a 16x16 box, vertically centred, clipped to SXRadiusXS corners.
// The box is reserved even when nil so names line up.
@property (strong) NSImage *icon;
// Right-aligned: field type, group count.
@property (copy) NSString *detailText;
// Filter match: accent-soft rounded fill behind the name, accent-ink text.
@property (assign) BOOL standout;
// Object not yet described: ink-muted.
@property (assign) BOOL dimmed;
// Semibold text.
@property (assign) BOOL selectedRow;

@end
