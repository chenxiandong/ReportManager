//
//  ReportManager.m
//  cztvVideoiPhone
//
//  Created by Chenxd on 2020/7/21.
//  Copyright © 2020 Zhejiang Xinlan Network Media Limited Company. All rights reserved.
//

#import "ReportManager.h"
#import "XLSSKeychain.h"
#import <sys/utsname.h>
#import <WebKit/WebKit.h>

#define ReportManagerVersion @"1.0.0"

@interface ReportManager ()<NSURLSessionDataDelegate>
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, copy) NSString *baseUrl;
@property (nonatomic, copy) NSString *customerId;
@property (nonatomic, copy) NSString *productId;
@property (nonatomic, assign) NSTimeInterval token_expires_in;

@property (nonatomic, copy) NSString *previous_g_id;
@property (nonatomic, copy) NSString *g_original_id;

@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy) NSString *birthday;
@property (nonatomic, copy) NSString *sex;
@property (nonatomic, copy) NSString *phone;
@property (nonatomic, copy) NSString *apple_openid;
@property (nonatomic, copy) NSString *qq_openid;
@property (nonatomic, copy) NSString *weixin_openid;
@property (nonatomic, copy) NSString *weibo_openid;
@property (nonatomic, copy) NSString *district;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *province;
@property (nonatomic, copy) NSString *country;
@property (nonatomic, strong) NSDictionary *authorizationsExtra;

@property (nonatomic, copy) NSString *app_version;
@property (nonatomic, copy) NSString *device_model;
@property (nonatomic, copy) NSString *device_os;

@property (nonatomic, assign) NSInteger actionType;
@property (nonatomic, strong) NSMutableDictionary *stepTimerDic;
@property (nonatomic, strong) NSMutableDictionary *actionTimeDic;
//@property (nonatomic, strong) NSSet *actionTimeSet;  //保存需要上报actionTime的actionType
@property (nonatomic, assign) NSInteger step;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, copy) NSString *userAgent;
@end

@implementation ReportManager

+ (void)initWithCustomerId:(NSString *)customerId productId:(NSString *)productId {
    ReportManager *manager = [self shareManager];
    manager.customerId = customerId;
    manager.productId = productId;
}

+ (ReportManager *)shareManager {
    static ReportManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (manager == nil) {
           manager= [[self alloc] init];
        }
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
        self.webView = [WKWebView new];
        [self.webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable oldAgent, NSError * _Nullable error) {
            self.userAgent = oldAgent;
        }];
        
        self.baseUrl = @"http://algo.cztv.com";
        self.step = 30;
        self.session = [NSURLSession sharedSession];
        self.stepTimerDic = [NSMutableDictionary dictionary];
        self.actionTimeDic = [NSMutableDictionary dictionary];
//        self.actionTimeSet = [NSSet setWithArray:@[@"7", @"8", @"9", @"11", @"12", @"13"]];
        self.access_token = [[NSUserDefaults standardUserDefaults] objectForKey:@"report_access_token"];
        NSNumber *expirs_in = [[NSUserDefaults standardUserDefaults] objectForKey:@"report_access_token_expires_in"];
        if (expirs_in) {
            self.token_expires_in = [expirs_in doubleValue];
        }
        
        self.app_version = [NSString stringWithFormat:@"%@ %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
        struct utsname systemInfo;
        uname(&systemInfo);
        self.device_model = [ReportManager iphoneType];
    
//        [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
        self.device_os = [NSString stringWithFormat:@"ios %@", [[UIDevice currentDevice] systemVersion]];

    }
    return self;
}

+ (NSString *)version {
    return ReportManagerVersion;
}

+ (void)setBaseUrl:(NSString *)baseUrl {
    ReportManager *manager = [self shareManager];
    manager.baseUrl = baseUrl;
}

+ (void)setStep:(NSInteger)step {
    ReportManager *manager = [self shareManager];
    manager.step = step;
}

+ (void)updateDistrict:(NSString *)district city:(NSString *)city province:(NSString *)province country:(NSString *)country {
    ReportManager *manager = [self shareManager];
    manager.district = district;
    manager.city = city;
    manager.province = province;
    manager.country = country;
}

+ (void)updatePlayerCurrentTime:(NSInteger)currentTime origin_item_id:(nonnull NSString *)origin_item_id {
    ReportManager *manager = [self shareManager];
    [manager.actionTimeDic setObject:@(currentTime).stringValue forKey:origin_item_id];
}

+ (void)getAuthorizationsWithUserId:(NSString *)userId name:(NSString *)name nickname:(NSString *)nickname birthday:(NSString *)birthday sex:(NSString *)sex phone:(NSString *)phone apple_openid:(nullable NSString *)apple_openid qq_openid:(NSString *)qq_openid weixin_openid:(NSString *)weixin_openid weibo_openid:(NSString *)weibo_openid extra:(nullable NSDictionary *)extra {
    ReportManager *manager = [self shareManager];
    manager.userId = userId;
    manager.name = name;
    manager.nickname = nickname;
    manager.birthday = birthday;
    manager.sex = sex;
    manager.phone = phone;
    manager.apple_openid = apple_openid;
    manager.qq_openid = qq_openid;
    manager.weibo_openid = weibo_openid;
    manager.weixin_openid = weixin_openid;
    manager.authorizationsExtra = extra;
    [self getAuthorizationsWithUserId:userId name:name nickname:nickname birthday:birthday sex:sex phone:phone apple_openid:apple_openid qq_openid:qq_openid weixin_openid:weixin_openid weibo_openid:weibo_openid district:manager.district city:manager.city province:manager.province country:manager.country extra:extra successBlock:nil];
}

+ (void)getAuthorizationsWithUserId:(NSString *)userId name:(NSString *)name nickname:(NSString *)nickname birthday:(NSString *)birthday sex:(NSString *)sex phone:(NSString *)phone apple_openid:(nullable NSString *)apple_openid qq_openid:(NSString *)qq_openid weixin_openid:(NSString *)weixin_openid weibo_openid:(NSString *)weibo_openid extra:(nullable NSDictionary *)extra successBlock:(void (^)(void))successBlock {
    ReportManager *manager = [self shareManager];
    manager.userId = userId;
    manager.name = name;
    manager.nickname = nickname;
    manager.birthday = birthday;
    manager.sex = sex;
    manager.phone = phone;
    manager.apple_openid = apple_openid;
    manager.qq_openid = qq_openid;
    manager.weibo_openid = weibo_openid;
    manager.weixin_openid = weixin_openid;
    manager.authorizationsExtra = extra;
    [self getAuthorizationsWithUserId:userId name:name nickname:nickname birthday:birthday sex:sex phone:phone apple_openid:apple_openid qq_openid:qq_openid weixin_openid:weixin_openid weibo_openid:weibo_openid district:manager.district city:manager.city province:manager.province country:manager.country extra:extra successBlock:successBlock];
}

+ (void)reportActionWithItem_type:(NSString *)item_type origin_item_id:(NSString *)origin_item_id action_type:(ReportActionType)action_type extra:(NSDictionary *)extra {
    ReportManager *manager = [self shareManager];
    NSString *step = nil;
    if (action_type == ReportActionTypePlay) {
        step = @(manager.step).stringValue;
    }
    NSString *action_start = nil;
    if (action_type == ReportActionTypeReport ||
        action_type == ReportActionTypePlay ||
        action_type == ReportActionTypeDrag ||
        action_type == ReportActionTypeBuffering ||
        action_type == ReportActionTypePause ||
        action_type == ReportActionTypeStop) {
        action_start = [manager.actionTimeDic objectForKey:origin_item_id];
    }
    [self reportActionWithItem_type:item_type product_id:manager.productId origin_item_id:origin_item_id action_type:action_type action_start:action_start step:step country:manager.country province:manager.province city:manager.city district:manager.district extra:extra];
}

+ (void)reportActionWithItem_type:(NSString *)item_type product_id:(NSString *)product_id origin_item_id:(NSString *)origin_item_id action_type:(ReportActionType)action_type action_start:(NSString *)action_start step:(NSString *)step country:(NSString *)country province:(NSString *)province city:(NSString *)city district:(NSString *)district extra:(NSDictionary *)extra {
    ReportManager *manager = [self shareManager];
    NSString *g_id = [self stringWithUUID];
    NSString *g_father_id = manager.previous_g_id;
    manager.previous_g_id = g_id;
    if (action_type == ReportActionTypeView || action_type == ReportActionTypeLaunch) manager.g_original_id = g_id;
    if (action_type == ReportActionTypeLaunch) origin_item_id = @"0";
    [self reportActionWithG_id:g_id g_father_id:g_father_id item_type:item_type product_id:product_id origin_item_id:origin_item_id action_type:action_type action_start:action_start step:step country:country province:province city:city district:district extra:extra];
}

+ (void)getAuthorizationsWithUserId:(NSString *)userId name:(NSString *)name nickname:(NSString *)nickname birthday:(NSString *)birthday sex:(NSString *)sex phone:(NSString *)phone apple_openid:(nullable NSString *)apple_openid qq_openid:(NSString *)qq_openid weixin_openid:(NSString *)weixin_openid weibo_openid:(NSString *)weibo_openid district:(NSString *)district city:(NSString *)city province:(NSString *)province country:(NSString *)country extra:(nullable NSDictionary *)extra successBlock:(void (^)(void))successBlock {
    NSString *uuid;
    NSString *bundleID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    if ([XLSSKeychain passwordForService:bundleID account:@"device_uuid"]) {
        uuid = [XLSSKeychain passwordForService:bundleID account:@"device_uuid"];
    } else {
        uuid = [self stringWithUUID];
        [XLSSKeychain setPassword:uuid forService:bundleID account:@"device_uuid"];
    }
    ReportManager *manager = [self shareManager];
    if (manager.customerId == nil || manager.productId == nil) {
#if DEBUG
        NSLog(@"ReportManager customerId 或 productId 为空");
#endif
        return;
    }
    
    
    /*
    NSMutableArray *pairs = [NSMutableArray array];
    [pairs addObject:[NSString stringWithFormat:@"customer_id=%@", manager.customerId]];
    [pairs addObject:[NSString stringWithFormat:@"product_id=%@", manager.productId]];
    [pairs addObject:[NSString stringWithFormat:@"device_id=%@", uuid]];

    if (userId)         [pairs addObject:[NSString stringWithFormat:@"origin_id=%@", userId]];
    if (name)           [pairs addObject:[NSString stringWithFormat:@"name=%@", name]];
    if (nickname)       [pairs addObject:[NSString stringWithFormat:@"nickname=%@", nickname]];
    if (birthday)       [pairs addObject:[NSString stringWithFormat:@"birthday=%@", birthday]];
    if (sex)            [pairs addObject:[NSString stringWithFormat:@"sex=%@", sex]];
    if (phone)          [pairs addObject:[NSString stringWithFormat:@"phone=%@", phone]];
    if (qq_openid)      [pairs addObject:[NSString stringWithFormat:@"qq_openid=%@", qq_openid]];
    if (weixin_openid)  [pairs addObject:[NSString stringWithFormat:@"weixin_openid=%@", weixin_openid]];
    if (weibo_openid)   [pairs addObject:[NSString stringWithFormat:@"weibo_openid=%@", weibo_openid]];
    if (district)       [pairs addObject:[NSString stringWithFormat:@"district=%@", district]];
    if (city)           [pairs addObject:[NSString stringWithFormat:@"city=%@", city]];
    if (province)       [pairs addObject:[NSString stringWithFormat:@"province=%@", province]];
    if (country)        [pairs addObject:[NSString stringWithFormat:@"country=%@", country]];
    if (extra)          [pairs addObject:[NSString stringWithFormat:@"extra=%@", extra]];
    NSString *params = [pairs componentsJoinedByString:@"&"];
    NSString *url = [NSString stringWithFormat:@"%@/api/authorizations", manager.baseUrl];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    request.HTTPMethod = @"POST";
    request.URL = [NSURL URLWithString:url];
    request.HTTPBody = [params dataUsingEncoding:NSUTF8StringEncoding];
    NSURLSessionDataTask *task = [manager.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error == nil && httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
            NSError *serializationError = nil;
            NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&serializationError];
            if (serializationError == nil) {
                manager.access_token = responseObject[@"access_token"];
                if (manager.access_token) {
                    [[NSUserDefaults standardUserDefaults] setObject:manager.access_token forKey:@"report_access_token"];
                }
                if (responseObject[@"expires_in"]) {
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
                    manager.token_expires_in = [[formatter dateFromString:responseObject[@"expires_in"]] timeIntervalSince1970];
                    [[NSUserDefaults standardUserDefaults] setObject:@(manager.token_expires_in) forKey:@"report_access_token_expires_in"];
                }
                [[NSUserDefaults standardUserDefaults] synchronize];
#if DEBUG
                NSLog(@"token获取成功 %@", responseObject);
#endif
                if (successBlock) {
                    successBlock();
                }
            }
        } else {
#if DEBUG
            NSLog(@"statusCode = %zd \n error = %@", httpResponse.statusCode, error);
#endif
        }
    }];
    [task resume];
    
    */

        NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (manager.customerId && manager.customerId.length > 0)  [params setObject:manager.customerId forKey:@"customer_id"];
        if (manager.productId && manager.productId.length > 0 )   [params setObject:manager.productId forKey:@"product_id"];
        if (uuid && uuid.length > 0 )                [params setObject:uuid forKey:@"device_id"];
        if (userId && userId.length > 0 )              [params setObject:userId forKey:@"origin_id"];
        if (name && name.length > 0 )                [params setObject:name forKey:@"name"];
        if (nickname && nickname.length > 0)                [params setObject:nickname forKey:@"nickname"];
        if (birthday && birthday.length > 0)            [params setObject:birthday forKey:@"birthday"];
        if (sex && sex.length > 0 )                 [params setObject:sex forKey:@"sex"];
        if (phone && phone.length > 0 )    [params setObject:phone forKey:@"phone"];
        if (apple_openid && apple_openid.length > 0 )    [params setObject:apple_openid forKey:@"apple_openid"];
        if (qq_openid && qq_openid.length > 0)   [params setObject:qq_openid forKey:@"qq_openid"];
        if (weixin_openid && weixin_openid.length > 0 )        [params setObject:weixin_openid forKey:@"weixin_openid"];
        if (weibo_openid && weibo_openid.length > 0 )       [params setObject:weibo_openid forKey:@"weibo_openid"];
        if (district && district.length > 0 )           [params setObject:district forKey:@"district"];
        if (city && city.length > 0 )       [params setObject:city forKey:@"city"];
        if (province && province.length > 0 )     [params setObject:province forKey:@"province"];
        if (country && country.length > 0 )     [params setObject:country forKey:@"country"];
        if (extra)     [params setObject:extra forKey:@"extra"];
    
        NSString *url = [NSString stringWithFormat:@"%@/api/authorizations", manager.baseUrl];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        request.HTTPMethod = @"POST";
        request.URL = [NSURL URLWithString:url];
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:params options:(NSJSONWritingOptions)0 error:nil];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSURLSessionDataTask *task = [manager.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (error == nil && httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                NSError *serializationError = nil;
                NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&serializationError];
                if (serializationError == nil) {
                    manager.access_token = responseObject[@"access_token"];
                    if (manager.access_token) {
                        [[NSUserDefaults standardUserDefaults] setObject:manager.access_token forKey:@"report_access_token"];
                    }
                    if (responseObject[@"expires_in"]) {
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
                        manager.token_expires_in = [[formatter dateFromString:responseObject[@"expires_in"]] timeIntervalSince1970];
                        [[NSUserDefaults standardUserDefaults] setObject:@(manager.token_expires_in) forKey:@"report_access_token_expires_in"];
                    }
                    [[NSUserDefaults standardUserDefaults] synchronize];
    #if DEBUG
                    NSLog(@"token获取成功 %@", responseObject);
    #endif
                    if (successBlock) {
                        successBlock();
                    }
                }
            } else {
    #if DEBUG
                NSLog(@"statusCode = %zd \n error = %@", httpResponse.statusCode, error);
    #endif
            }
        }];
        [task resume];
    
    
}


+ (void)reportActionWithG_id:(NSString *)g_id g_father_id:(NSString *)g_father_id  item_type:(NSString *)item_type product_id:(NSString *)product_id origin_item_id:(NSString *)origin_item_id action_type:(ReportActionType)action_type action_start:(NSString *)action_start step:(NSString *)step country:(NSString *)country province:(NSString *)province city:(NSString *)city district:(NSString *)district extra:(NSDictionary *)extra {
    ReportManager *manager = [self shareManager];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    NSString *action_time = [formatter stringFromDate:[NSDate date]];
    NSString *g_original_id = manager.g_original_id;
    
//    if (manager.token_expires_in - [[NSDate date] timeIntervalSince1970] <= 10) {  //刷新token后再上报
//        [self getAuthorizationsWithUserId:manager.userId name:manager.name nickname:manager.nickname birthday:manager.birthday sex:manager.sex phone:manager.phone qq_openid:manager.qq_openid weixin_openid:manager.weixin_openid weibo_openid:manager.weibo_openid district:manager.district city:manager.city province:manager.province country:manager.country extra:manager.authorizationsExtra successBlock:^{
//            [self reportActionWithItem_type:item_type product_id:product_id origin_item_id:origin_item_id action_type:action_type action_start:action_start step:step country:country province:province city:city district:district extra:extra];
//        }];
//        return;
//    }
    
    
    
    NSMutableDictionary *finalExtra = [NSMutableDictionary dictionary];
    if (manager.app_version) [finalExtra setObject:manager.app_version forKey:@"app_version"];
    if (manager.device_model) [finalExtra setObject:manager.device_model forKey:@"device_model"];
    if (manager.device_os) [finalExtra setObject:manager.device_os forKey:@"device_os"];
    [finalExtra setObject:@"2" forKey:@"device_platform"];
    if (manager.userAgent.length > 0) {
       [finalExtra setObject:manager.userAgent forKey:@"browser_ua"];
    }
    
    if (extra && [extra isKindOfClass:[NSDictionary class]]) {
        for (NSString *key in extra.allKeys) {
            [finalExtra setObject:extra[key] forKey:key];
        }
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (g_id)           [params setObject:g_id forKey:@"g_id"];
    if (g_original_id)  [params setObject:g_original_id forKey:@"g_origin_id"];
    if (g_father_id)    [params setObject:g_father_id forKey:@"g_father_id"];
    if (item_type)      [params setObject:item_type forKey:@"item_type"];
    if (product_id)     [params setObject:product_id forKey:@"product_id"];
    if (origin_item_id) [params setObject:origin_item_id forKey:@"origin_item_id"];
    if (action_time)    [params setObject:action_time forKey:@"action_time"];
    if (action_type > 0)[params setObject:@(action_type) forKey:@"action_type"];
    if (action_start)   [params setObject:action_start forKey:@"action_start"];
    if (country)        [params setObject:country forKey:@"country"];
    if (province)       [params setObject:province forKey:@"province"];
    if (city)           [params setObject:city forKey:@"city"];
    if (district)       [params setObject:district forKey:@"district"];
    if (finalExtra)     [params setObject:finalExtra forKey:@"extra"];
    if (step && action_type == ReportActionTypeReport) [params setObject:step forKey:@"step"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/algo/pushAction", manager.baseUrl];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    request.HTTPMethod = @"POST";
    request.URL = [NSURL URLWithString:url];
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:params options:(NSJSONWritingOptions)0 error:nil];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", manager.access_token] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task = [manager.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error == nil && httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
            NSError *serializationError = nil;
            NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&serializationError];
            if (serializationError == nil) {
                NSInteger status_code = [responseObject[@"status_code"] integerValue];
                if (status_code == 401) {  //token获取不正确或者过期,重新获取
                    [self getAuthorizationsWithUserId:manager.userId name:manager.name nickname:manager.nickname birthday:manager.birthday sex:manager.sex phone:manager.phone apple_openid:manager.apple_openid qq_openid:manager.qq_openid weixin_openid:manager.weixin_openid weibo_openid:manager.weibo_openid district:manager.district city:manager.city province:manager.province country:manager.country extra:manager.authorizationsExtra successBlock:^{
                        [self reportActionWithItem_type:item_type product_id:product_id origin_item_id:origin_item_id action_type:action_type action_start:action_start step:step country:country province:province city:city district:district extra:extra];
                    }];
                }
#if DEBUG
                if (status_code == 200) {
                    NSLog(@"actionType:%zd 上报成功", action_type);
                } else {
                    NSLog(@"actionType:%zd 上报失败", action_type);
                }
                NSLog(@"%@", responseObject);
#endif
            }
        } else {
#if DEBUG
            NSLog(@"actionType:%zd 上报失败 statusCode = %zd \n error = %@", action_type, httpResponse.statusCode, error);
#endif
        }
    }];
    [task resume];
    
    //定时上报
    if (action_type == ReportActionTypePlay) {
        if ([manager.stepTimerDic objectForKey:origin_item_id]) return;
        dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, [step integerValue] * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(timer, ^{
#if DEBUG
            NSLog(@"step 定时上报");
#endif
            NSString *action_start = nil;
            if (action_type == ReportActionTypeReport ||
                action_type == ReportActionTypePlay ||
                action_type == ReportActionTypeDrag ||
                action_type == ReportActionTypeBuffering ||
                action_type == ReportActionTypePause ||
                action_type == ReportActionTypeStop) {
                action_start = [manager.actionTimeDic objectForKey:origin_item_id];
            }
            [self reportActionWithG_id:g_id g_father_id:g_father_id item_type:item_type product_id:product_id origin_item_id:origin_item_id action_type:ReportActionTypeReport action_start:action_start step:step country:country province:province city:city district:district extra:extra];
        });
        dispatch_resume(timer);
        [manager.stepTimerDic setObject:timer forKey:origin_item_id];
    }
    //取消定时上报
    if (action_type == ReportActionTypeStop) {
#if DEBUG
        NSLog(@"stop 取消定时上报");
#endif
        dispatch_source_t timer = [manager.stepTimerDic objectForKey:origin_item_id];
        [manager.stepTimerDic removeObjectForKey:origin_item_id];
        if (timer) dispatch_source_cancel(timer);
        timer = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updatePlayerCurrentTime:0 origin_item_id:origin_item_id];
        });
    }
}

+ (void)logout {
    ReportManager *manager = [self shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/api/authorizations", manager.baseUrl];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    request.HTTPMethod = @"DELETE";
    request.URL = [NSURL URLWithString:url];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", manager.access_token] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task = [manager.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
#if DEBUG
        NSLog(@"%@", httpResponse);
#endif
        if (error == nil && httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"report_access_token"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"report_access_token_expires_in"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self getAuthorizationsWithUserId:nil name:nil nickname:nil birthday:nil sex:nil phone:nil apple_openid:nil qq_openid:nil weixin_openid:nil weibo_openid:nil extra:manager.authorizationsExtra];
        }
    }];
    [task resume];
}


+ (NSString *)stringWithUUID {
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return (__bridge_transfer NSString *)string;
}


+ (NSString *)getTypeWithValue:(nonnull NSString *)value{
    
    if ([value isEqualToString:@"news"]) {
        return @"1";
    } else if ([value isEqualToString:@"video"]) {
        return @"2";
    }else if ([value isEqualToString:@"album"]) {
        return @"3";
    }else if ([value isEqualToString:@"multilive"]) {
        return @"4";
    }else if ([value isEqualToString:@"albumlive"]) {
        return @"5";
    }else if ([value isEqualToString:@"link"]) {
        return @"6";
    }else if ([value isEqualToString:@"link_auth"]) {
        return @"7";
    }else if ([value isEqualToString:@"topic"]) {
        return @"8";
    }else if ([value isEqualToString:@"tv"]) {
        return @"9";
    }else if ([value isEqualToString:@"radio"]) {
        return @"10";
    }else if ([value isEqualToString:@"live"]) {
        return @"11";
    }else if ([value isEqualToString:@"dislike"]) {
        return @"12";
    }else{
        return @"13";
    }
    
}




+(NSString*)iphoneType {
 
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *platform = [NSString stringWithCString: systemInfo.machine encoding:NSASCIIStringEncoding];
 
    if ([platform isEqualToString:@"iPhone1,1"]) { return @"iPhone 2G";}
    if ([platform isEqualToString:@"iPhone1,2"]) { return @"iPhone 3G";}
    if ([platform isEqualToString:@"iPhone2,1"]) { return @"iPhone 3GS";}
    if ([platform isEqualToString:@"iPhone3,1"]) { return @"iPhone 4";}
    if ([platform isEqualToString:@"iPhone3,2"]) { return @"iPhone 4";}
    if ([platform isEqualToString:@"iPhone3,3"]) { return @"iPhone 4";}
    if ([platform isEqualToString:@"iPhone4,1"]) { return @"iPhone 4S";}
    if ([platform isEqualToString:@"iPhone5,1"]) { return @"iPhone 5";}
    if ([platform isEqualToString:@"iPhone5,2"]) { return @"iPhone 5";}
    if ([platform isEqualToString:@"iPhone5,3"]) { return @"iPhone 5C";}
    if ([platform isEqualToString:@"iPhone5,4"]) { return @"iPhone 5C";}
    if ([platform isEqualToString:@"iPhone6,1"]) { return @"iPhone 5S";}
    if ([platform isEqualToString:@"iPhone6,2"]) { return @"iPhone 5S";}
    if ([platform isEqualToString:@"iPhone7,1"]) { return @"iPhone 6 Plus";}
    if ([platform isEqualToString:@"iPhone7,2"]) { return @"iPhone 6";}
    if ([platform isEqualToString:@"iPhone8,1"]) { return @"iPhone 6S";}
    if ([platform isEqualToString:@"iPhone8,2"]) { return @"iPhone 6S Plus";}
    if ([platform isEqualToString:@"iPhone8,4"]) { return @"iPhone SE";}
    if ([platform isEqualToString:@"iPhone9,1"]) { return @"iPhone 7";}
    if ([platform isEqualToString:@"iPhone9,2"]) { return @"iPhone 7 Plus";}
    if ([platform isEqualToString:@"iPhone10,1"])  { return @"iPhone 8";}
    if ([platform isEqualToString:@"iPhone10,2"])  { return @"iPhone 8 Plus";}
    if ([platform isEqualToString:@"iPhone10,3"])  { return @"iPhone X";}
    if ([platform isEqualToString:@"iPhone10,4"])  { return @"iPhone 8";}
    if ([platform isEqualToString:@"iPhone10,5"])  { return @"iPhone 8 Plus";}
    if ([platform isEqualToString:@"iPhone10,6"]) { return @"iPhone X";}
    if ([platform isEqualToString:@"iPhone11,8"]) { return @"iPhone XR";}
     if ([platform isEqualToString:@"iPhone11,2"])  { return @"iPhone XS";}
     if ([platform isEqualToString:@"iPhone11,4"])  { return @"iPhone XS Max";}
     if ([platform isEqualToString:@"iPhone11,6"])  { return @"iPhone XS Max";}

    if ([platform isEqualToString:@"iPod1,1"])  { return @"iPod Touch 1G";}
    if ([platform isEqualToString:@"iPod2,1"]) { return @"iPod Touch 2G";}
    if ([platform isEqualToString:@"iPod3,1"])  { return @"iPod Touch 3G";}
    if ([platform isEqualToString:@"iPod4,1"]) { return @"iPod Touch 4G";}
    if ([platform isEqualToString:@"iPod5,1"])  { return @"iPod Touch 5G";}

    if ([platform isEqualToString:@"iPad1,1"])  { return @"iPad 1";}
    if ([platform isEqualToString:@"iPad2,1"])  { return @"iPad 2";}
    if ([platform isEqualToString:@"iPad2,2"])  { return @"iPad 2";}
    if ([platform isEqualToString:@"iPad2,3"])  { return @"iPad 2";}
    if ([platform isEqualToString:@"iPad2,4"])  { return @"iPad 2";}
    if ([platform isEqualToString:@"iPad2,5"]) { return @"iPad Mini 1";}
    if ([platform isEqualToString:@"iPad2,6"]) { return @"iPad Mini 1";}
    if ([platform isEqualToString:@"iPad2,7"])  { return @"iPad Mini 1";}
    if ([platform isEqualToString:@"iPad3,1"])  { return @"iPad 3";}
    if ([platform isEqualToString:@"iPad3,2"]) { return @"iPad 3";}
    if ([platform isEqualToString:@"iPad3,3"])  { return @"iPad 3";}
    if ([platform isEqualToString:@"iPad3,4"])  { return @"iPad 4";}
    if ([platform isEqualToString:@"iPad3,5"]) { return @"iPad 4";}
    if ([platform isEqualToString:@"iPad3,6"]) { return @"iPad 4";}
    if ([platform isEqualToString:@"iPad4,1"]) { return @"iPad Air";}
    if ([platform isEqualToString:@"iPad4,2"]) { return @"iPad Air";}
    if ([platform isEqualToString:@"iPad4,3"]) { return @"iPad Air";}
    if ([platform isEqualToString:@"iPad4,4"]) { return @"iPad Mini 2";}
    if ([platform isEqualToString:@"iPad4,5"]) { return @"iPad Mini 2";}
    if ([platform isEqualToString:@"iPad4,6"]) { return @"iPad Mini 2";}
    if ([platform isEqualToString:@"iPad4,7"]) { return @"iPad Mini 3";}
    if ([platform isEqualToString:@"iPad4,8"]) { return @"iPad Mini 3";}
    if ([platform isEqualToString:@"iPad4,9"]) { return @"iPad Mini 3";}
    if ([platform isEqualToString:@"iPad5,1"]) { return @"iPad Mini 4";}
    if ([platform isEqualToString:@"iPad5,2"]) { return @"iPad Mini 4";}
    if ([platform isEqualToString:@"iPad5,3"]) { return @"iPad Air 2";}
    if ([platform isEqualToString:@"iPad5,4"]) { return @"iPad Air 2";}
    if ([platform isEqualToString:@"iPad6,3"]) { return @"iPad Pro 9.7";}
    if ([platform isEqualToString:@"iPad6,4"]) { return @"iPad Pro 9.7";}
    if ([platform isEqualToString:@"iPad6,7"]) { return @"iPad Pro 12.9";}
    if ([platform isEqualToString:@"iPad6,8"]) { return @"iPad Pro 12.9";}

    if ([platform isEqualToString:@"i386"]) { return @"iPhone Simulator";}
    if ([platform isEqualToString:@"x86_64"]) { return @"iPhone Simulator";}
 
return platform;
 
}











@end

