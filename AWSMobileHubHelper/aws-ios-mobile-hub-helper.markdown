The AWS iOS Mobile Hub Helper provides a helper library written on top of AWS iOS SDK for developers to build connected applications for iPad, iPhone, or iPod touch devices using Amazon Web Services. It provides multiple utilities which are descibed in this API Reference. It also includes code snippets describing how to use the functions available in framework.

It is recommended that you configure your project through AWS Mobile Hub for appropriate configuration and settings for using the below utilities.

#Identity
Identity in Mobile Hub Helper is managed by AWSIdentityManager.  This is a singleton that is initialized the first time you access the AWSIdentityManager.defaultIdentityManager().  AWSIdentityManager is responsible for providing credentials for AWS managing both authenticated and unauthenticated identityId's. AWSIdentityManager does this with helpers that conform to the protocol AWSSignInProvider.  AWSSignInProviders are provided for Google+ and Facebook. You can write your own AWSSignInProvider, and there is at least one (for Cognito User Pools AWSCUPIdPSignInProvider.swift, included in this repository but not linked (because swift can't make a static library, so you would need to copy it into your project.). If you configure an your identity provider in Info.plist, it will be included as a possible sign in source.  It is your responsibility to manage the user interface to collect username password, or link to a web site that does, for each AWSSignInProvider you want to use.

The AWSSignInProvider's are singletons, and you simply reference them to instantiate them. For all functions related to logging in, logging out, and identityId's you use AWSIdentityManager to call the AWSSignInProvider.  AWSIdentityManager also returns the "friendly" name of the provider (via providerKey) and the friendly name of the current signInProvider (via authenticatedBy)

All of the AWSSignInProviders have methods for token (return a (usually openId)) token and identityProviderName. For AWSCUPIdPSignInProvider there are and for developer identitys there may be other methods available, for instance SignUp, Forgot password, update attributes, etc. 

The Mobile Hub configures it's project using AWSMobileClient from AppDelegate.  For identity, AWSMobileClient instantiates AWSIdentityManager.defaultIdentityManager() and calls interceptApplication which restarts any sessions that were active when the app was last run or simply returns with no active sessions and no active SignInProvider.

At any point you can request login from AWSIdentityManager specifiying an AWSsignInProvider.  In the case of AWSCUPIdPSignInProvider you have to pre-populate the username and password properties directly in the signInProvider (AWSIdentityManager does not yet provide that capability). 

#Modifications, Fixes, Enhancements

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
providerKey as a key. 
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


