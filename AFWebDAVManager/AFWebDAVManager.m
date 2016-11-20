// AFWebDAVManager.m
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

#import "AFWebDAVManager.h"
#import "ONOXMLDocument.h"

static NSString * const AFWebDAVXMLDeclarationString = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>";

static NSString * AFWebDAVStringForDepth(AFWebDAVDepth depth) {
    switch (depth) {
        case AFWebDAVZeroDepth:
            return @"0";
        case AFWebDAVOneDepth:
            return @"1";
        case AFWebDAVInfinityDepth:
        default:
            return @"infinity";
    }
}

static NSString * AFWebDAVStringForLockScope(AFWebDAVLockScope scope) {
    switch (scope) {
        case AFWebDAVLockScopeShared:
            return @"shared";
        case AFWebDAVLockScopeExclusive:
        default:
            return @"exclusive";
    }
}

static NSString * AFWebDAVStringForLockType(AFWebDAVLockType type) {
    switch (type) {
        case AFWebDAVLockTypeWrite:
        default:
            return @"write";
    }
}

#pragma mark -

@interface AFWebDAVMultiStatusResponse ()
- (instancetype)initWithResponseElement:(ONOXMLElement *)element;
@end

#pragma mark -

@implementation AFWebDAVManager

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }

    self.namespacesKeyedByAbbreviation = @{@"D": @"DAV:"};
    self.defaultAbbreviationOfXMLnamespaces = @"D";

    self.requestSerializer = [AFWebDAVRequestSerializer serializer];
    self.responseSerializer = [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:@[[AFWebDAVMultiStatusResponseSerializer serializer], [AFHTTPResponseSerializer serializer]]];

    self.operationQueue.maxConcurrentOperationCount = 1;

    return self;
}


#pragma mark - setters

- (void)setNamespacesKeyedByAbbreviation:(NSDictionary *)namespacesKeyedByAbbreviation
{
    _namespacesKeyedByAbbreviation = namespacesKeyedByAbbreviation;
}

- (void)setDefaultAbbreviationOfXMLnamespaces:(NSString *)defaultAbbreviationOfXMLnamespaces
{
    _defaultAbbreviationOfXMLnamespaces = defaultAbbreviationOfXMLnamespaces;
}



#pragma mark -

- (void)contentsOfDirectoryAtURLString:(NSString *)URLString
                             recursive:(BOOL)recursive
                     completionHandler:(void (^)(NSArray *items, NSError *error))completionHandler
{
    [self PROPFIND:URLString tokenDic:nil
     propertyNames:nil depth:(recursive ? AFWebDAVInfinityDepth : AFWebDAVOneDepth) success:^(__unused
        //AFHTTPRequestOperation *operation, id responseObject) {
        /* replaced with NSURLSessionDataTask by OYXJ on 2016.08.08 */
        NSURLSessionDataTask *task, id responseObject) {
        
        if (completionHandler) {
            completionHandler(responseObject, nil);
        }
        
    //} failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
    /* replaced with NSURLSessionDataTask by OYXJ on 2016.08.08 */
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
            
        if (completionHandler) {
            completionHandler(nil, error);
        }
    }];
}

- (void)createDirectoryAtURLString:(NSString *)URLString
       withIntermediateDirectories:(BOOL)createIntermediateDirectories
                 completionHandler:(void (^)(NSURL *directoryURL, NSError *error))completionHandler
{
    __weak __typeof(self) weakself = self;
    //[self MKCOL:URLString success:^(__unused AFHTTPRequestOperation *operation, NSURLResponse *response) {
    /* replaced with NSURLSessionDataTask by OYXJ on 2016.08.08 */
    [self MKCOL:URLString success:^(__unused NSURLSessionDataTask *task, NSURLResponse *response) {
    
        
        if (completionHandler) {
            /**
             Fixed crash related to sending 'URL' selector to '_NSInlineData' inst…
             Ref.: https://github.com/danielr/AFWebDAVManager/commit/1ba182bbbb743465830b694c4120456efc908ac6
             danielr committed on 13 Jan
             1 parent a25f308 commit 1ba182bbbb743465830b694c4120456efc908ac6
             
            if ([NSStringFromClass([response class]) isEqualToString:@"_NSZeroData"]) {
                completionHandler(nil, nil);
            } else {
                completionHandler([response URL], nil);
            }
             */
            if ([response respondsToSelector:@selector(URL)]) {
                completionHandler([response URL], nil);
            } else {
                completionHandler(nil, nil);
            }
        }
    //} failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
    /* replaced with NSURLSessionDataTask by OYXJ on 2016.08.08 */
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        
        __strong __typeof(weakself) strongSelf = weakself;
        
        NSInteger statusCode = 0;
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)(task.response);
        if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
            statusCode = httpResponse.statusCode;
        }
        
        //if ([operation.response statusCode] == 409 && createIntermediateDirectories) {
        if (statusCode == 409 && createIntermediateDirectories) {
            
            //NSArray *pathComponents = [[operation.request URL] pathComponents];
            /* replaced with NSURLSessionDataTask by OYXJ on 2016.08.08 */
            NSArray *pathComponents = [[task.originalRequest URL] pathComponents];
            
            if ([pathComponents count] > 1) {
                [pathComponents enumerateObjectsUsingBlock:^(NSString *component, NSUInteger idx, __unused BOOL *stop) {
                    NSString *intermediateURLString = [[[pathComponents subarrayWithRange:NSMakeRange(0, idx)] arrayByAddingObject:component] componentsJoinedByString:@"/"];
                    //[strongSelf MKCOL:intermediateURLString success:^(__unused AFHTTPRequestOperation *MKCOLOperation, __unused NSURLResponse *MKCOLResponse) {
                    /* replaced with NSURLSessionDataTask by OYXJ on 2016.08.08 */
                    [strongSelf MKCOL:intermediateURLString success:^(__unused NSURLSessionDataTask *MKCOLOperation, __unused NSURLResponse *MKCOLResponse) {
                        

                    //} failure:^(__unused AFHTTPRequestOperation *MKCOLOperation, NSError *MKCOLError) {
                    /* replaced with NSURLSessionDataTask by OYXJ on 2016.08.08 */
                    } failure:^(__unused NSURLSessionDataTask *MKCOLOperation, NSError *MKCOLError) {
                        
                        if (completionHandler) {
                            completionHandler(nil, MKCOLError);
                        }
                    }];
                }];
            }
        } else {
            if (completionHandler) {
                completionHandler(nil, error);
            }
        }
    }];
}

- (void)createFileAtURLString:(NSString *)URLString
  withIntermediateDirectories:(BOOL)createIntermediateDirectories
                     contents:(NSData *)contents
            completionHandler:(void (^)(NSURL *fileURL, NSError *error))completionHandler
{
    NSString *dataJSONString = [StringUtil jsonStringWith:contents];
    NSDictionary<NSString*,NSString*> *attributesDataToPut = @{@"" :  dataJSONString?:@""};
    
    __weak __typeof(self) weakself = self;
    //[self PUT:URLString data:contents success:^(AFHTTPRequestOperation *operation, __unused id responseObject) {
    /* replaced with NSURLSessionDataTask by OYXJ on 2016.08.08 */
    [self multiPUT:URLString tokenDic:nil extraHeaderDic:nil dataType:nil attributesData:attributesDataToPut success:^(NSURLSessionDataTask *task, __unused id responseObject) {
        
        if (completionHandler) {
            completionHandler([task.response URL], nil);
        }
    //} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    /* replaced with NSURLSessionDataTask by OYXJ on 2016.08.08 */
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        __strong __typeof(weakself) strongSelf = weakself;
        
        NSInteger statusCode = 0;
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)(task.response);
        if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
            statusCode = httpResponse.statusCode;
        }
        
        //if ([operation.response statusCode] == 409 && createIntermediateDirectories) {
        if (statusCode == 409 && createIntermediateDirectories) {
            
            //NSArray *pathComponents = [[operation.request URL] pathComponents];
            /* replaced with NSURLSessionDataTask by OYXJ on 2016.08.08 */
            NSArray *pathComponents = [[task.originalRequest URL] pathComponents];
            
            if ([pathComponents count] > 1) {
                [strongSelf createDirectoryAtURLString:[[pathComponents subarrayWithRange:NSMakeRange(0, [pathComponents count] - 1)] componentsJoinedByString:@"/"] withIntermediateDirectories:YES completionHandler:^(__unused NSURL *directoryURL, NSError *MKCOLError) {
                    if (MKCOLError) {
                        if (completionHandler) {
                            completionHandler(nil, MKCOLError);
                        }
                    } else {
                        [strongSelf createFileAtURLString:URLString withIntermediateDirectories:NO contents:contents completionHandler:completionHandler];
                    }
                }];
            }
        } else {
            if (completionHandler) {
                completionHandler(nil, error);
            }
        }
    }];
}


/**
 modify by OYXJ on 2016.08
 */
- (NSURLSessionDataTask *)removeFileAtURLString:(NSString *)URLString
                                       tokenDic:(NSDictionary<NSString*,NSString*> *)tokenDic  //e.g. @{"token", tokenStr};
                                 extraHeaderDic:(NSDictionary<NSString*,NSString*> *)extraHeaderDic //request的HTTPHeaderField
                                       dataType:(NSString *)dataType  //数据类型
                                 attributesData:(NSDictionary<NSString *,NSString *> *)attributesDataToDelete  //数据项
                                        success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                                        failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSMutableString *mutableXMLString = [NSMutableString stringWithString:AFWebDAVXMLDeclarationString];
    {
        /**
         add by OYXJ, considering that: XML Namespace not always 'D'
         
         [mutableXMLString appendString:[NSString stringWithFormat:@"<D:%@-multidel", dataType]];
         */
        [mutableXMLString appendString:[NSString stringWithFormat:@"<%@:%@-multidel", self.defaultAbbreviationOfXMLnamespaces?:@"D", dataType]];
        [self.namespacesKeyedByAbbreviation enumerateKeysAndObjectsUsingBlock:^(NSString *abbreviation, NSString *namespace, __unused BOOL *stop) {
            if (abbreviation.length > 0) {//天坑，补一下。
                [mutableXMLString appendFormat:@" xmlns:%@=\"%@\"", abbreviation, namespace];
            }else{//天坑，补一下。
                [mutableXMLString appendFormat:@" xmlns=\"%@\"", namespace];
            }
        }];
        [mutableXMLString appendString:@">"];
        
        if (attributesDataToDelete) {
            {
                /* e.g.  <href etag='W/"4124bc0a9335c27f086f24ba207a4912"'>/sync/new/xxx0.json</href>  */
                [attributesDataToDelete enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull attributes, NSString * _Nonnull dataJSONString, BOOL * _Nonnull stop) {
                    [mutableXMLString appendString: @"<href "];
                    [mutableXMLString appendString: attributes];
                    [mutableXMLString appendString: @">"];
                    [mutableXMLString appendString: dataJSONString];
                    [mutableXMLString appendString: @"</href>"];
                }];
            }
        }
        
        
        /**
         add by OYXJ, considering that: XML Namespace not always 'D'
         
         [mutableXMLString appendString:[NSString stringWithFormat:@"</D:%@-multidel>",dataType]];
         */
        [mutableXMLString appendString:[NSString stringWithFormat:@"</%@:%@-multidel>", self.defaultAbbreviationOfXMLnamespaces?:@"D", dataType]];
    }
    
    
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"DELETE" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];
    
    [request setValue:AFWebDAVStringForDepth(AFWebDAVZeroDepth) forHTTPHeaderField:@"Depth"];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[mutableXMLString dataUsingEncoding:NSUTF8StringEncoding]];
    if (tokenDic.count == 1) {//token
        [tokenDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }
    if (extraHeaderDic.count > 0) {//extraHeaderDic
        [extraHeaderDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }
    
    /*
     replaced with NSURLSessionDataTask by OYXJ on 2016.08.08
     
     AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
     [self.operationQueue addOperation:operation];
     
     return operation;
     */
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self dataTaskWithRequest: request
                       completionHandler: ^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                           
                           if (error) {
                               if (failure) {
                                   failure(dataTask, error);
                               }
                           } else {
                               if (success) {
                                   success(dataTask, responseObject);
                               }
                           }
                           
                       }];
    [dataTask resume];
    
    return dataTask;
}

- (void)moveItemAtURLString:(NSString *)originURLString
                toURLString:(NSString *)destinationURLString
                  overwrite:(BOOL)overwrite
          completionHandler:(void (^)(NSURL *fileURL, NSError *error))completionHandler
{
    //[self MOVE:originURLString destination:destinationURLString overwrite:overwrite conditions:nil success:^(AFHTTPRequestOperation *operation, __unused id responseObject) {
    /* replaced with NSURLSessionDataTask by OYXJ on 2016.08.08 */
    [self MOVE:originURLString destination:destinationURLString overwrite:overwrite conditions:nil success:^(NSURLSessionDataTask *task, __unused id responseObject) {
        
        if (completionHandler) {
            completionHandler([task.response URL], nil);
        }
    //} failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
    /* replaced with NSURLSessionDataTask by OYXJ on 2016.08.08 */
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        
        if (completionHandler) {
            completionHandler(nil, error);
        }
    }];
}

- (void)copyItemAtURLString:(NSString *)originURLString
                toURLString:(NSString *)destinationURLString
                  overwrite:(BOOL)overwrite
          completionHandler:(void (^)(NSURL *fileURL, NSError *error))completionHandler
{
    //[self COPY:originURLString destination:destinationURLString overwrite:overwrite conditions:nil success:^(AFHTTPRequestOperation *operation, __unused id responseObject) {
    /* replaced with NSURLSessionDataTask by OYXJ on 2016.08.08 */
    [self COPY:originURLString destination:destinationURLString overwrite:overwrite conditions:nil success:^(NSURLSessionDataTask *task, __unused id responseObject) {
        
        if (completionHandler) {
            completionHandler([task.response URL], nil);
        }
    //} failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
    /* replaced with NSURLSessionDataTask by OYXJ on 2016.08.08 */
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        
        if (completionHandler) {
            completionHandler(nil, error);
        }
    }];
}

- (void)contentsOfFileAtURLString:(NSString *)URLString
                completionHandler:(void (^)(NSData *contents, NSError *error))completionHandler
{
    //[self GET:URLString parameters:nil success:^(AFHTTPRequestOperation *operation, __unused id responseObject) {
    /* replaced with NSURLSessionDataTask by OYXJ on 2016.08.08 */
    [self GET:URLString parameters:nil progress:nil success:^(NSURLSessionDataTask *task, __unused id responseObject) {
        
        /**
         此处做法的依据 AFNetworking内部实现：
            在task完成(complete)之后，首先 执行completionHandler，然后 抛出通知AFNetworkingTaskDidCompleteNotification。
         */
        
        __block __weak id curTaskObserver;
        curTaskObserver = [[NSNotificationCenter defaultCenter] addObserverForName: AFNetworkingTaskDidCompleteNotification
                                                                            object: task
                                                                             queue: nil
                                                                        usingBlock: ^(NSNotification * _Nonnull note) {
                                  if (completionHandler) {
                                      
                                      NSData *aData = [note userInfo][AFNetworkingTaskDidCompleteResponseDataKey];
                                      
                                      completionHandler(aData, nil);
                                  }
                                                         
                                   // 这种方式，将导致 当前通知，只能调用一次。
                                   NSLog(@"attention here: run once, and only once!");
                                   [[NSNotificationCenter defaultCenter] removeObserver:curTaskObserver];
                                   curTaskObserver = nil;//这个重要，如果不是 __weak 。
                            }];
        
    //} failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
    /* replaced with NSURLSessionDataTask by OYXJ on 2016.08.08 */
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        
        if (completionHandler) {
            completionHandler(nil, error);
        }
    }];
}

#pragma mark -
/*
replaced with NSURLSessionDataTask by OYXJ on 2016.08.08

- (AFHTTPRequestOperation *)PUT:(NSString *)URLString
                           data:(NSData *)data
                        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
 
 modify by OYXJ on 2016.08
 */
- (NSURLSessionDataTask *)multiPUT:(NSString *)URLString
                          tokenDic:(NSDictionary<NSString*,NSString*> *)tokenDic  //e.g. @{"token", tokenStr};
                    extraHeaderDic:(NSDictionary<NSString*,NSString*> *)extraHeaderDic   //request的HTTPHeaderField
                          dataType:(NSString *)dataType  //数据类型
                    attributesData:(NSDictionary<NSString*,NSString*> *)attributesDataToPut    //数据项
                           success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                           failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSMutableString *mutableXMLString = [NSMutableString stringWithString:AFWebDAVXMLDeclarationString];
    {
        /**
         add by OYXJ, considering that: XML Namespace not always 'D'
         
         [mutableXMLString appendString:[NSString stringWithFormat:@"<D:%@-multiput", dataType]];
         */
        [mutableXMLString appendString:[NSString stringWithFormat:@"<%@:%@-multiput", self.defaultAbbreviationOfXMLnamespaces?:@"D", dataType]];
        [self.namespacesKeyedByAbbreviation enumerateKeysAndObjectsUsingBlock:^(NSString *abbreviation, NSString *namespace, __unused BOOL *stop) {
            if (abbreviation.length > 0) {//天坑，补一下。
                [mutableXMLString appendFormat:@" xmlns:%@=\"%@\"", abbreviation, namespace];
            }else{//天坑，补一下。
                [mutableXMLString appendFormat:@" xmlns=\"%@\"", namespace];
            }
        }];
        [mutableXMLString appendString:@">"];
        
        if (attributesDataToPut) {
            {
                /* e.g.  <data name='/sync/new/xxx0.json' etag='W/"4124bc0a9335c27f086f24ba207a4912"'>xxx</data>  */
                [attributesDataToPut enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull attributes, NSString * _Nonnull dataJSONString, BOOL * _Nonnull stop) {
                    [mutableXMLString appendString: @"<data "];
                    [mutableXMLString appendString: attributes];
                    [mutableXMLString appendString: @">"];
                    [mutableXMLString appendString: dataJSONString];
                    [mutableXMLString appendString: @"</data>"];
                }];
            }
        }
        
        
        /**
         add by OYXJ, considering that: XML Namespace not always 'D'
         
         [mutableXMLString appendString:[NSString stringWithFormat:@"</D:%@-multiput>",dataType]];
         */
        [mutableXMLString appendString:[NSString stringWithFormat:@"</%@:%@-multiput>", self.defaultAbbreviationOfXMLnamespaces?:@"D", dataType]];
    }
    
    LELOGI(@"mutableXMlString =  %@",mutableXMLString);
    
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"PUT" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];
    
    [request setValue:AFWebDAVStringForDepth(AFWebDAVZeroDepth) forHTTPHeaderField:@"Depth"];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[mutableXMLString dataUsingEncoding:NSUTF8StringEncoding]];
    if (tokenDic.count == 1) {//token
        [tokenDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }
    if (extraHeaderDic.count > 0) {//extraHeaderDic
        [extraHeaderDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }
    
#if defined( DEBUG )
    // TODO: test code
    // [request setValue:@"example.domain.com" forHTTPHeaderField:@"host"];
#endif
    
    /*
     replaced with NSURLSessionDataTask by OYXJ on 2016.08.08
     
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self.operationQueue addOperation:operation];

    return operation;
    */
    
    LELOGI(@"request == %@",request);
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self dataTaskWithRequest: request
                       completionHandler: ^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                           
                           if (error) {
                               if (failure) {
                                   failure(dataTask, error);
                               }
                           } else {
                               if (success) {
                                   success(dataTask, responseObject);
                               }
                           }

                       }];
    [dataTask resume];
    
    return dataTask;
}

/*
 replaced with NSURLSessionDataTask by OYXJ on 2016.08.08
 
- (AFHTTPRequestOperation *)PUT:(NSString *)URLString
                           file:(NSURL *)fileURL
                        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
 
 modify by OYXJ on 2016.08
 */
- (NSURLSessionDataTask *)multiPUT:(NSString *)URLString
                          tokenDic:(NSDictionary<NSString*,NSString*> *)tokenDic  //e.g. @{"token", tokenStr};
                    extraHeaderDic:(NSDictionary<NSString*,NSString*> *)extraHeaderDic   //request的HTTPHeaderField
                          dataType:(NSString *)dataType  //数据类型
                              file:(NSURL *)fileURL
                    attributesData:(NSDictionary<NSString*,NSString*> *)attributesDataToPut    //数据项
                           success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                           failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSParameterAssert(fileURL && [fileURL isFileURL]);

    NSMutableString *mutableXMLString = [NSMutableString stringWithString:AFWebDAVXMLDeclarationString];
    {
        /**
         add by OYXJ, considering that: XML Namespace not always 'D'
         
         [mutableXMLString appendString:[NSString stringWithFormat:@"<D:%@-multiput", dataType]];
         */
        [mutableXMLString appendString:[NSString stringWithFormat:@"<%@:%@-multiput", self.defaultAbbreviationOfXMLnamespaces?:@"D", dataType]];
        [self.namespacesKeyedByAbbreviation enumerateKeysAndObjectsUsingBlock:^(NSString *abbreviation, NSString *namespace, __unused BOOL *stop) {
            if (abbreviation.length > 0) {//天坑，补一下。
                [mutableXMLString appendFormat:@" xmlns:%@=\"%@\"", abbreviation, namespace];
            }else{//天坑，补一下。
                [mutableXMLString appendFormat:@" xmlns=\"%@\"", namespace];
            }
        }];
        [mutableXMLString appendString:@">"];
        
        if (attributesDataToPut) {
            {
                /* e.g.  <data name='/sync/new/xxx0.json' etag='W/"4124bc0a9335c27f086f24ba207a4912"'>xxx</data>  */
                [attributesDataToPut enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull attributes, NSString * _Nonnull dataJSONString, BOOL * _Nonnull stop) {
                    [mutableXMLString appendString: @"<data "];
                    [mutableXMLString appendString: attributes];
                    [mutableXMLString appendString: @">"];
                    [mutableXMLString appendString: dataJSONString];
                    [mutableXMLString appendString: @"</data>"];
                }];
            }
        }
        
        
        /**
         add by OYXJ, considering that: XML Namespace not always 'D'
         
         [mutableXMLString appendString:[NSString stringWithFormat:@"</D:%@-multiput>",dataType]];
         */
        [mutableXMLString appendString:[NSString stringWithFormat:@"</%@:%@-multiput>", self.defaultAbbreviationOfXMLnamespaces?:@"D", dataType]];
    }
    
    
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"PUT" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];
    
    [request setValue:AFWebDAVStringForDepth(AFWebDAVZeroDepth) forHTTPHeaderField:@"Depth"];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[mutableXMLString dataUsingEncoding:NSUTF8StringEncoding]];    // TODO:    setHTTPBody
    request.HTTPBodyStream = [NSInputStream inputStreamWithURL:fileURL];    // TODO:   HTTPBodyStream
    if (tokenDic.count == 1) {//token
        [tokenDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }
    if (extraHeaderDic.count > 0) {//extraHeaderDic
        [extraHeaderDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }

#if defined( DEBUG )
    // TODO: test code
    // [request setValue:@"example.domain.com" forHTTPHeaderField:@"host"];
#endif
    
    /*
     replaced with NSURLSessionDataTask by OYXJ on 2016.08.08
     
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self.operationQueue addOperation:operation];

    return operation;
    */
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self dataTaskWithRequest: request
                       completionHandler: ^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                            
                            if (error) {
                                if (failure) {
                                    failure(dataTask, error);
                                }
                            } else {
                                if (success) {
                                    success(dataTask, responseObject);
                                }
                            }
                            
                        }];
    [dataTask resume];
    
    return dataTask;
}

#pragma mark -

/*
replaced with NSURLSessionDataTask by OYXJ on 2016.08.08

- (AFHTTPRequestOperation *)PROPFIND:(NSString *)URLString
                       propertyNames:(NSArray *)propertyNames
                               depth:(AFWebDAVDepth)depth
                             success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                             failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
 
 modify by OYXJ on 2016.08
 */
- (NSURLSessionDataTask *)PROPFIND:(NSString *)URLString
                          tokenDic:(NSDictionary<NSString*,NSString*> *)tokenDic  //e.g. @{"token", tokenStr};
                     propertyNames:(NSArray *)propertyNames   //要获取的数据项
                             depth:(AFWebDAVDepth)depth
                           success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                           failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSMutableString *mutableXMLString = [NSMutableString stringWithString:AFWebDAVXMLDeclarationString];
    {
        /**
         add by OYXJ, considering that: XML Namespace not always 'D'
         
         [mutableXMLString appendString:@"<D:propfind"];
         */
        [mutableXMLString appendString:[NSString stringWithFormat:@"<%@:propfind", self.defaultAbbreviationOfXMLnamespaces?:@"D"]];
        [self.namespacesKeyedByAbbreviation enumerateKeysAndObjectsUsingBlock:^(NSString *abbreviation, NSString *namespace, __unused BOOL *stop) {
            if (abbreviation.length > 0) {//天坑，补一下。
                [mutableXMLString appendFormat:@" xmlns:%@=\"%@\"", abbreviation, namespace];
            }else{//天坑，补一下。
                [mutableXMLString appendFormat:@" xmlns=\"%@\"", namespace];
            }
        }];
        [mutableXMLString appendString:@">"];

        if (propertyNames) {
            [propertyNames enumerateObjectsUsingBlock:^(NSString *property, __unused NSUInteger idx, __unused BOOL *stop) {
                [mutableXMLString appendFormat:@"<%@/>", property];
            }];
        } else {
            /**
             add by OYXJ, considering that: XML Namespace not always 'D'
             
             [mutableXMLString appendString:@"<D:allprop/>"];
             */
            [mutableXMLString appendString:[NSString stringWithFormat:@"<%@:allprop/>", self.defaultAbbreviationOfXMLnamespaces?:@"D"]];
        }

        /**
         add by OYXJ, considering that: XML Namespace not always 'D'
         
         [mutableXMLString appendString:@"</D:propfind>"];
         */
        [mutableXMLString appendString:[NSString stringWithFormat:@"</%@:propfind>", self.defaultAbbreviationOfXMLnamespaces?:@"D"]];
    }

    /**
     fix bug by OYXJ: request's params `URLString` become nil, when `self.baseURL` is init with nil (or never get init at all).
     
     NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"PROPFIND" URLString:[[self.baseURL URLByAppendingPathComponent:URLString] absoluteString] parameters:nil error:nil];
     */
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"PROPFIND" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];
    
	[request setValue:AFWebDAVStringForDepth(depth) forHTTPHeaderField:@"Depth"];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[mutableXMLString dataUsingEncoding:NSUTF8StringEncoding]];
    if (tokenDic.count == 1) {//token
        [tokenDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }

#if defined( DEBUG )
    // TODO: test code
    // [request setValue:@"example.domain.com" forHTTPHeaderField:@"host"];
#endif
    
    /*
     replaced with NSURLSessionDataTask by OYXJ on 2016.08.08
     
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self.operationQueue addOperation:operation];
     
     return operation;
    */
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self dataTaskWithRequest: request
                       completionHandler: ^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                           
                           if (error) {
                               if (failure) {
                                   failure(dataTask, error);
                               }
                           } else {
                               if (success) {
                                   success(dataTask, responseObject);
                               }
                           }
                           
                       }];
    [dataTask resume];
    
    return dataTask;
}

/**
 GET
 
 @param URLString <#URLString description#>
 @param tokenDic  <#tokenDic description#>
 
 @return <#return value description#>
 
 add by OYXJ on 2016.10
 */
- (NSURLSessionDataTask *)GET:(NSString *)URLString
                     tokenDic:(NSDictionary<NSString *, NSString *>  *)tokenDic  //e.g. @{@"token", tokenStr}
                     dataType:(NSString *)dataType   //数据类型
                     pathList:(NSArray<NSString *> *)pathsToGet  //数据路径
                        depth:(AFWebDAVDepth)depth
                      success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSDictionary *parameters = nil;
    void (^uploadProgressBlock)(NSProgress *uploadProgress) = nil;
    void (^downloadProgressBlock)(NSProgress *downloadProgress) = nil;
    
    
//    NSMutableString *mutableXMLString = [NSMutableString stringWithString:AFWebDAVXMLDeclarationString];
//    {
//        /**
//         add by OYXJ, considering that: XML Namespace not always 'D'
//         
//         [mutableXMLString appendString:[NSString stringWithFormat:@"<D:%@-get", dataType]];
//         */
//        [mutableXMLString appendString:[NSString stringWithFormat:@"<%@:%@-get", self.defaultAbbreviationOfXMLnamespaces?:@"D", dataType]];
//        [self.namespacesKeyedByAbbreviation enumerateKeysAndObjectsUsingBlock:^(NSString *abbreviation, NSString *namespace, __unused BOOL *stop) {
//            if (abbreviation.length > 0) {//天坑，补一下。
//                [mutableXMLString appendFormat:@" xmlns:%@=\"%@\"", abbreviation, namespace];
//            }else{//天坑，补一下。
//                [mutableXMLString appendFormat:@" xmlns=\"%@\"", namespace];
//            }
//        }];
//        [mutableXMLString appendString:@">"];
//        
//        /*
//        if (propertiesToGet) {
//            [mutableXMLString appendString:@"<prop>"];
//            {
//                [propertiesToGet enumerateObjectsUsingBlock:^(NSString *property, __unused NSUInteger idx, __unused BOOL *stop) {
//                    [mutableXMLString appendFormat:@"<%@/>", property];
//                }];
//            }
//            [mutableXMLString appendString:@"</prop>"];
//        }
//        */
//        
//        if (pathsToGet) {
//            {
//                [pathsToGet enumerateObjectsUsingBlock:^(NSString *path, NSUInteger idx, BOOL * _Nonnull stop) {
//                    [mutableXMLString appendString:@"<href>"];
//                    [mutableXMLString appendString:path];
//                    [mutableXMLString appendString:@"</href>"];
//                }];
//            }
//        }
//        
//        /**
//         add by OYXJ, considering that: XML Namespace not always 'D'
//         
//         [mutableXMLString appendString:[NSString stringWithFormat:@"</D:%@-get>",dataType]];
//         */
//        [mutableXMLString appendString:[NSString stringWithFormat:@"</%@:%@-get>", self.defaultAbbreviationOfXMLnamespaces?:@"D", dataType]];
//    }

//    LELOGD(@"mutableXMLString-----%@",mutableXMLString);
    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.requestSerializer
                                    requestWithMethod: @"GET"
                                    URLString: [[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString]
                                    parameters: parameters
                                    error: &serializationError];
    if (serializationError) {
        if (failure) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
                failure(nil, serializationError);
            });
#pragma clang diagnostic pop
        }
        
        return nil;
    }
    
    
    
    [request setValue:AFWebDAVStringForDepth(depth) forHTTPHeaderField:@"Depth"];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
//    [request setHTTPBody:[mutableXMLString dataUsingEncoding:NSUTF8StringEncoding]];
    if (tokenDic.count == 1) {//token
        [tokenDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }
    
#if defined( DEBUG )
    // TODO: test code
    // [request setValue:@"example.domain.com" forHTTPHeaderField:@"host"];
#endif
    
    
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self dataTaskWithRequest: request
                          uploadProgress: uploadProgressBlock
                        downloadProgress: downloadProgressBlock
                       completionHandler: ^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                           if (error) {
                               if (failure) {
                                   failure(dataTask, error);
                               }
                           } else {
                               if (success) {
                                   success(dataTask, responseObject);
                               }
                           }
                           LELOGD(@"GETresponse--%@\nresponseObject--%@\nerror--%@",response,responseObject,error);
                       }];
    
    [dataTask resume];
    
    return dataTask;
}


/**
 *  获取完整的数据
 *
 *  @param URLString 服务器地址
 *  @param tokenDic  用户token
 *
 *  @return NSURLSessionDataTask*
 
 modify by OYXJ on 2016.08
 */
- (NSURLSessionDataTask *)REPORT:(NSString *)URLString
                        tokenDic:(NSDictionary<NSString*,NSString*> *)tokenDic  //e.g. @{"token", tokenStr};
                        dataType:(NSString *)dataType   //数据类型
                   propertyNames:(NSArray<NSString *>  *)propertiesToGet  //要获取的数据项
                        pathList:(NSArray<NSString *>  *)pathsToGet //数据路径
                           depth:(AFWebDAVDepth)depth
                         success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                         failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSMutableString *mutableXMLString = [NSMutableString stringWithString:AFWebDAVXMLDeclarationString];
    {
        /**
         add by OYXJ, considering that: XML Namespace not always 'D'
         
         [mutableXMLString appendString:[NSString stringWithFormat:@"<D:%@-multiget", dataType]];
         */
        [mutableXMLString appendString:[NSString stringWithFormat:@"<%@:%@-multiget", self.defaultAbbreviationOfXMLnamespaces?:@"D", dataType]];
        [self.namespacesKeyedByAbbreviation enumerateKeysAndObjectsUsingBlock:^(NSString *abbreviation, NSString *namespace, __unused BOOL *stop) {
            if (abbreviation.length > 0) {//天坑，补一下。
                [mutableXMLString appendFormat:@" xmlns:%@=\"%@\"", abbreviation, namespace];
            }else{//天坑，补一下。
                [mutableXMLString appendFormat:@" xmlns=\"%@\"", namespace];
            }
        }];
        [mutableXMLString appendString:@">"];
        
        if (propertiesToGet) {
            [mutableXMLString appendString:@"<prop>"];
            {
                [propertiesToGet enumerateObjectsUsingBlock:^(NSString *property, __unused NSUInteger idx, __unused BOOL *stop) {
                    [mutableXMLString appendFormat:@"<%@/>", property];
                }];
            }
            [mutableXMLString appendString:@"</prop>"];
        }
        
        if (pathsToGet) {
            {
                [pathsToGet enumerateObjectsUsingBlock:^(NSString *path, NSUInteger idx, BOOL * _Nonnull stop) {
                    [mutableXMLString appendString:@"<href>"];
                    [mutableXMLString appendString:path];
                    [mutableXMLString appendString:@"</href>"];
                }];
            }
        }
        
        /**
         add by OYXJ, considering that: XML Namespace not always 'D'
         
         [mutableXMLString appendString:[NSString stringWithFormat:@"</D:%@-multiget>",dataType]];
         */
        [mutableXMLString appendString:[NSString stringWithFormat:@"</%@:%@-multiget>", self.defaultAbbreviationOfXMLnamespaces?:@"D", dataType]];
    }
    
   
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"REPORT" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];
    
    [request setValue:AFWebDAVStringForDepth(depth) forHTTPHeaderField:@"Depth"];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[mutableXMLString dataUsingEncoding:NSUTF8StringEncoding]];
    if (tokenDic.count == 1) {//token
        [tokenDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }

#if defined( DEBUG )
    // TODO: test code
    // [request setValue:@"example.domain.com" forHTTPHeaderField:@"host"];
#endif
    
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self dataTaskWithRequest: request
                       completionHandler: ^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                           
                           if (error) {
                               if (failure) {
                                   failure(dataTask, error);
                               }
                           } else {
                               if (success) {
                                   success(dataTask, responseObject);
                               }
                           }
                           
                       }];
    [dataTask resume];
    
    return dataTask;
}




/*
 replaced with NSURLSessionDataTask by OYXJ on 2016.08.08
 
- (AFHTTPRequestOperation *)PROPPATCH:(NSString *)URLString
                                  set:(NSDictionary *)propertiesToSet
                               remove:(NSArray *)propertiesToRemove
                              success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
 */
- (NSURLSessionDataTask *)PROPPATCH:(NSString *)URLString
                                set:(NSDictionary *)propertiesToSet
                             remove:(NSArray *)propertiesToRemove
                            success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                            failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSMutableString *mutableXMLString = [NSMutableString stringWithString:AFWebDAVXMLDeclarationString];
    {
        /**
         add by OYXJ, considering that: XML Namespace not always 'D'
         
         [mutableXMLString appendString:@"<D:propertyupdate"];
         */
        [mutableXMLString appendString:[NSString stringWithFormat:@"<%@:propertyupdate", self.defaultAbbreviationOfXMLnamespaces?:@"D"]];
        [self.namespacesKeyedByAbbreviation enumerateKeysAndObjectsUsingBlock:^(NSString *abbreviation, NSString *namespace, __unused BOOL *stop) {
            if (abbreviation.length > 0) {//天坑，补一下。
                [mutableXMLString appendFormat:@" xmlns:%@=\"%@\"", abbreviation, namespace];
            }else{//天坑，补一下。
                [mutableXMLString appendFormat:@" xmlns=\"%@\"", namespace];
            }
        }];
        [mutableXMLString appendString:@">"];

        if (propertiesToSet) {
            /**
             add by OYXJ, considering that: XML Namespace not always 'D'
             
             [mutableXMLString appendString:@"<D:set>"];
             */
            [mutableXMLString appendString:[NSString stringWithFormat:@"<%@:set>", self.defaultAbbreviationOfXMLnamespaces?:@"D"]];
            {
                [propertiesToSet enumerateKeysAndObjectsUsingBlock:^(NSString *property, id value, __unused BOOL *stop) {
                    [mutableXMLString appendFormat:@"<%@>", property];
                    [mutableXMLString appendString:[value description]];
                    [mutableXMLString appendFormat:@"</%@>", property];
                }];
            }
            /**
             add by OYXJ, considering that: XML Namespace not always 'D'
             
             [mutableXMLString appendString:@"</D:set>"];
             */
            [mutableXMLString appendString:[NSString stringWithFormat:@"</%@:set>", self.defaultAbbreviationOfXMLnamespaces?:@"D"]];
        }

        if (propertiesToRemove) {
            /**
             add by OYXJ, considering that: XML Namespace not always 'D'
             
             [mutableXMLString appendString:@"<D:remove>"];
             */
            [mutableXMLString appendString:[NSString stringWithFormat:@"<%@:remove>", self.defaultAbbreviationOfXMLnamespaces?:@"D"]];
            {
                [propertiesToRemove enumerateObjectsUsingBlock:^(NSString *property, __unused NSUInteger idx, __unused BOOL *stop) {
                    /**
                     add by OYXJ, considering that: XML Namespace not always 'D'
                     
                     [mutableXMLString appendFormat:@"<D:prop><%@/></D:prop>", property];
                     */
                    [mutableXMLString appendString:[NSString stringWithFormat:@"<%@:prop><%@/></%@:prop>", self.defaultAbbreviationOfXMLnamespaces?:@"D", property, self.defaultAbbreviationOfXMLnamespaces?:@"D"]];
                }];
            }
            /**
             add by OYXJ, considering that: XML Namespace not always 'D'
             
             [mutableXMLString appendString:@"</D:remove>"];
             */
            [mutableXMLString appendString:[NSString stringWithFormat:@"</%@:remove>", self.defaultAbbreviationOfXMLnamespaces?:@"D"]];
        }

        /**
         add by OYXJ, considering that: XML Namespace not always 'D'
         
         [mutableXMLString appendString:@"</D:propertyupdate>"];
         */
        [mutableXMLString appendString:[NSString stringWithFormat:@"</%@:propertyupdate>", self.defaultAbbreviationOfXMLnamespaces?:@"D"]];
    }

    /**
     fix bug by OYXJ: request's params `URLString` become nil, when `self.baseURL` is init with nil (or never get init at all).
     
     NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"PROPPATCH" URLString:[[self.baseURL URLByAppendingPathComponent:URLString] absoluteString] parameters:nil error:nil];
     */
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"PROPPATCH" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];
    
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[mutableXMLString dataUsingEncoding:NSUTF8StringEncoding]];

    /*
     replaced with NSURLSessionDataTask by OYXJ on 2016.08.08
     
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self.operationQueue addOperation:operation];
    
    return operation;
    */
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self dataTaskWithRequest: request
                       completionHandler: ^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                           
                           if (error) {
                               if (failure) {
                                   failure(dataTask, error);
                               }
                           } else {
                               if (success) {
                                   success(dataTask, responseObject);
                               }
                           }
                           
                       }];
    [dataTask resume];
    
    return dataTask;
}

/*
 replaced with NSURLSessionDataTask by OYXJ on 2016.08.08
 
- (AFHTTPRequestOperation *)MKCOL:(NSString *)URLString
                          success:(void (^)(AFHTTPRequestOperation *operation, NSURLResponse *response))success
                          failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
 */
- (NSURLSessionDataTask *)MKCOL:(NSString *)URLString
                        success:(void (^)(NSURLSessionDataTask *task, NSURLResponse *response))success
                        failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    /**
     fix bug by OYXJ: request's params `URLString` become nil, when `self.baseURL` is init with nil (or never get init at all).
    
     NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"MKCOL" URLString:[[self.baseURL URLByAppendingPathComponent:URLString] absoluteString] parameters:nil error:nil];
     */
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"MKCOL" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];

    /*
     replaced with NSURLSessionDataTask by OYXJ on 2016.08.08
     
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self.operationQueue addOperation:operation];

    return operation;
    */
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self dataTaskWithRequest: request
                       completionHandler: ^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                           
                           if (error) {
                               if (failure) {
                                   failure(dataTask, error);
                               }
                           } else {
                               if (success) {
                                   success(dataTask, responseObject);
                               }
                           }
                           
                       }];
    [dataTask resume];
    
    return dataTask;
}

/*
 replaced with NSURLSessionDataTask by OYXJ on 2016.08.08
 
- (AFHTTPRequestOperation *)COPY:(NSString *)sourceURLString
                     destination:(NSString *)destinationURLString
                       overwrite:(BOOL)overwrite
                      conditions:(NSString *)IfHeaderFieldValue
                         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
 */
- (NSURLSessionDataTask *)COPY:(NSString *)sourceURLString
                   destination:(NSString *)destinationURLString
                     overwrite:(BOOL)overwrite
                    conditions:(NSString *)IfHeaderFieldValue
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    /**
     fix bug by OYXJ: request's params `URLString` become nil, when `self.baseURL` is init with nil (or never get init at all).
     
     NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"COPY" URLString:[[self.baseURL URLByAppendingPathComponent:sourceURLString] absoluteString] parameters:nil error:nil];
     */
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"COPY" URLString:[[NSURL URLWithString:sourceURLString relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];
    
    /**
     fix bug by OYXJ: request's params `URLString` become nil, when `self.baseURL` is init with nil (or never get init at all).
     
     [request setValue:[[self.baseURL URLByAppendingPathComponent:destinationURLString] absoluteString] forHTTPHeaderField:@"Destination"];
     */
    [request setValue:[[NSURL URLWithString:destinationURLString relativeToURL:self.baseURL] absoluteString] forHTTPHeaderField:@"Destination"];
    
    
    [request setValue:(overwrite ? @"T" : @"F") forHTTPHeaderField:@"Overwrite"];
    if (IfHeaderFieldValue) {
        [request setValue:IfHeaderFieldValue forHTTPHeaderField:@"If"];
    }

    /*
     replaced with NSURLSessionDataTask by OYXJ on 2016.08.08
     
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self.operationQueue addOperation:operation];

    return operation;
    */
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self dataTaskWithRequest: request
                       completionHandler: ^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                           
                           if (error) {
                               if (failure) {
                                   failure(dataTask, error);
                               }
                           } else {
                               if (success) {
                                   success(dataTask, responseObject);
                               }
                           }
                           
                       }];
    [dataTask resume];
    
    return dataTask;
}

/*
 replaced with NSURLSessionDataTask by OYXJ on 2016.08.08

- (AFHTTPRequestOperation *)MOVE:(NSString *)sourceURLString
                     destination:(NSString *)destinationURLString
                       overwrite:(BOOL)overwrite
                      conditions:(NSString *)IfHeaderFieldValue
                         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
 */
- (NSURLSessionDataTask *)MOVE:(NSString *)sourceURLString
                   destination:(NSString *)destinationURLString
                     overwrite:(BOOL)overwrite
                    conditions:(NSString *)IfHeaderFieldValue
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    /**
     fix bug by OYXJ: request's params `URLString` become nil, when `self.baseURL` is init with nil (or never get init at all).
     
     NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"MOVE" URLString:[[self.baseURL URLByAppendingPathComponent:sourceURLString] absoluteString] parameters:nil error:nil];
     */
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"MOVE" URLString:[[NSURL URLWithString:sourceURLString relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];
    
    /**
     fix bug by OYXJ: request's params `URLString` become nil, when `self.baseURL` is init with nil (or never get init at all).
     
     [request setValue:[[self.baseURL URLByAppendingPathComponent:destinationURLString] absoluteString] forHTTPHeaderField:@"Destination"];
     */
    [request setValue:[[NSURL URLWithString:destinationURLString relativeToURL:self.baseURL] absoluteString] forHTTPHeaderField:@"Destination"];
    
    [request setValue:(overwrite ? @"T" : @"F") forHTTPHeaderField:@"Overwrite"];
    if (IfHeaderFieldValue) {
        [request setValue:IfHeaderFieldValue forHTTPHeaderField:@"If"];
    }

    /*
     replaced with NSURLSessionDataTask by OYXJ on 2016.08.08
     
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self.operationQueue addOperation:operation];

    return operation;
    */
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self dataTaskWithRequest: request
                       completionHandler: ^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                           
                           if (error) {
                               if (failure) {
                                   failure(dataTask, error);
                               }
                           } else {
                               if (success) {
                                   success(dataTask, responseObject);
                               }
                           }
                           
                       }];
    [dataTask resume];
    
    return dataTask;
}


/*
 replaced with NSURLSessionDataTask by OYXJ on 2016.08.08
 
- (AFHTTPRequestOperation *)LOCK:(NSString *)URLString
                         timeout:(NSTimeInterval)timeoutInterval
                           depth:(AFWebDAVDepth)depth
                           scope:(AFWebDAVLockScope)scope
                            type:(AFWebDAVLockType)type
                           owner:(NSURL *)ownerURL
                         success:(void (^)(AFHTTPRequestOperation *operation, NSString *lockToken))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
 */
- (NSURLSessionDataTask *)LOCK:(NSString *)URLString
                       timeout:(NSTimeInterval)timeoutInterval
                         depth:(AFWebDAVDepth)depth
                         scope:(AFWebDAVLockScope)scope
                          type:(AFWebDAVLockType)type
                         owner:(NSURL *)ownerURL
                       success:(void (^)(NSURLSessionDataTask *task, NSString *lockToken))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSMutableString *mutableXMLString = [NSMutableString stringWithString:AFWebDAVXMLDeclarationString];
    {
        /**
         add by OYXJ, considering that: XML Namespace not always 'D'
         
         [mutableXMLString appendString:@"<D:lockinfo"];
         */
        [mutableXMLString appendString:[NSString stringWithFormat:@"<%@:lockinfo", self.defaultAbbreviationOfXMLnamespaces?:@"D"]];
        [self.namespacesKeyedByAbbreviation enumerateKeysAndObjectsUsingBlock:^(NSString *abbreviation, NSString *namespace, __unused BOOL *stop) {
            if (abbreviation.length > 0) {//天坑，补一下。
                [mutableXMLString appendFormat:@" xmlns:%@=\"%@\"", abbreviation, namespace];
            }else{//天坑，补一下。
                [mutableXMLString appendFormat:@" xmlns=\"%@\"", namespace];
            }
        }];
        [mutableXMLString appendString:@">"];

        /**
         add by OYXJ, considering that: XML Namespace not always 'D'
         
         [mutableXMLString appendFormat:@"<D:lockscope><D:%@/></D:lockscope>", AFWebDAVStringForLockScope(scope)];
         */
        [mutableXMLString appendString:[NSString stringWithFormat:@"<%@:lockscope><%@:%@/></%@:lockscope>",
                                        self.defaultAbbreviationOfXMLnamespaces?:@"D",
                                        self.defaultAbbreviationOfXMLnamespaces?:@"D",AFWebDAVStringForLockScope(scope),
                                        self.defaultAbbreviationOfXMLnamespaces?:@"D"]];
        
        /**
         add by OYXJ, considering that: XML Namespace not always 'D'
         
         [mutableXMLString appendFormat:@"<D:locktype><D:%@/></D:locktype>", AFWebDAVStringForLockType(type)];
         */
        [mutableXMLString appendString:[NSString stringWithFormat:@"<%@:locktype><%@:%@/></%@:locktype>",
                                        self.defaultAbbreviationOfXMLnamespaces?:@"D",
                                        self.defaultAbbreviationOfXMLnamespaces?:@"D",AFWebDAVStringForLockType(type),
                                        self.defaultAbbreviationOfXMLnamespaces?:@"D"]];
        if (ownerURL) {
            /**
             add by OYXJ, considering that: XML Namespace not always 'D'
             
             [mutableXMLString appendFormat:@"<D:owner><D:href>%@</D:href></D:owner>", [ownerURL absoluteString]];
             */
            [mutableXMLString appendString:[NSString stringWithFormat:@"<%@:owner><%@:href>%@</%@:href></%@:owner>",
                                            self.defaultAbbreviationOfXMLnamespaces?:@"D",
                                            self.defaultAbbreviationOfXMLnamespaces?:@"D",
                                            [ownerURL absoluteString],
                                            self.defaultAbbreviationOfXMLnamespaces?:@"D",
                                            self.defaultAbbreviationOfXMLnamespaces?:@"D"]];
        }

        /**
         add by OYXJ, considering that: XML Namespace not always 'D'
         
         [mutableXMLString appendString:@"</D:lockinfo>"];
         */
        [mutableXMLString appendString:[NSString stringWithFormat:@"</%@:lockinfo>", self.defaultAbbreviationOfXMLnamespaces?:@"D"]];
    }

    /**
     fix bug by OYXJ: request's params `URLString` become nil, when `self.baseURL` is init with nil (or never get init at all).
     
     NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"LOCK" URLString:[[self.baseURL URLByAppendingPathComponent:URLString] absoluteString] parameters:nil error:nil];
     */
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"LOCK" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];
    
    [request setValue:AFWebDAVStringForDepth(depth) forHTTPHeaderField:@"Depth"];
    if (timeoutInterval > 0) {
        [request setValue:[@(timeoutInterval) stringValue] forHTTPHeaderField:@"Timeout"];
    }

    /*
     replaced with NSURLSessionDataTask by OYXJ on 2016.08.08
     
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self.operationQueue addOperation:operation];

    return operation;
    */
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self dataTaskWithRequest: request
                       completionHandler: ^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                           
                           if (error) {
                               if (failure) {
                                   failure(dataTask, error);
                               }
                           } else {
                               if (success) {
                                   success(dataTask, responseObject);
                               }
                           }
                           
                       }];
    [dataTask resume];
    
    return dataTask;
}

/*
 replaced with NSURLSessionDataTask by OYXJ on 2016.08.08
 
- (AFHTTPRequestOperation *)UNLOCK:(NSString *)URLString
                             token:(NSString *)lockToken
                           success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
 */
- (NSURLSessionDataTask *)UNLOCK:(NSString *)URLString
                           token:(NSString *)lockToken
                         success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                         failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    /**
     fix bug by OYXJ: request's params `URLString` become nil, when `self.baseURL` is init with nil (or never get init at all).
     
     NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"UNLOCK" URLString:[[self.baseURL URLByAppendingPathComponent:URLString] absoluteString] parameters:nil error:nil];
     */
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"UNLOCK" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];
    
    [request setValue:lockToken forHTTPHeaderField:@"Lock-Token"];

    /*
     replaced with NSURLSessionDataTask by OYXJ on 2016.08.08
     
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self.operationQueue addOperation:operation];

    return operation;
    */
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self dataTaskWithRequest: request
                       completionHandler: ^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                           
                           if (error) {
                               if (failure) {
                                   failure(dataTask, error);
                               }
                           } else {
                               if (success) {
                                   success(dataTask, responseObject);
                               }
                           }
                           
                       }];
    [dataTask resume];
    
    return dataTask;
}

@end

#pragma mark -

@implementation AFWebDAVRequestSerializer

@end

@implementation AFWebDAVSharePointRequestSerializer

#pragma mark - AFURLResponseSerializer

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error
{
    NSMutableURLRequest *mutableRequest = [[super requestBySerializingRequest:request withParameters:parameters error:error] mutableCopy];
    NSString *unescapedURLString = CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (__bridge CFStringRef)([[request URL] absoluteString]), NULL, kCFStringEncodingASCII));
    mutableRequest.URL = [NSURL URLWithString:unescapedURLString];

    return mutableRequest;
}

@end

#pragma mark -

@implementation AFWebDAVMultiStatusResponseSerializer

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"application/xml", @"text/xml", nil];
    self.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:207];

    return self;
}

#pragma mark - AFURLResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        return nil;
    }

    NSMutableArray *mutableResponses = [NSMutableArray array];

    ONOXMLDocument *XMLDocument = [ONOXMLDocument XMLDocumentWithData:data error:error];
    for (ONOXMLElement *element in [XMLDocument.rootElement childrenWithTag:@"response"]) {
        AFWebDAVMultiStatusResponse *memberResponse = [[AFWebDAVMultiStatusResponse alloc] initWithResponseElement:element];
        if (memberResponse) {
            [mutableResponses addObject:memberResponse];
        }
    }

    return [NSArray arrayWithArray:mutableResponses];
}

@end

#pragma mark -

@interface AFWebDAVMultiStatusResponse ()
@property (readwrite, nonatomic, assign, getter=isCollection) BOOL collection;
@property (readwrite, nonatomic, assign) NSUInteger contentLength;
@property (readwrite, nonatomic, copy) NSDate *creationDate;
@property (readwrite, nonatomic, copy) NSDate *lastModifiedDate;


//! add by OYXJ, used to retrieve some wanted data of XML.
@property (readwrite, nonatomic, strong) ONOXMLElement *element;//strong


/**
 begin --- 实现协议 WebDavResource --- begin
 */

//! The `etag` of the resource at the response URL.
@property(nonatomic, copy, readwrite) NSString *etag;

/**
 服务端资源的唯一id(主键)
 */
@property(nonatomic, copy, readwrite) NSString *name; // 相当于 source id

//@property(nonatomic, copy, readonly) NSString *ctag;

@property(nonatomic, strong, readwrite)NSDictionary<NSString*, NSString*> *customProps;

//private final Resourcetype resourceType; ???
//private final String contentType; ??? TODO::
//private final Long contentLength; ??? TODO::

@property(nonatomic, copy, readwrite) NSString *notedata;
@property(nonatomic, copy, readwrite) NSString *lastModified;
@property(nonatomic, copy, readwrite) NSString *deletedTime;
@property(nonatomic, copy, readwrite) NSString *deletedDataName;
@property(nonatomic, copy, readwrite) NSString *deleted;

/**
 end --- 实现协议 WebDavResource --- end
 */



@end



@implementation AFWebDAVMultiStatusResponse

// by OYXJ
NSString * const getcontentlengthCONST = @"getcontentlength";
NSString * const creationdateCONST = @"creationdate";
NSString * const getlastmodifiedCONST = @"getlastmodified";
NSString * const getetagCONST = @"getetag";//实现协议 WebDavResource

// 实现协议 WebDavResource
NSString * const resourcetypeCONST = @"resourcetype";
NSString * const getcontenttypeCONST = @"getcontenttype";
NSString * const notedataCONST = @"notedata";
NSString * const getDeletedTimeCONST = @"getDeletedTime";
NSString * const getDeletedDataNameCONST = @"getDeletedDataName";
NSString * const getDeletedCONST = @"getDeleted";


#pragma mark - init

- (instancetype)initWithResponseElement:(ONOXMLElement *)element {
    NSParameterAssert(element);

    
    /*
     <d:response>
        <d:href>/sync/chatcontacts/f5187830e27a4120bd17107c62011ba5</d:href>
        <d:propstat>
            <d:prop>
                <d:getetag>W/"db3b4d0b9c05509d3967a56b4a0a0353"</d:getetag>
                <x2:chatcontacts-data xmlns:x2="urn:ietf:params:xml:ns:webdav">{"source_id":"f5187830e27a4120bd17107c62011ba5","display_name":"vhs","phone_number":"13716750071#13716750075","is_voip_number":"1","account_phone_number":"13661248236","contact_type":0,"contact_from":0,"device_id":"--866647020047438"}</x2:chatcontacts-data>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
        </d:propstat>
     </d:response>
     */
    

    /**
     WebDav Response Namespace not always 'D'
     Ref.:  https://github.com/BitSuites/AFWebDAVManager/commit/c25abdb71e07897212b44212e2d854e744a64048
     rocket0423 committed on 10 Jul 2015
     1 parent 45504c7 commit c25abdb71e07897212b44212e2d854e744a64048
     
     NSString *href = [[element firstChildWithTag:@"href" inNamespace:@"D"] stringValue];
     NSInteger status = [[[element firstChildWithTag:@"status" inNamespace:@"D"] numberValue] integerValue];
     */
    NSString *href = [[element firstChildWithTag:@"href"] stringValue];
    NSInteger status = [[[element firstChildWithTag:@"status"] numberValue] integerValue];
    
    if (status == 0) {//[begin] fix bug: ｀status code｀ not found in firstChild element.
        NSString *statusString = [[[element firstChildWithTag:@"propstat"] firstChildWithTag:@"status"] stringValue];
        statusString = [statusString stringByReplacingOccurrencesOfString:@"HTTP/1.1" withString:@""];
        statusString = [statusString stringByTrimmingCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];
        statusString = [statusString stringByTrimmingCharactersInSet:[NSCharacterSet letterCharacterSet]];
        statusString = [statusString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (statusString.length > 0) {
            if ([statusString integerValue] > 0) {
                status = [statusString integerValue];
            }
        }
    }//[end] fix bug: ｀status code｀ not found in firstChild element.
    
    
    self = [self initWithURL:[NSURL URLWithString:href] statusCode:status HTTPVersion:@"HTTP/1.1" headerFields:nil];
    {//element
        //TODO: A true deep copy  http://stackoverflow.com/questions/647260/deep-copying-an-nsarray
        self.element = element;//strong reference
        {//解析数据---begin//
            NSDictionary *atts = [element attributes];
            if (atts.count > 0) {
                //开源库Ono
                self.customProps = atts;
            }else{
                //自己 解析数据
                ONOXMLElement *propElement = [[element firstChildWithTag:@"propstat"] firstChildWithTag:@"prop"];
                
                
                NSMutableDictionary<NSString*,NSString*> *proDic = [NSMutableDictionary dictionaryWithCapacity:2];
                
                NSArray<ONOXMLElement*> *childrenElements = [propElement children];
                for (int i = 0; i < childrenElements.count; i++) {
                    ONOXMLElement *e = childrenElements[i];
                    NSString *aTag = [e tag];
                    NSString *stringValue = [self valueOfTag: aTag
                                                   inElement: e];
                    if (aTag.length && stringValue.length) {
                        [proDic setObject:stringValue forKey:aTag];
                    }
                }
                
                DDLogVerbose(@"%@", proDic);
                
                self.customProps = proDic;
            }
        }//解析数据---end//
    }//element
    if (!self) {
        return nil;
    }

    ONOXMLElement *propElement = [[element firstChildWithTag:@"propstat"] firstChildWithTag:@"prop"];
    for (ONOXMLElement *resourcetypeElement in [propElement childrenWithTag:@"resourcetype"]) {
        if ([resourcetypeElement childrenWithTag:@"collection"].count > 0) {
            self.collection = YES;
            break;
        }
    }

    
    /**
     WebDav Response Namespace not always 'D'
     Ref.:  https://github.com/BitSuites/AFWebDAVManager/commit/c25abdb71e07897212b44212e2d854e744a64048
     rocket0423 committed on 10 Jul 2015
     1 parent 45504c7 commit c25abdb71e07897212b44212e2d854e744a64048
     
    self.contentLength = [[[propElement firstChildWithTag:@"getcontentlength" inNamespace:@"D"] numberValue] unsignedIntegerValue];
    self.creationDate = [[propElement firstChildWithTag:@"creationdate" inNamespace:@"D"] dateValue];
    self.lastModifiedDate = [[propElement firstChildWithTag:@"getlastmodified" inNamespace:@"D"] dateValue];
    */
    
    
    //by OYXJ
    NSString *ns = [propElement namespace];
    NSMutableArray<NSString*> *beginEndTAGs = [NSMutableArray arrayWithCapacity:2];
    NSArray * const tags = @[getcontentlengthCONST,creationdateCONST,getlastmodifiedCONST,getetagCONST];
    [tags enumerateObjectsUsingBlock:^(id  _Nonnull eachTag, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *beginTAG = [NSString stringWithFormat:@"<%@:%@>", ns,eachTag];
        NSString *endTAG  = [NSString stringWithFormat:@"</%@:%@>", ns,eachTag];
        [beginEndTAGs addObject: beginTAG];
        [beginEndTAGs addObject: endTAG];
    }];
    
    
    {//getcontentlength
        self.contentLength = [[[propElement firstChildWithTag:getcontentlengthCONST]
                               numberValue] unsignedIntegerValue];
        if (self.contentLength==0) {//by OYXJ
            NSMutableString *contentLengthSTR = [[[propElement firstChildWithTag:getcontentlengthCONST]
                                                 stringValue] mutableCopy];
            [beginEndTAGs enumerateObjectsUsingBlock:^(id  _Nonnull aTAG, NSUInteger idx, BOOL * _Nonnull stop) {
                [contentLengthSTR replaceOccurrencesOfString:aTAG
                                                  withString:@""
                                                     options:NSLiteralSearch
                                                       range:NSMakeRange(0, contentLengthSTR.length)];
            }];
            
            NSNumber *aContentLength = [propElement.document.numberFormatter numberFromString:contentLengthSTR];
            
            self.contentLength = [aContentLength unsignedIntegerValue];
        }
    }//getcontentlength
    
    {//creationdate
        self.creationDate = [[propElement firstChildWithTag:creationdateCONST] dateValue];
        if (self.creationDate==nil) {//by OYXJ
            NSMutableString *creationDateSTR = [[[propElement firstChildWithTag:creationdateCONST]
                                                 stringValue] mutableCopy];
            [beginEndTAGs enumerateObjectsUsingBlock:^(id  _Nonnull aTAG, NSUInteger idx, BOOL * _Nonnull stop) {
                [creationDateSTR replaceOccurrencesOfString:aTAG
                                                 withString:@""
                                                    options:NSLiteralSearch
                                                      range:NSMakeRange(0, creationDateSTR.length)];
            }];
            
            NSDate *aCreationDate = [propElement.document.dateFormatter dateFromString:creationDateSTR];
            if (aCreationDate==nil) {
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                //[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];//by OYXJ
                //[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];//by OYXJ
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];//by OYXJ
                
                aCreationDate = [dateFormatter dateFromString:creationDateSTR];
            }
            
            self.creationDate = aCreationDate;
        }
    }//creationdate
    
    
    {//getlastmodified
        self.lastModifiedDate = [[propElement firstChildWithTag:getlastmodifiedCONST] dateValue];
        if (self.lastModifiedDate==nil) {//by OYXJ
            NSMutableString *lastModifiedDateSTR = [[[propElement firstChildWithTag:getlastmodifiedCONST]
                                                     stringValue] mutableCopy];
            [beginEndTAGs enumerateObjectsUsingBlock:^(id  _Nonnull aTAG, NSUInteger idx, BOOL * _Nonnull stop) {
                [lastModifiedDateSTR replaceOccurrencesOfString:aTAG
                                                     withString:@""
                                                        options:NSLiteralSearch
                                                          range:NSMakeRange(0, lastModifiedDateSTR.length)];
            }];
            
            NSDate *aLastModifiedDate = [propElement.document.dateFormatter dateFromString:lastModifiedDateSTR];
            if (aLastModifiedDate==nil) {
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                //[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];//by OYXJ
                //[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];//by OYXJ
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];//by OYXJ
                
                aLastModifiedDate = [dateFormatter dateFromString:lastModifiedDateSTR];
            }
            
            self.lastModifiedDate = aLastModifiedDate;
        }
    }//getlastmodified
    
    
    {//getetag
        NSMutableString *aEtagSTR = [[[propElement firstChildWithTag:getetagCONST]
                                     stringValue] mutableCopy];
        [beginEndTAGs enumerateObjectsUsingBlock:^(id  _Nonnull aTAG, NSUInteger idx, BOOL * _Nonnull stop) {
            [aEtagSTR replaceOccurrencesOfString:aTAG
                                      withString:@""
                                         options:NSLiteralSearch
                                           range:NSMakeRange(0, aEtagSTR.length)];
        }];
        
        self.etag = [aEtagSTR copy];
    }//getetag
    
    
    return self;
}


#pragma mark - private

/**
 根据标签名字，获取标签的值
 特别注意，标签的值，是String类型，才使用此方法。

 @param aTagNameCONST 标签名字，使用此类中定义的 常量字符串

 @return 标签的值
 */
- (NSString *)valueOfTag:(NSString *)aTagNameCONST inElement:(ONOXMLElement *)anElement
{
    if (aTagNameCONST.length <= 0) {
        return nil;
    }
    if (anElement == nil) {
        return nil;
    }
    
    NSString *returnStr = nil;
    @try {
        //Code that can potentially throw an exception
        
        NSMutableString *aTagValueSTR = [[anElement stringValue] mutableCopy];
        
        
        if ([aTagValueSTR rangeOfString:aTagNameCONST].location == NSNotFound) {
            // do nothing here !
        }else{
        
            NSString *ns = [anElement namespace];
            NSMutableArray *beginEndTAGs = [NSMutableArray arrayWithCapacity:1];
            [@[aTagNameCONST] enumerateObjectsUsingBlock:^(id  _Nonnull eachTag, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *beginTAG = [NSString stringWithFormat:@"<%@:%@>", ns,eachTag];
                NSString *endTAG  = [NSString stringWithFormat:@"</%@:%@>", ns,eachTag];
                [beginEndTAGs addObject: beginTAG];
                [beginEndTAGs addObject: endTAG];
            }];
            
            [beginEndTAGs enumerateObjectsUsingBlock:^(id  _Nonnull aTAG, NSUInteger idx, BOOL * _Nonnull stop) {
                [aTagValueSTR replaceOccurrencesOfString:aTAG
                                              withString:@""
                                                 options:NSLiteralSearch
                                                   range:NSMakeRange(0, aTagValueSTR.length)];
            }];
        }
        
        returnStr = [aTagValueSTR copy];
        
    } @catch (NSException *exception) {
        //Handle an exception thrown in the @try block
        
        NSLog(@"%@", exception);
        
    } @finally {
        //Code that gets executed whether or not an exception is thrown
        
        return returnStr;
    }
    
}


#pragma mark - getters

- (NSString *)etag
{
    return _etag;
}

/**
 服务端资源的唯一id(主键)
 相当于 source id
 */
- (NSString *)name
{
    if (nil==_name) {
        _name = self.URL.absoluteString.lastPathComponent ?: self.URL.absoluteString;
    }
    
    return _name;
}

//- (NSString *)ctag
//{
//    return _ctag;
//}

- (NSDictionary<NSString*,NSString*> *)customProps
{
    return _customProps;
}

//private final Resourcetype resourceType; ???
//private final String contentType; ??? TODO::
//private final Long contentLength; ??? TODO::



- (NSString *)notedata
{
    if (nil==_notedata) {
        
        ONOXMLElement *propElement = [[self.element firstChildWithTag:@"propstat"] firstChildWithTag:@"prop"];
        _notedata = [self valueOfTag: notedataCONST
                           inElement: [propElement firstChildWithTag:notedataCONST]];
    }
    
    return _notedata;
}

- (NSString *)lastModified
{
    if (nil==_lastModified) {
        
        _lastModified = [self.lastModifiedDate description];
    }
    
    return _lastModified;
}

- (NSString *)deletedTime
{
    if (nil==_deletedTime) {
        
        ONOXMLElement *propElement = [[self.element firstChildWithTag:@"propstat"] firstChildWithTag:@"prop"];
        _deletedTime = [self valueOfTag: getDeletedTimeCONST
                              inElement: [propElement firstChildWithTag:getDeletedTimeCONST]];
    }
    
    return _deletedTime;
}

- (NSString *)deletedDataName
{
    if (nil==_deletedDataName) {
        
        ONOXMLElement *propElement = [[self.element firstChildWithTag:@"propstat"] firstChildWithTag:@"prop"];
        _deletedDataName = [self valueOfTag: getDeletedDataNameCONST
                                  inElement: [propElement firstChildWithTag:getDeletedDataNameCONST]];
    }
    
    return _deletedDataName;
}

- (NSString *)deleted
{
    if (nil==_deleted) {
        
        ONOXMLElement *propElement = [[self.element firstChildWithTag:@"propstat"] firstChildWithTag:@"prop"];
        _deleted = [self valueOfTag: getDeletedCONST
                          inElement: [propElement firstChildWithTag:getDeletedCONST]];
    }
    
    return _deleted;
}


@end

