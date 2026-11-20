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

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

// The "SoqlX Rebooted" design system, as AppKit values.
//
// Colours live in Media.xcassets as sx.<token> colour sets with light and dark variants,
// so every NSColor here follows the window's effective appearance automatically. Type uses
// the bundled Inter and JetBrains Mono variable fonts (see Fonts/README.md), falling back to
// the system fonts if they aren't registered (e.g. in unit tests). Spacing, radii and sizes
// are the token values as points.
@interface SXTokens : NSObject

// MARK: Colour
+(NSColor*)color:(NSString*)token;     // any token by name, e.g. @"accent-soft"

+(NSColor*)ground;                     // window background behind every panel
+(NSColor*)surface;                    // panels that hold work
+(NSColor*)surfaceRaised;              // popovers, menus, row hover
+(NSColor*)surfaceSunken;              // wells: gutters, table header band
+(NSColor*)line;                       // hairline dividers
+(NSColor*)lineStrong;                 // control borders (3:1)
+(NSColor*)ink;                        // primary text
+(NSColor*)inkMuted;                   // labels, secondary text
+(NSColor*)inkSubtle;                  // placeholders, line numbers, nulls
+(NSColor*)accent;                     // mustard fill of the one primary action
+(NSColor*)accentHover;
+(NSColor*)onAccent;                   // text on accent, never white
+(NSColor*)accentSoft;                 // selection fill
+(NSColor*)accentInk;                  // mustard as text or a thin mark
+(NSColor*)link;                       // links and the focus ring (sage)
+(NSColor*)success;
+(NSColor*)successSoft;
+(NSColor*)danger;                     // destructive fills, error text, Production
+(NSColor*)onDanger;
+(NSColor*)dangerSoft;

// MARK: Type
// Weight is the variable font's wght axis value (400 regular, 600 semibold, 700 bold).
+(NSFont*)sans:(CGFloat)size weight:(CGFloat)weight;
+(NSFont*)mono:(CGFloat)size weight:(CGFloat)weight;

+(NSFont*)display;        // 72/0.95 bold, cover and first run only
+(NSFont*)titleLarge;     // 32/36, one per screen
+(NSFont*)title;          // 20/26, panel and dialog titles
+(NSFont*)heading;        // 14/20 semibold, section headings in panels
+(NSFont*)body;           // 13/20, default UI text
+(NSFont*)bodyStrong;     // 13/20 semibold, button labels, selected items
+(NSFont*)caption;        // 12/16, status bar and hints
+(NSFont*)label;          // 11/16 semibold, uppercase eyebrow labels
+(NSFont*)code;           // 13/20 mono, SOQL and Apex
+(NSFont*)data;           // 12/16 mono, grid cells, Ids, API names
+(NSFont*)dataStrong;     // 12/16 mono semibold

// Uppercase eyebrow label attributes (label font, 0.06em tracking, ink-muted).
+(NSDictionary<NSAttributedStringKey,id>*)labelAttributes;

// YES if the bundled fonts registered with the system (so sans:/mono: return Inter/JetBrains Mono).
+(BOOL)bundledFontsAvailable;

// Settings, Appearance. Text scale applies to the results, sidebar and details; row height follows density.
+(CGFloat)textScale;                       // PREF_TEXT_SCALE, clamped to 0.8 ... 1.5, 1.0 when unset
+(NSFont*)scaled:(NSFont*)font;            // font at textScale times its size
+(CGFloat)rowHeight;                       // SXRowCompact, or SXRowComfortable when PREF_DENSITY is "comfortable"

@end

// MARK: Spacing (4px scale)
extern const CGFloat SXSpace1;   // 4
extern const CGFloat SXSpace2;   // 8
extern const CGFloat SXSpace3;   // 12
extern const CGFloat SXSpace4;   // 16
extern const CGFloat SXSpace5;   // 24
extern const CGFloat SXSpace6;   // 32
extern const CGFloat SXSpace7;   // 48
extern const CGFloat SXSpace8;   // 64

// MARK: Radius
extern const CGFloat SXRadiusXS;   // 2, checkboxes, badges
extern const CGFloat SXRadiusSM;   // 4, buttons, inputs, tree rows
extern const CGFloat SXRadiusMD;   // 6, panels, schema nodes, popovers
extern const CGFloat SXRadiusLG;   // 10, dialogs
extern const CGFloat SXRadiusPill; // 999, org chip and filter chips only

// MARK: Size
extern const CGFloat SXRowCompact;       // 28
extern const CGFloat SXRowComfortable;   // 36
extern const CGFloat SXControlSM;        // 24
extern const CGFloat SXControlMD;        // 28
extern const CGFloat SXControlLG;        // 36
extern const CGFloat SXTitlebarHeight;   // 44
extern const CGFloat SXSidebarWidth;     // 260
extern const CGFloat SXInspectorWidth;   // 320

NS_ASSUME_NONNULL_END
