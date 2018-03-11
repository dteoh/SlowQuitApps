@import Foundation;

@interface SQAPreferences : NSObject

+ (NSInteger)delay;
+ (NSArray<NSString *> *)whitelist;
+ (BOOL)invertList;
@end
