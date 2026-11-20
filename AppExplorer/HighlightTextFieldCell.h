#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, SidebarRowStyle) {
    SidebarRowObject,
    SidebarRowField,
    SidebarRowGroup
};

// The sidebar's only cell. Draws everything itself and ignores backgroundStyle,
// so the table's selection never changes its colours.
@interface HighlightTextFieldCell : NSTextFieldCell

@property (assign) SidebarRowStyle rowStyle;
// Object rows: drawn in a 16x16 box, vertically centred, clipped to SXRadiusXS corners.
// The box is reserved even when nil so names line up.
@property (strong) NSImage *icon;
// Right-aligned: field type, group count.
@property (copy) NSString *detailText;
// Filter match: accent-soft rounded fill behind the name, accent-ink text.
@property (assign) BOOL standout;
// Object not yet described: ink-muted.
@property (assign) BOOL dimmed;
// Semibold text.
@property (assign) BOOL selectedRow;

@end
