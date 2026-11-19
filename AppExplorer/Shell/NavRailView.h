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

// The 64pt navigation rail: a column of icon + label items, some pinned to the bottom.
@interface NavRailView : NSView

// Adds an item; image should be a template image (may be nil).
-(void)addItemWithTitle:(NSString *)title image:(nullable NSImage *)image tag:(NSInteger)tag pinToBottom:(BOOL)bottom;

// The highlighted item. Setting it redraws but does not send the action.
@property (assign, nonatomic) NSInteger selectedTag;

// Sent on a click inside an item, with the rail as sender (selectedTag is already updated).
@property (weak, nullable) id target;
@property (assign, nullable) SEL action;

@end

NS_ASSUME_NONNULL_END
