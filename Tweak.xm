#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AFNetworking/AFNetworking.h>
#import "Tweak.h"

@interface YTSlimVideoDetailsActionView (YDR)
@property (nonatomic, assign) NSInteger dislikeCount;
@end

static NSString *getNormalizedDislikes(NSString *dislikeCount) {
    if (dislikeCount == nil) {
        return @"Failed";
    }
    NSUInteger digits = dislikeCount.length;
    NSString *dislikeCountShort;
    if (digits <= 3) {
        dislikeCountShort = dislikeCount;
    }
    else if (digits == 4) {
        NSString *firstInt = [dislikeCount substringWithRange:NSMakeRange(0, 1)];
        NSString *secondInt = [dislikeCount substringWithRange:NSMakeRange(1, 1)];
        dislikeCountShort = [NSString stringWithFormat:@"%@.%@K", firstInt, secondInt];
    }
    else if (digits <= 6) {
        dislikeCountShort = [NSString stringWithFormat:@"%@K", [dislikeCount substringToIndex:digits - 3]];
    }
    else if (digits <= 8) {
        dislikeCountShort = [NSString stringWithFormat:@"%@M", [dislikeCount substringToIndex:digits - 6]];
    }
    else if (digits == 9) {
        dislikeCountShort = [NSString stringWithFormat:@"%@B", [dislikeCount substringToIndex:1]];
    }
    else {
        dislikeCountShort = [NSString stringWithFormat:@"%@B", [dislikeCount substringToIndex:2]];
    }
    return dislikeCountShort;
}

static void setDislikeCount(YTSlimVideoDetailsActionView *self, NSString *dislikeCount) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.label setFormattedString:[%c(YTIFormattedString) formattedStringWithString:dislikeCount]];
        [self.label sizeToFit];
    });
}

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
            YTISlimMetadataToggleButtonRenderer *meta = renderer.slimMetadataToggleButtonRenderer;
            NSString *videoIdentifier = meta.target.videoId;
            NSString *apiUrl = [NSString stringWithFormat:@"https://returnyoutubedislikeapi.com/votes?videoId=%@", videoIdentifier];
            NSURL *dataUrl = [NSURL URLWithString:apiUrl];
            NSURLRequest *apiRequest = [NSURLRequest requestWithURL:dataUrl];

            NSURLSessionConfiguration *dataConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
            AFURLSessionManager *dataManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:dataConfiguration];
            NSURLSessionDataTask *dataTask = [dataManager dataTaskWithRequest:apiRequest uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                if (error) {
                    setDislikeCount(self, @"Failed");
                } else {
                    NSString *dislikeCount = responseObject[@"dislikes"];
                    self.dislikeCount = [dislikeCount longLongValue];
                    NSString *dislikeCountShort = getNormalizedDislikes(dislikeCount);
                    setDislikeCount(self, dislikeCountShort);
                }
            }];
            [dataTask resume];
        }
    }
    return self;
}

- (void)setToggled:(BOOL)toggled {
    YTISlimMetadataButtonSupportedRenderers *renderer = [self valueForKey:@"_supportedRenderer"];
    if ([renderer slimButton_isDislikeButton]) {
        YTIToggleButtonRenderer *buttonRenderer = renderer.slimMetadataToggleButtonRenderer.button.toggleButtonRenderer;
        if (toggled) {
            NSString *newDislikeCount = getNormalizedDislikes([@(self.dislikeCount + 1) stringValue]);
            buttonRenderer.toggledText = [%c(YTIFormattedString) formattedStringWithString:newDislikeCount];
        } else {
            NSString *dislikeCount = getNormalizedDislikes([@(self.dislikeCount) stringValue]);
            buttonRenderer.defaultText = [%c(YTIFormattedString) formattedStringWithString:dislikeCount];
        }
    }
    %orig;
}
%end
