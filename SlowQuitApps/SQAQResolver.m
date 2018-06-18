@import Carbon;
#import "SQAQResolver.h"

@interface SQAQResolver() {
@private
    CGKeyCode resolvedKeyCode;
}
@end

@implementation SQAQResolver

- (id)init {
    self = [super init];
    if (!self) return self;

    resolvedKeyCode = whatIsQ();

    return self;
}

- (CGKeyCode)keyCode {
    return resolvedKeyCode;
}

CGKeyCode whatIsQ() {
    NSData *rawLayout = (__bridge NSData *)((CFDataRef) TISGetInputSourceProperty(TISCopyCurrentKeyboardInputSource(), kTISPropertyUnicodeKeyLayoutData));
    UInt32 cmdKeyBitmask = (cmdKey >> 8) & 0xFF;
    UInt32 deadKeyState = 0;
    UniChar str[4] = {0, 0, 0, 0};
    UniCharCount actualLength = 0;

    CGKeyCode candidates[] = {
        kVK_ANSI_Q, // Because most people would use QWERTY, try this first.
        kVK_ANSI_A,
        kVK_ANSI_B,
        kVK_ANSI_C,
        kVK_ANSI_D,
        kVK_ANSI_E,
        kVK_ANSI_F,
        kVK_ANSI_G,
        kVK_ANSI_H,
        kVK_ANSI_I,
        kVK_ANSI_J,
        kVK_ANSI_K,
        kVK_ANSI_L,
        kVK_ANSI_M,
        kVK_ANSI_N,
        kVK_ANSI_O,
        kVK_ANSI_P,
        kVK_ANSI_R,
        kVK_ANSI_S,
        kVK_ANSI_T,
        kVK_ANSI_U,
        kVK_ANSI_V,
        kVK_ANSI_W,
        kVK_ANSI_X,
        kVK_ANSI_Y,
        kVK_ANSI_Z
    };
    for (int i = 0; i < sizeof(candidates); i++) {
        CGKeyCode candidate = candidates[i];
        OSStatus status = UCKeyTranslate(rawLayout.bytes,
                                         candidate,
                                         kUCKeyActionDown,
                                         cmdKeyBitmask,
                                         LMGetKbdType(),
                                         kUCKeyTranslateNoDeadKeysBit,
                                         &deadKeyState,
                                         4,
                                         &actualLength,
                                         str);
        if (status == paramErr) {
            // Maybe we shouldn't do this?
            continue;
        }
        NSString *result = [NSString stringWithCharacters:str length:actualLength];
        if ([result isEqualToString:@"q"]) {
            return candidate;
        }
    }

    // Give up.
    return kVK_ANSI_Q;
}

@end
