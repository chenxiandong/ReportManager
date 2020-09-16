//
//  ReportManager.h
//  ReportManager
//
//  Created by Chenxd on 2020/9/15.
//  Copyright © 2020 Chenxd. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for ReportManager.
FOUNDATION_EXPORT double ReportManagerVersionNumber;

//! Project version string for ReportManager.
FOUNDATION_EXPORT const unsigned char ReportManagerVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <ReportManager/PublicHeader.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ReportActionType) {
    ReportActionTypeView = 1,
    ReportActionTypeLike,
    ReportActionTypeCollection,
    ReportActionTypeComment,
    ReportActionTypeRepost,
    ReportActionTypeDislike,
    ReportActionTypeReport,
    ReportActionTypePlay,
    ReportActionTypeDrag,
    ReportActionTypeLoading,
    ReportActionTypeBuffering,
    ReportActionTypePause,
    ReportActionTypeStop,
    ReportActionTypeLaunch,
};

@interface ReportManager : NSObject

+ (ReportManager *)shareManager;

@property (nonatomic, copy) NSString *access_token;

/// 初始化
/// @param customerId 租户id
/// @param productId 产品id
+ (void)initWithCustomerId:(nonnull NSString *)customerId
                 productId:(nonnull NSString *)productId;


/// 设置上报接口域名
/// @param baseUrl 上报接口域名  测试地址：http://10.30.129.68
+ (void)setBaseUrl:(nonnull NSString *)baseUrl;


/// 设置step定时上报间隔
/// @param step step定时上报间隔 默认30
+ (void)setStep:(NSInteger)step;


/// 更新位置信息
/// @param district 区
/// @param city 市
/// @param province 省
/// @param country 国
+ (void)updateDistrict:(nullable NSString *)district
                  city:(nullable NSString *)city
              province:(nullable NSString *)province
               country:(nullable NSString *)country;


/// 更新播放进度
/// @param currentTime 当前播放进度
/// @param origin_item_id  视频id
+ (void)updatePlayerCurrentTime:(NSInteger)currentTime
                 origin_item_id:(NSString *)origin_item_id;


/// 获取token  启动和登录时调用
/// @param userId 当前用户在其用户系统内ID,未登录用户可不填
/// @param name 用户名
/// @param nickname  用户昵称
/// @param birthday 生日
/// @param sex 性别 0女 1男
/// @param phone 手机号
/// @param qq_openid QQ OPENID
/// @param weixin_openid WEIXIN OPENID
/// @param weibo_openid WEIBO OPENID
+ (void)getAuthorizationsWithUserId:(nullable NSString *)userId
                               name:(nullable NSString *)name
                           nickname:(nullable NSString *)nickname
                           birthday:(nullable NSString *)birthday
                                sex:(nullable NSString *)sex
                              phone:(nullable NSString *)phone
                            apple_openid:(nullable NSString *)apple_openid
                          qq_openid:(nullable NSString *)qq_openid
                      weixin_openid:(nullable NSString *)weixin_openid
                       weibo_openid:(nullable NSString *)weibo_openid
                              extra:(nullable NSDictionary *)extra;

/// 获取token  启动和登录时调用
/// @param userId 当前用户在其用户系统内ID,未登录用户可不填
/// @param name 用户名
/// @param nickname  用户昵称
/// @param birthday 生日
/// @param sex 性别 0女 1男
/// @param phone 手机号
/// @param qq_openid QQ OPENID
/// @param weixin_openid WEIXIN OPENID
/// @param weibo_openid WEIBO OPENID
/// @param successBlock 成功回调
+ (void)getAuthorizationsWithUserId:(nullable NSString *)userId
                               name:(nullable NSString *)name
                           nickname:(nullable NSString *)nickname
                           birthday:(nullable NSString *)birthday
                                sex:(nullable NSString *)sex
                              phone:(nullable NSString *)phone
                            apple_openid:(nullable NSString *)apple_openid
                          qq_openid:(nullable NSString *)qq_openid
                      weixin_openid:(nullable NSString *)weixin_openid
                       weibo_openid:(nullable NSString *)weibo_openid
                              extra:(nullable NSDictionary *)extra
                       successBlock:(void (^)(void))successBlock;


/// 上报动作信息
/// @param item_type 产品内部定义 传当前资讯对象的类型 在算法库内登记的ID 格式为int(6)
/// @param origin_item_id APP内资讯的ID
/// @param action_type 1阅读 2点赞 3收藏 4评论 5转发 6不喜欢 7报告 8播放 9拖拽 10加载 11缓冲  12暂停  13停止  其中123456 10没有action_start参数 除7以外 没有step参数   8播放会触发定时step上报，13停止会取消定时step上报
/// @param extra 额外信息
+ (void)reportActionWithItem_type:(nonnull NSString *)item_type
                   origin_item_id:(NSString *)origin_item_id
                      action_type:(ReportActionType)action_type
                            extra:(nullable NSDictionary *)extra;


/// 退出登录时调用，撤销原token，并重新获取token
+ (void)logout;

+ (NSString *)getTypeWithValue:(nonnull NSString *)value;

+ (NSString *)version;

@end

NS_ASSUME_NONNULL_END


