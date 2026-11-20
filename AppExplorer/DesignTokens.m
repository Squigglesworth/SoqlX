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

#import "DesignTokens.h"
#import "Prefs.h"

const CGFloat SXSpace1 = 4;
const CGFloat SXSpace2 = 8;
const CGFloat SXSpace3 = 12;
const CGFloat SXSpace4 = 16;
const CGFloat SXSpace5 = 24;
const CGFloat SXSpace6 = 32;
const CGFloat SXSpace7 = 48;
const CGFloat SXSpace8 = 64;

const CGFloat SXRadiusXS = 2;
const CGFloat SXRadiusSM = 4;
const CGFloat SXRadiusMD = 6;
const CGFloat SXRadiusLG = 10;
const CGFloat SXRadiusPill = 999;

const CGFloat SXRowCompact = 28;
const CGFloat SXRowComfortable = 36;
const CGFloat SXControlSM = 24;
const CGFloat SXControlMD = 28;
const CGFloat SXControlLG = 36;
const CGFloat SXTitlebarHeight = 44;
const CGFloat SXSidebarWidth = 260;
const CGFloat SXInspectorWidth = 320;

static NSString *const SansPostScriptName = @"Inter-Regular";
static NSString *const MonoPostScriptName = @"JetBrainsMono-Regular";
// The OpenType 'wght' variation axis, as the four-char code NSFontVariationAttribute keys on.
static const NSUInteger WeightAxisTag = 0x77676874;

@implementation SXTokens

// MARK: - Colour

+(NSColor*)color:(NSString*)token {
    // In unit tests the main bundle is the test runner, so look in the bundle that holds this class.
    NSColor *c = [NSColor colorNamed:[@"sx." stringByAppendingString:token] bundle:[NSBundle bundleForClass:self]];
    NSAssert(c != nil, @"No colour asset for design token %@", token);
    return c ?: [NSColor magentaColor];
}

+(NSColor*)ground         { return [self color:@"ground"]; }
+(NSColor*)surface        { return [self color:@"surface"]; }
+(NSColor*)surfaceRaised  { return [self color:@"surface-raised"]; }
+(NSColor*)surfaceSunken  { return [self color:@"surface-sunken"]; }
+(NSColor*)line           { return [self color:@"line"]; }
+(NSColor*)lineStrong     { return [self color:@"line-strong"]; }
+(NSColor*)ink            { return [self color:@"ink"]; }
+(NSColor*)inkMuted       { return [self color:@"ink-muted"]; }
+(NSColor*)inkSubtle      { return [self color:@"ink-subtle"]; }
+(NSColor*)accent         { return [self color:@"accent"]; }
+(NSColor*)accentHover    { return [self color:@"accent-hover"]; }
+(NSColor*)onAccent       { return [self color:@"on-accent"]; }
+(NSColor*)accentSoft     { return [self color:@"accent-soft"]; }
+(NSColor*)accentInk      { return [self color:@"accent-ink"]; }
+(NSColor*)link           { return [self color:@"link"]; }
+(NSColor*)success        { return [self color:@"success"]; }
+(NSColor*)successSoft    { return [self color:@"success-soft"]; }
+(NSColor*)danger         { return [self color:@"danger"]; }
+(NSColor*)onDanger       { return [self color:@"on-danger"]; }
+(NSColor*)dangerSoft     { return [self color:@"danger-soft"]; }

// MARK: - Type

+(BOOL)bundledFontsAvailable {
    static dispatch_once_t onceToken;
    static BOOL available;
    dispatch_once(&onceToken, ^{
        available = [NSFont fontWithName:SansPostScriptName size:13] != nil && [NSFont fontWithName:MonoPostScriptName size:13] != nil;
        if (!available) {
            NSLog(@"Bundled fonts are not registered, falling back to the system fonts");
        }
    });
    return available;
}

// Maps a wght axis value onto the system font weights for the fallback fonts.
+(NSFontWeight)systemWeightFor:(CGFloat)wght {
    if (wght >= 800) return NSFontWeightHeavy;
    if (wght >= 700) return NSFontWeightBold;
    if (wght >= 600) return NSFontWeightSemibold;
    if (wght >= 500) return NSFontWeightMedium;
    if (wght >= 400) return NSFontWeightRegular;
    if (wght >= 300) return NSFontWeightLight;
    return NSFontWeightThin;
}

+(NSFont*)variableFont:(NSString*)psName size:(CGFloat)size weight:(CGFloat)wght {
    NSFont *base = [NSFont fontWithName:psName size:size];
    if (base == nil) {
        return nil;
    }
    NSFontDescriptor *d = [base.fontDescriptor fontDescriptorByAddingAttributes:@{
        NSFontVariationAttribute: @{ @(WeightAxisTag): @(wght) }
    }];
    NSFont *f = [NSFont fontWithDescriptor:d size:size];
    return f ?: base;
}

+(NSFont*)sans:(CGFloat)size weight:(CGFloat)weight {
    NSFont *f = [self bundledFontsAvailable] ? [self variableFont:SansPostScriptName size:size weight:weight] : nil;
    return f ?: [NSFont systemFontOfSize:size weight:[self systemWeightFor:weight]];
}

+(NSFont*)mono:(CGFloat)size weight:(CGFloat)weight {
    NSFont *f = [self bundledFontsAvailable] ? [self variableFont:MonoPostScriptName size:size weight:weight] : nil;
    return f ?: [NSFont monospacedSystemFontOfSize:size weight:[self systemWeightFor:weight]];
}

+(NSFont*)display     { return [self sans:72 weight:700]; }
+(NSFont*)titleLarge  { return [self sans:32 weight:650]; }
+(NSFont*)title       { return [self sans:20 weight:600]; }
+(NSFont*)heading     { return [self sans:14 weight:600]; }
+(NSFont*)body        { return [self sans:13 weight:400]; }
+(NSFont*)bodyStrong  { return [self sans:13 weight:600]; }
+(NSFont*)caption     { return [self sans:12 weight:400]; }
+(NSFont*)label       { return [self sans:11 weight:600]; }
+(NSFont*)code        { return [self mono:13 weight:400]; }
+(NSFont*)data        { return [self mono:12 weight:400]; }
+(NSFont*)dataStrong  { return [self mono:12 weight:600]; }

+(NSDictionary<NSAttributedStringKey,id>*)labelAttributes {
    return @{
        NSFontAttributeName: [self label],
        NSForegroundColorAttributeName: [self inkMuted],
        NSKernAttributeName: @(11 * 0.06),
    };
}

// MARK: - Text size and density

+(CGFloat)textScale {
    id v = [[NSUserDefaults standardUserDefaults] objectForKey:PREF_TEXT_SCALE];
    double scale = [v respondsToSelector:@selector(doubleValue)] ? [v doubleValue] : 1.0;
    if (scale <= 0) return 1.0;
    return MIN(1.5, MAX(0.8, scale));
}

+(NSFont*)scaled:(NSFont*)font {
    CGFloat scale = [self textScale];
    if (font == nil || scale == 1.0) return font;
    return [NSFont fontWithDescriptor:font.fontDescriptor size:round(font.pointSize * scale * 2) / 2] ?: font;
}

+(CGFloat)rowHeight {
    NSString *density = [[NSUserDefaults standardUserDefaults] stringForKey:PREF_DENSITY];
    return [density isEqualToString:@"comfortable"] ? SXRowComfortable : SXRowCompact;
}

@end
