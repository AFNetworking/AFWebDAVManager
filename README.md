# AFWebDAVManager

`AFWebDAVManager` is an `AFHTTPRequestOperationManager` subclass for interacting with the [WebDAV](http://en.wikipedia.org/wiki/WebDAV).

**Caution:** This code is still in its early stages of development, so exercise caution when incorporating this into production code.

## Example Usage

```objective-c
AFWebDAVManager *webDAVManager = [[AFWebDAVManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://example.com"]];
webDAVManager.credential = [NSURLCredential credentialWithUser:@"username"
                                                      password:@"Pa55word"
                                                   persistence:NSURLCredentialPersistenceForSession];

[webDAVManager createFileAtURLString:@"/path/to/file.txt"
         withIntermediateDirectories:YES
                            contents:[@"Hello, World" dataUsingEncoding:NSUTF8StringEncoding]
                   completionHandler:^(NSURL *fileURL, NSError *error)
{
    if (error) {
        NSLog(@"[Error] %@", error);
    } else {
        NSLog(@"File created: %@", fileURL);
    }
}];

[webDAVManager contentsOfDirectoryAtURLString:@"/path"
                                    recursive:NO
                            completionHandler:^(NSArray *items, NSError *error)
{
    if (error) {
        NSLog(@"[Error] %@", error);
    } else {
        NSLog(@"Items: %@", items);
    }
}];
```

## Contact

Mattt Thompson

- http://github.com/mattt
- http://twitter.com/mattt
- m@mattt.me

## License

AFWebDAVManager is available under the MIT license. See the LICENSE file for more info.
