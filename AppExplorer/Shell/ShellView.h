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
#import "NavRailView.h"
#import "OrgChipView.h"

NS_ASSUME_NONNULL_BEGIN

// The design system's window layout, built around the nib's existing content view:
//
//   [ rail | content (sidebar + work area) | inspector ]
//
// The title bar row (product name, Recent/Details toggles, OrgChip) is NOT part of this view:
// those controls are created here and handed to the window's unified NSToolbar by the
// Explorer, so that window tabs and sheets sit below them the way macOS expects.
@interface ShellView : NSView

-(instancetype)initWithContentView:(NSView *)content;   // re-parents content; sets up Auto Layout

// Views for the window toolbar (not subviews of the shell).
@property (readonly, strong) NSTextField *productLabel;  // "SoqlX Rebooted"
@property (readonly, strong) NSButton *recentToggle;     // template "history" icon + "Recent"
@property (readonly, strong) NSButton *detailsToggle;    // template "panel-right" icon + "Details"
@property (readonly, strong) OrgChipView *orgChip;

@property (readonly, strong) NavRailView *rail;
@property (readonly, strong) NSView *inspectorContainer; // fill this with the inspector content
@property (readonly, strong) NSTextField *inspectorTitle;
@property (assign, nonatomic) BOOL inspectorVisible;
-(void)setInspectorVisible:(BOOL)visible animated:(BOOL)animated;

// A full page (Settings) that covers everything right of the rail. nil shows the work area again.
@property (strong, nonatomic, nullable) NSView *pageView;

@end

NS_ASSUME_NONNULL_END
