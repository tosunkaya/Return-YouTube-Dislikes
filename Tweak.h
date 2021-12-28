#import <Foundation/Foundation.h>

@interface YTAppDelegate : UIResponder <UIApplicationDelegate>
@end

@interface YTSlimVideoScrollableDetailsActionsView : UIView
@end

@interface YTIFormattedString : NSObject
+ (instancetype)formattedStringWithString:(NSString *)string;
@end

@interface YTIFormattedStringLabel : UILabel
- (void)setFormattedString:(YTIFormattedString *)string;
@end

@interface YTQTMButton : UIButton
@end

@interface YTIToggleButtonRenderer : NSObject
@property (nonatomic, strong, readwrite) YTIFormattedString *defaultText;
@property (nonatomic, strong, readwrite) YTIFormattedString *toggledText;
@end

@interface YTIButtonSupportedRenderers : NSObject
@property (nonatomic, strong, readwrite) YTIToggleButtonRenderer *toggleButtonRenderer;
@end

@interface YTSlimVideoDetailsActionView : UIView
@property (nonatomic, strong, readwrite) YTIFormattedStringLabel *label;
- (instancetype)initWithSlimMetadataButtonSupportedRenderer:(id)renderer;
@end

@interface YTISlimMetadataToggleButtonRenderer : NSObject
@property (nonatomic, strong, readwrite) YTIButtonSupportedRenderers *button;
@end

@interface YTISlimMetadataButtonSupportedRenderers : NSObject
@property (nonatomic, strong, readwrite) YTISlimMetadataToggleButtonRenderer *slimMetadataToggleButtonRenderer;
- (BOOL)slimButton_isDislikeButton;
- (int)rendererOneOfCase;
@end

@interface YTLocalPlaybackController : NSObject
- (NSString *)currentVideoID;
@end
