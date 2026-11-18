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

#import "SoqlFunction.h"
#import "CaseInsensitiveStringKey.h"
#import "SoqlToken.h"
#import "Completion.h"
#import <ZKSforce/ZKSforce.h>

ExampleProvider firstFieldP(NSPredicate*p) {
    return ^NSString*(ZKDescribeSObject*o) {
        for (ZKDescribeField *f in o.fields) {
            if ([p evaluateWithObject:f]) {
                return f.name;
            }
        }
        return @"Id";
    };
}
ExampleProvider firstField(NSString*p) {
    return firstFieldP([NSPredicate predicateWithFormat:p]);
}
ExampleProvider fixed(NSString*value) {
    return ^NSString*(ZKDescribeSObject*o) {
        return value;
    };
}

@implementation SoqlFuncArg
+(instancetype)arg:(TokenType)type fldPred:(NSString*)fieldFilter fnPred:(NSPredicate *)fnFilter {
    SoqlFuncArg *a = [self new];
    a.type = type;
    a.fieldFilter = [NSPredicate predicateWithFormat:fieldFilter];
    a.example = firstFieldP(a.fieldFilter);
    a.funcFilter = fnFilter;
    return a;
}

+(instancetype)arg:(TokenType)type fldPred:(NSString*)fieldFilter {
    return [self arg:type fldPred:fieldFilter fnPred:nil];
}

+(instancetype)arg:(TokenType)type ex:(ExampleProvider)ex {
    SoqlFuncArg *a = [self new];
    a.type = type;
    a.example = ex;
    return a;
}
-(Token*)validateToken:(Token*)argToken {
    if ((self.type & argToken.type) != argToken.type) {
        Token *err = [argToken tokenOf:argToken.loc];
        err.type = TTError;
        err.value = [NSString stringWithFormat:@"Function argument of unexpected type %@, should be %@", tokenName(argToken.type), tokenNames(self.type)];
        return err;
    }
    if (((self.type & TTFieldPath) != 0) && argToken.type==TTFieldPath && self.fieldFilter != nil) {
        if ([argToken.value isKindOfClass:[Tokens class]]) {
            Tokens *pathTokens = (Tokens*)argToken.value;
            Token *lastPathToken = pathTokens.tokens.lastObject;
            if (lastPathToken.type == TTField) {
                ZKDescribeField *f = (ZKDescribeField *)lastPathToken.value;
                if (![self.fieldFilter evaluateWithObject:f]) {
                    Token *err = [argToken tokenOf:argToken.loc];
                    err.type = TTError;
                    err.value = [NSString stringWithFormat:@"Field %@ is not valid for this function", argToken.tokenTxt];
                    return err;
                }
            }
        }
    }
    return nil;
}
@end

@interface DistanceMeasureArg : SoqlFuncArg
@end

@implementation DistanceMeasureArg
-(instancetype)init {
    self = [super init];
    self.type = TTLiteralString;
    self.example = fixed(@"'mi'");
    return self;
}

-(Token*)validateToken:(Token*)argToken {
    [argToken.completions addObjectsFromArray:[Completion completions:@[@"'mi'", @"'km'"] type:TTLiteralString]];
    Token *err = [super validateToken:argToken];
    if (err == nil) {
        if ((![argToken matches:@"'mi'"]) && (![argToken matches:@"'km'"])) {
            err = [argToken tokenOf:argToken.loc];
            err.type = TTError;
            err.value = @"Function argument should be 'mi' or 'km'";
        }
    }
    return err;
}

@end

@interface FieldsArg : SoqlFuncArg
@end
@implementation FieldsArg
-(instancetype)init {
    self = [super init];
    self.type = TTKeyword;
    self.example = fixed(@"STANDARD");
    return self;
}
-(Token*)validateToken:(Token*)argToken {
    NSArray<NSString*> *valid = @[@"STANDARD", @"ALL", @"CUSTOM"];
    [argToken.completions addObjectsFromArray:[Completion completions:valid type:TTKeyword]];
    if (argToken.type == TTFieldPath) {
        argToken.type = TTKeyword;
    }
    Token *err = [super validateToken:argToken];
    if (err == nil) {
        for (NSString *v in valid) {
            if ([argToken matches:v]) {
                return nil;
            }
        }
        argToken.type = TTError;
        argToken.value = [NSString stringWithFormat:@"Fields argument should be one of %@", [valid componentsJoinedByString:@","]];
    }
    return err;
}

@end

@interface SoqlCountFunction : SoqlFunction
@end

@implementation SoqlCountFunction
-(instancetype)init {
    self = [super init];
    self.name = @"Count";
    self.args = @[[SoqlFuncArg arg:TTFieldPath fldPred:@"aggregatable=true"]];
    self.doc = @"COUNT() returns the number of rows matching the query, with no other fields allowed. COUNT(field) returns the number of rows where field is not null, and can be combined with GROUP BY.";
    return self;
}

-(NSString*)signature {
    return @"COUNT()  |  COUNT(field)";
}
-(Token*)validateArgCount:(Token*)tFunc {
    // count is different in that there's both count() and count(field)
    Tokens *args = (Tokens*)tFunc.value;
    if (args.count == 0) {
        return nil;
    }
    return [super validateArgCount:tFunc];
}

@end

@implementation SoqlFunction

+(NSDictionary<CaseInsensitiveStringKey*,SoqlFunction*>*)all {
    static dispatch_once_t onceToken;
    static NSDictionary<CaseInsensitiveStringKey*,SoqlFunction*>* funcs;
    
    dispatch_once(&onceToken, ^{
        SoqlFunction *cvtTz = [self fn:@"ConvertTimezone" args:@[[SoqlFuncArg arg:TTFieldPath fldPred:@"type='datetime' OR type='date'"]]];
        NSPredicate *cvzTzOnly = [NSPredicate predicateWithFormat:@"name=%@", cvtTz.name];
        
        SoqlFunction *geoLoc = [self fn:@"Geolocation" args:@[[SoqlFuncArg arg:TTLiteralNumber ex:fixed(@"1.0")], [SoqlFuncArg arg:TTLiteralNumber ex:fixed(@"1.0")]]];
        SoqlFuncArg *distGeoArg = [SoqlFuncArg arg:TTFunc ex:fixed(@"GeoLocation(1.0,1.0)")];
        distGeoArg.funcFilter = [NSPredicate predicateWithFormat:@"name=%@", geoLoc.name];
        
        SoqlFunction *convCurrency = [self fn:@"ConvertCurrency" args:@[[SoqlFuncArg arg:TTFieldPath fldPred:@"type='currency'"]]];
        NSPredicate *convCurrencyOnly = [NSPredicate predicateWithFormat:@"name=%@", convCurrency.name];

        cvtTz.doc = @"Converts a date/time field from UTC to the user's time zone before a date function such as CALENDAR_YEAR or DAY_IN_MONTH is applied to it. Only valid as the argument to a date function.";
        geoLoc.doc = @"Builds a location value from a latitude and longitude. Only valid as the second argument to DISTANCE.";
        convCurrency.doc = @"Converts a currency field from the record's currency into the user's currency. Only available in orgs with multiple currencies enabled.";

        NSArray<SoqlFunction*>* fns = @[
            [self fn:@"Fields" args:@[[FieldsArg new]]
                  doc:@"Selects a group of fields without listing them. FIELDS(ALL) returns every field, FIELDS(STANDARD) the standard fields, FIELDS(CUSTOM) the custom fields. ALL and CUSTOM require a LIMIT of 200 or less."],
            [self fn:@"ToLabel" args:@[[SoqlFuncArg arg:TTFieldPath fldPred:@"type!='id' AND type!='reference'"]]
                  doc:@"Returns the translated label for a picklist, record type, or other translatable field instead of its API value, in the user's language."],
            [SoqlCountFunction new],
            [self fn:@"Count_Distinct" args:@[[SoqlFuncArg arg:TTFieldPath fldPred:@"aggregatable=true"]]
                  doc:@"Returns the number of distinct non-null values of the field. Aggregate; use with GROUP BY to count per group."],
            [self fn:@"Avg" args:@[[SoqlFuncArg arg:TTFieldPath | TTFunc fldPred:@"aggregatable=true AND (type='double' OR type='int' OR type='percent' OR type='currency')" fnPred:convCurrencyOnly]]
                  doc:@"Returns the average of a numeric field over the matching rows, ignoring nulls. Aggregate; use with GROUP BY for per group averages."],
            [self fn:@"Sum" args:@[[SoqlFuncArg arg:TTFieldPath | TTFunc fldPred:@"aggregatable=true AND (type='double' OR type='int' OR type='percent' OR type='currency')" fnPred:convCurrencyOnly]]
                  doc:@"Returns the total of a numeric field over the matching rows, ignoring nulls. Aggregate; use with GROUP BY for per group totals."],
            [self fn:@"Min" args:@[[SoqlFuncArg arg:TTFieldPath | TTFunc fldPred:@"aggregatable=true AND type!='id' AND type!='reference'" fnPred:convCurrencyOnly]]
                  doc:@"Returns the smallest value of the field over the matching rows. Works on numbers, dates and strings (string comparison is by sort order)."],
            [self fn:@"Max" args:@[[SoqlFuncArg arg:TTFieldPath | TTFunc fldPred:@"aggregatable=true AND type!='id' AND type!='reference'" fnPred:convCurrencyOnly]]
                  doc:@"Returns the largest value of the field over the matching rows. Works on numbers, dates and strings (string comparison is by sort order)."],
            [self fn:@"Format" args:@[[SoqlFuncArg arg:TTFieldPath | TTFunc
                                               fldPred:@"type='datetime' OR type='date' OR type='time' or type='currency' or type='double' or type='int'"]]
                  doc:@"Returns the field formatted as a string using the user's locale: dates and times in the user's time zone and format, numbers and currencies with locale separators and symbols."],
            [self fn:@"Distance" args:@[[SoqlFuncArg arg:TTFieldPath fldPred:@"type='location'"],
                                        distGeoArg,
                                        [DistanceMeasureArg new]]
                  doc:@"Returns the distance between a geolocation field and a fixed point, in miles ('mi') or kilometers ('km'). Can be used in WHERE (e.g. < 20) and ORDER BY as well as SELECT."],
            [self fn:@"Calendar_Month" args:@[[SoqlFuncArg arg:TTFieldPath | TTFunc fldPred:@"type='datetime' OR type='date'" fnPred:cvzTzOnly]]
                  doc:@"Returns the month of a date as a number, 1 (January) to 12. Date/time fields are evaluated in UTC unless wrapped in CONVERTTIMEZONE."],
            [self fn:@"Calendar_Quarter" args:@[[SoqlFuncArg arg:TTFieldPath| TTFunc fldPred:@"type='datetime' OR type='date'" fnPred:cvzTzOnly]]
                  doc:@"Returns the calendar quarter of a date, 1 (January to March) to 4. Date/time fields are evaluated in UTC unless wrapped in CONVERTTIMEZONE."],
            [self fn:@"Calendar_Year" args:@[[SoqlFuncArg arg:TTFieldPath | TTFunc fldPred:@"type='datetime' OR type='date'" fnPred:cvzTzOnly]]
                  doc:@"Returns the four digit calendar year of a date. Date/time fields are evaluated in UTC unless wrapped in CONVERTTIMEZONE."],
            [self fn:@"Day_In_Month" args:@[[SoqlFuncArg arg:TTFieldPath | TTFunc fldPred:@"type='datetime' OR type='date'" fnPred:cvzTzOnly]]
                  doc:@"Returns the day of the month of a date, 1 to 31."],
            [self fn:@"Day_In_Week" args:@[[SoqlFuncArg arg:TTFieldPath | TTFunc fldPred:@"type='datetime' OR type='date'" fnPred:cvzTzOnly]]
                  doc:@"Returns the day of the week of a date, 1 (Sunday) to 7 (Saturday)."],
            [self fn:@"Day_In_Year" args:@[[SoqlFuncArg arg:TTFieldPath | TTFunc fldPred:@"type='datetime' OR type='date'" fnPred:cvzTzOnly]]
                  doc:@"Returns the day of the year of a date, 1 to 366."],
            [self fn:@"Day_Only" args:@[[SoqlFuncArg arg:TTFieldPath | TTFunc fldPred:@"type='datetime'" fnPred:cvzTzOnly]]
                  doc:@"Returns just the date part of a date/time field, so rows can be grouped or compared by day. Evaluated in UTC unless wrapped in CONVERTTIMEZONE."],
            [self fn:@"Fiscal_Month" args:@[[SoqlFuncArg arg:TTFieldPath | TTFunc fldPred:@"type='datetime' OR type='date'" fnPred:cvzTzOnly]]
                  doc:@"Returns the month within the fiscal year of a date, 1 to 12, based on the org's fiscal year settings."],
            [self fn:@"Fiscal_Quarter" args:@[[SoqlFuncArg arg:TTFieldPath | TTFunc fldPred:@"type='datetime' OR type='date'" fnPred:cvzTzOnly]]
                  doc:@"Returns the fiscal quarter of a date, 1 to 4, based on the org's fiscal year settings."],
            [self fn:@"Fiscal_Year" args:@[[SoqlFuncArg arg:TTFieldPath | TTFunc fldPred:@"type='datetime' OR type='date'" fnPred:cvzTzOnly]]
                  doc:@"Returns the fiscal year of a date, based on the org's fiscal year settings."],
            [self fn:@"Hour_In_Day" args:@[[SoqlFuncArg arg:TTFieldPath | TTFunc fldPred:@"type='datetime'" fnPred:cvzTzOnly]]
                  doc:@"Returns the hour of a date/time field, 0 to 23. Evaluated in UTC unless wrapped in CONVERTTIMEZONE."],
            [self fn:@"Week_In_Month" args:@[[SoqlFuncArg arg:TTFieldPath | TTFunc fldPred:@"type='datetime' OR type='date'" fnPred:cvzTzOnly]]
                  doc:@"Returns the week of the month of a date, 1 to 5."],
            [self fn:@"Week_In_Year" args:@[[SoqlFuncArg arg:TTFieldPath | TTFunc fldPred:@"type='datetime' OR type='date'" fnPred:cvzTzOnly]]
                  doc:@"Returns the week of the year of a date, 1 to 53."],
            [self fn:@"Grouping" args:@[[SoqlFuncArg arg:TTFieldPath fldPred:@"groupable=TRUE"]]
                  doc:@"For GROUP BY ROLLUP and CUBE queries: returns 1 for subtotal rows where the field was rolled up, and 0 for ordinary grouped rows."],

            convCurrency, cvtTz, geoLoc
        ];
        NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:fns.count];
        for (SoqlFunction *f in fns) {
            NSAssert(f.doc.length > 0, @"function %@ is missing its documentation", f.name);
            [d setObject:f forKey:[CaseInsensitiveStringKey of:f.name]];
        }
        funcs = [NSDictionary dictionaryWithDictionary:d];
    });
    return funcs;
}

+(NSPredicate*)defaultFuncFilter {
    static dispatch_once_t onceToken;
    static NSPredicate *filter;
    dispatch_once(&onceToken, ^() {
        NSDictionary<CaseInsensitiveStringKey*,SoqlFunction*>* fns = [self all];
        SoqlFunction *geo = fns[[CaseInsensitiveStringKey of:@"geolocation"]];
        SoqlFunction *convTz = fns[[CaseInsensitiveStringKey of:@"convertTimezone"]];
        filter = [NSPredicate predicateWithFormat:@"name!=%@ and name!=%@", geo.name, convTz.name];
    });
    return filter;
}

+(NSArray<SoqlFunction*>*)functionsFilteredBy:(NSPredicate*)p {
    static dispatch_once_t onceToken;
    static NSArray<SoqlFunction*>* allFuncs;
    static NSMutableDictionary<NSPredicate*, NSArray<SoqlFunction*>*> *predicateCache;
    dispatch_once(&onceToken, ^() {
        allFuncs = [NSArray arrayWithArray:[[self all] allValues]];
        predicateCache = [NSMutableDictionary dictionaryWithCapacity:32];
    });
    if (p == nil) {
        return allFuncs;
    }
    NSArray<SoqlFunction*>* res = predicateCache[p];
    if (res == nil) {
        res = [allFuncs filteredArrayUsingPredicate:p];
        predicateCache[p] = res;
    }
    return res;
}

+(instancetype)fn:(NSString*)name args:(NSArray<SoqlFuncArg*>*)args {
    SoqlFunction *f = [self new];
    f.name = name;
    f.args = args;
    return f;
}

+(instancetype)fn:(NSString*)name args:(NSArray<SoqlFuncArg*>*)args doc:(NSString*)doc {
    SoqlFunction *f = [self fn:name args:args];
    f.doc = doc;
    return f;
}

// a short human readable name for the types an argument accepts, e.g. field|function
+(NSString*)argTypeName:(TokenType)t {
    NSMutableArray<NSString*> *names = [NSMutableArray arrayWithCapacity:2];
    if (t & TTFieldPath)      [names addObject:@"field"];
    if (t & TTFunc)           [names addObject:@"function"];
    if (t & TTLiteralNumber)  [names addObject:@"number"];
    if (t & TTLiteralString)  [names addObject:@"string"];
    if (t & TTKeyword)        [names addObject:@"keyword"];
    if (names.count == 0)     [names addObject:@"value"];
    return [names componentsJoinedByString:@"|"];
}

-(NSString*)signature {
    NSMutableArray<NSString*> *argNames = [NSMutableArray arrayWithCapacity:self.args.count];
    for (SoqlFuncArg *a in self.args) {
        [argNames addObject:[SoqlFunction argTypeName:a.type]];
    }
    return [NSString stringWithFormat:@"%@(%@)", self.name.uppercaseString, [argNames componentsJoinedByString:@", "]];
}

-(NSString*)documentation {
    if (self.doc.length == 0) {
        return self.signature;
    }
    return [NSString stringWithFormat:@"%@\n%@", self.signature, self.doc];
}

-(Completion*)completionOn:(ZKDescribeSObject*)primary {
    NSMutableString *s = [NSMutableString stringWithCapacity:32];
    NSInteger posAtEndOfFirstArg = 0;
    [s appendString:self.name];
    [s appendString:@"("];
    if (self.args.count > 0) {
        NSEnumerator<SoqlFuncArg*> *e = [self.args objectEnumerator];
        [s appendString:e.nextObject.example(primary)];
        posAtEndOfFirstArg = s.length;
        SoqlFuncArg *arg = e.nextObject;
        while (arg != nil) {
            [s appendString:@","];
            [s appendString:arg.example(primary)];
            arg = e.nextObject;
        }
    }
    [s appendString:@")"];
    Completion *fc = [Completion txt:self.name type:TTFunc];
    fc.finalInsertionText = s;
    fc.documentation = self.documentation;
    if (posAtEndOfFirstArg > 0) {
        fc.onFinalInsert = moveSelection(-(s.length-posAtEndOfFirstArg));
    }
    return fc;
}

-(Token*)validateArgCount:(Token*)tFunc {
    Tokens *argTokens = (Tokens*)tFunc.value;
    if (argTokens.count != self.args.count) {
        Token *err = [tFunc tokenOf:tFunc.loc];
        err.type = TTError;
        err.value = [NSString stringWithFormat:@"The function %@ should have %ld arguments, but has %ld", self.name, self.args.count, argTokens.count];
        return err;
    }
    return nil;
}

@end
