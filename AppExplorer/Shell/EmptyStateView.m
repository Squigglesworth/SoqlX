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

#import "EmptyStateView.h"
#import "DesignTokens.h"
#import "SXControls.h"

@interface EmptyStateView ()
@property (strong) NSTextField *eyebrowLabel;
@property (strong) NSTextField *titleLabel;
@property (strong) NSTextField *bodyLabel;
@property (strong, nullable) NSButton *actionButton;
@property (strong) NSStackView *stack;
@end

@implementation EmptyStateView
@synthesize eyebrow = _eyebrow;

-(instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (!self) return nil;

    _eyebrowLabel = [SXControls labelWithString:@"" font:[SXTokens label] color:[SXTokens inkMuted]];
    _titleLabel = [SXControls labelWithString:@"" font:[SXTokens title] color:[SXTokens ink]];
    _bodyLabel = [SXControls labelWithString:@"" font:[SXTokens body] color:[SXTokens inkMuted]];
    _bodyLabel.maximumNumberOfLines = 0;
    _bodyLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _titleLabel.maximumNumberOfLines = 0;
    _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    for (NSTextField *l in @[_eyebrowLabel, _titleLabel, _bodyLabel]) {
        l.alignment = NSTextAlignmentLeft;
        l.hidden = YES;
    }

    _stack = [NSStackView stackViewWithViews:@[_eyebrowLabel, _titleLabel, _bodyLabel]];
    _stack.translatesAutoresizingMaskIntoConstraints = NO;
    _stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    _stack.alignment = NSLayoutAttributeLeading;
    _stack.spacing = SXSpace2;
    _stack.detachesHiddenViews = YES;
    [self addSubview:_stack];

    [NSLayoutConstraint activateConstraints:@[
        [_stack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:SXSpace6],
        [_stack.topAnchor constraintEqualToAnchor:self.topAnchor constant:SXSpace6],
        [_stack.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-SXSpace6],
        [_stack.bottomAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor constant:-SXSpace6],
    ]];
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)coder {
    return [self initWithFrame:NSZeroRect];
}

-(BOOL)isFlipped { return YES; }

-(void)drawRect:(NSRect)dirtyRect {
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        [[SXTokens surface] setFill];
        NSRectFill(self.bounds);
    }];
}

-(void)layout {
    CGFloat w = NSWidth(self.bounds) - 2 * SXSpace6;
    if (w < 1.0) w = 1.0;
    self.bodyLabel.preferredMaxLayoutWidth = w;
    self.titleLabel.preferredMaxLayoutWidth = w;
    [super layout];
}

-(void)applyText:(NSString *)text toLabel:(NSTextField *)label {
    NSString *s = text ?: @"";
    label.stringValue = s;
    label.hidden = (s.length == 0);
    [self setNeedsLayout:YES];
}

-(NSString *)eyebrow { return _eyebrow; }
-(void)setEyebrow:(NSString *)eyebrow {
    _eyebrow = [eyebrow copy];
    NSString *s = _eyebrow ?: @"";
    NSMutableAttributedString *a = [[NSMutableAttributedString alloc]
        initWithString:s.uppercaseString attributes:[SXTokens labelAttributes]];
    self.eyebrowLabel.attributedStringValue = a;
    self.eyebrowLabel.hidden = (s.length == 0);
    [self setNeedsLayout:YES];
}

-(void)setTitle:(NSString *)title {
    _title = [title copy];
    [self applyText:_title toLabel:self.titleLabel];
}

-(void)setBody:(NSString *)body {
    _body = [body copy];
    [self applyText:_body toLabel:self.bodyLabel];
}

-(void)setActionTitle:(NSString *)title target:(id)target action:(SEL)action {
    if (self.actionButton != nil) {
        [self.stack removeView:self.actionButton];
        [self.actionButton removeFromSuperview];
        self.actionButton = nil;
    }
    if (title.length > 0) {
        NSButton *b = [SXControls defaultButtonWithTitle:title target:target action:action];
        self.actionButton = b;
        [self.stack addArrangedSubview:b];
        [self.stack setCustomSpacing:SXSpace4 afterView:self.bodyLabel];
    }
    [self setNeedsLayout:YES];
}

@end
