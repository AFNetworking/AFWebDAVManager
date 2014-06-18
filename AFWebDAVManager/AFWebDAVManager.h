// AFWebDAVManager.h
//
// Copyright (c) 2014 AFNetworking (http://afnetworking.com/)
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

#import <Foundation/Foundation.h>

#import "AFHTTPRequestOperationManager.h"

/**

 */
typedef NS_ENUM(NSUInteger, AFWebDAVDepth) {
    AFWebDAVZeroDepth = 0,
    AFWebDAVOneDepth = 1,
    AFWebDAVInfinityDepth = (NSUIntegerMax - 1),
};

/**

 */
typedef NS_OPTIONS(NSUInteger, AFWebDAVLockType) {
    AFWebDAVLockTypeWrite = 0,
};

/**

 */
typedef NS_ENUM(NSUInteger, AFWebDAVLockScope) {
    AFWebDAVLockScopeExclusive = 0,
    AFWebDAVLockScopeShared = 1,
};

/**

 */

@interface AFWebDAVManager : AFHTTPRequestOperationManager
///

/**

 */
@property (nonatomic, strong) NSDictionary *namespacesKeyedByAbbreviation;

///

/**

 */
- (void)contentsOfDirectoryAtURLString:(NSString *)URLString
                             recursive:(BOOL)recursive
                     completionHandler:(void (^)(NSArray *items, NSError *error))completionHandler;

/**

 */
- (void)createDirectoryAtURLString:(NSString *)URLString
       withIntermediateDirectories:(BOOL)createIntermediateDirectories
                 completionHandler:(void (^)(NSURL *directoryURL, NSError *error))completionHandler;

/**

 */
- (void)createFileAtURLString:(NSString *)URLString
  withIntermediateDirectories:(BOOL)createIntermediateDirectories
                     contents:(NSData *)contents
            completionHandler:(void (^)(NSURL *fileURL, NSError *error))completionHandler;

/**

 */
- (void)removeFileAtURLString:(NSString *)URLString
            completionHandler:(void (^)(NSURL *fileURL, NSError *error))completionHandler;

/**

 */
- (void)moveItemAtURLString:(NSString *)originURLString
                toURLString:(NSString *)destinationURLString
                  overwrite:(BOOL)overwrite
          completionHandler:(void (^)(NSURL *fileURL, NSError *error))completionHandler;

/**

 */
- (void)copyItemAtURLString:(NSString *)originURLString
                toURLString:(NSString *)destinationURLString
                  overwrite:(BOOL)overwrite
          completionHandler:(void (^)(NSURL *fileURL, NSError *error))completionHandler;

/**

 */
- (void)contentsOfFileAtURLString:(NSString *)URLString
                completionHandler:(void (^)(NSData *contents, NSError *error))completionHandler;

///

/**

 */
- (AFHTTPRequestOperation *)PUT:(NSString *)URLString
                           data:(NSData *)data
                        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**

 */
- (AFHTTPRequestOperation *)PUT:(NSString *)URLString
                           file:(NSURL *)fileURL
                        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**

 */
- (AFHTTPRequestOperation *)PROPFIND:(NSString *)URLString
                       propertyNames:(NSArray *)propertyNames
                               depth:(AFWebDAVDepth)depth
                             success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                             failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**

 */
- (AFHTTPRequestOperation *)PROPPATCH:(NSString *)URLString
                                  set:(NSDictionary *)propertiesToSet
                               remove:(NSArray *)propertiesToRemove
                              success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**

 */
- (AFHTTPRequestOperation *)MKCOL:(NSString *)URLString
                          success:(void (^)(AFHTTPRequestOperation *operation, NSURLResponse *response))success
                          failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**

 */
- (AFHTTPRequestOperation *)COPY:(NSString *)sourceURLString
                     destination:(NSString *)destinationURLString
                       overwrite:(BOOL)overwrite
                      conditions:(NSString *)IfHeaderFieldValue
                         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**

 */
- (AFHTTPRequestOperation *)MOVE:(NSString *)sourceURLString
                     destination:(NSString *)destinationURLString
                       overwrite:(BOOL)overwrite
                      conditions:(NSString *)IfHeaderFieldValue
                         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**

 */
- (AFHTTPRequestOperation *)LOCK:(NSString *)URLString
                         timeout:(NSTimeInterval)timeoutInterval
                           depth:(AFWebDAVDepth)depth
                           scope:(AFWebDAVLockScope)scope
                            type:(AFWebDAVLockType)type
                           owner:(NSURL *)ownerURL
                         success:(void (^)(AFHTTPRequestOperation *operation, NSString *lockToken))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**

 */
- (AFHTTPRequestOperation *)UNLOCK:(NSString *)URLString
                             token:(NSString *)lockToken
                           success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@end

#pragma mark -

/**
 
 */
@interface AFWebDAVRequestSerializer : AFHTTPRequestSerializer

@end

/**
 
 */
@interface AFWebDAVSharePointRequestSerializer : AFWebDAVRequestSerializer

@end

#pragma mark -

/**
 
 */
@interface AFWebDAVMultiStatusResponseSerializer : AFHTTPResponseSerializer

///

/**
 
 */
@property (readonly, nonatomic, strong) NSArray *responses;

@end

/**
 
 */
@interface AFWebDAVMultiStatusResponse : NSHTTPURLResponse

///

/**
 
 */
@property (readonly, nonatomic, strong) id properties;
@property (readonly, nonatomic) bool isCollection;
@property (readonly, nonatomic) int contentLength;
@property (readonly, nonatomic, strong) NSString *status;
@property (readonly, nonatomic, strong) NSString *creationDate;
@property (readonly, nonatomic, strong) NSString *lastModified;

///

/**
 
 */
- (instancetype)initWithURL:(NSURL *)URL
                 statusCode:(NSInteger)statusCode
                 properties:(id)properties;

@end
