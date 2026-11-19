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

#import "ConfirmDeleteDialog.h"
#import "DesignTokens.h"
#import <objc/runtime.h>

static const void *kDelegateKey = &kDelegateKey;

// Enables the alert's destructive button while the typed text matches the phrase.
@interface ConfirmDeleteFieldDelegate : NSObject <NSTextFieldDelegate>
@property (assign) NSUInteger count;
@property (weak) NSButton *button;
@end

@implementation ConfirmDeleteFieldDelegate
-(void)controlTextDidChange:(NSNotification *)obj {
    NSTextField *field = obj.object;
    if (![field isKindOfClass:[NSTextField class]]) return;
    self.button.enabled = [ConfirmDeleteDialog typed:field.stringValue matchesPhraseForCount:self.count];
}
@end

@implementation ConfirmDeleteDialog

+(NSString *)phraseForCount:(NSUInteger)count {
    return [NSString stringWithFormat:@"DELETE %lu", (unsigned long)count];
}

+(BOOL)typed:(NSString *)typed matchesPhraseForCount:(NSUInteger)count {
    if (typed == nil) return NO;
    NSString *t = [typed stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [t caseInsensitiveCompare:[self phraseForCount:count]] == NSOrderedSame;
}

+(NSString *)titleForCount:(NSUInteger)count objectName:(NSString *)name {
    return [NSString stringWithFormat:@"Delete %lu %@ %@?", (unsigned long)count, name ?: @"",
            count == 1 ? @"record" : @"records"];
}

// Production always asks, and so does a Trial org (the plan's test table requires Trial 1 -> YES);
// Sandbox and Developer orgs only ask for more than one record.
+(BOOL)needsConfirmationForCount:(NSUInteger)count kind:(SXOrgKind)kind {
    if (kind == SXOrgKindProduction || kind == SXOrgKindTrial) return YES;
    return count > 1;
}

+(void)confirmDeleteOf:(NSUInteger)count objectName:(NSString *)name kind:(SXOrgKind)kind
                window:(NSWindow *)window completion:(void (^)(BOOL))completion {
    if (![self needsConfirmationForCount:count kind:kind]) {
        completion(YES);
        return;
    }

    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleWarning;
    alert.messageText = [self titleForCount:count objectName:name];
    alert.informativeText = @"They go to the Recycle Bin and can be restored for 15 days.";
    NSString *deleteTitle = count == 1 ? @"Delete 1 record"
                                       : [NSString stringWithFormat:@"Delete %lu records", (unsigned long)count];
    NSButton *deleteButton = [alert addButtonWithTitle:deleteTitle];
    deleteButton.hasDestructiveAction = YES;
    NSButton *cancelButton = [alert addButtonWithTitle:@"Cancel"];
    cancelButton.keyEquivalent = @"\x1b";

    ConfirmDeleteFieldDelegate *fieldDelegate = nil;
    NSTextField *field = nil;
    if (kind == SXOrgKindProduction) {
        field = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 240, 24)];
        field.font = [SXTokens data];
        field.placeholderString = [NSString stringWithFormat:@"Type %@ to confirm", [self phraseForCount:count]];
        fieldDelegate = [[ConfirmDeleteFieldDelegate alloc] init];
        fieldDelegate.count = count;
        fieldDelegate.button = deleteButton;
        field.delegate = fieldDelegate;
        alert.accessoryView = field;
        deleteButton.enabled = NO;
        // Keep the delegate alive as long as the alert (and so the sheet) lives.
        objc_setAssociatedObject(alert, kDelegateKey, fieldDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [alert layout];
        alert.window.initialFirstResponder = field;
    }

    [alert beginSheetModalForWindow:window completionHandler:^(NSModalResponse returnCode) {
        // Referencing the delegate here also keeps it retained until the sheet ends.
        (void)fieldDelegate;
        completion(returnCode == NSAlertFirstButtonReturn);
    }];
}

@end
