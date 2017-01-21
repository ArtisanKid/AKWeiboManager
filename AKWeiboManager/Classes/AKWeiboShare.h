//
//  AKWeiboShare.h
//  Pods
//
//  Created by 李翔宇 on 2017/1/17.
//
//

#import <Foundation/Foundation.h>
#import "AKWeiboShareProtocol.h"

#pragma mark - AKWeiboShare

@interface AKWeiboShare : NSObject<AKWeiboShareProtocol>

/**
 消息的文本内容，长度小于140个汉字
 */
@property (nonatomic, copy) NSString *text;

@end

#pragma mark - AKWeiboShareText

@interface AKWeiboShareText : AKWeiboShare

@end

#pragma mark - AKWeiboShareImage

@interface AKWeiboShareImage : AKWeiboShare

/**
 图片真实数据内容，大小不能超过10M
 */
@property (nonatomic, strong) UIImage *image;

@end

#pragma mark - AKWeiboShareObject

@interface AKWeiboShareObject : AKWeiboShare

/**
 对象唯一ID，用于唯一标识一个多媒体内容
 当第三方应用分享多媒体内容到微博时，应该将此参数设置为被分享的内容在自己的系统中的唯一标识
 不能为空，长度小于255字节
 */
@property (nonatomic, copy) NSString *mediaID;

/**
 多媒体内容标题，不能为空且长度小于1k
 */
@property (nonatomic, copy) NSString *title;

/**
 多媒体内容描述，长度小于1k
 */
@property (nonatomic, copy) NSString *description;

/**
 多媒体内容缩略图，大小小于32k
 */
@property (nonatomic, strong) UIImage *thumbImage;

/**
 点击多媒体内容之后呼起第三方应用特定页面的scheme，长度小于255字节
 */
@property (nonatomic, copy) NSString *schemeURL;

/**
 网页的url地址，长度不能超过10K
 支持普通网页，音乐网页，视频网页等
 */
@property (nonatomic, copy) NSString *URL;

@end

#pragma mark - AKWeiboShareWeb

@interface AKWeiboShareWeb : AKWeiboShareObject

@end

#pragma mark - AKWeiboShareMedia

typedef NS_ENUM(NSUInteger, AKWeiboShareMediaType) {
    AKWeiboShareMediaTypeNone,
    AKWeiboShareMediaTypeMusic,
    AKWeiboShareMediaTypeVideo
};

@interface AKWeiboShareMedia : AKWeiboShareObject

@property (nonatomic, assign, readonly) AKWeiboShareMediaType type;

/**
 音乐与视频的低带网页url地址，长度不能超过10K
 */
@property (nonatomic, copy) NSString *lowBandURL;

/**
 音乐与视频数据流的url地址，长度不能超过255字节
 */
@property (nonatomic, copy) NSString *streamURL;

/**
 音乐与视频数据流的url地址，长度不能超过255字节
 */
@property (nonatomic, copy) NSString *lowBandStreamURL;

@end
