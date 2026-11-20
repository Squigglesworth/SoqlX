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

#import "SettingsPageView.h"
#import "DesignTokens.h"

static const CGFloat kNavWidth = 208.0;
static const CGFloat kColumnMaxWidth = 680.0;
static const CGFloat kRowMinHeight = 56.0;
static const CGFloat kNavItemHeight = 28.0;
static const CGFloat kVisibleSlack = 24.0;

// MARK: Helper views

// A text field that wraps to its own width in Auto Layout.
@interface SXWrapLabel : NSTextField
@end

@implementation SXWrapLabel
-(void)layout {
    [super layout];
    CGFloat w = NSWidth(self.frame);
    if (w > 0.0 && fabs(w - self.preferredMaxLayoutWidth) > 0.5) {
        self.preferredMaxLayoutWidth = w;
        [self invalidateIntrinsicContentSize];
    }
}
@end

// A plain view with a 1pt line along its bottom edge.
@interface SXLineView : NSView
@property (assign) BOOL strongLine;   // lineStrong instead of line
@end

@implementation SXLineView
-(BOOL)isFlipped { return YES; }
-(void)drawRect:(NSRect)dirtyRect {
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        [(self.strongLine ? [SXTokens lineStrong] : [SXTokens line]) setFill];
        NSRectFill(NSMakeRect(0.0, NSMaxY(self.bounds) - 1.0, NSWidth(self.bounds), 1.0));
    }];
}
@end

// Flipped document view so content starts at the top of the scroll view.
@interface SXFlippedView : NSView
@end

@implementation SXFlippedView
-(BOOL)isFlipped { return YES; }
@end

// The left column: ground fill and a 1pt line on the right edge.
@interface SXSettingsNav : NSView
@end

@implementation SXSettingsNav
-(BOOL)isFlipped { return YES; }
-(void)drawRect:(NSRect)dirtyRect {
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        [[SXTokens ground] setFill];
        NSRectFill(self.bounds);
        [[SXTokens line] setFill];
        NSRectFill(NSMakeRect(NSMaxX(self.bounds) - 1.0, 0.0, 1.0, NSHeight(self.bounds)));
    }];
}
@end

// One nav entry; draws its own hover and selected state.
@interface SXSettingsNavItem : NSView
@property (copy) NSString *title;
@property (assign, nonatomic) BOOL selected;
@property (assign) BOOL hovered;
@property (copy, nullable) void (^onClick)(void);
@end

@implementation SXSettingsNavItem

-(BOOL)isFlipped { return YES; }
-(BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }

-(NSSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoIntrinsicMetric, kNavItemHeight);
}

-(void)setSelected:(BOOL)selected {
    if (_selected == selected) return;
    _selected = selected;
    self.needsDisplay = YES;
}

-(void)updateTrackingAreas {
    [super updateTrackingAreas];
    for (NSTrackingArea *a in [self.trackingAreas copy]) [self removeTrackingArea:a];
    NSTrackingAreaOptions opts = NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect;
    [self addTrackingArea:[[NSTrackingArea alloc] initWithRect:self.bounds options:opts owner:self userInfo:nil]];
}

-(void)mouseEntered:(NSEvent *)event {
    self.hovered = YES;
    self.needsDisplay = YES;
}

-(void)mouseExited:(NSEvent *)event {
    self.hovered = NO;
    self.needsDisplay = YES;
}

-(void)mouseDown:(NSEvent *)event {
    if (self.onClick) self.onClick();
}

-(void)drawRect:(NSRect)dirtyRect {
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        if (self.selected || self.hovered) {
            [(self.selected ? [SXTokens accentSoft] : [SXTokens surfaceRaised]) setFill];
            [[NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:SXRadiusSM yRadius:SXRadiusSM] fill];
        }
        NSDictionary *attrs = @{
            NSFontAttributeName: self.selected ? [SXTokens bodyStrong] : [SXTokens body],
            NSForegroundColorAttributeName: [SXTokens ink],
        };
        NSSize size = [self.title sizeWithAttributes:attrs];
        CGFloat y = floor((NSHeight(self.bounds) - size.height) / 2.0);
        [self.title drawInRect:NSMakeRect(SXSpace2, y, NSWidth(self.bounds) - 2 * SXSpace2, size.height) withAttributes:attrs];
    }];
}

@end

// The accent badge.
@interface SXBadgeView : NSView
@end

@implementation SXBadgeView
-(void)drawRect:(NSRect)dirtyRect {
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        NSRect r = NSInsetRect(self.bounds, 0.5, 0.5);
        NSBezierPath *p = [NSBezierPath bezierPathWithRoundedRect:r xRadius:SXRadiusXS yRadius:SXRadiusXS];
        [[SXTokens accentSoft] setFill];
        [p fill];
        [[SXTokens accentInk] setStroke];
        p.lineWidth = 1.0;
        [p stroke];
    }];
}
@end

// MARK: Factory helpers

static SXWrapLabel *SXMakeWrapLabel(NSString *string, NSFont *font, NSColor *color) {
    SXWrapLabel *l = [[SXWrapLabel alloc] initWithFrame:NSZeroRect];
    l.translatesAutoresizingMaskIntoConstraints = NO;
    l.bezeled = NO;
    l.bordered = NO;
    l.drawsBackground = NO;
    l.editable = NO;
    l.selectable = YES;
    l.lineBreakMode = NSLineBreakByWordWrapping;
    l.maximumNumberOfLines = 0;
    l.usesSingleLineMode = NO;
    l.font = font;
    l.textColor = color;
    l.stringValue = string ?: @"";
    [l setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    [l setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    return l;
}

// Wraps content in a box with extra space above and below; the box takes the width it is given.
static NSView *SXPadded(NSView *content, CGFloat top, CGFloat bottom) {
    NSView *box = [[NSView alloc] initWithFrame:NSZeroRect];
    box.translatesAutoresizingMaskIntoConstraints = NO;
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [box addSubview:content];
    [NSLayoutConstraint activateConstraints:@[
        [content.leadingAnchor constraintEqualToAnchor:box.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:box.trailingAnchor],
        [content.topAnchor constraintEqualToAnchor:box.topAnchor constant:top],
        [content.bottomAnchor constraintEqualToAnchor:box.bottomAnchor constant:-bottom],
    ]];
    return box;
}

// Adds a view to a vertical stack and makes it as wide as the stack.
static void SXAddFullWidth(NSStackView *stack, NSView *view) {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [stack addArrangedSubview:view];
    [view.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
}

// MARK: SettingsPageView

@interface SettingsPageView ()
@property (strong) SXSettingsNav *navView;
@property (strong) NSStackView *navStack;
@property (strong) NSScrollView *scrollView;
@property (strong) SXFlippedView *docView;
@property (strong) NSStackView *column;
@property (strong, nullable) SXWrapLabel *titleLabel;
@property (strong) NSMutableDictionary<NSString *, NSStackView *> *sectionStacks;
@property (strong) NSMutableDictionary<NSString *, SXSettingsNavItem *> *navItems;
@property (strong) NSMutableArray<NSString *> *sectionOrder;
@end

@implementation SettingsPageView {
    NSString *_visibleSection;
}
@synthesize pageTitle = _pageTitle;

-(instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (!self) return nil;
    _pageTitle = @"";
    _visibleSection = @"";
    _sectionStacks = [NSMutableDictionary dictionary];
    _navItems = [NSMutableDictionary dictionary];
    _sectionOrder = [NSMutableArray array];
    [self buildNav];
    [self buildBody];
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)coder {
    return [self initWithFrame:NSZeroRect];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(BOOL)isFlipped { return YES; }

-(void)buildNav {
    _navView = [[SXSettingsNav alloc] initWithFrame:NSZeroRect];
    _navView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_navView];

    _navStack = [[NSStackView alloc] initWithFrame:NSZeroRect];
    _navStack.translatesAutoresizingMaskIntoConstraints = NO;
    _navStack.orientation = NSUserInterfaceLayoutOrientationVertical;
    _navStack.alignment = NSLayoutAttributeLeading;
    _navStack.spacing = 2.0;
    [_navView addSubview:_navStack];

    [NSLayoutConstraint activateConstraints:@[
        [_navView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_navView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_navView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [_navView.widthAnchor constraintEqualToConstant:kNavWidth],
        [_navStack.leadingAnchor constraintEqualToAnchor:_navView.leadingAnchor constant:SXSpace2],
        [_navStack.trailingAnchor constraintEqualToAnchor:_navView.trailingAnchor constant:-(SXSpace2 + 1.0)],
        [_navStack.topAnchor constraintEqualToAnchor:_navView.topAnchor constant:SXSpace4],
        [_navStack.bottomAnchor constraintLessThanOrEqualToAnchor:_navView.bottomAnchor constant:-SXSpace4],
    ]];
}

-(void)buildBody {
    _scrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.borderType = NSNoBorder;
    _scrollView.hasVerticalScroller = YES;
    _scrollView.hasHorizontalScroller = NO;
    _scrollView.autohidesScrollers = YES;
    _scrollView.drawsBackground = YES;
    _scrollView.backgroundColor = [SXTokens ground];
    [self addSubview:_scrollView];

    _docView = [[SXFlippedView alloc] initWithFrame:NSZeroRect];
    _docView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.documentView = _docView;

    NSClipView *clip = _scrollView.contentView;
    clip.postsBoundsChangedNotifications = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clipBoundsChanged:)
                                                 name:NSViewBoundsDidChangeNotification
                                               object:clip];

    _column = [[NSStackView alloc] initWithFrame:NSZeroRect];
    _column.translatesAutoresizingMaskIntoConstraints = NO;
    _column.orientation = NSUserInterfaceLayoutOrientationVertical;
    _column.alignment = NSLayoutAttributeLeading;
    _column.spacing = 0.0;
    [_docView addSubview:_column];

    NSLayoutConstraint *preferred = [_column.widthAnchor constraintEqualToConstant:kColumnMaxWidth];
    preferred.priority = NSLayoutPriorityDefaultHigh;

    [NSLayoutConstraint activateConstraints:@[
        [_scrollView.leadingAnchor constraintEqualToAnchor:_navView.trailingAnchor],
        [_scrollView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_scrollView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_scrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

        [_docView.leadingAnchor constraintEqualToAnchor:clip.leadingAnchor],
        [_docView.trailingAnchor constraintEqualToAnchor:clip.trailingAnchor],
        [_docView.topAnchor constraintEqualToAnchor:clip.topAnchor],

        [_column.leadingAnchor constraintEqualToAnchor:_docView.leadingAnchor constant:SXSpace6],
        [_column.topAnchor constraintEqualToAnchor:_docView.topAnchor constant:SXSpace5],
        [_column.bottomAnchor constraintEqualToAnchor:_docView.bottomAnchor constant:-SXSpace6],
        [_column.widthAnchor constraintLessThanOrEqualToConstant:kColumnMaxWidth],
        [_column.trailingAnchor constraintLessThanOrEqualToAnchor:_docView.trailingAnchor constant:-SXSpace6],
        preferred,
    ]];
}

// MARK: Title

-(NSString *)pageTitle { return _pageTitle; }

-(void)setPageTitle:(NSString *)pageTitle {
    _pageTitle = [pageTitle copy] ?: @"";
    if (_pageTitle.length == 0) {
        if (self.titleLabel) {
            [self.column removeArrangedSubview:self.titleLabel];
            [self.titleLabel removeFromSuperview];
            self.titleLabel = nil;
        }
        return;
    }
    if (self.titleLabel) {
        self.titleLabel.stringValue = _pageTitle;
        return;
    }
    SXWrapLabel *l = SXMakeWrapLabel(_pageTitle, [SXTokens titleLarge], [SXTokens ink]);
    self.titleLabel = l;
    [self.column insertArrangedSubview:l atIndex:0];
    [l.widthAnchor constraintEqualToAnchor:self.column.widthAnchor].active = YES;
    [self.column setCustomSpacing:SXSpace2 afterView:l];
}

-(NSString *)visibleSection { return _visibleSection ?: @""; }

// MARK: Sections

-(void)addSection:(NSString *)identifier title:(NSString *)title {
    if (identifier.length == 0 || self.sectionStacks[identifier] != nil) return;

    // Nav item.
    SXSettingsNavItem *item = [[SXSettingsNavItem alloc] initWithFrame:NSZeroRect];
    item.translatesAutoresizingMaskIntoConstraints = NO;
    item.title = title ?: @"";
    NSString *ident = [identifier copy];
    __weak SettingsPageView *weakSelf = self;
    item.onClick = ^{ [weakSelf scrollToSection:ident]; };
    SXAddFullWidth(self.navStack, item);
    self.navItems[ident] = item;

    // Heading with top margin, bottom padding and a strong rule.
    SXLineView *heading = [[SXLineView alloc] initWithFrame:NSZeroRect];
    heading.strongLine = YES;
    NSTextField *h = SXMakeWrapLabel(title, [SXTokens heading], [SXTokens ink]);
    h.selectable = NO;
    [heading addSubview:h];
    [NSLayoutConstraint activateConstraints:@[
        [h.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [h.trailingAnchor constraintEqualToAnchor:heading.trailingAnchor],
        [h.topAnchor constraintEqualToAnchor:heading.topAnchor constant:SXSpace5],
        [h.bottomAnchor constraintEqualToAnchor:heading.bottomAnchor constant:-(SXSpace2 + 1.0)],
    ]];

    NSStackView *section = [[NSStackView alloc] initWithFrame:NSZeroRect];
    section.translatesAutoresizingMaskIntoConstraints = NO;
    section.orientation = NSUserInterfaceLayoutOrientationVertical;
    section.alignment = NSLayoutAttributeLeading;
    section.spacing = 0.0;
    SXAddFullWidth(section, heading);

    SXAddFullWidth(self.column, section);
    self.sectionStacks[ident] = section;
    [self.sectionOrder addObject:ident];

    if (_visibleSection.length == 0) [self selectNavForSection:ident];
}

-(void)addRowInSection:(NSString *)identifier title:(NSString *)title text:(NSString *)text control:(NSView *)control {
    NSStackView *section = self.sectionStacks[identifier];
    if (!section) return;

    SXLineView *row = [[SXLineView alloc] initWithFrame:NSZeroRect];

    NSStackView *textStack = [[NSStackView alloc] initWithFrame:NSZeroRect];
    textStack.translatesAutoresizingMaskIntoConstraints = NO;
    textStack.orientation = NSUserInterfaceLayoutOrientationVertical;
    textStack.alignment = NSLayoutAttributeLeading;
    textStack.spacing = 2.0;
    if (title.length > 0) {
        SXAddFullWidth(textStack, SXMakeWrapLabel(title, [SXTokens bodyStrong], [SXTokens ink]));
    }
    if (text.length > 0) {
        SXAddFullWidth(textStack, SXMakeWrapLabel(text, [SXTokens caption], [SXTokens inkMuted]));
    }
    [row addSubview:textStack];

    NSLayoutConstraint *minHeight = [row.heightAnchor constraintGreaterThanOrEqualToConstant:kRowMinHeight];
    NSLayoutConstraint *shrink = [row.heightAnchor constraintEqualToConstant:0.0];
    shrink.priority = NSLayoutPriorityDefaultLow;
    [NSLayoutConstraint activateConstraints:@[
        minHeight,
        shrink,
        [textStack.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],
        [textStack.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [textStack.topAnchor constraintGreaterThanOrEqualToAnchor:row.topAnchor constant:SXSpace2],
        [textStack.bottomAnchor constraintLessThanOrEqualToAnchor:row.bottomAnchor constant:-(SXSpace2 + 1.0)],
    ]];

    if (control) {
        control.translatesAutoresizingMaskIntoConstraints = NO;
        [control setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
        [control setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
        [row addSubview:control];
        [NSLayoutConstraint activateConstraints:@[
            [control.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],
            [control.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
            [control.topAnchor constraintGreaterThanOrEqualToAnchor:row.topAnchor constant:SXSpace2],
            [control.bottomAnchor constraintLessThanOrEqualToAnchor:row.bottomAnchor constant:-(SXSpace2 + 1.0)],
            [textStack.trailingAnchor constraintEqualToAnchor:control.leadingAnchor constant:-SXSpace4],
        ]];
    } else {
        [textStack.trailingAnchor constraintEqualToAnchor:row.trailingAnchor].active = YES;
    }

    SXAddFullWidth(section, row);
}

-(void)addSubheading:(NSString *)text inSection:(NSString *)identifier {
    NSStackView *section = self.sectionStacks[identifier];
    if (!section) return;
    SXWrapLabel *l = SXMakeWrapLabel(text, [SXTokens heading], [SXTokens ink]);
    SXAddFullWidth(section, SXPadded(l, SXSpace4, SXSpace1));
}

-(void)addProse:(NSString *)text inSection:(NSString *)identifier {
    NSStackView *section = self.sectionStacks[identifier];
    if (!section) return;
    SXWrapLabel *l = SXMakeWrapLabel(text, [SXTokens body], [SXTokens ink]);
    SXAddFullWidth(section, SXPadded(l, SXSpace2, SXSpace2));
}

-(void)addBullets:(NSArray<NSString *> *)items inSection:(NSString *)identifier {
    NSStackView *section = self.sectionStacks[identifier];
    if (!section) return;
    for (NSString *item in items) {
        NSTextField *dot = [NSTextField labelWithString:@"•"];
        dot.translatesAutoresizingMaskIntoConstraints = NO;
        dot.font = [SXTokens body];
        dot.textColor = [SXTokens ink];
        [dot setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
        [dot setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
        [dot.widthAnchor constraintEqualToConstant:SXSpace3].active = YES;

        SXWrapLabel *l = SXMakeWrapLabel(item, [SXTokens body], [SXTokens ink]);

        NSStackView *h = [[NSStackView alloc] initWithFrame:NSZeroRect];
        h.translatesAutoresizingMaskIntoConstraints = NO;
        h.orientation = NSUserInterfaceLayoutOrientationHorizontal;
        h.alignment = NSLayoutAttributeTop;
        h.spacing = SXSpace1;
        [h addArrangedSubview:dot];
        [h addArrangedSubview:l];

        SXAddFullWidth(section, SXPadded(h, 0.0, SXSpace1));
    }
}

-(void)addView:(NSView *)view inSection:(NSString *)identifier {
    NSStackView *section = self.sectionStacks[identifier];
    if (!section || !view) return;
    SXAddFullWidth(section, view);
}

-(void)removeContentOfSection:(NSString *)identifier {
    NSStackView *section = self.sectionStacks[identifier];
    if (!section) return;
    NSArray<NSView *> *views = [section.arrangedSubviews copy];
    for (NSUInteger i = 1; i < views.count; i++) {
        NSView *v = views[i];
        [section removeArrangedSubview:v];
        [v removeFromSuperview];
    }
}

// MARK: Scrolling and nav state

// Document y of the section heading text, the point that lines up with the top of the visible area.
-(CGFloat)topOfSection:(NSString *)identifier {
    NSStackView *section = self.sectionStacks[identifier];
    if (!section) return 0.0;
    NSRect r = [section convertRect:section.bounds toView:self.docView];
    return NSMinY(r) + SXSpace5;
}

-(void)selectNavForSection:(NSString *)identifier {
    _visibleSection = [identifier copy] ?: @"";
    [self.navItems enumerateKeysAndObjectsUsingBlock:^(NSString *key, SXSettingsNavItem *item, BOOL *stop) {
        item.selected = [key isEqualToString:identifier];
    }];
}

-(void)scrollToSection:(NSString *)identifier {
    if (self.sectionStacks[identifier] == nil) return;
    [self layoutSubtreeIfNeeded];
    NSClipView *clip = self.scrollView.contentView;
    CGFloat maxY = MAX(0.0, NSHeight(self.docView.frame) - NSHeight(clip.bounds));
    CGFloat y = MIN(MAX([self topOfSection:identifier], 0.0), maxY);
    [clip scrollToPoint:NSMakePoint(NSMinX(clip.bounds), y)];
    [self.scrollView reflectScrolledClipView:clip];
    [self selectNavForSection:identifier];
}

-(void)clipBoundsChanged:(NSNotification *)note {
    if (self.sectionOrder.count == 0) return;
    CGFloat top = NSMinY(self.scrollView.contentView.bounds) + kVisibleSlack;
    NSString *found = self.sectionOrder.firstObject;
    for (NSString *ident in self.sectionOrder) {
        if ([self topOfSection:ident] <= top) found = ident;
    }
    if (![found isEqualToString:_visibleSection]) [self selectNavForSection:found];
}

// MARK: Badge

+(NSView *)badgeWithText:(NSString *)text {
    SXBadgeView *badge = [[SXBadgeView alloc] initWithFrame:NSZeroRect];
    badge.translatesAutoresizingMaskIntoConstraints = NO;
    NSTextField *l = [NSTextField labelWithString:text ?: @""];
    l.translatesAutoresizingMaskIntoConstraints = NO;
    l.font = [SXTokens label];
    l.textColor = [SXTokens ink];
    [badge addSubview:l];
    [NSLayoutConstraint activateConstraints:@[
        [badge.heightAnchor constraintEqualToConstant:20.0],
        [l.leadingAnchor constraintEqualToAnchor:badge.leadingAnchor constant:6.0],
        [l.trailingAnchor constraintEqualToAnchor:badge.trailingAnchor constant:-6.0],
        [l.centerYAnchor constraintEqualToAnchor:badge.centerYAnchor],
    ]];
    return badge;
}

@end
