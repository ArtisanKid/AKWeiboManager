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

const NSString * const AKWeiboManagerErrorKeyStateCode = @"stateCode";
const NSString * const AKWeiboManagerErrorKeyAlert = @"alert";

@interface AKWeiboManager () <WeiboSDKDelegate, WBHttpRequestDelegate>

@property (nonatomic, strong) NSString *appID;
@property (nonatomic, strong) NSString *secretKey;

@property (nonatomic, strong) AKWeiboManagerLoginSuccess loginSuccess;
@property (nonatomic, strong) AKWeiboManagerFailure loginFailure;

@property (nonatomic, strong) AKWeiboManagerSuccess shareSuccess;
@property (nonatomic, strong) AKWeiboManagerFailure shareFailure;

@end

@implementation AKWeiboManager

static NSString * const AKWeiboManagerAppRedirectURI = @"http://sns.whalecloud.com/sina2/callback";

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

#pragma mark- Public Method
+ (void)setAppID:(NSString *)appID secretKey:(NSString *)secretKey {
    self.manager.appID = appID;
    self.manager.secretKey = secretKey;
}

+ (BOOL)handleOpenURL:(NSURL *)url {
    BOOL handle = [WeiboSDK handleOpenURL:url delegate:[self manager]];
}

+ (void)loginSuccess:(AKWeiboManagerLoginSuccess)success
             failure:(AKWeiboManagerFailure)failure {
    //相关文档在这里：
    
    self.manager.loginSuccess = success;
    self.manager.loginFailure = failure;
    
    WBAuthorizeRequest *request = [WBAuthorizeRequest request];
    request.redirectURI = AKWeiboManagerAppRedirectURI;
    request.scope = @"all";
    [WeiboSDK sendRequest:request];
}

+ (void)share:(id<AKWeiboShareProtocol>)item
        scene:(AKWeiboShareScene)scene
      success:(AKWeiboManagerSuccess)success
      failure:(AKWeiboManagerFailure)failure {
    //相关文档在这里：https://open.Weibo.qq.com/cgi-bin/showdocument?action=dir_list&t=resource/res_list&verify=1&id=open1419317332&token=&lang=zh_CN
    
    AK_WBM_Nilable_Class_Return(self.manager.appID, NO, NSString, {})
    
    self.manager.shareSuccess = success;
    self.manager.shareFailure = failure;
    
    WBSendMessageToWeiboRequest *request = nil;
    if(scene == AKWeiboShareSceneContact) {
        request = [item messageToContact];
    } else/* if(scene == AKWeiboShareSceneContact)*/ {
        request = [item messageToScene];
    }
    [WeiboSDK sendRequest:request];
}

#pragma mark- WXApiDelegate
/**
 收到一个来自微博客户端程序的响应
 
 收到微博的响应后，第三方应用可以通过响应类型、响应的数据和 WBBaseResponse.userInfo 中的数据完成自己的功能
 @param response 具体的响应对象
 */
- (void)didReceiveWeiboResponse:(WBBaseResponse *)response {
    if(response.statusCode != WeiboSDKResponseStatusCodeSuccess) {
        NSMutableDictionary *userInfo = [@{AKWeiboManagerErrorKeyStateCode : @(response.statusCode)} mutableCopy];
        NSString *alert = [self alert:response.statusCode];
        if(alert) {
            userInfo[AKWeiboManagerErrorKeyAlert] = alert;
        }
        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:response.statusCode userInfo:userInfo];
        
        if ([response isKindOfClass:[WBAuthorizeRequest class]]) {
            !self.loginFailure ? : self.loginFailure(error);
            
            self.loginSuccess = nil;
            self.loginFailure = nil;
        } else if([response isKindOfClass:[WBSendMessageToWeiboRequest class]]) {
            !self.shareFailure ? : self.shareFailure(error);
            
            self.shareSuccess = nil;
            self.shareFailure = nil;
        }
        return;
    }
    
    if ([response isKindOfClass:[WBAuthorizeRequest class]]) {
        WBAuthorizeResponse *response = (WBAuthorizeResponse *)response;
        [self loginWithResponse:response];
    } else if ([response isKindOfClass:[WBSendMessageToWeiboRequest class]]) {
        !self.shareSuccess ? : self.shareSuccess();
        
        self.shareSuccess = nil;
        self.shareFailure = nil;
    }
}

- (void)loginWithResponse:(WBAuthorizeResponse *)response {
    AK_WBM_Nilable_Class_Return(self.appID, NO, NSString, {})
    AK_WBM_Nilable_Class_Return(self.secretKey, NO, NSString, {})
    
    //获取用户信息
    [WBHttpRequest
     requestForUserProfile:response.userID
     withAccessToken:response.accessToken
     andOtherProperties:nil
     queue:nil
     withCompletionHandler:^(WBHttpRequest *httpRequest, id result, NSError *error) {
         if(error) {
             !self.loginFailure ? :  self.loginFailure(error);
             return;
         }
         
         if(![result isKindOfClass:[WeiboUser class]]) {
             NSError *error = [NSError errorWithDomain:NSStringFromClass([self class])
                                                  code:0
                                              userInfo:@{ AKWeiboManagerErrorKeyAlert : @"登陆失败" }];
             !self.loginFailure ? :  self.loginFailure(error);
             return;
         }
         
         WeiboUser *wbUser = (WeiboUser *)result;
         
         AKWeiboUser *user = [[AKWeiboUser alloc] init];
         user.accessToken = response.accessToken;
         user.refreshToken = response.refreshToken;
         user.expiredTime = response.expirationDate.timeIntervalSince1970;
         user.openID = response.userID;
         user.nickname = wbUser.screenName;
         user.portrait = wbUser.avatarLargeUrl;
         
         !self.loginSuccess ? :  self.loginSuccess(error);
     }];
}

@end
