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

#import "ShellView.h"
#import "DesignTokens.h"

static const CGFloat kRailWidth = 64.0;
static const CGFloat kInspectorHeaderHeight = 28.0;
static const CGFloat kStatusBarHeight = 28.0;   // matches the nib's bottom status strip

// The inspector column: surface fill with a hairline on its left edge.
@interface ShellInspectorColumnView : NSView
@end

@implementation ShellInspectorColumnView
-(void)drawRect:(NSRect)dirtyRect {
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        [[SXTokens surface] setFill];
        NSRectFill(self.bounds);
        [[SXTokens line] setFill];
        NSRectFill(NSMakeRect(0, 0, 1.0, NSHeight(self.bounds)));
    }];
}
@end

@interface ShellView ()
@property (strong) NSTextField *productLabel;
@property (strong) NSButton *recentToggle;
@property (strong) NSButton *detailsToggle;
@property (strong) OrgChipView *orgChip;
@property (strong) NavRailView *rail;
@property (strong) NSView *inspectorContainer;
@property (strong) NSTextField *inspectorTitle;
@property (strong) NSLayoutConstraint *inspectorWidthConstraint;
@end

@implementation ShellView {
    BOOL _inspectorVisible;
    NSView *_workContent;
    NSView *_inspectorColumn;
}

-(NSButton *)toolbarButtonWithTitle:(NSString *)title imageName:(NSString *)imageName {
    NSButton *b = [NSButton buttonWithTitle:title target:nil action:nil];
    [b setButtonType:NSButtonTypeMomentaryChange];
    b.bordered = NO;
    b.font = [SXTokens body];
    b.imagePosition = NSImageLeading;
    b.contentTintColor = [SXTokens inkMuted];
    NSImage *img = [NSImage imageNamed:imageName];
    if (img != nil) {
        img.template = YES;
        b.image = img;
    } else {
        b.imagePosition = NSNoImage;
    }
    [b sizeToFit];
    return b;
}

-(instancetype)initWithContentView:(NSView *)content {
    self = [super initWithFrame:NSMakeRect(0, 0, 1000, 700)];
    if (!self) return nil;
    // This view becomes the window's content view, so the window sizes it; it must keep
    // translating its autoresizing mask (the subviews below are constraint-based).
    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    // Toolbar views. They are owned here but hosted by the window's NSToolbar.
    _productLabel = [NSTextField labelWithString:@"SoqlX Rebooted"];
    _productLabel.font = [SXTokens bodyStrong];
    _productLabel.textColor = [SXTokens ink];
    [_productLabel sizeToFit];
    _recentToggle = [self toolbarButtonWithTitle:@"Recent" imageName:@"icon.history"];
    _detailsToggle = [self toolbarButtonWithTitle:@"Details" imageName:@"icon.panel-right"];
    _orgChip = [[OrgChipView alloc] initWithFrame:NSMakeRect(0, 0, 120, SXControlSM)];
    _orgChip.translatesAutoresizingMaskIntoConstraints = YES;   // sized by the toolbar from intrinsicContentSize

    // Rail.
    _rail = [[NavRailView alloc] initWithFrame:NSZeroRect];
    [self addSubview:_rail];

    // Content (re-parented).
    [content removeFromSuperview];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:content];

    // Inspector column: clips its fixed-width inner view, so width 0 hides everything.
    ShellInspectorColumnView *column = [[ShellInspectorColumnView alloc] initWithFrame:NSZeroRect];
    column.translatesAutoresizingMaskIntoConstraints = NO;
    column.clipsToBounds = YES;
    [self addSubview:column];
    _workContent = content;
    _inspectorColumn = column;

    NSView *inner = [[NSView alloc] initWithFrame:NSZeroRect];
    inner.translatesAutoresizingMaskIntoConstraints = NO;
    [column addSubview:inner];

    NSView *header = [[NSView alloc] initWithFrame:NSZeroRect];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [inner addSubview:header];

    _inspectorTitle = [NSTextField labelWithString:@""];
    _inspectorTitle.translatesAutoresizingMaskIntoConstraints = NO;
    _inspectorTitle.font = [SXTokens heading];
    _inspectorTitle.textColor = [SXTokens ink];
    _inspectorTitle.lineBreakMode = NSLineBreakByTruncatingTail;
    [_inspectorTitle setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    [header addSubview:_inspectorTitle];

    _inspectorContainer = [[NSView alloc] initWithFrame:NSZeroRect];
    _inspectorContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [inner addSubview:_inspectorContainer];

    _inspectorWidthConstraint = [column.widthAnchor constraintEqualToConstant:0];

    [NSLayoutConstraint activateConstraints:@[
        // Rail down the left edge.
        [_rail.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_rail.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [_rail.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_rail.widthAnchor constraintEqualToConstant:kRailWidth],

        // Content fills the middle.
        [content.topAnchor constraintEqualToAnchor:self.topAnchor],
        [content.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [content.leadingAnchor constraintEqualToAnchor:_rail.trailingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:column.leadingAnchor],

        // Inspector column on the right.
        [column.topAnchor constraintEqualToAnchor:self.topAnchor],
        [column.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [column.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        _inspectorWidthConstraint,

        [inner.topAnchor constraintEqualToAnchor:column.topAnchor],
        [inner.bottomAnchor constraintEqualToAnchor:column.bottomAnchor],
        [inner.trailingAnchor constraintEqualToAnchor:column.trailingAnchor],
        [inner.widthAnchor constraintEqualToConstant:SXInspectorWidth],

        [header.topAnchor constraintEqualToAnchor:inner.topAnchor],
        [header.leadingAnchor constraintEqualToAnchor:inner.leadingAnchor],
        [header.trailingAnchor constraintEqualToAnchor:inner.trailingAnchor],
        [header.heightAnchor constraintEqualToConstant:kInspectorHeaderHeight],

        [_inspectorTitle.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:SXSpace3],
        [_inspectorTitle.trailingAnchor constraintLessThanOrEqualToAnchor:header.trailingAnchor constant:-SXSpace3],
        [_inspectorTitle.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],

        [_inspectorContainer.topAnchor constraintEqualToAnchor:header.bottomAnchor],
        [_inspectorContainer.leadingAnchor constraintEqualToAnchor:inner.leadingAnchor],
        [_inspectorContainer.trailingAnchor constraintEqualToAnchor:inner.trailingAnchor],
        [_inspectorContainer.bottomAnchor constraintEqualToAnchor:inner.bottomAnchor],
    ]];

    return self;
}

-(BOOL)inspectorVisible { return _inspectorVisible; }

-(void)setInspectorVisible:(BOOL)visible {
    [self setInspectorVisible:visible animated:NO];
}

-(void)setInspectorVisible:(BOOL)visible animated:(BOOL)animated {
    _inspectorVisible = visible;
    CGFloat width = visible ? SXInspectorWidth : 0.0;
    if (!animated || self.window == nil) {
        self.inspectorWidthConstraint.constant = width;
        return;
    }
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.2;
        context.allowsImplicitAnimation = YES;
        [self.inspectorWidthConstraint.animator setConstant:width];
        [self layoutSubtreeIfNeeded];
    } completionHandler:nil];
}

-(void)setPageView:(NSView *)pageView {
    if (_pageView == pageView) return;
    [_pageView removeFromSuperview];
    _pageView = pageView;
    BOOL showing = pageView != nil;
    _workContent.hidden = showing;
    _inspectorColumn.hidden = showing;
    if (!showing) return;
    pageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:pageView positioned:NSWindowAbove relativeTo:_inspectorColumn];
    [NSLayoutConstraint activateConstraints:@[
        [pageView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [pageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [pageView.leadingAnchor constraintEqualToAnchor:self.rail.trailingAnchor],
        [pageView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
    ]];
}

-(void)drawRect:(NSRect)dirtyRect {
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        [[SXTokens ground] setFill];
        NSRectFill(self.bounds);
        // Status band along the bottom, under the nib's status text and API meter.
        [[SXTokens surfaceSunken] setFill];
        NSRectFill(NSMakeRect(0, 0, NSWidth(self.bounds), kStatusBarHeight));
        [[SXTokens line] setFill];
        NSRectFill(NSMakeRect(0, kStatusBarHeight, NSWidth(self.bounds), 1.0));
    }];
}

@end
