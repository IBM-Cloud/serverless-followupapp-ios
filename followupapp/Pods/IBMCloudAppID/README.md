# IBM Cloud App ID iOS Swift SDK

[![IBM Cloud powered][img-ibmcloud-powered]][url-ibmcloud]
[![Travis][img-travis-master]][url-travis-master]
[![Coveralls][img-coveralls-master]][url-coveralls-master]
[![Codacy][img-codacy]][url-codacy]
[![License][img-license]][url-bintray]

[![GithubWatch][img-github-watchers]][url-github-watchers]
[![GithubStars][img-github-stars]][url-github-stars]
[![GithubForks][img-github-forks]][url-github-forks]

## Requirements
* Xcode 9.0 or above
* CocoaPods 1.1.0 or higher
* MacOS 10.11.5 or higher
* iOS 10.0 or higher

## Installing the SDK:

1. Add the 'IBMCloudAppID' dependency to your Podfile, for example:

    ```swift
    target <yourTarget> do
       use_frameworks!
	     pod 'IBMCloudAppID'
    end
    ```  
2. From the terminal, run:  
    ```swift
    pod install --repo-update
    ```

## Initializing the App ID client SDK
1. Open your Xcode project and enable Keychain Sharing (Under project settings > Capabilities > Keychain sharing)
2. Under project setting > info > Url Types, Add $(PRODUCT_BUNDLE_IDENTIFIER) as a URL Scheme
3. Add the following import to your AppDelegate.swift file:
	```swift
	import IBMCloudAppID
	```
4. Initialize the client SDK by passing the tenantId and region parameters to the initialize method. A common, though not mandatory, place to put the initialization code is in the application:didFinishLaunchingWithOptions: method of the AppDelegate in your Swift application.
    ```swift
    AppID.sharedInstance.initialize(tenantId: <tenantId>, region: AppID.REGION_UK)
    ```
    * Replace "tenantId" with the App ID service tenantId.
    * Replace the `AppID.REGION_UK` with the your App ID region (`AppID.REGION_US_SOUTH`, `AppID.REGION_SYDNEY`).

5. Add the following code to you AppDelegate file
    ```swift
    func application(_ application: UIApplication, open url: URL, options :[UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return AppID.sharedInstance.application(application, open: url, options: options)
    }
    ```

## Using the Login Widget
After the App ID client SDK is initialized, you can start authenticating users by launching the Login Widget.
1. Add the following import to the file in which you want to use with the login Widget:
```swift
import IBMCloudAppID
```
2. Add the following code to the same file:
```swift
class delegate : AuthorizationDelegate {
    public func onAuthorizationSuccess(accessToken: AccessToken?, identityToken: IdentityToken?, refreshToken: RefreshToken?, response:Response?) {
        //User authenticated
    }

    public func onAuthorizationCanceled() {
        //Authentication canceled by the user
    }

    public func onAuthorizationFailure(error: AuthorizationError) {
        //Exception occurred
    }
}

AppID.sharedInstance.loginWidget?.launch(delegate: delegate())
```
**Note**:
* By default, App ID is configured to use Facebook, Google, and Cloud Directory as identity providers. If you change your identity provider settings to provide only one option, then the Login Widget is not needed and will not display. The user is directed to your chosen identity provider's authentication screen.
* When using Cloud Directory, and "Email verification" is configured to *not* allow users to sign-in without email verification, then the "onAuthorizationSuccess" of the "AuthorizationListener" will be invoked without tokens.


## Managing Cloud Directory with the iOS Swift SDK


### Sign in using Resource Owner Password

You can obtain access token and id token by supplying the end user's username and the end user's password.
  ```swift
  class delegate : TokenResponseDelegate {
      public func onAuthorizationSuccess(accessToken: AccessToken?, identityToken: IdentityToken?, refreshToken: RefreshToken?, response:Response?) {
      //User authenticated
      }

      public func onAuthorizationFailure(error: AuthorizationError) {
      //Exception occurred
      }
  }

  AppID.sharedInstance.signinWithResourceOwnerPassword(username: username, password: password, delegate: delegate())
  ```

### Sign in with refresh token

It is recommended to store the refresh token locally such that it will be possible to sign in with the refresh token without requiring the user to type his credentials again.
  ```swift
  class delegate : TokenResponseDelegate {
      public func onAuthorizationSuccess(accessToken: AccessToken?, identityToken: IdentityToken?, refreshToken: RefreshToken?, response:Response?) {
      //User authenticated
      }

      public func onAuthorizationFailure(error: AuthorizationError) {
      //Exception occurred
      }
  }

  AppID.sharedInstance.signInWithRefreshToken(refreshTokenString: refreshTokenString, delegate: delegate())
  ```


### Sign Up

Make sure to set **Allow users to sign up and reset their password** to **ON**, in the settings for Cloud Directory.

Use LoginWidget class to start the sign up flow.
```swift
class delegate : AuthorizationDelegate {
  public func onAuthorizationSuccess(accessToken: AccessToken?, identityToken: IdentityToken?, refreshToken: RefreshToken?, response:Response?) {
     if accessToken == nil && identityToken == nil {
      //email verification is required
      return
     }
   //User authenticated
  }

  public func onAuthorizationCanceled() {
      //Sign up canceled by the user
  }

  public func onAuthorizationFailure(error: AuthorizationError) {
      //Exception occurred
  }
}

AppID.sharedInstance.loginWidget?.launchSignUp(delegate: delegate())
```
### Forgot Password
Make sure to set **Allow users to sign up and reset their password** and **Forgot password email** to **ON**, in the settings for Cloud Directory.

Use LoginWidget class to start the forgot password flow.
```swift
class delegate : AuthorizationDelegate {
   public func onAuthorizationSuccess(accessToken: AccessToken?, identityToken: IdentityToken?, refreshToken: RefreshToken?, response:Response?) {
      //forgot password finished, in this case accessToken and identityToken will be null.
   }

   public func onAuthorizationCanceled() {
       //forgot password canceled by the user
   }

   public func onAuthorizationFailure(error: AuthorizationError) {
       //Exception occurred
   }
}

AppID.sharedInstance.loginWidget?.launchForgotPassword(delegate: delegate())
```
### Change Details

Make sure to set **Allow users to sign up and reset their password** to **ON**, in the settings for Cloud Directory.

Use LoginWidget class to start the change details flow.
This API can be used only when the user is logged in using Cloud Directory identity provider.
```swift

 class delegate : AuthorizationDelegate {
     public func onAuthorizationSuccess(accessToken: AccessToken?, identityToken: IdentityToken?, refreshToken: RefreshToken?, response:Response?) {
        //User authenticated, and fresh tokens received
     }

     public func onAuthorizationCanceled() {
         //changed details canceled by the user
     }

     public func onAuthorizationFailure(error: AuthorizationError) {
         //Exception occurred
     }
 }

 AppID.sharedInstance.loginWidget?.launchChangeDetails(delegate: delegate())
```

### Change Password

Make sure to set **Allow users to sign up and reset their password** to **ON**, in the settings for Cloud Directory.

Use LoginWidget class to start the change password flow.
This API can be used only when the user is logged in using Cloud Directory identity provider.
```swift
 class delegate : AuthorizationDelegate {
     public func onAuthorizationSuccess(accessToken: AccessToken?, identityToken: IdentityToken?, refreshToken: RefreshToken?, response:Response?) {
         //User authenticated, and fresh tokens received
     }

     public func onAuthorizationCanceled() {
         //change password canceled by the user
     }

     public func onAuthorizationFailure(error: AuthorizationError) {
          //Exception occurred
     }
  }

  AppID.sharedInstance.loginWidget?.launchChangePassword(delegate: delegate())
```

### User Profile

Using the App ID UserProfileManager, you are able to create, read, and delate attributes in a user's profile as well as retrieve additional info about a user.

```swift

let key = "attrKey"
let value = "attrValue"
let accessToken = "<access token>"
let idToken = "<id token>"

let userProfileManager = AppID.sharedInstance.userProfileManager

// Handle attribute response
func attributeHandler(error: Error?, response: [String: Any]) {}

/// If no tokens are passed, App ID will attempt to use the latest stored access and identity tokens

// Set Attributes
userProfileManager?.setAttribute(key: key, value: value, completionHandler: attributeHandler)
userProfileManager?.setAttribute(key: key, value: value, accessTokenString: accessToken)

// Get particular attribute
userProfileManager?.getAttribute(key: key, completionHandler: attributeHandler)
userProfileManager?.getAttribute(key: key, accessTokenString: accessToken, completionHandler: attributeHandler)

// Get all attributes
userProfileManager?.getAttributes(completionHandler: attributeHandler)
userProfileManager?.getAttributes(accessTokenString: accessToken, completionHandler: attributeHandler)

// Delete an Attribute
userProfileManager?.deleteAttribute(key: key, completionHandler:attributeHandler)
userProfileManager?.deleteAttribute(key: key, accessTokenString: accessToken, completionHandler: attributeHandler)

// Retrieve additional information about a user using the stored access/identity tokens
userProfileManager?.getUserInfo { (error: Error?, info: [String: Any]?) in

}

// Retrieve additional information about a user using the provided access and identity token
// If an identityToken is provided (recommended), we will validate the user info response
userProfileManager?.getUserInfo(accessTokenString: accessToken, identityTokenString: idToken { (error: Error?, info: [String: Any]?) in

}
```

## Invoking protected resources
Add the following imports to the file in which you want to invoke a protected resource request:
```swift
import BMSCore
import IBMCloudAppID
```
Then add the following code:
```swift
BMSClient.sharedInstance.initialize(region: AppID.REGION_UK)
BMSClient.sharedInstance.authorizationManager = AppIDAuthorizationManager(appid:AppID.sharedInstance)
var request:Request =  Request(url: "<your protected resource url>")
request.send(completionHandler: {(response:Response?, error:Error?) in
    //code handling the response here
})
```

## Setting Keychain Accessibility
In a rare case your application requires refreshing App ID tokens while running in the background you can use this API to set the required keychain permissions.
```
AppID.secAttrAccess = .accessibleAlways
```

## License
This package contains code licensed under the Apache License, Version 2.0 (the "License"). You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0 and may also view the License in the LICENSE file within this package.

[img-ibmcloud-powered]: https://img.shields.io/badge/ibm%20cloud-powered-blue.svg
[url-ibmcloud]: https://www.ibm.com/cloud/
[url-bintray]: https://bintray.com/ibmcloudsecurity/appid-clientsdk-swift
[img-license]: https://img.shields.io/github/license/ibm-cloud-security/appid-clientsdk-swift.svg
[img-version]: https://img.shields.io/bintray/v/ibmcloudsecurity/maven/appid-clientsdk-swift.svg

[img-github-watchers]: https://img.shields.io/github/watchers/ibm-cloud-security/appid-clientsdk-swift.svg?style=social&label=Watch
[url-github-watchers]: https://github.com/ibm-cloud-security/appid-clientsdk-swift/watchers
[img-github-stars]: https://img.shields.io/github/stars/ibm-cloud-security/appid-clientsdk-swift.svg?style=social&label=Star
[url-github-stars]: https://github.com/ibm-cloud-security/appid-clientsdk-swift/stargazers
[img-github-forks]: https://img.shields.io/github/forks/ibm-cloud-security/appid-clientsdk-swift.svg?style=social&label=Fork
[url-github-forks]: https://github.com/ibm-cloud-security/appid-clientsdk-swift/network

[img-travis-master]: https://travis-ci.org/ibm-cloud-security/appid-clientsdk-swift.svg?branch=master
[url-travis-master]: https://travis-ci.org/ibm-cloud-security/appid-clientsdk-swift?branch=master

[img-coveralls-master]: https://coveralls.io/repos/github/ibm-cloud-security/appid-clientsdk-swift/badge.svg
[url-coveralls-master]: https://coveralls.io/github/ibm-cloud-security/appid-clientsdk-swift

[img-codacy]: https://api.codacy.com/project/badge/Grade/d41f8f069dd343769fcbdb55089561fc
[url-codacy]: https://www.codacy.com/app/ibm-cloud-security/appid-clientsdk-swift
