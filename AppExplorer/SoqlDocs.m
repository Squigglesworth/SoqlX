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

#import "SoqlDocs.h"

@implementation SoqlDocs

// Keys are upper case. Values are "first line\nrest" where the first line is a
// short signature/example and the rest is the description.
+(NSDictionary<NSString*,NSString*>*)keywordDocs {
    static dispatch_once_t onceToken;
    static NSDictionary<NSString*,NSString*> *docs;
    dispatch_once(&onceToken, ^{
        docs = @{
            // clauses
            @"SELECT":      @"SELECT fieldList FROM object\nStarts a query. The field list can contain fields, relationship paths (Account.Name), aggregate functions, and nested sub-queries for child relationships.",
            @"FROM":        @"FROM object [alias]\nThe object to query. Only one primary object is allowed; relationships are reached via field paths or sub-queries.",
            @"WHERE":       @"WHERE condition [AND|OR condition]\nFilters the rows returned. Conditions can be grouped with parentheses and negated with NOT.",
            @"GROUP BY":    @"GROUP BY field [, field]\nGroups rows so that aggregate functions (COUNT, SUM, ...) are computed per group. Every non-aggregated field in SELECT must appear here.",
            @"ROLLUP":      @"GROUP BY ROLLUP (field [, field])\nAdds subtotal rows for each grouping level plus a grand total. Use GROUPING(field) to tell subtotal rows apart.",
            @"CUBE":        @"GROUP BY CUBE (field [, field])\nAdds subtotal rows for every combination of the grouped fields. Use GROUPING(field) to tell subtotal rows apart.",
            @"HAVING":      @"HAVING aggregateCondition\nFilters groups after GROUP BY, e.g. HAVING COUNT(Id) > 1. WHERE filters rows, HAVING filters groups.",
            @"ORDER BY":    @"ORDER BY field [ASC|DESC] [NULLS FIRST|LAST]\nSorts the results. Multiple fields are separated by commas; the default is ascending with nulls first.",
            @"ASC":         @"ORDER BY field ASC\nSort ascending (the default).",
            @"DESC":        @"ORDER BY field DESC\nSort descending.",
            @"NULLS":       @"ORDER BY field NULLS FIRST|LAST\nControls where null values sort. The default is NULLS FIRST.",
            @"FIRST":       @"ORDER BY field NULLS FIRST\nNull values sort before non-null values (the default).",
            @"LAST":        @"ORDER BY field NULLS LAST\nNull values sort after non-null values.",
            @"LIMIT":       @"LIMIT n\nReturns at most n rows. Combine with ORDER BY for predictable results.",
            @"OFFSET":      @"OFFSET n\nSkips the first n rows. The maximum offset is 2,000; use the Query More button or a WHERE on Id for deeper paging.",
            @"WITH":        @"WITH DATA CATEGORY ...  |  WITH SECURITY_ENFORCED  |  WITH USER_MODE\nAdds a data category filter for knowledge articles, or enforces field and object level security for the running user.",
            @"USING SCOPE": @"USING SCOPE scope\nRestricts rows to a predefined scope such as Mine, Team, Delegated, Everything, or My_Territory.",
            @"FOR VIEW":    @"FOR VIEW\nUpdates LastViewedDate for the returned records.",
            @"FOR REFERENCE": @"FOR REFERENCE\nUpdates LastReferencedDate for the returned records.",
            @"FOR UPDATE":  @"FOR UPDATE\nLocks the returned records for the duration of the transaction (Apex only).",
            @"VIEW":        @"FOR VIEW\nUpdates LastViewedDate for the returned records.",
            @"REFERENCE":   @"FOR REFERENCE\nUpdates LastReferencedDate for the returned records.",
            @"UPDATE":      @"UPDATE TRACKING | UPDATE VIEWSTAT\nFor knowledge articles: records keyword search tracking, or increments the article view count.",
            @"TRACKING":    @"UPDATE TRACKING\nRecords which knowledge article keywords were searched for.",
            @"VIEWSTAT":    @"UPDATE VIEWSTAT\nIncrements the view count of the returned knowledge articles.",
            @"TYPEOF":      @"TYPEOF polymorphicField WHEN Type THEN fields ELSE fields END\nSelects different fields depending on the concrete type of a polymorphic lookup such as Task.Who or Event.What.",
            @"WHEN":        @"TYPEOF field WHEN ObjectType THEN fields\nNames the concrete object type this branch applies to.",
            @"THEN":        @"WHEN ObjectType THEN fields\nThe fields to select when the polymorphic field is of the preceding type.",
            @"ELSE":        @"ELSE fields\nThe fields to select when none of the WHEN types match.",
            @"END":         @"END\nCloses a TYPEOF expression.",
            @"ALL ROWS":    @"ALL ROWS\nIncludes deleted and archived records. SoqlX runs this via queryAll; use the Query All command.",
            // boolean operators
            @"AND":         @"condition AND condition\nBoth conditions must be true.",
            @"OR":          @"condition OR condition\nEither condition may be true. Use parentheses when mixing AND and OR.",
            @"NOT":         @"NOT condition\nNegates a condition, e.g. WHERE NOT Name LIKE 'A%'.",
            // scopes
            @"EVERYTHING":  @"USING SCOPE Everything\nAll records the user can see.",
            @"MINE":        @"USING SCOPE Mine\nRecords owned by the running user.",
            @"MINE_AND_MY_GROUPS": @"USING SCOPE Mine_And_My_Groups\nRecords assigned to the running user and their queues.",
            @"MY_TERRITORY": @"USING SCOPE My_Territory\nRecords in the running user's territory (Enterprise Territory Management).",
            @"MY_TEAM_TERRITORY": @"USING SCOPE My_Team_Territory\nRecords in the territory of the running user's team.",
            @"TEAM":        @"USING SCOPE Team\nRecords assigned to a team the running user belongs to, such as an account team.",
            @"DELEGATED":   @"USING SCOPE Delegated\nRecords delegated to the running user for action, such as approvals.",
            // SOSL
            @"FIND":        @"FIND {searchTerm} [IN scope] [RETURNING object(fields)]\nStarts a SOSL text search across one or more objects. Search terms support * and ? wildcards and AND, OR, AND NOT.",
            @"RETURNING":   @"RETURNING Account(Id, Name), Contact(Id, Name WHERE ...)\nLists the objects (and optionally fields, filters, ordering and limits) to return from a SOSL search.",
            @"IN ALL FIELDS": @"FIND {term} IN ALL FIELDS\nSearch every searchable field.",
            @"IN NAME FIELDS": @"FIND {term} IN NAME FIELDS\nSearch only name fields.",
            @"IN EMAIL FIELDS": @"FIND {term} IN EMAIL FIELDS\nSearch only email fields.",
            @"IN PHONE FIELDS": @"FIND {term} IN PHONE FIELDS\nSearch only phone fields.",
            @"IN SIDEBAR FIELDS": @"FIND {term} IN SIDEBAR FIELDS\nSearch the fields used by the sidebar search.",
            @"ALL FIELDS":  @"IN ALL FIELDS\nSearch every searchable field.",
            @"NAME FIELDS": @"IN NAME FIELDS\nSearch only name fields.",
            @"EMAIL FIELDS": @"IN EMAIL FIELDS\nSearch only email fields.",
            @"PHONE FIELDS": @"IN PHONE FIELDS\nSearch only phone fields.",
            @"SIDEBAR FIELDS": @"IN SIDEBAR FIELDS\nSearch the fields used by the sidebar search.",
            @"LISTVIEW":    @"USING ListView=listViewApiName\nIn a SOSL RETURNING clause, limits results to the records in a list view.",
            @"DATA CATEGORY": @"WITH DATA CATEGORY group AT|ABOVE|BELOW|ABOVE_OR_BELOW category\nFilters knowledge articles or questions by data category.",
            @"AT":          @"WITH DATA CATEGORY group AT category\nArticles in exactly this category.",
            @"ABOVE":       @"WITH DATA CATEGORY group ABOVE category\nArticles in this category or any of its parents.",
            @"BELOW":       @"WITH DATA CATEGORY group BELOW category\nArticles in this category or any of its children.",
            @"ABOVE_OR_BELOW": @"WITH DATA CATEGORY group ABOVE_OR_BELOW category\nArticles in this category, its parents, or its children.",
            @"SECURITY_ENFORCED": @"WITH SECURITY_ENFORCED\nThe query fails if the user lacks read access to any field or object it references.",
            @"USER_MODE":   @"WITH USER_MODE\nRuns the query with the running user's object, field and sharing permissions.",
            @"SYSTEM_MODE": @"WITH SYSTEM_MODE\nRuns the query ignoring the running user's object and field permissions (sharing still applies).",
        };
    });
    return docs;
}

+(NSDictionary<NSString*,NSString*>*)operatorDocs {
    static dispatch_once_t onceToken;
    static NSDictionary<NSString*,NSString*> *docs;
    dispatch_once(&onceToken, ^{
        docs = @{
            @"=":        @"field = value\nEquals. String comparisons are case insensitive except for fields marked case sensitive.",
            @"!=":       @"field != value\nNot equal. Note that null rows are included: Name != 'x' matches rows where Name is null.",
            @"<":        @"field < value\nLess than.",
            @"<=":       @"field <= value\nLess than or equal.",
            @">":        @"field > value\nGreater than.",
            @">=":       @"field >= value\nGreater than or equal.",
            @"LIKE":     @"field LIKE 'pattern'\nCase insensitive pattern match on string fields. % matches any run of characters, _ matches a single character.",
            @"IN":       @"field IN ('a', 'b')  |  field IN (SELECT ... )\nMatches any of the listed values, or any Id returned by a semi-join sub-query.",
            @"NOT IN":   @"field NOT IN ('a', 'b')  |  field NOT IN (SELECT ... )\nMatches none of the listed values, or no Id returned by an anti-join sub-query.",
            @"INCLUDES": @"multiPicklist INCLUDES ('a;b', 'c')\nFor multi-select picklists: true if the field contains all values in a semicolon-separated entry, for any entry in the list.",
            @"EXCLUDES": @"multiPicklist EXCLUDES ('a', 'b')\nFor multi-select picklists: true if the field contains none of the listed values.",
        };
    });
    return docs;
}

+(NSDictionary<NSString*,NSString*>*)dateLiteralDocs {
    static dispatch_once_t onceToken;
    static NSDictionary<NSString*,NSString*> *docs;
    dispatch_once(&onceToken, ^{
        docs = @{
            @"YESTERDAY":   @"YESTERDAY\nFrom midnight to 11:59:59 PM of the previous day, in the user's time zone.",
            @"TODAY":       @"TODAY\nFrom midnight to 11:59:59 PM today, in the user's time zone.",
            @"TOMORROW":    @"TOMORROW\nFrom midnight to 11:59:59 PM of the next day.",
            @"LAST_WEEK":   @"LAST_WEEK\nAll days of the previous week (weeks start on the locale's first day of the week).",
            @"THIS_WEEK":   @"THIS_WEEK\nAll days of the current week.",
            @"NEXT_WEEK":   @"NEXT_WEEK\nAll days of the following week.",
            @"LAST_MONTH":  @"LAST_MONTH\nAll days of the previous month.",
            @"THIS_MONTH":  @"THIS_MONTH\nAll days of the current month.",
            @"NEXT_MONTH":  @"NEXT_MONTH\nAll days of the following month.",
            @"LAST_90_DAYS": @"LAST_90_DAYS\nFrom 90 days ago through to the end of today.",
            @"NEXT_90_DAYS": @"NEXT_90_DAYS\nFrom today through to 90 days from now.",
            @"THIS_QUARTER": @"THIS_QUARTER\nAll days of the current calendar quarter.",
            @"LAST_QUARTER": @"LAST_QUARTER\nAll days of the previous calendar quarter.",
            @"NEXT_QUARTER": @"NEXT_QUARTER\nAll days of the following calendar quarter.",
            @"THIS_YEAR":   @"THIS_YEAR\nJanuary 1 to December 31 of the current year.",
            @"LAST_YEAR":   @"LAST_YEAR\nJanuary 1 to December 31 of the previous year.",
            @"NEXT_YEAR":   @"NEXT_YEAR\nJanuary 1 to December 31 of the following year.",
            @"THIS_FISCAL_QUARTER": @"THIS_FISCAL_QUARTER\nThe current fiscal quarter, as defined in the org's fiscal year settings.",
            @"LAST_FISCAL_QUARTER": @"LAST_FISCAL_QUARTER\nThe previous fiscal quarter.",
            @"NEXT_FISCAL_QUARTER": @"NEXT_FISCAL_QUARTER\nThe following fiscal quarter.",
            @"THIS_FISCAL_YEAR": @"THIS_FISCAL_YEAR\nThe current fiscal year, as defined in the org's fiscal year settings.",
            @"LAST_FISCAL_YEAR": @"LAST_FISCAL_YEAR\nThe previous fiscal year.",
            @"NEXT_FISCAL_YEAR": @"NEXT_FISCAL_YEAR\nThe following fiscal year.",
            @"LAST_N_DAYS":  @"LAST_N_DAYS:n\nFrom midnight n days ago through to the end of today. LAST_N_DAYS:1 is yesterday and today.",
            @"NEXT_N_DAYS":  @"NEXT_N_DAYS:n\nFrom midnight tomorrow through to the end of the day n days from now.",
            @"LAST_N_WEEKS": @"LAST_N_WEEKS:n\nThe previous n whole weeks, not including the current week.",
            @"NEXT_N_WEEKS": @"NEXT_N_WEEKS:n\nThe next n whole weeks, not including the current week.",
            @"LAST_N_MONTHS": @"LAST_N_MONTHS:n\nThe previous n whole months, not including the current month.",
            @"NEXT_N_MONTHS": @"NEXT_N_MONTHS:n\nThe next n whole months, not including the current month.",
            @"LAST_N_QUARTERS": @"LAST_N_QUARTERS:n\nThe previous n whole calendar quarters.",
            @"NEXT_N_QUARTERS": @"NEXT_N_QUARTERS:n\nThe next n whole calendar quarters.",
            @"LAST_N_YEARS": @"LAST_N_YEARS:n\nThe previous n whole calendar years.",
            @"NEXT_N_YEARS": @"NEXT_N_YEARS:n\nThe next n whole calendar years.",
            @"LAST_N_FISCAL_QUARTERS": @"LAST_N_FISCAL_QUARTERS:n\nThe previous n whole fiscal quarters.",
            @"NEXT_N_FISCAL_QUARTERS": @"NEXT_N_FISCAL_QUARTERS:n\nThe next n whole fiscal quarters.",
            @"LAST_N_FISCAL_YEARS": @"LAST_N_FISCAL_YEARS:n\nThe previous n whole fiscal years.",
            @"NEXT_N_FISCAL_YEARS": @"NEXT_N_FISCAL_YEARS:n\nThe next n whole fiscal years.",
            @"TRUE":        @"field = TRUE\nBoolean literal.",
            @"FALSE":       @"field = FALSE\nBoolean literal.",
            @"NULL":        @"field = NULL  |  field != NULL\nMatches rows where the field has no value. Use = and != rather than IS.",
        };
    });
    return docs;
}

+(NSString*)normalize:(NSString*)txt {
    NSString *t = [[txt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    // collapse runs of whitespace so that "ORDER   BY" still matches "ORDER BY"
    NSArray<NSString*> *parts = [t componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSMutableArray<NSString*> *nonEmpty = [NSMutableArray arrayWithCapacity:parts.count];
    for (NSString *p in parts) {
        if (p.length > 0) {
            [nonEmpty addObject:p];
        }
    }
    t = [nonEmpty componentsJoinedByString:@" "];
    // Some date literal names in the tokenizer carry a zero width space (a copy/paste
    // artifact from the SOQL docs), strip it so lookups still match.
    t = [t stringByReplacingOccurrencesOfString:@"​" withString:@""];
    // LAST_N_DAYS:7 -> LAST_N_DAYS
    NSRange colon = [t rangeOfString:@":"];
    if (colon.location != NSNotFound) {
        t = [t substringToIndex:colon.location];
    }
    return t;
}

+(NSString*)docFor:(NSString*)txt type:(TokenType)type {
    if (txt.length == 0) {
        return nil;
    }
    NSString *key = [self normalize:txt];
    NSString *doc = nil;
    if (type & TTOperator) {
        doc = [self operatorDocs][key];
    }
    if (doc == nil && (type & (TTLiteralNamedDateTime | TTLiteralBoolean | TTLiteralNull | TTLiteral))) {
        doc = [self dateLiteralDocs][key];
    }
    if (doc == nil && (type & (TTKeyword | TTTypeOf | TTUsingScope | TTOperator))) {
        doc = [self keywordDocs][key];
    }
    if (doc == nil && type == 0) {
        // untyped lookup, try everything.
        doc = [self operatorDocs][key];
        if (doc == nil) doc = [self dateLiteralDocs][key];
        if (doc == nil) doc = [self keywordDocs][key];
    }
    return doc;
}

+(NSArray<NSString*>*)documentedTerms {
    NSMutableArray<NSString*> *all = [NSMutableArray array];
    [all addObjectsFromArray:[self keywordDocs].allKeys];
    [all addObjectsFromArray:[self operatorDocs].allKeys];
    [all addObjectsFromArray:[self dateLiteralDocs].allKeys];
    return all;
}

@end
