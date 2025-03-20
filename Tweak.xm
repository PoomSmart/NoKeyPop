#define CHECK_TARGET
#import <PSHeader/PS.h>
#import "../../PSPrefs/PSPrefs.x"
#import <TextInput/TIKeyboardLayoutFactory.h> // What happened, Theos?
#import <UIKit/UIKBKeyView.h>
#import <UIKit/UIKBRenderConfig.h>
#import <UIKit/UIKBRenderFactoryiPhone.h>
#import <UIKit/UIKeyboardImpl.h>
#import <dlfcn.h>
#import <version.h>

BOOL override;
BOOL override2;
BOOL override3;

BOOL enabled;
BOOL highlight;
NSUInteger popupState = IS_IOS_OR_NEWER(iOS_7_0) ? 4 : 1;
NSUInteger normalState = IS_IOS_OR_NEWER(iOS_7_0) ? 2 : 4;

static BOOL stringKey(UIKBTree *key) {
    BOOL string = NO;
    if ([key respondsToSelector:@selector(_renderAsStringKey)])
        string = [key _renderAsStringKey];
    else if ([key respondsToSelector:@selector(renderAsStringKey)])
        string = [key renderAsStringKey];
    NSString *keyName = key.name;
    BOOL currency = [keyName rangeOfString:@"Currency-Sign"].location != NSNotFound;
    BOOL tag = [keyName isEqualToString:@"Primary-Tag-Symbol"] || [keyName isEqualToString:@"Alternate-Tag-Symbol"];
    BOOL domain = [keyName isEqualToString:@"Top-Level-Domain-Key"] || [keyName isEqualToString:@"Single-Domain-Key"] || [keyName isEqualToString:@"Email-Dot-Key"];
    return string || currency || tag || domain;
}

%group iOS7Up

%hook UIKBRenderTraits

- (void)setBlendForm: (NSInteger)form {
    if (override2) {
        %orig(1);
        override2 = NO;
    } else
        %orig;
}

%end

%hook UIKBRenderFactoryiPhone

- (NSInteger)_popupStyleForKey: (UIKBTree *)key {
    return enabled && (key.state == popupState) && (key.interactionType == 2) && stringKey(key) ? 0 : %orig;
}

- (UIKBRenderTraits *)_traitsForKey:(UIKBTree *)key onKeyplane:(UIKBKeyplaneView *)keyplane {
    override2 = enabled && highlight && !self.renderConfig.lightKeyboard && (key.state == popupState) && (key.interactionType == 2) && stringKey(key);
    UIKBRenderTraits *orig = %orig;
    override2 = NO;
    return orig;
}

%end

%hook UIKBRenderFactory

+ (BOOL)_enabled {
    return override ? YES : %orig;
}

%end

%hook UIKeyboardCache

+ (BOOL)enabled {
    return override3 ? NO : %orig;
}

%end

%hook UIKBKeyView

- (void)drawRect:(CGRect)rect {
    override = enabled && stringKey(MSHookIvar<UIKBTree *>(self, "m_key")) && highlight;
    %orig;
    override = NO;
}

- (void)layoutSubviews {
    override = enabled && stringKey(MSHookIvar<UIKBTree *>(self, "m_key")) && highlight;
    %orig;
    override = NO;
}

- (void)displayLayer:(id)layer {
    override = enabled && stringKey(MSHookIvar<UIKBTree *>(self, "m_key")) && highlight;
    override3 = override;
    %orig;
    override = NO;
    override3 = NO;
}

%end

%end

%group iOS56

id (*UIKBThemeCreate)(UIKBTree *, void *, void *);
%hookf(id, UIKBThemeCreate, UIKBTree *key, void *arg2, void *arg3) {
    if (override)
        key.displayType = 0;
    id theme = %orig(key, arg2, arg3);
    if (override)
        key.displayType = 25;
    return theme;
}

void (*UIKBDrawKeyWithOptions)(void *, UIKBTree *, UIKBTree *, NSInteger, void *, void *);
%hookf(void, UIKBDrawKeyWithOptions, void *arg1, UIKBTree *keyboard, UIKBTree *key, NSInteger state, void *arg5, void *arg6) {
    override = override && stringKey(key) && (key.interactionType == 2) && highlight;
    if (override) {
        key.interactionType = 1;
        key.displayType = 25;
    }
    %orig(arg1, keyboard, key, state, arg5, arg6);
    if (override) {
        key.interactionType = 2;
        key.displayType = 0;
    }
    override = NO;
}

void (*UIKBThemeSetFontName)(void *, NSString *);
%hookf(void, UIKBThemeSetFontName, void *arg1, NSString *font) {
    %orig(arg1, override ? @".PhoneKeyCaps" : font);
}

void (*UIKBThemeSetFontSize)(void *, CGFloat);
%hookf(void, UIKBThemeSetFontSize, void *arg1, CGFloat fontSize) {
    %orig(arg1, override ? 22.0 : fontSize);
}

BOOL (*UIKBKeyDrawsOwnBackground)(UIKBTree *, UIKBTree *, NSInteger);
%hookf(BOOL, UIKBKeyDrawsOwnBackground, UIKBTree *keyboard, UIKBTree *key, NSInteger arg3) {
    return (key.interactionType == 2) && stringKey(key) ? NO : %orig(keyboard, key, arg3);
}

%hook UIKBKeyView

- (void)drawRect:(CGRect)rect {
    override = self.state == popupState;
    %orig;
    override = NO;
}

%end

%end

%hook UIKBTree

- (void)setOverrideDisplayString: (NSString *)string {
    %orig(enabled && highlight && stringKey(self) ? nil : string);
}

%end

%hook UIKBKeyplaneView

- (void)setState: (NSInteger)state forKey: (UIKBTree *)key {
    if (enabled && !highlight) {
        if (stringKey(key)) {
            %orig(state == popupState ? normalState : state, key);
            if ([key respondsToSelector:@selector(setState:)])
                key.state = state;
            return;
        }
    }
    %orig;
}

%end

static NSString const *tweakIdentifier = @"com.PS.NoKeyPop";

HaveCallback() {
    GetPrefs();
    GetBool(enabled, @"enabled", YES);
    GetBool(highlight, @"highlight", YES);
}

%ctor {
    if (isTarget(TargetTypeApps)) {
        HaveObserver();
        callback();
        dlopen("/Library/MobileSubstrate/DynamicLibraries/Vintage.dylib", RTLD_LAZY);
        %init;
        if (IS_IOS_OR_NEWER(iOS_7_0)) {
            %init(iOS7Up);
        } else {
            MSImageRef ref = MSGetImageByName("/System/Library/Frameworks/UIKit.framework/UIKit");
            UIKBDrawKeyWithOptions = (void (*)(void *, UIKBTree *, UIKBTree *, NSInteger, void *, void *))MSFindSymbol(ref, "_UIKBDrawKeyWithOptions");
            UIKBKeyDrawsOwnBackground = (BOOL (*)(UIKBTree *, UIKBTree *, NSInteger))MSFindSymbol(ref, "_UIKBKeyDrawsOwnBackground");
            UIKBThemeSetFontName = (void (*)(void *, NSString *))MSFindSymbol(ref, "_UIKBThemeSetFontName");
            UIKBThemeSetFontSize = (void (*)(void *, CGFloat))MSFindSymbol(ref, "_UIKBThemeSetFontSize");
            UIKBThemeCreate = (id (*)(UIKBTree *, void *, void *))MSFindSymbol(ref, "_UIKBThemeCreate");
            %init(iOS56);
        }
    }
}
