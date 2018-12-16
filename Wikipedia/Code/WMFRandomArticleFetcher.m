#import <WMF/WMFRandomArticleFetcher.h>
#import <WMF/MWNetworkActivityIndicatorManager.h>
#import <WMF/WMFNumberOfExtractCharacters.h>
#import <WMF/UIScreen+WMFImageWidth.h>
#import <WMF/MWKSearchResult.h>
#import <WMF/WMF-Swift.h>
#import <WMF/WMFLegacySerializer.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFRandomArticleFetcher ()

@property (nonatomic, strong) WMFSession *session;

@end

@implementation WMFRandomArticleFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        self.session = [WMFSession shared];
    }
    return self;
}

- (void)fetchRandomArticleWithSiteURL:(NSURL *)siteURL completion:(void (^)(NSError *_Nullable error, MWKSearchResult *_Nullable result))completion {
    NSParameterAssert(siteURL);
    if (siteURL == nil) {
        NSError *error = [NSError wmf_errorWithType:WMFErrorTypeInvalidRequestParameters
                                           userInfo:nil];
        completion(error, nil);
        return;
    }

    NSDictionary *params = [[self class] params];
    NSURLComponents *components = [WMFConfiguration.current mediaWikiAPIURLComponentsForHost:siteURL.host withQueryParameters:params];

    [self.session getJSONDictionaryFromURL:components.URL
                               ignoreCache:YES
                         completionHandler:^(NSDictionary<NSString *, id> *_Nullable result, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
                             if (error) {
                                 completion(error, nil);
                                 return;
                             }

                             if (response.statusCode == 304) {
                                 NSError *error = [NSError wmf_errorWithType:WMFErrorTypeNoNewData userInfo:nil];
                                 completion(error, nil);
                                 return;
                             }

                             NSError *serializerError = nil;
                             
                             NSArray<MWKSearchResult *> *randomResults = [WMFLegacySerializer modelsOfClass:[MWKSearchResult class] fromAllValuesOfDictionaryForKeyPath:@"query.pages" inJSONDictionary:result error:&serializerError];
                             if (serializerError) {
                                 completion(serializerError, nil);
                                 return;
                             }

                             MWKSearchResult *article = [self getBestRandomResultFromResults:randomResults];

                             completion(nil, article);
                         }];
}

- (MWKSearchResult *)getBestRandomResultFromResults:(NSArray *)results {
    //Sort so random results with good extracts and images come first and disambiguation pages come last.
    NSSortDescriptor *extractSorter = [[NSSortDescriptor alloc] initWithKey:@"extract.length" ascending:NO];
    NSSortDescriptor *descripSorter = [[NSSortDescriptor alloc] initWithKey:@"wikidataDescription" ascending:NO];
    NSSortDescriptor *thumbSorter = [[NSSortDescriptor alloc] initWithKey:@"thumbnailURL.absoluteString" ascending:NO];
    NSSortDescriptor *disambigSorter = [[NSSortDescriptor alloc] initWithKey:@"isDisambiguation" ascending:YES];
    NSSortDescriptor *listSorter = [[NSSortDescriptor alloc] initWithKey:@"isList" ascending:YES];
    results = [results sortedArrayUsingDescriptors:@[disambigSorter, listSorter, thumbSorter, descripSorter, extractSorter]];
    return [results firstObject];
}

+ (NSDictionary *)params {
    NSNumber *numberOfRandomItemsToFetch = @8;
    return @{
        @"action": @"query",
        @"prop": @"extracts|description|pageimages|pageprops|revisions",
        //random
        @"generator": @"random",
        @"grnnamespace": @0,
        @"grnfilterredir": @"nonredirects",
        @"grnlimit": numberOfRandomItemsToFetch,
        // extracts
        @"exintro": @YES,
        @"exlimit": numberOfRandomItemsToFetch,
        @"explaintext": @"",
        @"exchars": @(WMFNumberOfExtractCharacters),
        // pageprops
        @"ppprop": @"displaytitle|disambiguation",
        // pageimage
        @"piprop": @"thumbnail",
        //@"pilicense": @"any",
        @"pithumbsize": [[UIScreen mainScreen] wmf_leadImageWidthForScale],
        @"pilimit": numberOfRandomItemsToFetch,
        // revision
        // @"rrvlimit": @(1),
        @"rvprop": @"ids",
        @"format": @"json",
    };
}

@end

NS_ASSUME_NONNULL_END
