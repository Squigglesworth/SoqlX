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

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

// A settings page: a fixed left nav of section names and a scrolling column of sections on the right.
// The nav follows the scroll position and clicking a nav item scrolls to its section.
@interface SettingsPageView : NSView

@property (copy) NSString *pageTitle;                       // drawn once in titleLarge

-(void)addSection:(NSString *)identifier title:(NSString *)title;   // nav item + h2 heading
// Title in bodyStrong ink, text in caption inkMuted (wraps), control right-aligned and vertically
// centred; nil control gives a text-only row. Min height 56, 1pt `line` underneath.
-(void)addRowInSection:(NSString *)identifier title:(NSString *)title text:(NSString *)text control:(nullable NSView *)control;
-(void)addSubheading:(NSString *)text inSection:(NSString *)identifier;   // heading font, SXSpace4 above
-(void)addProse:(NSString *)text inSection:(NSString *)identifier;        // body, ink, wraps
-(void)addBullets:(NSArray<NSString *> *)items inSection:(NSString *)identifier;  // "•" hanging indent
-(void)addView:(NSView *)view inSection:(NSString *)identifier;           // full column width
-(void)removeContentOfSection:(NSString *)identifier;                    // keeps the heading
-(void)scrollToSection:(NSString *)identifier;
@property (readonly, copy) NSString *visibleSection;
+(NSView *)badgeWithText:(NSString *)text;   // sx-badge--accent: accent-soft fill, accent-ink border, label font

@end

NS_ASSUME_NONNULL_END
