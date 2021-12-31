#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AFNetworking/AFNetworking.h>
#import "Tweak.h"

@interface YTSlimVideoDetailsActionView (YDR)
@property (nonatomic, assign) NSInteger dislikeCount;
@end

static NSString *getXPointYFormat(NSString *count, char c) {
    char firstInt = [count characterAtIndex:0];
    char secondInt = [count characterAtIndex:1];
    if (secondInt == '0') {
        return [NSString stringWithFormat:@"%c%c", firstInt, c];
    }
    return [NSString stringWithFormat:@"%c.%c%c", firstInt, secondInt, c];
}

static NSString *getNormalizedDislikes(NSString *dislikeCount) {
    NSUInteger digits = dislikeCount.length;
    if (digits <= 3) { // 0 - 999
        return dislikeCount;
    }
    if (digits == 4) { // 1000 - 9999
        return getXPointYFormat(dislikeCount, 'K');
    }
    if (digits <= 6) { // 10_000 - 999_999
        return [NSString stringWithFormat:@"%@K", [dislikeCount substringToIndex:digits - 3]];
    }
    if (digits <= 9) { // 1_000_000 - 999_999_999
        return [NSString stringWithFormat:@"%@M", [dislikeCount substringToIndex:digits - 6]];
    }
    return [NSString stringWithFormat:@"%@B", [dislikeCount substringToIndex:digits - 9]]; // 1_000_000_000+
}

static void setDislikeCount(YTSlimVideoDetailsActionView *self, NSString *dislikeCount) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.label setFormattedString:[%c(YTIFormattedString) formattedStringWithString:dislikeCount]];
        [self.label sizeToFit];
    });
}

static void getDislikeFromVideoWithHandler(NSString *videoIdentifier, void (^handler)(NSString *dislikeCount)) {
    NSString *apiUrl = [NSString stringWithFormat:@"https://returnyoutubedislikeapi.com/votes?videoId=%@", videoIdentifier];
    NSURL *dataUrl = [NSURL URLWithString:apiUrl];
    NSURLRequest *apiRequest = [NSURLRequest requestWithURL:dataUrl];

    NSURLSessionConfiguration *dataConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *dataManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:dataConfiguration];
    NSURLSessionDataTask *dataTask = [dataManager dataTaskWithRequest:apiRequest uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        NSString *dislikeCount = error ? nil : [NSString stringWithFormat:@"%@", [responseObject objectForKey:@"dislikes"]];
        handler(dislikeCount);
    }];
    [dataTask resume];
}

YTLocalPlaybackController *playingVideoID;

%hook YTLocalPlaybackController
- (NSString *)currentVideoID {
    playingVideoID = self;
    return %orig;
}
%end

%hook YTAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"YouTube Dislikes Return Loaded Successfully");
    return %orig;
}
%end

%hook YTSlimVideoDetailsActionView
%property (nonatomic, assign) NSInteger dislikeCount;
+ (YTSlimVideoDetailsActionView *)actionViewWithSlimMetadataButtonSupportedRenderer:(YTISlimMetadataButtonSupportedRenderers *)renderer withElementsContextBlock:(id)block {
    if ([renderer rendererOneOfCase] == 153515154) {
        return [[%c(YTSlimVideoDetailsActionView) alloc] initWithSlimMetadataButtonSupportedRenderer:renderer];
    }
    return %orig;
}

- (id)initWithSlimMetadataButtonSupportedRenderer:(id)arg1 {
    self = %orig;
    if (self) {
        self.dislikeCount = -1;
        YTISlimMetadataButtonSupportedRenderers *renderer = [self valueForKey:@"_supportedRenderer"];
        if ([renderer slimButton_isDislikeButton]) {
            NSString *videoIdentifier = [playingVideoID currentVideoID];
            getDislikeFromVideoWithHandler(videoIdentifier, ^(NSString *dislikeCount) {
                if (dislikeCount != nil) {
                    self.dislikeCount = [dislikeCount longLongValue];
                    NSString *dislikeCountShort = getNormalizedDislikes(dislikeCount);
                    setDislikeCount(self, dislikeCountShort);
                } else {
                    setDislikeCount(self, @"Failed");
                }
        });
        }
    }
    return self;
}

- (void)setToggled:(BOOL)toggled {
    YTISlimMetadataButtonSupportedRenderers *renderer = [self valueForKey:@"_supportedRenderer"];
    if ([renderer slimButton_isDislikeButton]) {
        YTIToggleButtonRenderer *buttonRenderer = renderer.slimMetadataToggleButtonRenderer.button.toggleButtonRenderer;
        // FIXME: Ideally, the tweak should refetch the dislike number
        NSString *dislikeCount = getNormalizedDislikes([@(self.dislikeCount) stringValue]);
        YTIFormattedString *formattedText = [%c(YTIFormattedString) formattedStringWithString:dislikeCount];
        if (toggled) {
            buttonRenderer.toggledText = formattedText;
        } else {
            buttonRenderer.defaultText = formattedText;
        }
    }
    %orig;
}
%end

%hook YTReelWatchLikesController
- (void)updateLikeButtonWithRenderer:(YTILikeButtonRenderer *)renderer {
    %orig(renderer);
    getDislikeFromVideoWithHandler(renderer.target.videoId, ^(NSString *dislikeCount) {
        if (dislikeCount != nil) {
            NSString *formattedDislikeCount = getNormalizedDislikes(dislikeCount);
            YTIFormattedString *formattedText = [%c(YTIFormattedString) formattedStringWithString:formattedDislikeCount];
            if (renderer.hasDislikeCountText) {
                renderer.dislikeCountText = formattedText;
            }
            if (renderer.hasDislikeCountWithDislikeText) {
                renderer.dislikeCountWithDislikeText = formattedText;
            }
            if (renderer.hasDislikeCountWithUndislikeText) {
                renderer.dislikeCountWithUndislikeText = formattedText;
            }
        }
        %orig(renderer);
    });
}
%end
