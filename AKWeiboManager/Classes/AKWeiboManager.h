//
//  AKWeiboManager.h
//  Pods
//
//  Created by 李翔宇 on 16/3/28.
//
//

#import <Foundation/Foundation.h>
#import "AKWeiboUserProtocol.h"
#import "AKWeiboShareProtocol.h"

NS_ASSUME_NONNULL_BEGIN

extern const NSString * const AKWeiboManagerErrorCodeKey;
extern const NSString * const AKWeiboManagerErrorMessageKey;

typedef void (^AKWeiboManagerSuccess)();
typedef void (^AKWeiboManagerLoginSuccess)(id<AKWeiboUserProtocol> user);
typedef void (^AKWeiboManagerFailure)(NSError *error);

@interface AKWeiboManager : NSObject

/**
 标准单例模式
 
 @return AKWeiboManager
 */
+ (AKWeiboManager *)manager;
    
@property (class, nonatomic, assign, getter=isDebug) BOOL debug;
    
+ (void)setAppID:(NSString *)appID secretKey:(NSString *)secretKey;

//处理从Application回调方法获取的URL
+ (BOOL)handleOpenURL:(NSURL *)url;

+ (void)loginSuccess:(AKWeiboManagerLoginSuccess)success
             failure:(AKWeiboManagerFailure)failure;

+ (void)share:(id<AKWeiboShareProtocol>)item
        scene:(AKWeiboShareScene)scene
      success:(AKWeiboManagerSuccess)success
      failure:(AKWeiboManagerFailure)failure;

@end

NS_ASSUME_NONNULL_END
