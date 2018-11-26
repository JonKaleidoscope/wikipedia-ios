@import Foundation;
@import WebKit;

@class MWKArticle;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const WMFURLSchemeHandlerScheme;

@interface WMFURLSchemeHandler : NSObject <WKURLSchemeHandler>

@property (nonatomic, readonly, getter=isRunning) BOOL running;

+ (WMFURLSchemeHandler *)shared;

- (nullable NSString *)localFilePathForRelativeFilePath:(NSString *)relativeFilePath; //path for writing files to the file proxy's server

- (nullable NSURL *)proxyURLForRelativeFilePath:(NSString *)relativeFilePath fragment:(NSString *)fragment; //returns the proxy url for a given relative path

// Details: https://github.com/wikimedia/wikipedia-ios/pull/1334/commits/f2b2228e2c0fd852479464ec84e38183d1cf2922
- (nullable NSURL *)proxyURLForWikipediaAPIHost:(NSString *)host;

- (NSString *)stringByReplacingImageURLsWithProxyURLsInHTMLString:(NSString *)HTMLString withBaseURL:(nullable NSURL *)baseURL targetImageWidth:(NSUInteger)targetImageWidth; //replaces image URLs in an HTML string with URLs that will be routed through this proxy

- (void)setResponseData:(nullable NSData *)data withContentType:(nullable NSString *)contentType forPath:(NSString *)path requestURL:(NSURL *)requestURL;

- (void)cacheSectionDataForArticle:(MWKArticle *)article;

- (nullable NSURL *)articleSectionDataURLForArticleWithURL:(NSURL *)articleURL targetImageWidth:(NSInteger)targetImageWidth;

@end

NS_ASSUME_NONNULL_END
