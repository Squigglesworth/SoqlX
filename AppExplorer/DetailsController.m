// Copyright (c) 2007-2015 Simon Fell
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

#import "DetailsController.h"
#import "NSWindow_additions.h"
#import "NSTableView_additions.h"
#import "DataSources.h"
#import "Shell/ShellView.h"
#import "DesignTokens.h"
#import <objc/runtime.h>

static NSString *SHOWING_DETAILS = @"details";

static const void *kBaseFontKey = &kBaseFontKey;

@implementation DetailsController

+(NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *paths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"title"])
        return [paths setByAddingObject:@"dataSource"];
    return paths;
}


-(NSString *)windowVisiblePrefName {
    return SHOWING_DETAILS;
}

-(NSString *)title {
    if ([self dataSource] == nil) return @"Details";
    return [self dataSource].description;
}

-(DetailDataSource *)dataSource {
    return detailsTable.dataSource;
}

-(void)setDataSource:(DetailDataSource *)aValue {
    dataSourceRef = aValue;
    detailsTable.dataSource = aValue;
    aValue.onChange = ^void(DetailDataSource*ds) {
        [self->detailsTable reloadData];
    };
    self.inspectorHost.inspectorTitle.stringValue = self.title ?: @"";
}

- (void)setIcon:(NSImage *)image {
    if (self.inspectorHost != nil) {
        // docked in the main window, which has no document icon.
        return;
    }
    detailsTable.window.representedURL = [NSURL fileURLWithPath:self.title];
    [detailsTable.window standardWindowButton:NSWindowDocumentIconButton].image = image;
}

- (void)dockInInspector:(ShellView *)shell {
    NSScrollView *sv = detailsTable.enclosingScrollView;
    if (sv == nil || shell == nil) {
        return;
    }
    [sv removeFromSuperview];
    sv.translatesAutoresizingMaskIntoConstraints = NO;
    sv.borderType = NSNoBorder;
    NSView *container = shell.inspectorContainer;
    [container addSubview:sv];
    [NSLayoutConstraint activateConstraints:@[
        [sv.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [sv.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [sv.topAnchor constraintEqualToAnchor:container.topAnchor],
        [sv.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
    ]];
    self.inspectorHost = shell;
    shell.inspectorTitle.stringValue = self.title ?: @"";
    [shell setInspectorVisible:self.windowVisible animated:NO];
}

-(void)setWindowVisible:(BOOL)windowVisible updateWindow:(BOOL)updateWindow {
    if (self.inspectorHost == nil) {
        [super setWindowVisible:windowVisible updateWindow:updateWindow];
        return;
    }
    [super setWindowVisible:windowVisible updateWindow:NO];
    if (updateWindow) {
        [self.inspectorHost setInspectorVisible:windowVisible animated:YES];
    }
}

- (IBAction) copy:(id)sender {
    [detailsTable zkCopyTableDataToClipboard];
}

- (void)applyTextScale {
    if (detailsTable == nil) return;
    // The nib's sizes are the 1.0 scale; remember them the first time through.
    NSNumber *baseRow = objc_getAssociatedObject(detailsTable, kBaseFontKey);
    if (baseRow == nil) {
        baseRow = @(detailsTable.rowHeight);
        objc_setAssociatedObject(detailsTable, kBaseFontKey, baseRow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        for (NSTableColumn *c in detailsTable.tableColumns) {
            NSCell *cell = c.dataCell;
            if (cell.font != nil) objc_setAssociatedObject(c, kBaseFontKey, cell.font, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    CGFloat scale = [SXTokens textScale];
    for (NSTableColumn *c in detailsTable.tableColumns) {
        NSFont *base = objc_getAssociatedObject(c, kBaseFontKey);
        if (base != nil) ((NSCell *)c.dataCell).font = [SXTokens scaled:base];
    }
    detailsTable.rowHeight = ceil(baseRow.doubleValue * MAX(1.0, scale));
    [detailsTable reloadData];
}

@end
