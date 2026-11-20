// Copyright (c) 2021 Simon Fell
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

#import "DescribeExtras.h"
#import <objc/runtime.h>
#import <ZKSforce/ZKSforce.h>
#import "CaseInsensitiveStringKey.h"
#import "SoqlToken.h"
#import "Completion.h"
#import "SObjectKinds.h"

@implementation ZKDescribeSObject (Relationships)

-(NSDictionary<CaseInsensitiveStringKey*,ZKDescribeField*>*)parentRelationshipsByName {
    NSDictionary<CaseInsensitiveStringKey*,ZKDescribeField*>* r = objc_getAssociatedObject(self, @selector(parentRelationshipsByName));
    if (r == nil) {
        NSMutableDictionary<CaseInsensitiveStringKey*,ZKDescribeField*>* pr = [NSMutableDictionary dictionary];
        for (ZKDescribeField *f in self.fields) {
            if (f.relationshipName.length > 0 && f.referenceTo.count > 0) {
                [pr setObject:f forKey:[CaseInsensitiveStringKey of:f.relationshipName]];
            }
        }
        r = pr;
        objc_setAssociatedObject(self, @selector(parentRelationshipsByName), r, OBJC_ASSOCIATION_RETAIN);
    }
    return r;
}

-(NSDictionary<CaseInsensitiveStringKey*,ZKChildRelationship*>*)childRelationshipsByName {
    NSDictionary<CaseInsensitiveStringKey*,ZKChildRelationship*>* r = objc_getAssociatedObject(self, @selector(childRelationshipsByName));
    if (r == nil) {
        NSMutableDictionary<CaseInsensitiveStringKey*,ZKChildRelationship*>* cr = [NSMutableDictionary dictionaryWithCapacity:self.childRelationships.count];
        for (ZKChildRelationship *r in self.childRelationships) {
            if (r.relationshipName.length > 0) {
                [cr setObject:r forKey:[CaseInsensitiveStringKey of:r.relationshipName]];
            }
        }
        r = cr;
        objc_setAssociatedObject(self, @selector(childRelationshipsByName), r, OBJC_ASSOCIATION_RETAIN);
    }
    return r;
}

@end

@implementation ZKDescribeSObject (Completions)
-(NSArray<Completion*>*)parentRelCompletions {
    NSArray<Completion*> *comps = objc_getAssociatedObject(self, @selector(parentRelCompletions));
    if (comps == nil) {
        NSArray<ZKDescribeField*> *relFields = self.parentRelationshipsByName.allValues;
        NSMutableArray<Completion*> *built = [NSMutableArray arrayWithCapacity:relFields.count];
        for (ZKDescribeField *f in relFields) {
            Completion *c = [Completion txt:f.relationshipName type:TTRelationship];
            c.documentation = [NSString stringWithFormat:@"%@ \u2192 %@\n%@",
                               f.relationshipName,
                               [f.referenceTo componentsJoinedByString:@", "],
                               [f documentation]];
            [built addObject:c];
        }
        comps = built;
        for (Completion *c in comps) {
            c.finalInsertionText = [NSString stringWithFormat:@"%@.Id", c.finalInsertionText];
            c.onFinalInsert = ^BOOL(ZKTextView *tv, id<ZKTextViewCompletion> c) {
                // This selects the 'Id' we just inserted so that the user can start typing and it'll replace the Id.
                // otherwise typing starts after the Id.
                NSRange sel = tv.selectedRange;
                sel.location -= 2;
                sel.length += 2;
                tv.selectedRange = sel;
                [tv showPopup];
                return TRUE;
            };
        }
        objc_setAssociatedObject(self, @selector(parentRelCompletions), comps, OBJC_ASSOCIATION_RETAIN);
    }
    return comps;
}
@end

@implementation ZKDescribeField (Completion)
-(Completion*)completion {
    Completion *c = objc_getAssociatedObject(self, @selector(completion));
    if (c == nil) {
        c = [Completion txt:self.name type:TTField];
        c.documentation = [self documentation];
        objc_setAssociatedObject(self, @selector(completion), c, OBJC_ASSOCIATION_RETAIN);
    }
    return c;
}
@end

@implementation ZKDescribeSObject (Documentation)
-(NSString*)documentation {
    NSMutableArray<NSString*> *lines = [NSMutableArray arrayWithCapacity:3];
    NSString *label = self.label.length > 0 ? self.label : self.name;
    if ([label isEqualToString:self.name]) {
        [lines addObject:self.name];
    } else {
        [lines addObject:[NSString stringWithFormat:@"%@ (%@)", label, self.name]];
    }
    NSMutableArray<NSString*> *attrs = [NSMutableArray arrayWithCapacity:8];
    if (self.keyPrefix.length > 0) [attrs addObject:[NSString stringWithFormat:@"key prefix %@", self.keyPrefix]];
    if (self.custom)        [attrs addObject:@"custom"];
    if (self.customSetting) [attrs addObject:@"custom setting"];
    if (!self.queryable)    [attrs addObject:@"not queryable"];
    if (self.createable)    [attrs addObject:@"createable"];
    if (self.updateable)    [attrs addObject:@"updateable"];
    if (self.deletable)     [attrs addObject:@"deletable"];
    if (self.searchable)    [attrs addObject:@"searchable"];
    if (self.feedEnabled)   [attrs addObject:@"feed enabled"];
    if (attrs.count > 0) {
        [lines addObject:[attrs componentsJoinedByString:@" \u00b7 "]];
    }
    [lines addObject:[NSString stringWithFormat:@"%lu fields \u00b7 %lu child relationships",
                      (unsigned long)self.fields.count, (unsigned long)self.childRelationships.count]];
    return [lines componentsJoinedByString:@"\n"];
}
@end

@implementation ZKDescribeField (Documentation)

-(NSString*)typeDescription {
    NSString *type = self.type.length > 0 ? self.type : @"unknown";
    NSString *lower = type.lowercaseString;
    if ([lower isEqualToString:@"reference"]) {
        if (self.referenceTo.count > 0) {
            return [NSString stringWithFormat:@"reference to %@", [self.referenceTo componentsJoinedByString:@", "]];
        }
        return type;
    }
    if ([lower isEqualToString:@"string"] || [lower isEqualToString:@"textarea"] || [lower isEqualToString:@"picklist"] ||
        [lower isEqualToString:@"multipicklist"] || [lower isEqualToString:@"email"] || [lower isEqualToString:@"phone"] ||
        [lower isEqualToString:@"url"] || [lower isEqualToString:@"encryptedstring"] || [lower isEqualToString:@"combobox"]) {
        if (self.length > 0) {
            return [NSString stringWithFormat:@"%@(%ld)", type, (long)self.length];
        }
        return type;
    }
    if ([lower isEqualToString:@"double"] || [lower isEqualToString:@"currency"] || [lower isEqualToString:@"percent"]) {
        if (self.precision > 0) {
            return [NSString stringWithFormat:@"%@(%ld,%ld)", type, (long)self.precision, (long)self.scale];
        }
        return type;
    }
    if ([lower isEqualToString:@"int"] && self.digits > 0) {
        return [NSString stringWithFormat:@"%@(%ld)", type, (long)self.digits];
    }
    return type;
}

-(NSString*)documentation {
    NSMutableArray<NSString*> *lines = [NSMutableArray arrayWithCapacity:5];
    NSString *label = self.label.length > 0 ? self.label : self.name;
    if ([label isEqualToString:self.name]) {
        [lines addObject:self.name];
    } else {
        [lines addObject:[NSString stringWithFormat:@"%@ (%@)", label, self.name]];
    }
    NSMutableArray<NSString*> *attrs = [NSMutableArray arrayWithCapacity:8];
    [attrs addObject:[self typeDescription]];
    if (self.custom)        [attrs addObject:@"custom"];
    if (self.calculated)    [attrs addObject:@"formula"];
    if (self.autoNumber)    [attrs addObject:@"auto number"];
    if (self.externalId)    [attrs addObject:@"external id"];
    if (self.unique)        [attrs addObject:@"unique"];
    if (self.nameField)     [attrs addObject:@"name field"];
    if (!self.nillable && self.createable && !self.defaultedOnCreate) [attrs addObject:@"required"];
    if (!self.updateable && !self.createable) {
        [attrs addObject:@"read only"];
    } else if (!self.updateable) {
        [attrs addObject:@"create only"];
    }
    if (!self.filterable)   [attrs addObject:@"not filterable"];
    if (!self.sortable)     [attrs addObject:@"not sortable"];
    if (!self.groupable)    [attrs addObject:@"not groupable"];
    [lines addObject:[attrs componentsJoinedByString:@" \u00b7 "]];

    NSArray *picklist = self.picklistValues;
    if (picklist.count > 0) {
        NSMutableArray<NSString*> *vals = [NSMutableArray arrayWithCapacity:8];
        NSUInteger active = 0;
        for (ZKPicklistEntry *ple in picklist) {
            if (!ple.active) continue;
            active++;
            if (vals.count < 8) {
                [vals addObject:ple.value];
            }
        }
        if (vals.count > 0) {
            NSString *more = active > vals.count ? [NSString stringWithFormat:@", +%lu more", (unsigned long)(active - vals.count)] : @"";
            [lines addObject:[NSString stringWithFormat:@"Values: %@%@", [vals componentsJoinedByString:@", "], more]];
        }
    }
    if (self.inlineHelpText.length > 0) {
        [lines addObject:[NSString stringWithFormat:@"Help: %@", self.inlineHelpText]];
    }
    if (self.calculatedFormula.length > 0) {
        [lines addObject:[NSString stringWithFormat:@"Formula: %@", self.calculatedFormula]];
    }
    return [lines componentsJoinedByString:@"\n"];
}
@end

// MARK: - Hover

static void addLine(NSMutableArray<NSString*> *lines, NSString *prefix, NSArray<NSString*> *items, NSString *sep) {
    if (items.count > 0) {
        [lines addObject:[NSString stringWithFormat:@"%@%@", prefix, [items componentsJoinedByString:sep]]];
    }
}

static NSString *joinFacts(NSArray<NSString*> *facts, NSArray<NSString*> *meta) {
    NSMutableArray<NSString*> *all = [NSMutableArray arrayWithArray:facts];
    [all addObject:@""];
    [all addObject:@"Metadata:"];
    [all addObjectsFromArray:meta];
    return [all componentsJoinedByString:@"\n"];
}

@implementation ZKDescribeGlobalSObject (Hover)

-(NSString *)hoverTextWithDescribe:(ZKDescribeSObject *)describe {
    NSMutableArray<NSString*> *facts = [NSMutableArray arrayWithCapacity:5];
    [facts addObject:self.label.length > 0 ? self.label : self.name];
    [facts addObject:[NSString stringWithFormat:@"API name: %@", self.name]];
    NSMutableArray<NSString*> *kind = [NSMutableArray arrayWithCapacity:2];
    [kind addObject:[SObjectKinds kindDescriptionForName:self.name custom:self.custom customSetting:self.customSetting]];
    if (self.keyPrefix.length > 0) {
        [kind addObject:[NSString stringWithFormat:@"key prefix %@", self.keyPrefix]];
    }
    addLine(facts, @"Kind: ", kind, @" \u00b7 ");
    if (describe != nil) {
        [facts addObject:[NSString stringWithFormat:@"Fields: %lu \u00b7 child relationships: %lu",
                          (unsigned long)describe.fields.count, (unsigned long)describe.childRelationships.count]];
    }

    NSMutableArray<NSString*> *meta = [NSMutableArray arrayWithCapacity:3];
    NSMutableArray<NSString*> *query = [NSMutableArray arrayWithCapacity:2];
    [query addObject:self.queryable ? @"queryable" : @"not queryable"];
    if (self.searchable) [query addObject:@"searchable"];
    addLine(meta, @"Query: ", query, @", ");

    NSMutableArray<NSString*> *edit = [NSMutableArray arrayWithCapacity:4];
    if (self.createable)  [edit addObject:@"create"];
    if (self.updateable)  [edit addObject:@"update"];
    if (self.deletable)   [edit addObject:@"delete"];
    if (self.undeletable) [edit addObject:@"undelete"];
    if (edit.count == 0)  [edit addObject:@"read only"];
    addLine(meta, @"Edit: ", edit, @", ");

    NSMutableArray<NSString*> *flags = [NSMutableArray arrayWithCapacity:4];
    if (self.customSetting) [flags addObject:@"custom setting"];
    if (self.feedEnabled)   [flags addObject:@"feed tracking"];
    if (self.triggerable)   [flags addObject:@"triggers"];
    if (self.mergeable)     [flags addObject:@"mergeable"];
    addLine(meta, @"Flags: ", flags, @", ");
    return joinFacts(facts, meta);
}

@end

@implementation ZKDescribeField (Hover)

-(NSString *)hoverText {
    NSMutableArray<NSString*> *facts = [NSMutableArray arrayWithCapacity:6];
    [facts addObject:self.label.length > 0 ? self.label : self.name];
    [facts addObject:[NSString stringWithFormat:@"API name: %@", self.name]];
    [facts addObject:[NSString stringWithFormat:@"Type: %@", [self typeDescription]]];
    if (self.inlineHelpText.length > 0) {
        [facts addObject:[NSString stringWithFormat:@"Help text: %@", self.inlineHelpText]];
    }
    NSMutableArray<NSString*> *vals = [NSMutableArray arrayWithCapacity:8];
    NSUInteger active = 0;
    for (ZKPicklistEntry *ple in self.picklistValues) {
        if (!ple.active) continue;
        active++;
        if (vals.count < 8 && ple.value != nil) {
            [vals addObject:ple.value];
        }
    }
    if (vals.count > 0) {
        NSString *more = active > vals.count ? [NSString stringWithFormat:@", +%lu more", (unsigned long)(active - vals.count)] : @"";
        [facts addObject:[NSString stringWithFormat:@"Values: %@%@", [vals componentsJoinedByString:@", "], more]];
    }
    if (self.calculatedFormula.length > 0) {
        [facts addObject:[NSString stringWithFormat:@"Formula: %@", self.calculatedFormula]];
    }

    NSMutableArray<NSString*> *meta = [NSMutableArray arrayWithCapacity:3];
    NSMutableArray<NSString*> *yes = [NSMutableArray arrayWithCapacity:4];
    NSMutableArray<NSString*> *no = [NSMutableArray arrayWithCapacity:4];
    [(self.filterable ? yes : no) addObject:@"filterable"];
    [(self.sortable ? yes : no) addObject:@"sortable"];
    [(self.groupable ? yes : no) addObject:@"groupable"];
    [(self.aggregatable ? yes : no) addObject:@"aggregatable"];
    NSMutableArray<NSString*> *qparts = [NSMutableArray arrayWithCapacity:2];
    if (yes.count > 0) [qparts addObject:[yes componentsJoinedByString:@", "]];
    if (no.count > 0)  [qparts addObject:[NSString stringWithFormat:@"not %@", [no componentsJoinedByString:@", not "]]];
    addLine(meta, @"Query: ", qparts, @" \u00b7 ");

    NSString *edit;
    if (self.createable && self.updateable)      edit = @"create and update";
    else if (self.createable)                    edit = @"create only";
    else if (self.updateable)                    edit = @"update only";
    else                                         edit = @"read only";
    if (!self.nillable && self.createable && !self.defaultedOnCreate) {
        edit = [edit stringByAppendingString:@", required"];
    }
    [meta addObject:[NSString stringWithFormat:@"Edit: %@", edit]];

    NSMutableArray<NSString*> *flags = [NSMutableArray arrayWithCapacity:8];
    if (self.custom)      [flags addObject:@"custom"];
    if (self.calculated)  [flags addObject:@"formula"];
    if (self.autoNumber)  [flags addObject:@"auto number"];
    if (self.externalId)  [flags addObject:@"external id"];
    if (self.unique)      [flags addObject:@"unique"];
    if (self.idLookup)    [flags addObject:@"id lookup"];
    if (self.nameField)   [flags addObject:@"name field"];
    if (self.encrypted)   [flags addObject:@"encrypted"];
    addLine(meta, @"Flags: ", flags, @", ");
    return joinFacts(facts, meta);
}

@end
