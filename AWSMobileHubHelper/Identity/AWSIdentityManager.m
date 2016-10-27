//
//  AWSIdentityManager.m
//
// Copyright 2016 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to
// copy, distribute and modify it.
//

#import "AWSIdentityManager.h"
#import "AWSSignInProvider.h"
#import "AWSFacebookSignInProvider.h"
#import "AWSGoogleSignInProvider.h"

NSString *const AWSIdentityManagerDidSignInNotification = @"com.amazonaws.AWSIdentityManager.AWSIdentityManagerDidSignInNotification";
NSString *const AWSIdentityManagerDidSignOutNotification = @"com.amazonaws.AWSIdentityManager.AWSIdentityManagerDidSignOutNotification";

typedef void (^AWSIdentityManagerCompletionBlock)(id result, NSError *error);

@interface AWSIdentityManager()

@property (nonatomic, strong) AWSCognitoCredentialsProvider *credentialsProvider;
@property (atomic, copy) AWSIdentityManagerCompletionBlock completionHandler;

@property (nonatomic, strong) id<AWSSignInProvider> currentSignInProvider;

@end

@implementation AWSIdentityManager

static NSString *const AWSInfoIdentityManager = @"IdentityManager";
static NSString *const AWSInfoRoot = @"AWS";
static NSString *const AWSInfoMobileHub = @"MobileHub";
static NSString *const AWSInfoProjectClientId = @"ProjectClientId";

+ (instancetype)defaultIdentityManager {
    static AWSIdentityManager *_defaultIdentityManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AWSServiceInfo *serviceInfo = [[AWSInfo defaultAWSInfo] defaultServiceInfo:AWSInfoIdentityManager];
        
        if (!serviceInfo) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:@"The service configuration is `nil`. You need to configure `Info.plist` before using this method."
                                         userInfo:nil];
        }
        _defaultIdentityManager = [[AWSIdentityManager alloc] initWithCredentialProvider:serviceInfo];
    });
    
    return _defaultIdentityManager;
}

- (instancetype)initWithCredentialProvider:(AWSServiceInfo *)serviceInfo {
    if (self = [super init]) {
        [AWSLogger defaultLogger].logLevel = AWSLogLevelVerbose;
        
        self.credentialsProvider = serviceInfo.cognitoCredentialsProvider;
        [self.credentialsProvider setIdentityProviderManagerOnce:self];
        
        // Init the ProjectTemplateId
        NSString *projectTemplateId = [[[AWSInfo defaultAWSInfo].rootInfoDictionary objectForKey:AWSInfoMobileHub] objectForKey:AWSInfoProjectClientId];
        if (!projectTemplateId) {
            projectTemplateId = @"MobileHub HelperFramework";
        }
        [AWSServiceConfiguration addGlobalUserAgentProductToken:projectTemplateId];
    }
    return self;
}

#pragma mark - AWSIdentityProviderManager

- (AWSTask<NSDictionary<NSString *, NSString *> *> *)logins {
    if (!self.currentSignInProvider) {
        return [AWSTask taskWithResult:nil];
    }
    return [[self.currentSignInProvider token] continueWithSuccessBlock:^id _Nullable(AWSTask<NSString *> * _Nonnull task) {
        NSString *token = task.result;
        return [AWSTask taskWithResult:@{self.currentSignInProvider.identityProviderName : token}];
    }];
}

#pragma mark -

- (NSString *)identityId {
    return self.credentialsProvider.identityId;
}

- (BOOL)isLoggedIn {
    return self.currentSignInProvider.isLoggedIn;
}

- (NSURL *)imageURL {
    return self.currentSignInProvider.imageURL;
}

- (NSString *)userName {
    return self.currentSignInProvider.userName;
}

- (void)wipeAll {
    [self.credentialsProvider clearKeychain];
}

- (void)logoutWithCompletionHandler:(void (^)(id result, NSError *error))completionHandler {
    if ([self.currentSignInProvider isLoggedIn]) {
        [self.currentSignInProvider logout];
    }
    
    [self wipeAll];
    
    self.currentSignInProvider = nil;
    
    [[self.credentialsProvider getIdentityId] continueWithBlock:^id _Nullable(AWSTask<NSString *> * _Nonnull task) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
            [notificationCenter postNotificationName:AWSIdentityManagerDidSignOutNotification
                                              object:[AWSIdentityManager defaultIdentityManager]
                                            userInfo:nil];
            if (task.exception) {
                AWSLogError(@"Fatal exception: [%@]", task.exception);
                kill(getpid(), SIGKILL);
            }
            completionHandler(task.result, task.error);
        });
        return nil;
    }];
}

- (void)loginWithSignInProvider:(id)signInProvider
              completionHandler:(void (^)(id result, NSError *error))completionHandler {
    self.currentSignInProvider = signInProvider;
    
    self.completionHandler = completionHandler;
    [self.currentSignInProvider login:completionHandler];
}

- (void)resumeSessionWithCompletionHandler:(void (^)(id result, NSError *error))completionHandler {
    self.completionHandler = completionHandler;
    
    [self.currentSignInProvider reloadSession];
    
    if (self.currentSignInProvider == nil) {
        [self completeLogin];
    }
}

- (void)completeLogin {
    // Force a refresh of credentials to see if we need to merge
    [self.credentialsProvider invalidateCachedTemporaryCredentials];
    
    [[self.credentialsProvider credentials] continueWithBlock:^id _Nullable(AWSTask<AWSCredentials *> * _Nonnull task) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.currentSignInProvider) {
                NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
                [notificationCenter postNotificationName:AWSIdentityManagerDidSignInNotification
                                                  object:[AWSIdentityManager defaultIdentityManager]
                                                userInfo:nil];
            }
            if (task.exception) {
                AWSLogError(@"Fatal exception: [%@]", task.exception);
                kill(getpid(), SIGKILL);
            }
            self.completionHandler(task.result, task.error);
        });
        return nil;
    }];
}

- (NSArray *)activeProviders {
    Class signInProviderClass = nil;
    
    AWSServiceInfo *serviceInfo = [[AWSInfo defaultAWSInfo] defaultServiceInfo:AWSInfoIdentityManager];
    NSDictionary *signInProviderKeyDictionary = [serviceInfo.infoDictionary objectForKey:@"SignInProviderKeyDictionary"];
    
    NSMutableArray *providerArray;
    providerArray = [[NSMutableArray<id<AWSSignInProvider>> alloc] init ];
    // loop through the Info.plist AWS->IdentityManager->Default->SignInProviderClassDictionary
    // and return any sessions found.
    // Dictionary is keyed by class name and the value is the providerKey
    // Example: "AWSGoogleSignInProvider":"Google" etc.
    for (NSString *key in signInProviderKeyDictionary) {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:[signInProviderKeyDictionary objectForKey:key]]) {
            signInProviderClass = NSClassFromString(key);
            [providerArray addObject:[signInProviderClass sharedInstance]]; // assemble list
            if (signInProviderClass && !providerArray.lastObject) {
                NSLog(@"Unable to locate the SignIn Provider SDK for %@. Signing Out any existing session...", key);
                [self wipeAll];
            }
        }
    }
    return providerArray;
}
- (BOOL)interceptApplication:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Restart any sessions found.

    for (id provider in [self activeProviders]) {
        
            self.currentSignInProvider = provider;
            }
            
            if (self.currentSignInProvider) {
                if (![self.currentSignInProvider interceptApplication:application
                                       didFinishLaunchingWithOptions:launchOptions]) {
                    NSLog(@"Unable to instantiate AWSSignInProvider for existing session.");
                }
            }
    
    return YES;
}

- (BOOL)interceptApplication:(UIApplication *)application
                     openURL:(NSURL *)url
           sourceApplication:(NSString *)sourceApplication
                  annotation:(id)annotation {
    if (self.currentSignInProvider) {
        return [self.currentSignInProvider interceptApplication:application
                                                        openURL:url
                                              sourceApplication:sourceApplication
                                                     annotation:annotation];
    }
    else {
        return YES;
    }
}

@end
