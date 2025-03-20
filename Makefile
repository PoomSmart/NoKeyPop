TARGET = iphone:clang:14.5:5.0
export PREFIX = $(THEOS)/toolchain/Xcode11.xctoolchain/usr/bin/

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NoKeyPop
$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp -R Resources $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/NoKeyPop$(ECHO_END)
