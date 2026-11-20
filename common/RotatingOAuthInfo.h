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

#import <Foundation/Foundation.h>
#import <ZKSforce/ZKSforce.h>

NS_ASSUME_NONNULL_BEGIN

// ZKOAuthInfo refreshes sessions with the refresh token but ignores the new refresh token that
// Salesforce returns when the connected app has Refresh Token Rotation on (which new apps do, and
// it can't be turned off). The old token is then dead and the next refresh fails with
// "expired access/refresh token". This subclass does the refresh itself, keeps the rotated token,
// and tells its owner so the keychain entry can be updated.
@interface RotatingOAuthInfo : ZKOAuthInfo

// Called on the main queue whenever a refresh returns a new refresh token.
@property (copy, nullable) void (^onRefreshTokenRotated)(NSString *newRefreshToken);

@end

NS_ASSUME_NONNULL_END
