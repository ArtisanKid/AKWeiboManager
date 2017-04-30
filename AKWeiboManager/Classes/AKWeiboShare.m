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
    WBMessageObject *message = [WBMessageObject message];
    message.text = self.text;
    return message;
}

- (void)complete:(WBMessageObject *)message {
    if([self.text isKindOfClass:[NSString class]]
       && self.text.length) {
        message.text = self.text;
    }
}

- (WBSendMessageToWeiboRequest *)messageToScene {
    WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest request];
    request.message = [self message];
    return request;
}

- (WBShareMessageToContactRequest *)messageToContact {
    WBShareMessageToContactRequest *request = [WBShareMessageToContactRequest request];
    request.message = [self message];
    return request;
}

@end

@implementation AKWeiboShareText

@end

@implementation AKWeiboShareImage

- (WBMessageObject *)message {
    WBImageObject *image = [WBImageObject object];
    if([self.image isKindOfClass:[UIImage class]]) {
        NSData *imageData = nil;
        imageData = UIImageJPEGRepresentation(self.image, 1.);
        if(!imageData.length) {
            imageData = UIImagePNGRepresentation(self.image);
        }
        if(imageData.length) {
            image.imageData = imageData;
        }
    }
    
    WBMessageObject *message = [WBMessageObject message];
    [super complete:message];
    message.imageObject = image;
    return message;
}

@end

@implementation AKWeiboShareURL

- (void)completeMedia:(WBBaseMediaObject *)media {
    if([self.mediaID isKindOfClass:[NSString class]]
       && self.mediaID.length) {
        media.objectID = self.mediaID;
    }
    
    if([self.title isKindOfClass:[NSString class]]
       && self.title.length) {
        media.title = self.title;
    }
    
    if([self.detail isKindOfClass:[NSString class]]
       && self.detail.length) {
        media.description = self.title;
    }
    
    if([self.thumbImage isKindOfClass:[UIImage class]]) {
        NSData *imageData = nil;
        imageData = UIImageJPEGRepresentation(self.thumbImage, 1.);
        if(!imageData.length) {
            imageData = UIImagePNGRepresentation(self.thumbImage);
        }
        if(imageData.length) {
            media.thumbnailData = imageData;
        }
    }
    
    if([self.schemeURL isKindOfClass:[NSString class]]
       && self.schemeURL.length) {
        media.scheme = self.schemeURL;
    }
}

@end

@implementation AKWeiboShareWeb

- (WBMessageObject *)message {
    WBMessageObject *message = [WBMessageObject message];
    [self complete:message];
    return message;
}

- (void)complete:(WBMessageObject *)message {
    [super complete:message];
    
    WBWebpageObject *web = [WBWebpageObject object];
    [super completeMedia:web];
    
    if([self.URL isKindOfClass:[NSString class]]
       && self.URL.length) {
        web.webpageUrl = self.URL;
    }
    
    message.mediaObject = web;
}

@end

@implementation AKWeiboShareAudio

- (WBMessageObject *)message {
    WBMessageObject *message = [WBMessageObject message];
    [self complete:message];
    return message;
}

- (void)complete:(WBMessageObject *)message {
    [super complete:message];
    
    WBMusicObject *music = [WBMusicObject object];
    [super completeMedia:music];
    
    if([self.URL isKindOfClass:[NSString class]]
       && self.URL.length) {
        music.musicUrl = self.URL;
    }
    
    if([self.lowBandURL isKindOfClass:[NSString class]]
       && self.lowBandURL.length) {
        music.musicLowBandUrl = self.lowBandURL;
    }
    
    if([self.streamURL isKindOfClass:[NSString class]]
       && self.streamURL.length) {
        music.musicStreamUrl = self.streamURL;
    }
    
    if([self.lowBandStreamURL isKindOfClass:[NSString class]]
       && self.lowBandStreamURL.length) {
        music.musicLowBandStreamUrl = self.lowBandStreamURL;
    }
    
    message.mediaObject = music;
}

@end

@implementation AKWeiboShareVideo

- (WBMessageObject *)message {
    WBMessageObject *message = [WBMessageObject message];
    [self complete:message];
    return message;
}

- (void)complete:(WBMessageObject *)message {
    [super complete:message];
    
    WBVideoObject *video = [WBMusicObject object];
    [super completeMedia:video];
    
    if([self.URL isKindOfClass:[NSString class]]
       && self.URL.length) {
        video.videoUrl = self.URL;
    }
    
    if([self.lowBandURL isKindOfClass:[NSString class]]
       && self.lowBandURL.length) {
        video.videoLowBandUrl = self.lowBandURL;
    }
    
    if([self.streamURL isKindOfClass:[NSString class]]
       && self.streamURL.length) {
        video.videoStreamUrl = self.streamURL;
    }
    
    if([self.lowBandStreamURL isKindOfClass:[NSString class]]
       && self.lowBandStreamURL.length) {
        video.videoLowBandStreamUrl = self.lowBandStreamURL;
    }
    
    message.mediaObject = video;
}

@end
