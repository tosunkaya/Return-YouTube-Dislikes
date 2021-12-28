TARGET := iphone:clang:14.4:13.0
INSTALL_TARGET_PROCESSES = YouTube
GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YouTubeDislikesReturn
YouTubeDislikesReturn_FILES = Tweak.xm $(shell find AFNetworking -name '*.m')
YouTubeDislikesReturn_CFLAGS = -fobjc-arc
YouTubeDislikesReturn_FRAMEWORKS = UIKit Foundation
ARCHS = arm64 arm64e

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
