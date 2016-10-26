# AWS Mobile Hub Helper for iOS

The AWS Mobile Hub simplifies the process of building, testing, and monitoring mobile applications that make use of one or more AWS services. It helps you skip the heavy lifting of integrating and configuring services by letting you add and configure features to your apps, including user authentication, data storage, backend logic, push notifications, content delivery, and analytics—all from a single, integrated console.

This helper code is the source for the AWSMobileHubHelper.framework file which is included with every Objective C and Swift application download from AWS Mobile Hub. 

* [API Docs](https://docs.aws.amazon.com/awsmobilehubhelper/apireference/latest/index.html)
* [Forums](https://forums.aws.amazon.com/forum.jspa?forumID=88)
* [Issues](https://github.com/aws/aws-mobilehub-helper-ios/issues)

## Distribution

You can download the framework along with the sample app from the mobile hub [console](https://console.aws.amazon.com/mobilehub) under the build section. The framework is currently distributed as a static library.

## Building framework from source

You can build the framework from source using the [Script](Scripts/GenerateHelperFramework.sh). The API reference documentation can be generated using the [Script](Scripts/GenerateHelperFrameworkDocs.sh).

## Submitting Pull Requests

At this time we are accepting pull requests only for Bug fixes (one bug fix per requests). For new features please submit feedback on the [mobile hub console](https://console.aws.amazon.com/mobilehub/home) (link for feedback on the bottom left corner). Please make sure that your pull requests comply with the license.

##Modifications, Fixes, Enhancements
For this fork:

authenticatedBy method
A user readable name (providerKey) of the currentSignInProvider, such as Facebook or Google or
Cognito Your User Pools.  Note you may be authenticated with more id's
logins may contain multiple providers, but only one is the currentSignInProvider
Returns providerKey of currentSignInProvider or "Guest"

currentSignInProvider property
Some processes in a mobile app require access to the currentSignInProvider.
For example with custom OpenIdConnect or CognitoUserPools providers you may
need to have access to the provider in order to sign-up a user, or recall a forgotten
password.  The SignInProvider class is a good place to encapsulate interfacing with
the authentication provider, but we need to be able to get the currentSignInProvider

activeProviders property
Returns an array of instances of AWSSignInProviders with active sessions. 
SignIn Providers that have active sessions store a value in NSUserDefaults with thier
providerKey as a key.  Usually this value is "YES", but does not need to be (some have
stored a token).  The existence of any value is enough to indicate that there is an 
active session with this provider.
Returns NSArray of active AWSSignInProvider instances

providerKey method
A user readable name of the signInProvider passed as an such as Facebook or Google or
Cognito Your User Pools.  This is the value for the Class name key in the 
Info.plist ClassNameKeyDictionary
Returns provider name or nil (if classname not found)

interceptApplication method
Modified so that it re-instantiates any AWSSignInProviders listed in the SignInProviderKeyDictionary in Info.plist Some (Cognito User Pools, or developer providers) will interact directly with the application. Modified so that it re-instantiates any 
AWSSignInProviders listed in the SignInProviderKeyDictionary in Info.plist (not
just Google and Facebook).

Other:
Support for Allow Simultaneous Active Accounts in Info.plist
Requires Allow Identity Merging to be YES.

Support for Allow Identity Merging in Info.plist
Various modifications to functions including logins to produce a merged logins response when a user logs in to a second account while using a first account.  Controlled by the Info.plist boolean flag  “Allow Identity Merging”.  This allows the credentials provider to merge identityId’s when two logins occur simultaneously.




