// A0RSA.m
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <A0RSA.h>
#import <CommonCrypto/CommonCrypto.h>

@interface A0RSA ()
@property (readonly, nonatomic) SecKeyRef key;
@end

@implementation A0RSA

- (nullable instancetype)initWithKey: (SecKeyRef)key {
    self = [super init];
    if (self) {
        _key = key;
    }
    return self;
}

- (NSData *)sign:(NSData *)plainData {
    NSData* signedHash = nil;
#if TARGET_OS_OSX && __MAC_OS_X_VERSION_MIN_REQUIRED >= 101200
    NSData* result = nil;
    CFErrorRef* error = nil;
    result = CFBridgingRelease(SecKeyCreateSignature(self.key, kSecKeyAlgorithmRSASignatureDigestPKCS1v15SHA256, (CFDataRef)plainData, error));
    
    if (error == nil) {
        signedHash = result;
    }
#else
    size_t signedHashBytesSize = SecKeyGetBlockSize(self.key);
    uint8_t signedHashBytes[signedHashBytesSize];
    memset(signedHashBytes, 0x0, signedHashBytesSize);
    
    OSStatus result = SecKeyRawSign(self.key,
                                    kSecPaddingPKCS1SHA256,
                                    plainData.bytes,
                                    plainData.length,
                                    signedHashBytes,
                                    &signedHashBytesSize);
    
    if (result == errSecSuccess) {
        signedHash = [NSData dataWithBytes:signedHashBytes
                                    length:(NSUInteger)signedHashBytesSize];
    }
#endif

    return signedHash;
}

- (Boolean)verify:(NSData *)plainData signature:(NSData *)signature {
#if TARGET_OS_OSX && __MAC_OS_X_VERSION_MIN_REQUIRED >= 101200
    CFErrorRef* error = nil;
    return SecKeyVerifySignature(self.key, kSecKeyAlgorithmRSASignatureDigestPKCS1v15SHA256, (CFDataRef)plainData, (CFDataRef)signature, error);
#else
    OSStatus result = SecKeyRawVerify(self.key,
                                      kSecPaddingPKCS1SHA256,
                                      plainData.bytes,
                                      plainData.length,
                                      signature.bytes,
                                      signature.length);
    return result == errSecSuccess;
#endif

}

@end
