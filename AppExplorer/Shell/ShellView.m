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
static const CGFloat kProductNameLeading = 78.0;   // clears the traffic lights

// Title bar background: ground fill with a 1pt line along the bottom edge.
@interface ShellTitleBarView : NSView
@end

@implementation ShellTitleBarView
-(void)drawRect:(NSRect)dirtyRect {
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        [[SXTokens ground] setFill];
        NSRectFill(self.bounds);
        [[SXTokens line] setFill];
        NSRectFill(NSMakeRect(0, 0, NSWidth(self.bounds), 1.0));
    }];
}
@end

// Inspector column background: surface fill with a 1pt line along the leading (left) edge.
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
@property (strong) NavRailView *rail;
@property (strong) OrgChipView *orgChip;
@property (strong) NSButton *recentToggle;
@property (strong) NSButton *detailsToggle;
@property (strong) NSView *inspectorContainer;
@property (strong) NSTextField *inspectorTitle;
@property (strong) NSLayoutConstraint *inspectorWidthConstraint;
@end

@implementation ShellView {
    BOOL _inspectorVisible;
}

-(NSButton *)titleButtonWithTitle:(NSString *)title imageName:(NSString *)imageName {
    NSButton *b = [NSButton buttonWithTitle:title target:nil action:nil];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.bordered = NO;
    b.font = [SXTokens body];
    b.imagePosition = NSImageLeading;
    b.contentTintColor = [SXTokens inkMuted];
    [b setButtonType:NSButtonTypePushOnPushOff];
    NSImage *img = [NSImage imageNamed:imageName];
    if (img) {
        img.template = YES;
        b.image = img;
    } else {
        b.imagePosition = NSNoImage;
    }
    return b;
}

-(instancetype)initWithContentView:(NSView *)content {
    self = [super initWithFrame:NSMakeRect(0, 0, 1000, 700)];
    if (!self) return nil;
    // This view becomes the window's content view, so the window sizes it; it must keep
    // translating its autoresizing mask (the subviews below are constraint-based).
    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    // Title bar.
    ShellTitleBarView *titleBar = [[ShellTitleBarView alloc] initWithFrame:NSZeroRect];
    titleBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:titleBar];

    NSTextField *product = [NSTextField labelWithString:@"SoqlX Rebooted"];
    product.translatesAutoresizingMaskIntoConstraints = NO;
    product.font = [SXTokens bodyStrong];
    product.textColor = [SXTokens ink];
    [titleBar addSubview:product];

    _recentToggle = [self titleButtonWithTitle:@"Recent" imageName:@"icon.history"];
    _detailsToggle = [self titleButtonWithTitle:@"Details" imageName:@"icon.panel-right"];
    [titleBar addSubview:_recentToggle];
    [titleBar addSubview:_detailsToggle];

    _orgChip = [[OrgChipView alloc] initWithFrame:NSZeroRect];
    [titleBar addSubview:_orgChip];

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

    // Constraints.
    _inspectorWidthConstraint = [column.widthAnchor constraintEqualToConstant:0];

    [NSLayoutConstraint activateConstraints:@[
        // Title bar across the top.
        [titleBar.topAnchor constraintEqualToAnchor:self.topAnchor],
        [titleBar.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [titleBar.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [titleBar.heightAnchor constraintEqualToConstant:SXTitlebarHeight],

        [product.leadingAnchor constraintEqualToAnchor:titleBar.leadingAnchor constant:kProductNameLeading],
        [product.centerYAnchor constraintEqualToAnchor:titleBar.centerYAnchor],
        [_recentToggle.leadingAnchor constraintEqualToAnchor:product.trailingAnchor constant:SXSpace5],
        [_recentToggle.centerYAnchor constraintEqualToAnchor:titleBar.centerYAnchor],
        [_detailsToggle.leadingAnchor constraintEqualToAnchor:_recentToggle.trailingAnchor constant:SXSpace2],
        [_detailsToggle.centerYAnchor constraintEqualToAnchor:titleBar.centerYAnchor],
        [_orgChip.trailingAnchor constraintEqualToAnchor:titleBar.trailingAnchor constant:-SXSpace3],
        [_orgChip.centerYAnchor constraintEqualToAnchor:titleBar.centerYAnchor],
        [_orgChip.heightAnchor constraintEqualToConstant:SXControlSM],
        [_orgChip.leadingAnchor constraintGreaterThanOrEqualToAnchor:_detailsToggle.trailingAnchor constant:SXSpace3],

        // Rail.
        [_rail.topAnchor constraintEqualToAnchor:titleBar.bottomAnchor],
        [_rail.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [_rail.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_rail.widthAnchor constraintEqualToConstant:kRailWidth],

        // Content fills the middle.
        [content.topAnchor constraintEqualToAnchor:titleBar.bottomAnchor],
        [content.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [content.leadingAnchor constraintEqualToAnchor:_rail.trailingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:column.leadingAnchor],

        // Inspector column.
        [column.topAnchor constraintEqualToAnchor:titleBar.bottomAnchor],
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

// MARK: Inspector

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

// MARK: Drawing

-(void)drawRect:(NSRect)dirtyRect {
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        [[SXTokens ground] setFill];
        NSRectFill(self.bounds);
    }];
}

@end
