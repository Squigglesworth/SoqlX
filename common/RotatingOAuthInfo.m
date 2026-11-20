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

#import "RotatingOAuthInfo.h"

static NSString *const RotatingOAuthErrorDomain = @"SoqlXOAuth";
// Matches ZKSforce's own DEFAULT_MAX_SESSION_AGE.
static const NSTimeInterval kSessionAge = 25 * 60;

static NSString *formEncoded(NSString *v) {
    NSMutableCharacterSet *cs = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [cs removeCharactersInString:@"&+=/?:"];
    return [v stringByAddingPercentEncodingWithAllowedCharacters:cs] ?: @"";
}

@implementation RotatingOAuthInfo

// ZKOAuthInfo keeps sessionId, url, clientId and refreshToken behind private readwrite
// declarations; their synthesized accessors are reachable through key-value coding.
-(NSString *)privateClientId {
    id v = [self valueForKey:@"clientId"];
    return [v isKindOfClass:[NSString class]] ? v : @"";
}

-(void)refresh:(void (^)(NSError *))cb {
    NSString *refreshToken = self.refreshToken;
    if (refreshToken.length == 0) {
        cb([NSError errorWithDomain:RotatingOAuthErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"No refresh token to refresh the session with"}]);
        return;
    }
    NSURL *tokenUrl = [NSURL URLWithString:@"/services/oauth2/token" relativeToURL:self.authHostUrl];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:tokenUrl];
    req.HTTPMethod = @"POST";
    NSString *body = [NSString stringWithFormat:@"grant_type=refresh_token&refresh_token=%@&client_id=%@",
                      formEncoded(refreshToken), formEncoded([self privateClientId])];
    req.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];
    [req addValue:@"application/x-www-form-urlencoded; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    [req addValue:@"application/json" forHTTPHeaderField:@"Accept"];

    NSURLSessionDataTask *t = [[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            cb(error);
            return;
        }
        id json = data.length > 0 ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        if (![json isKindOfClass:[NSDictionary class]]) {
            NSInteger status = [response isKindOfClass:[NSHTTPURLResponse class]] ? [(NSHTTPURLResponse *)response statusCode] : 0;
            cb([NSError errorWithDomain:RotatingOAuthErrorDomain code:2 userInfo:@{NSLocalizedDescriptionKey:
                [NSString stringWithFormat:@"Unexpected response from the token endpoint (HTTP %ld)", (long)status]}]);
            return;
        }
        NSDictionary *tokens = json;
        if (tokens[@"error"] != nil) {
            NSString *msg = [NSString stringWithFormat:@"%@ : %@", tokens[@"error"], tokens[@"error_description"] ?: @""];
            cb([NSError errorWithDomain:RotatingOAuthErrorDomain code:3 userInfo:@{NSLocalizedDescriptionKey: msg}]);
            return;
        }
        NSString *access = tokens[@"access_token"];
        NSString *instance = tokens[@"instance_url"];
        if (![access isKindOfClass:[NSString class]] || ![instance isKindOfClass:[NSString class]]) {
            cb([NSError errorWithDomain:RotatingOAuthErrorDomain code:4 userInfo:@{NSLocalizedDescriptionKey:
                @"The token response from Salesforce was missing the access token or instance URL"}]);
            return;
        }
        [self setValue:access forKey:@"sessionId"];
        [self setValue:[NSURL URLWithString:instance] forKey:@"url"];
        [self setValue:[NSDate dateWithTimeIntervalSinceNow:kSessionAge] forKey:@"sessionExpiresAt"];

        NSString *rotated = tokens[@"refresh_token"];
        if ([rotated isKindOfClass:[NSString class]] && rotated.length > 0 && ![rotated isEqualToString:refreshToken]) {
            [self setValue:rotated forKey:@"refreshToken"];
            void (^notify)(NSString *) = self.onRefreshTokenRotated;
            if (notify != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{ notify(rotated); });
            }
        }
        cb(nil);
    }];
    [t resume];
}

@end
