//
//  AKWeiboManager.m
//  Pods
//
//  Created by 李翔宇 on 16/3/28.
//
//

#import "AKWeiboManager.h"
#import <AKWeiboSDK/WeiboSDK.h>
#import <AKWeiboSDK/WBHttpRequest+WeiboToken.h>
#import <AKWeiboSDK/WBHttpRequest+WeiboUser.h>
#import <AKWeiboSDK/WeiboUser.h>
#import "AKWeiboManagerMacro.h"
#import "AKWeiboUser.h"

const NSString * const AKWeiboManagerErrorCodeKey = @"code";
const NSString * const AKWeiboManagerErrorMessageKey = @"message";

@interface AKWeiboManager () <WeiboSDKDelegate, WBHttpRequestDelegate>
    
@property (nonatomic, assign, getter=isDebug) BOOL debug;

@property (nonatomic, strong) NSString *appID;
@property (nonatomic, strong) NSString *secretKey;

@property (nonatomic, strong) AKWeiboManagerLoginSuccess loginSuccess;
@property (nonatomic, strong) AKWeiboManagerFailure loginFailure;

@property (nonatomic, strong) AKWeiboManagerSuccess shareSuccess;
@property (nonatomic, strong) AKWeiboManagerFailure shareFailure;

@property (nonatomic, strong) AKWeiboUser *user;

@end

@implementation AKWeiboManager
    
//static NSString * const AKWeiboManagerAppRedirectURI = @"http://sns.whalecloud.com/sina2/callback";
static NSString * const AKWeiboManagerAppRedirectURI = @"https://api.weibo.com/oauth2/default.html";
    
+ (AKWeiboManager *)manager {
    static AKWeiboManager *weiboManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        weiboManager = [[super allocWithZone:NULL] init];
    });
    return weiboManager;
}
    
+ (id)alloc {
    return [self manager];
}
    
+ (id)allocWithZone:(NSZone * _Nullable)zone {
    return [self manager];
}
    
- (id)copy {
    return self;
}
    
- (id)copyWithZone:(NSZone * _Nullable)zone {
    return self;
}
    
#pragma mark- Public Method
+ (void)setDebug:(BOOL)debug {
    self.manager.debug = debug;
}
    
+ (BOOL)isDebug {
    return self.manager.isDebug;
}
    
+ (void)setAppID:(NSString *)appID secretKey:(NSString *)secretKey {
    self.manager.appID = appID;
    self.manager.secretKey = secretKey;
    [WeiboSDK registerApp:self.manager.appID];
}
    
+ (BOOL)handleOpenURL:(NSURL *)url {
    BOOL handle = [WeiboSDK handleOpenURL:url delegate:self.manager];
    return handle;
}
    
+ (void)loginSuccess:(AKWeiboManagerLoginSuccess)success
             failure:(AKWeiboManagerFailure)failure {    
    if(![self.manager checkAppInstalled]) {
        [self.manager failure:failure message:@"未安装微博"];
        return;
    }
    
    if(![self.manager checkAppVersion]) {
        [self.manager failure:failure message:@"微博版本过低"];
        return;
    }
    
    NSTimeInterval now = [NSDate date].timeIntervalSince1970;
    if(self.manager.user.expiredTime - now >= 60) {
        !success ? : success(self.manager.user);
    } else if(self.manager.user.expiredTime > now && self.manager.user.expiredTime - now < 60) {
        [self.manager refreshAccessTokenSuccess:^{
            [self.manager realLoginSuccess:success failure:failure];
        } failure:failure];
    } else if(self.manager.user.refreshToken.length) {
        [self.manager refreshAccessTokenSuccess:^{
            [self.manager realLoginSuccess:success failure:failure];
        } failure:failure];
    } else {
        WBAuthorizeRequest *request = [WBAuthorizeRequest request];
        request.redirectURI = AKWeiboManagerAppRedirectURI;
        request.scope = @"all";
        
        BOOL result = [WeiboSDK sendRequest:request];
        if(!result) {
            [self.manager failure:failure message:@"Auth请求发送失败"];
            return;
        }
        
        self.manager.loginSuccess = success;
        self.manager.loginFailure = failure;
    }
}
    
+ (void)share:(id<AKWeiboShareProtocol>)item
        scene:(AKWeiboShareScene)scene
      success:(AKWeiboManagerSuccess)success
      failure:(AKWeiboManagerFailure)failure {
    //相关文档在这里：https://open.Weibo.qq.com/cgi-bin/showdocument?action=dir_list&t=resource/res_list&verify=1&id=open1419317332&token=&lang=zh_CN
    
    AKWBM_String_Nilable_Return(self.manager.appID, NO, {
        [self.manager failure:failure message:@"未设置appID"];
    });
    
    AKWBM_String_Nilable_Return(self.manager.secretKey, NO, {
        [self.manager failure:failure message:@"未设置secretKey"];
    });
    
    if(![self.manager checkAppInstalled]) {
        [self.manager failure:failure message:@"未安装微博"];
        return;
    }
    
    if(![self.manager checkAppVersion]) {
        [self.manager failure:failure message:@"微博版本过低"];
        return;
    }
    
    id request = nil;
    if(scene == AKWeiboShareSceneContact) {
        request = [item messageToContact];
    } else/* if(scene == AKWeiboShareSceneTimeline)*/ {
        request = [item messageToScene];
    }
    
    BOOL result = [WeiboSDK sendRequest:request];
    if(!result) {
        [self.manager failure:failure message:@"Share请求发送失败"];
        return;
    }
    
    self.manager.shareSuccess = success;
    self.manager.shareFailure = failure;
}
    
#pragma mark- WeiboSDKDelegate
/**
 收到一个来自微博客户端程序的响应
 
 收到微博的响应后，第三方应用可以通过响应类型、响应的数据和 WBBaseResponse.userInfo 中的数据完成自己的功能
 @param response 具体的响应对象
 */
- (void)didReceiveWeiboResponse:(WBBaseResponse *)response {
    if(response.statusCode != WeiboSDKResponseStatusCodeSuccess) {
        NSString *message = [self alert:response.statusCode];
        if ([response isKindOfClass:[WBAuthorizeRequest class]]) {
            [self failure:self.loginFailure code:response.statusCode message:message];
            
            [self.user invalid];
            self.loginSuccess = nil;
            self.loginFailure = nil;
        } else if([response isKindOfClass:[WBSendMessageToWeiboRequest class]]) {
            [self failure:self.shareFailure code:response.statusCode message:message];
            
            self.shareSuccess = nil;
            self.shareFailure = nil;
        }
        return;
    }
    
    if ([response isKindOfClass:[WBAuthorizeRequest class]]) {
        WBAuthorizeResponse *authResponse = (WBAuthorizeResponse *)response;
        self.user.accessToken = authResponse.accessToken;
        self.user.refreshToken = authResponse.refreshToken;
        self.user.expiredTime = authResponse.expirationDate.timeIntervalSince1970;
        self.user.openID = authResponse.userID;
        
        [self realLoginSuccess:self.loginSuccess failure:self.loginFailure];
        
        self.loginSuccess = nil;
        self.loginFailure = nil;
    } else if ([response isKindOfClass:[WBSendMessageToWeiboRequest class]]) {
        !self.shareSuccess ? : self.shareSuccess();
        
        self.shareSuccess = nil;
        self.shareFailure = nil;
    }
}

/**
 收到一个来自微博客户端程序的请求
 
 收到微博的请求后，第三方应用应该按照请求类型进行处理，处理完后必须通过 [WeiboSDK sendResponse:] 将结果回传给微博
 @param request 具体的请求对象
 */
- (void)didReceiveWeiboRequest:(WBBaseRequest *)request {
    
}
    
#pragma mark- Private Method
/*
 WeiboSDKResponseStatusCodeSuccess               = 0,//成功
 WeiboSDKResponseStatusCodeUserCancel            = -1,//用户取消发送
 WeiboSDKResponseStatusCodeSentFail              = -2,//发送失败
 WeiboSDKResponseStatusCodeAuthDeny              = -3,//授权失败
 WeiboSDKResponseStatusCodeUserCancelInstall     = -4,//用户取消安装微博客户端
 WeiboSDKResponseStatusCodePayFail               = -5,//支付失败
 WeiboSDKResponseStatusCodeShareInSDKFailed      = -8,//分享失败 详情见response UserInfo
 WeiboSDKResponseStatusCodeUnsupport             = -99,//不支持的请求
 WeiboSDKResponseStatusCodeUnknown               = -100,
 */
- (NSString *)alert:(WeiboSDKResponseStatusCode)stateCode {
    NSString *alert = nil;
    switch (stateCode) {
        case WeiboSDKResponseStatusCodeUserCancel: alert = @"取消发送"; break;
        case WeiboSDKResponseStatusCodeSentFail: alert = @"发送失败"; break;
        case WeiboSDKResponseStatusCodeAuthDeny: alert = @"授权失败"; break;
        case WeiboSDKResponseStatusCodeUserCancelInstall: alert = @"取消安装微博"; break;
        case WeiboSDKResponseStatusCodePayFail: alert = @"支付失败"; break;
        case WeiboSDKResponseStatusCodeShareInSDKFailed: alert = @"分享失败"; break;
        case WeiboSDKResponseStatusCodeUnsupport: alert = @"微博不支持"; break;
        case WeiboSDKResponseStatusCodeUnknown: alert = @"未知错误"; break;
        default: break;
    }
    return alert;
}
    
+ (NSString *)identifier {
    NSTimeInterval timestamp = [NSDate date].timeIntervalSince1970;
    return @(timestamp).description;
}
    
- (void)refreshAccessTokenSuccess:(AKWeiboManagerSuccess)success
                          failure:(AKWeiboManagerFailure)failure {
    AKWBM_String_Nilable_Return(self.user.refreshToken, NO, {
        [self failure:failure message:@"refreshToken类型错误或nil"];
    });
    
    [WBHttpRequest
     requestForRenewAccessTokenWithRefreshToken:self.user.refreshToken
     queue:nil
     withCompletionHandler:^(WBHttpRequest *httpRequest, id result, NSError *error) {
         if(error) {
             if(self.isDebug) {
                 AKWeiboManagerLog(@"%@", error);
             }
             !failure ? : failure(error);
             [self.user invalid];
             return;
         }
         
         if(![result isKindOfClass:[NSDictionary class]]) {
             [self failure:failure message:@"refreshAccessToken返回数据类型错误"];
             [self.user invalid];
             return;
         }
         
#warning 没有找到文档来说明返回内容
         self.user.accessToken = result;
         
         !success ? : success();
     }];
}
    
- (void)realLoginSuccess:(AKWeiboManagerLoginSuccess)success
                 failure:(AKWeiboManagerFailure)failure {
    AKWBM_String_Nilable_Return(self.user.openID, NO, {
        [self failure:failure message:@"openID类型错误或nil"];
    });
    
    AKWBM_String_Nilable_Return(self.user.accessToken, NO, {
        [self failure:failure message:@"accessToken类型错误或nil"];
    });
    
    //获取用户信息
    [WBHttpRequest
     requestForUserProfile:self.user.openID
     withAccessToken:self.user.accessToken
     andOtherProperties:nil
     queue:nil
     withCompletionHandler:^(WBHttpRequest *httpRequest, id result, NSError *error) {
         if(error) {
             if(self.isDebug) {
                 AKWeiboManagerLog(@"%@", error);
             }
             !failure ? : failure(error);
             [self.user invalid];
             return;
         }
         
         if(![result isKindOfClass:[WeiboUser class]]) {
             [self failure:failure message:@"login接口返回数据类型错误"];
             [self.user invalid];
             return;
         }
         
         WeiboUser *wbUser = (WeiboUser *)result;
         
         self.user.nickname = wbUser.screenName;
         self.user.portrait = wbUser.avatarLargeUrl;
         
         !success ? : success(self.user);
     }];
}
    
- (BOOL)checkAppInstalled {
    if([WeiboSDK isWeiboAppInstalled]) {
        return YES;
    }
    
    [self showAlert:@"当前您还没有安装微博，是否安装微博？"];
    return NO;
}
    
- (BOOL)checkAppVersion {
    if([WeiboSDK isCanSSOInWeiboApp]
       && [WeiboSDK isCanShareInWeiboAPP]) {
        return YES;
    }
    
    [self showAlert:@"当前微博版本过低，是否升级？"];
    return NO;
}
    
- (void)showAlert:(NSString *)message {
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"提示"
                                          message:message
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *downloadAction = [UIAlertAction actionWithTitle:@"下载"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
                                                               [rootViewController dismissViewControllerAnimated:YES completion:^{
                                                                   NSString *appStoreURL = [WeiboSDK getWeiboAppInstallUrl];
                                                                   [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appStoreURL]];
                                                               }];
                                                           }];
    UIAlertAction *cancleAction = [UIAlertAction actionWithTitle:@"取消登录"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [rootViewController dismissViewControllerAnimated:YES completion:^{}];
                                                         }];
    [alertController addAction:downloadAction];
    [alertController addAction:cancleAction];
    [rootViewController presentViewController:alertController animated:YES completion:^{}];
}
    
- (void)failure:(AKWeiboManagerFailure)failure message:(NSString *)message {
    if(self.isDebug) {
        AKWeiboManagerLog(@"%@", message);
    }
    
    NSDictionary *userInfo = nil;
    if([message isKindOfClass:[NSString class]]
       && message.length) {
        userInfo = @{AKWeiboManagerErrorMessageKey : message};
    }
    
    NSError *error = [NSError errorWithDomain:NSStringFromClass([self class])
                                         code:0
                                     userInfo:userInfo];
    !failure ? : failure(error);
}
    
- (void)failure:(AKWeiboManagerFailure)failure code:(NSUInteger)code message:(NSString *)message {
    if(self.isDebug) {
        AKWeiboManagerLog(@"%@", message);
    }
    
    NSMutableDictionary *userInfo = [@{AKWeiboManagerErrorCodeKey : @(code)} mutableCopy];
    if([message isKindOfClass:[NSString class]]
       && message.length) {
        userInfo[AKWeiboManagerErrorMessageKey] = message;
    }
    
    NSError *error = [NSError errorWithDomain:NSStringFromClass([self class])
                                         code:0
                                     userInfo:[userInfo copy]];
    !failure ? : failure(error);
}
    
    @end
