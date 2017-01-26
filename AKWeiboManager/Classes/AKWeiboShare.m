//
//  AKWeiboShare.m
//  Pods
//
//  Created by 李翔宇 on 2017/1/17.
//
//

#import "AKWeiboShare.h"

@implementation AKWeiboShare

/**
 子类重载此方法

 @return WBMessageObject
 */
- (WBMessageObject *)message {
    return nil;
}

- (WBSendMessageToWeiboRequest *)messageToScene {
    WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest request];
    request.shouldOpenWeiboAppInstallPageIfNotInstalled = YES;
    request.message = [self message];
    return request;
}

- (WBShareMessageToContactRequest *)messageToContact {
    WBShareMessageToContactRequest *request = [WBShareMessageToContactRequest request];
    request.shouldOpenWeiboAppInstallPageIfNotInstalled = YES;
    request.message = [self message];
    return request;
}

@end

@implementation AKWeiboShareText

- (WBMessageObject *)message {
    WBMessageObject *message = [WBMessageObject message];
    message.text = self.text;
    return message;
}

@end

@implementation AKWeiboShareImage

- (WBMessageObject *)message {
    NSData *imageData = nil;
    imageData = UIImageJPEGRepresentation(self.image, 1.);
    if(!imageData.length) {
        imageData = UIImagePNGRepresentation(self.image);
    }
    
    WBImageObject *object = [WBImageObject object];
    object.imageData = imageData;
    
    WBMessageObject *message = [WBMessageObject message];
    message.text = self.text;
    message.imageObject = object;
    return message;
}

@end

@implementation AKWeiboShareBaseMedia

@end

@implementation AKWeiboShareWeb

- (WBMessageObject *)message {
    WBWebpageObject *object = [WBWebpageObject object];
    object.objectID = self.mediaID;
    object.title = self.title;
    object.description = self.detail;
    
    NSData *imageData = nil;
    imageData = UIImageJPEGRepresentation(self.thumbImage, 1.);
    if(!imageData.length) {
        imageData = UIImagePNGRepresentation(self.thumbImage);
    }
    object.thumbnailData = imageData;
    
    object.scheme = self.schemeURL;
    object.webpageUrl = self.URL;
    
    WBMessageObject *message = [WBMessageObject message];
    message.mediaObject = object;
    return message;
}

@end

@implementation AKWeiboShareAudio

- (WBMessageObject *)message {
    WBMusicObject *object = [WBMusicObject object];
    object.objectID = self.mediaID;
    object.title = self.title;
    object.description = self.detail;
    
    NSData *imageData = nil;
    imageData = UIImageJPEGRepresentation(self.thumbImage, 1.);
    if(!imageData.length) {
        imageData = UIImagePNGRepresentation(self.thumbImage);
    }
    object.thumbnailData = imageData;
    object.scheme = self.schemeURL;
    
    object.musicUrl = self.URL;
    object.musicLowBandUrl = self.lowBandURL;
    object.musicStreamUrl = self.streamURL;
    object.musicLowBandStreamUrl = self.lowBandStreamURL;
    
    WBMessageObject *message = [WBMessageObject message];
    message.mediaObject = object;
    return message;
}

@end

@implementation AKWeiboShareVideo

- (WBMessageObject *)message {
    WBVideoObject *object = [WBVideoObject object];
    object.objectID = self.mediaID;
    object.title = self.title;
    object.description = self.detail;
    
    NSData *imageData = nil;
    imageData = UIImageJPEGRepresentation(self.thumbImage, 1.);
    if(!imageData.length) {
        imageData = UIImagePNGRepresentation(self.thumbImage);
    }
    object.thumbnailData = imageData;
    
    object.scheme = self.schemeURL;
    
    object.videoUrl = self.URL;
    object.videoLowBandUrl = self.lowBandURL;
    object.videoStreamUrl = self.streamURL;
    object.videoLowBandStreamUrl = self.lowBandStreamURL;
    
    WBMessageObject *message = [WBMessageObject message];
    message.mediaObject = object;
    return message;
}

@end
