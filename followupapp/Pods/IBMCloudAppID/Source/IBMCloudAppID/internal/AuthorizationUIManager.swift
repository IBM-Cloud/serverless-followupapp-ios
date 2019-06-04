/* *     Copyright 2016, 2017 IBM Corp.
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */


import Foundation
import BMSCore

public class AuthorizationUIManager {
    var oAuthManager: OAuthManager
    var authorizationDelegate: AuthorizationDelegate
    var authorizationUrl: String
    var redirectUri: String

    private static let logger = Logger.logger(name: Logger.bmsLoggerPrefix + "AppIDAuthorizationUIManager")
    var loginView:safariView?
    init(oAuthManager: OAuthManager, authorizationDelegate: AuthorizationDelegate, authorizationUrl: String, redirectUri: String) {
        self.oAuthManager = oAuthManager
        self.authorizationDelegate = authorizationDelegate
        self.authorizationUrl = authorizationUrl
        self.redirectUri = redirectUri
    }

    public func launch() {
        AuthorizationUIManager.logger.debug(message: "Launching safari view")
        loginView =  safariView(url: URL(string: authorizationUrl)!)
        loginView?.authorizationDelegate = authorizationDelegate
        DispatchQueue.main.async {
            let rootView = UIApplication.shared.keyWindow?.rootViewController
            let currentView = rootView?.presentedViewController
            let view = currentView != nil ? currentView : rootView
            view?.present(self.loginView!, animated: true, completion:  nil)
        }
    }

    public func application(_ application: UIApplication, open url: URL, options :[UIApplicationOpenURLOptionsKey: Any]) -> Bool {

        func tokenRequest(code: String?, errMsg:String?) {
            loginView?.dismiss(animated: true, completion: { () -> Void in
                guard errMsg == nil else {
                    self.authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure(errMsg!))
                    return
                }
                guard let unwrappedCode = code else {
                    self.authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure("Failed to extract grant code"))
                    return
                }
                AuthorizationUIManager.logger.debug(message: "Obtaining tokens")

                self.oAuthManager.tokenManager?.obtainTokensAuthCode(code: unwrappedCode, authorizationDelegate: self.authorizationDelegate)
            })
        }

        if let err = Utils.getParamFromQuery(url: url, paramName: "error") {
            loginView?.dismiss(animated: true, completion: { () -> Void in
                if err == "invalid_client" {
                    self.oAuthManager.registrationManager?.clearRegistrationData()
                    self.oAuthManager.authorizationManager?.launchAuthorizationUI(authorizationDelegate: self.authorizationDelegate)
                } else {
                    let errorDescription = Utils.getParamFromQuery(url: url, paramName: "error_description")
                    let errorCode = Utils.getParamFromQuery(url: url, paramName: "error_code")
                    AuthorizationUIManager.logger.error(message: "Failed to obtain access and identity tokens, error: " + err)
                    AuthorizationUIManager.logger.error(message: "errorCode: " + (errorCode ?? "not available"))
                    AuthorizationUIManager.logger.error(message: "errorDescription: " + (errorDescription ?? "not available"))
                    self.authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure(err))
                }
            })
            return false
        } else if let flow = Utils.getParamFromQuery(url: url, paramName: AppIDConstants.JSON_FLOW_KEY) {
            if flow == AppIDConstants.JSON_FORGOT_PASSWORD_KEY ||  flow == AppIDConstants.JSON_SIGN_UP_KEY {
                loginView?.dismiss(animated: true, completion: { () -> Void in
                    AuthorizationUIManager.logger.debug(message: "Finish " + flow + " flow")
                    self.authorizationDelegate.onAuthorizationSuccess(accessToken: nil,
                                                                      identityToken: nil,
                                                                      refreshToken: nil,
                                                                      response: nil)
                })
                return true
            }
            loginView?.dismiss(animated: true, completion: { () -> Void in
                AuthorizationUIManager.logger.error(message: "Bad callback uri:" + url.absoluteString)
                self.authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure("Bad callback uri"))
            })
            return false
        } else {

            let urlString = url.absoluteString
            guard urlString.lowercased().hasPrefix(AppIDConstants.REDIRECT_URI_VALUE.lowercased()) else {
                return false
            }

            // Gets "code" url query parameters
            guard let code = Utils.getParamFromQuery(url: url, paramName: AppIDConstants.JSON_CODE_KEY) else {
                    AuthorizationUIManager.logger.debug(message: "Failed to extract grant code")
                    tokenRequest(code: nil, errMsg: "Failed to extract grant code")
                    return false
            }
            
            // Get "state" url query parameters
            guard let state = Utils.getParamFromQuery(url: url, paramName: AppIDConstants.JSON_STATE_KEY) else {
                AuthorizationUIManager.logger.debug(message: "Failed to extract state")
                tokenRequest(code: nil, errMsg: "Failed to extract state")
                return false
            }

            // Validates state matches the original
            guard getStoredState() == state else {
                AuthorizationUIManager.logger.debug(message: "Mismatched state parameter")
                tokenRequest(code: nil, errMsg: "Mismatched state parameter")
                return false
            }

            tokenRequest(code: code, errMsg: nil)
            return true

        }

    }

    internal func getStoredState() -> String? {
        return self.oAuthManager.authorizationManager?.state
    }

}
