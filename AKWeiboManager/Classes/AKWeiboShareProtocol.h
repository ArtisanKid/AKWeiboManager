//
//  AKWeiboShareProtocol.h
//  Pods
//
//  Created by 李翔宇 on 2017/1/17.
//
//

#import <Foundation/Foundation.h>
#import <AKWeiboSDK/WeiboSDK.h>

typedef NS_ENUM(NSUInteger, AKWeiboShareScene) {
    AKWeiboShareSceneNone = 0,
    AKWeiboShareSceneTimeline,//微博
    AKWeiboShareSceneContact,//联系人
};

@protocol AKWeiboShareProtocol <NSObject>

- (WBSendMessageToWeiboRequest *)messageToScene;
- (WBShareMessageToContactRequest *)messageToContact;

@end
