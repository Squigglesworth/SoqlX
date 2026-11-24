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


#import "ApiMeterView.h"
#import "DesignTokens.h"

@implementation ApiMeterView

-(void)setFraction:(double)fraction {
    _fraction = MIN(1.0, MAX(0.0, fraction));
    self.toolTip = [NSString stringWithFormat:@"%.1f%% of the org's daily API request limit used", _fraction * 100.0];
    [self setNeedsDisplay:YES];
}

-(BOOL)isFlipped { return NO; }

-(void)drawRect:(NSRect)dirtyRect {
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        NSRect track = NSInsetRect(self.bounds, 0.5, 0.5);
        CGFloat radius = NSHeight(track) / 2;
        [[SXTokens surfaceSunken] setFill];
        [[NSBezierPath bezierPathWithRoundedRect:track xRadius:radius yRadius:radius] fill];
        [[SXTokens lineStrong] setStroke];
        [[NSBezierPath bezierPathWithRoundedRect:track xRadius:radius yRadius:radius] stroke];

        if (self.fraction <= 0) return;
        NSColor *fill = self.fraction >= 0.9 ? [SXTokens danger]
                      : self.fraction >= 0.75 ? [SXTokens accent]
                      : [SXTokens link];
        CGFloat w = MAX(NSHeight(track), round(NSWidth(track) * self.fraction));
        NSRect bar = NSMakeRect(NSMinX(track), NSMinY(track), MIN(w, NSWidth(track)), NSHeight(track));
        [fill setFill];
        [[NSBezierPath bezierPathWithRoundedRect:bar xRadius:radius yRadius:radius] fill];
    }];
}

@end
