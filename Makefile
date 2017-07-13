DEBUG = 0
PACKAGE_VERSION = 1.1.2
TARGET = iphone:8.0:5.0
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 5.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NoKeyPop
NoKeyPop_FILES = Tweak.xm
NoKeyPop_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp -R Resources $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/NoKeyPop$(ECHO_END)
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -name .DS_Store | xargs rm -rf$(ECHO_END)
