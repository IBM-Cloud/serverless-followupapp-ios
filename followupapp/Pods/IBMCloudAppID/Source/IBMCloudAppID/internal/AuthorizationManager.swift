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
public class AuthorizationManager {

    static var logger = Logger.logger(name: AppIDConstants.RegistrationManagerLoggerName)

    var registrationManager:RegistrationManager
    var appid:AppID
    var oAuthManager:OAuthManager
    var authorizationUIManager:AuthorizationUIManager?
    var preferredLocale:Locale?
    var state: String?

    init(oAuthManager:OAuthManager) {
        self.oAuthManager = oAuthManager
        self.appid = oAuthManager.appId
        self.registrationManager = oAuthManager.registrationManager!
    }

    internal func getAuthorizationUrl(idpName : String?, accessToken : String?, responseType : String) -> String? {
        guard let state = Utils.generateStateParameter(of: 24) else {
            return nil
        }
        self.state = state

        var url = Config.getServerUrl(appId: self.appid) + AppIDConstants.OAUTH_AUTHORIZATION_PATH + "?" + AppIDConstants.JSON_RESPONSE_TYPE_KEY + "=" + responseType
        if let clientId = self.registrationManager.getRegistrationDataString(name: AppIDConstants.client_id_String) {
            url += "&" + AppIDConstants.client_id_String + "=" + clientId
        }
        if let redirectUri = self.registrationManager.getRegistrationDataString(arrayName: AppIDConstants.JSON_REDIRECT_URIS_KEY, arrayIndex: 0) {
            url +=  "&" + AppIDConstants.JSON_REDIRECT_URI_KEY + "=" + redirectUri
        }
        url += "&" + AppIDConstants.JSON_SCOPE_KEY + "=" + AppIDConstants.OPEN_ID_VALUE
        if let unWrappedIdpName = idpName {
            url += "&idp=" + unWrappedIdpName
        }
        if let unWrappedAccessToken = accessToken {
            url += "&appid_access_token=" + unWrappedAccessToken
        }

        url = addLocaleQueryParam(url)
        url += "&state=" + state

        return url
    }

    internal func getChangePasswordUrl(userId : String, redirectUri : String) -> String {
        var url = Config.getServerUrl(appId: self.appid) + AppIDConstants.changePasswordPath + "?" + AppIDConstants.JSON_USER_ID + "=" + userId
        if let clientId = self.registrationManager.getRegistrationDataString(name: AppIDConstants.client_id_String) {
            url += "&" + AppIDConstants.client_id_String + "=" + clientId
        }
        url +=  "&" + AppIDConstants.JSON_REDIRECT_URI_KEY + "=" + redirectUri
        url = addLocaleQueryParam(url)

        return url
    }

    internal func getChangeDetailsUrl(code : String, redirectUri : String) -> String {
        var url = Config.getServerUrl(appId: self.appid) + AppIDConstants.changeDetailsPath + "?" + AppIDConstants.JSON_CODE_KEY + "=" + code
        if let clientId = self.registrationManager.getRegistrationDataString(name: AppIDConstants.client_id_String) {
            url += "&" + AppIDConstants.client_id_String + "=" + clientId
        }
        url +=  "&" + AppIDConstants.JSON_REDIRECT_URI_KEY + "=" + redirectUri
        url = addLocaleQueryParam(url)

        return url
    }

    internal func getForgotPasswordUrl(redirectUri: String) -> String {
        var url = Config.getServerUrl(appId: self.appid) + AppIDConstants.FORGOT_PASSWORD_PATH
        if let clientId = self.registrationManager.getRegistrationDataString(name: AppIDConstants.client_id_String) {
            url += "?" + AppIDConstants.client_id_String + "=" + clientId + "&" + AppIDConstants.JSON_REDIRECT_URI_KEY + "=" + redirectUri
        }
        url = addLocaleQueryParam(url)

        return url
    }

    internal func launchAuthorizationUI(accessTokenString:String? = nil, authorizationDelegate:AuthorizationDelegate) {
        self.registrationManager.ensureRegistered { (error: AppIDError?) in
            guard error == nil else {
                AuthorizationManager.logger.error(message: error!.description)
                authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure(error!.description))
                return
            }
            guard let authorizationUrl = self.getAuthorizationUrl(idpName: nil, accessToken: accessTokenString, responseType: AppIDConstants.JSON_CODE_KEY) else {
                AuthorizationManager.logger.error(message: "Could not generate authorization url")
                authorizationDelegate.onAuthorizationFailure(error: .authorizationFailure("Could not generate authorization url"))
                return
            }
            let redirectUri = self.registrationManager.getRegistrationDataString(arrayName: AppIDConstants.JSON_REDIRECT_URIS_KEY, arrayIndex: 0)
            self.authorizationUIManager = AuthorizationUIManager(oAuthManager: self.oAuthManager, authorizationDelegate: authorizationDelegate, authorizationUrl: authorizationUrl, redirectUri: redirectUri!)
            self.authorizationUIManager?.launch()
        }
    }

    internal func launchSignUpAuthorizationUI(authorizationDelegate:AuthorizationDelegate) {
        self.registrationManager.ensureRegistered { (error: AppIDError?) in
            guard error == nil else {
                AuthorizationManager.logger.error(message: error!.description)
                authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure(error!.description))
                return
            }
            guard let signUpAuthorizationUrl = self.getAuthorizationUrl(idpName: nil, accessToken: nil, responseType: AppIDConstants.JSON_SIGN_UP_KEY) else {
                AuthorizationManager.logger.error(message: "Could not generate authorization url")
                authorizationDelegate.onAuthorizationFailure(error: .authorizationFailure("Could not generate authorization url"))
                return
            }
            let redirectUri = self.registrationManager.getRegistrationDataString(arrayName: AppIDConstants.JSON_REDIRECT_URIS_KEY, arrayIndex: 0)
            self.authorizationUIManager = AuthorizationUIManager(oAuthManager: self.oAuthManager, authorizationDelegate: authorizationDelegate, authorizationUrl: signUpAuthorizationUrl, redirectUri: redirectUri!)
            self.authorizationUIManager?.launch()
        }
    }

    internal func launchChangePasswordUI(authorizationDelegate:AuthorizationDelegate) {
        let currentIdToken:IdentityToken? = self.oAuthManager.tokenManager?.latestIdentityToken
        if currentIdToken == nil {
            authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure("No identity token found."))
        } else if currentIdToken?.identities?.first?[AppIDConstants.JSON_PROVIDER] as? String != AppIDConstants.JSON_CLOUD_DIRECTORY {
            authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure("The identity token was not retrieved using cloud directory idp."))
        } else {
            let userId = currentIdToken?.identities?.first?[AppIDConstants.JSON_ID]
            let redirectUri = self.registrationManager.getRegistrationDataString(arrayName: AppIDConstants.JSON_REDIRECT_URIS_KEY, arrayIndex: 0)
            let changePasswordUrl = getChangePasswordUrl(userId: userId as! String, redirectUri: redirectUri!)
            self.authorizationUIManager = AuthorizationUIManager(oAuthManager: self.oAuthManager, authorizationDelegate: authorizationDelegate, authorizationUrl: changePasswordUrl, redirectUri: redirectUri!)
            self.authorizationUIManager?.launch()
        }
    }

    internal func launchChangeDetailsUI(authorizationDelegate:AuthorizationDelegate) {
        let currentIdToken:IdentityToken? = self.oAuthManager.tokenManager?.latestIdentityToken
        if currentIdToken == nil {
            authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure("No identity token found."))
        } else if currentIdToken?.identities?.first?[AppIDConstants.JSON_PROVIDER] as? String != AppIDConstants.JSON_CLOUD_DIRECTORY {
            authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure("The identity token was not retrieved using cloud directory idp."))
        } else {
            let generateCodeURL = Config.getServerUrl(appId: self.appid) + AppIDConstants.generateCodePath
            let request:Request =  Request(url: generateCodeURL)
            self.sendRequest(request: request, internalCallBack: {(response:Response?, error:Error?) in
                if error == nil {
                    if let unWrapperResponse = response {
                        let code = unWrapperResponse.responseText
                        if code != nil {
                            let redirectUri = self.registrationManager.getRegistrationDataString(arrayName: AppIDConstants.JSON_REDIRECT_URIS_KEY, arrayIndex: 0)
                            let changeDetailsUrl = self.getChangeDetailsUrl(code: code!, redirectUri: redirectUri!)
                            self.authorizationUIManager = AuthorizationUIManager(oAuthManager: self.oAuthManager, authorizationDelegate: authorizationDelegate, authorizationUrl: changeDetailsUrl, redirectUri: redirectUri!)
                            self.authorizationUIManager?.launch()
                        }
                    } else {
                        self.logAndFail(message: "Failed to extract code", delegate: authorizationDelegate)
                    }
                } else {
                    self.logAndFail(message: "Unable to get response from server", delegate: authorizationDelegate)
                }
            })
        }
    }

    internal func launchForgotPasswordUI(authorizationDelegate:AuthorizationDelegate) {
        self.registrationManager.ensureRegistered(callback: {(error:AppIDError?) in
            guard error == nil else {
                AuthorizationManager.logger.error(message: error!.description)
                authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure(error!.description))
                return
            }

            let redirectUri = self.registrationManager.getRegistrationDataString(arrayName: AppIDConstants.JSON_REDIRECT_URIS_KEY, arrayIndex: 0)
            let forgotPasswordUrl = self.getForgotPasswordUrl(redirectUri: redirectUri!)
            self.authorizationUIManager = AuthorizationUIManager(oAuthManager:self.oAuthManager, authorizationDelegate:authorizationDelegate, authorizationUrl: forgotPasswordUrl, redirectUri: redirectUri!)
            self.authorizationUIManager?.launch()
        })
    }

    internal func loginAnonymously(accessTokenString:String?, allowCreateNewAnonymousUsers: Bool, authorizationDelegate:AuthorizationDelegate) {
        self.registrationManager.ensureRegistered { (error: AppIDError?) in
            guard error == nil else {
                AuthorizationManager.logger.error(message: error!.description)
                authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure(error!.description))
                return
            }

            let accessTokenToUse = accessTokenString != nil ? accessTokenString : self.oAuthManager.tokenManager?.latestAccessToken?.raw
            if accessTokenToUse == nil && !allowCreateNewAnonymousUsers {
                authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure("Not allowed to create new anonymous users"))
                return
            }

            guard let authorizationUrl = self.getAuthorizationUrl(idpName: AppIDConstants.AnonymousIdpName, accessToken: accessTokenToUse, responseType: AppIDConstants.JSON_CODE_KEY) else {
                AuthorizationManager.logger.error(message: "Could not generate authorization url")
                authorizationDelegate.onAuthorizationFailure(error: .authorizationFailure("Could not generate authorization url"))
                return
            }

            let internalCallback:BMSCompletionHandler = {(response: Response?, error: Error?) in
                if error == nil {
                    if let unWrapperResponse = response {
                        if let urlString = self.extractUrlString(body : unWrapperResponse.responseText) {

                            if let url = URL(string: urlString) {
                                if let err = Utils.getParamFromQuery(url: url, paramName: "error") {
                                    // authorization endpoint returned error
                                    let errorDescription = Utils.getParamFromQuery(url: url, paramName: "error_description")
                                    let errorCode = Utils.getParamFromQuery(url: url, paramName: "error_code")
                                    AuthorizationManager.logger.error(message: "error: " + err)
                                    AuthorizationManager.logger.error(message: "errorCode: " + (errorCode ?? "not available"))
                                    AuthorizationManager.logger.error(message: "errorDescription: " + (errorDescription ?? "not available"))
                                    authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure("Failed to obtain access and identity tokens"))
                                    return

                                } else {
                                    // authorization endpoint success
                                    guard let code = Utils.getParamFromQuery(url: url, paramName: AppIDConstants.JSON_CODE_KEY) else {
                                        self.logAndFail(message: "Failed to extract grant code", delegate: authorizationDelegate)
                                        return
                                    }

                                    guard let state = Utils.getParamFromQuery(url: url, paramName: AppIDConstants.JSON_STATE_KEY) else {
                                        self.logAndFail(message: "Failed to extract state", delegate: authorizationDelegate)
                                        return
                                    }

                                    guard self.state == state else {
                                        self.logAndFail(message: "Mismatched state parameter", delegate: authorizationDelegate)
                                        return
                                    }

                                    if urlString.lowercased().hasPrefix(AppIDConstants.REDIRECT_URI_VALUE.lowercased()) {
                                        self.oAuthManager.tokenManager?.obtainTokensAuthCode(code: code, authorizationDelegate: authorizationDelegate)
                                        return
                                    }
                                }
                            }
                        }
                    }
                    self.logAndFail(message: "Failed to extract grant code", delegate: authorizationDelegate)
                } else {
                    self.logAndFail(message: "Unable to get response from server", delegate: authorizationDelegate)
                }
            }

            let request = Request(url: authorizationUrl,method: HttpMethod.GET, headers: nil, queryParameters: nil, timeout: 0)
            request.timeout = BMSClient.sharedInstance.requestTimeout
            request.allowRedirects = false
            self.sendRequest(request: request, internalCallBack: internalCallback)
        }

    }

    private func addLocaleQueryParam(_ url : String) -> String {
        let localeToUse = preferredLocale ?? Locale.current
        return url + "&" + AppIDConstants.localeParamName + "=" + localeToUse.identifier
    }

    private func logAndFail(message : String, delegate: AuthorizationDelegate) {
        AuthorizationManager.logger.debug(message : message)
        delegate.onAuthorizationFailure( error: AuthorizationError.authorizationFailure(message))
    }

    private func extractUrlString(body: String?) -> String? {
        guard let body = body,
              let r = body.range(of: AppIDConstants.REDIRECT_URI_VALUE) else {
            return nil
        }

        return String(body[r.lowerBound...])
    }

    internal func sendRequest(request:Request, internalCallBack: @escaping BMSCompletionHandler) {
        request.send(completionHandler: internalCallBack)
    }

    internal func signinWithResourceOwnerPassword(accessTokenString:String? = nil, username: String, password: String, tokenResponseDelegate:TokenResponseDelegate) {
        var accessTokenToUse = accessTokenString
        if accessTokenToUse == nil {
            let latestAccessToken = self.oAuthManager.tokenManager?.latestAccessToken
            if latestAccessToken != nil && (latestAccessToken?.isAnonymous)! {
                accessTokenToUse = latestAccessToken?.raw
            }
        }
        self.registrationManager.ensureRegistered(callback: {(error:AppIDError?) in
            guard error == nil else {
                AuthorizationManager.logger.error(message: error!.description)
                tokenResponseDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure(error!.description))
                return
            }
            self.oAuthManager.tokenManager?.obtainTokensRoP(accessTokenString: accessTokenToUse, username: username, password: password, tokenResponseDelegate: tokenResponseDelegate)
            return
        })
    }

    internal func signinWithRefreshToken(refreshTokenString: String? = nil, tokenResponseDelegate: TokenResponseDelegate) {

        var refreshTokenToUse = refreshTokenString
        if refreshTokenToUse == nil {
            let latestRefreshToken = self.oAuthManager.tokenManager?.latestRefreshToken
            if latestRefreshToken != nil {
                refreshTokenToUse = latestRefreshToken?.raw
            }
        }
        self.registrationManager.ensureRegistered(callback: {(error:AppIDError?) in
            guard error == nil else {
                AuthorizationManager.logger.error(message: error!.description)
                tokenResponseDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure(error!.description))
                return
            }
            guard refreshTokenToUse != nil else {
                tokenResponseDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure("Could not find refresh token to use - either provide it as parameter or make sure it is cached locally"))
                return
            }
            self.oAuthManager.tokenManager?.obtainTokensRefreshToken(
                refreshTokenString: refreshTokenToUse!,
                tokenResponseDelegate: tokenResponseDelegate)
            return
        })

    }

    public func application(_ application: UIApplication, open url: URL, options :[UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return (self.authorizationUIManager?.application(application, open: url, options: options))!
    }

}
