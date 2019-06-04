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

public class UserProfileManagerImpl: UserProfileManager {

    static var logger = Logger.logger(name: AppIDConstants.UserProfileManagerLoggerName)

    private var appId: AppID

    init(appId: AppID) {
        self.appId = appId
    }

    public func setAttribute(key: String, value: String, completionHandler: @escaping (Error?, [String: Any]?) -> Void) {
        sendAttributeRequest(method: HttpMethod.PUT, key: key, value: value, accessTokenString: getLatestAccessToken(), completionHandler: completionHandler)
    }

    public func setAttribute(key: String, value: String, accessTokenString: String, completionHandler: @escaping (Error?, [String: Any]?) -> Void) {
        sendAttributeRequest(method: HttpMethod.PUT, key: key, value: value, accessTokenString: accessTokenString, completionHandler: completionHandler)
    }

    public func getAttribute(key: String, completionHandler: @escaping (Error?, [String: Any]?) -> Void) {
        sendAttributeRequest(method: HttpMethod.GET, key: key, value: nil, accessTokenString: getLatestAccessToken(), completionHandler: completionHandler)
    }

    public func getAttribute(key: String, accessTokenString: String, completionHandler: @escaping (Error?, [String: Any]?) -> Void) {
        sendAttributeRequest(method: HttpMethod.GET, key: key, value: nil, accessTokenString: accessTokenString, completionHandler: completionHandler)
    }

    public func deleteAttribute(key: String, completionHandler: @escaping (Error?, [String: Any]?) -> Void) {
        sendAttributeRequest(method: HttpMethod.DELETE, key: key, value: nil, accessTokenString: getLatestAccessToken(), completionHandler: completionHandler)
    }

    public func deleteAttribute(key: String, accessTokenString: String, completionHandler: @escaping (Error?, [String: Any]?) -> Void) {
        sendAttributeRequest(method: HttpMethod.DELETE, key: key, value: nil, accessTokenString: accessTokenString, completionHandler: completionHandler)
    }

    public func getAttributes(completionHandler: @escaping (Error?, [String: Any]?) -> Void) {
        sendAttributeRequest(method: HttpMethod.GET, key: nil, value: nil, accessTokenString: getLatestAccessToken(), completionHandler: completionHandler)
    }

    public func getAttributes(accessTokenString: String, completionHandler: @escaping (Error?, [String: Any]?) -> Void) {
        sendAttributeRequest(method: HttpMethod.GET, key: nil, value: nil, accessTokenString: accessTokenString, completionHandler: completionHandler)
    }

    ///
    /// Retrieves user info using the latest access and identity tokens
    ///
    /// - Parameter completionHandler {(Error?, [String: Any]?) -> Void}: result handler
    ///
    public func getUserInfo(completionHandler: @escaping (Error?, [String: Any]?) -> Void) {

        guard let accessToken = getLatestAccessToken() else {
            return logAndFail(error: .missingAccessToken, completionHandler: completionHandler)
        }

        let sub = getLatestIdentityTokenSubject()

        sendUserInfoRequest(accessToken: accessToken, idTokenSub: sub, completionHandler: completionHandler)
    }

    ///
    /// Retrives user info using the provided tokens
    ///
    /// - Parameter accessToken {String}: the access token used for authorization
    /// - Parameter idToken {String}: an optional identity token to use for validation
    /// - Parameter completionHandler {(Error?, [String: Any]?) -> Void}: result handler
    ///
    public func getUserInfo(accessTokenString accessToken: String, identityTokenString idToken: String? = nil, completionHandler: @escaping (Error?, [String: Any]?) -> Void) {

        // If provided an identityToken, we should validate user info response if possible
        if let idToken = idToken {

            guard let identityToken = IdentityTokenImpl(with: idToken) else {
                return logAndFail(error: .missingOrMalformedIdToken, completionHandler: completionHandler)
            }

            // If subject exists, use for validation
            if let sub = identityToken.subject {
                return sendUserInfoRequest(accessToken: accessToken, idTokenSub: sub, completionHandler: completionHandler)
            }
        }

        sendUserInfoRequest(accessToken: accessToken, idTokenSub: nil, completionHandler: completionHandler)
    }

    ///
    /// Retrives user info using the provided access token and validates if data provided
    ///
    /// - Parameter accessToken {String}: the access token used for authorization
    /// - Parameter idTokenSub {String}: the subject field from the identity token used for validation
    /// - Parameter completionHandler {(Error?, [String: Any]?) -> Void}: result handler
    ///
    private func sendUserInfoRequest(accessToken: String, idTokenSub: String? = nil, completionHandler: @escaping (Error?, [String: Any]?) -> Void) {

        let url = Config.getServerUrl(appId: appId) + "/" + AppIDConstants.userInfoEndPoint

        sendRequest(url: url, method: HttpMethod.GET, accessToken: accessToken) { (error, info) in

            guard error == nil else {
                return completionHandler(error, nil)
            }

            // Validate reponse received and contains a subject
            guard let info = info, let subject = info["sub"] as? String else {
                return self.logAndFail(error: .invalidUserInfoResponse, completionHandler: completionHandler)
            }

            // If a subject was provided, attempt validation
            if let idTokenSub = idTokenSub, subject != idTokenSub {
                return self.logAndFail(error: .responseValidationError, completionHandler: completionHandler)
            }

            completionHandler(nil, info)
        }
    }

    ///
    /// Handler for an attribute request
    ///
    /// - Parameter method {HttpMethod}: the Http method to make the request with
    /// - Parameter key {String?}: the optional attribute name to target
    /// - Parameter value {String?}: the optional attribute value to set
    /// - Parameter accessTokenString {String?}: the access token to authorize request
    /// - Parameter completionHandler {(Error?, [String: Any]?) -> Void}: result handler
    ///
    internal func sendAttributeRequest(method: HttpMethod, key: String?, value: String?, accessTokenString: String?, completionHandler: @escaping (Error?, [String: Any]?) -> Void) {

        var urlString = Config.getAttributesUrl(appId: appId) + AppIDConstants.attibutesEndpoint

        if let key = key {
            urlString = urlString + "/" + Utils.urlEncode(key)
        }

        guard let accessToken = accessTokenString else {
            return completionHandler(UserProfileError.missingAccessToken, nil)
        }

        sendRequest(url: urlString, method: method, body: value, accessToken: accessToken, completionHandler: completionHandler)

    }

    ///
    /// Constructs a url request
    ///
    /// - Parameter url {String}: the url to make the request to
    /// - Parameter method {HTTPMethod}: the request method
    /// - Parameter body {String}: the value to add to the request body
    /// - Parameter accessToken {String}: access token used for authorization
    /// - Parameter completionHandler {(Error?, [String: Any]?) -> Void}: result handler
    ///
    private func sendRequest(url: String, method: HttpMethod, body: String? = nil, accessToken: String, completionHandler: @escaping (Error?, [String: Any]?) -> Void) {

        guard let url = URL(string: url) else {
            return self.logAndFail(error: "Failed to parse URL string", completionHandler: completionHandler)
        }

        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue
        req.timeoutInterval = BMSClient.sharedInstance.requestTimeout

        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")

        if let value = body {
            req.httpBody = value.data(using: .utf8)
        }

        send(request: req) { (data, response, error) in

            guard error == nil else {
                let errString = error?.localizedDescription ?? "Encountered an error"
                return self.logAndFail(level: "error", error: errString, completionHandler: completionHandler)
            }

            guard let resp = response, let response = resp as? HTTPURLResponse else {
                return self.logAndFail(error: "Did not receive a response", completionHandler: completionHandler)
            }

            guard response.statusCode >= 200 && response.statusCode < 300 else {
                if response.statusCode == 401 {
                    UserProfileManagerImpl.logger.warn(message: "Ensure user profiles feature is enabled in the App ID dashboard.")
                    return self.logAndFail(error: .unauthorized, completionHandler: completionHandler)
                } else if response.statusCode == 404 {
                    return self.logAndFail(error: .notFound, completionHandler: completionHandler)
                } else {
                    return self.logAndFail(error: "Unexpected response from server. Status Code:" + String(response.statusCode), completionHandler: completionHandler)
                }
            }

            if response.statusCode == 204 {
                return completionHandler(nil, [:])
            }

            guard let responseData = data else {
                return self.logAndFail(error: "Failed to parse server response - no response text", completionHandler: completionHandler)
            }

            guard let respString = String(data: responseData, encoding: .utf8),
                let json = try? Utils.parseJsonStringtoDictionary(respString) else {
                    return self.logAndFail(error: .bodyParsingError, completionHandler: completionHandler)
            }

            completionHandler(nil, json)
        }
    }

    ///
    /// Error Handler
    ///
    /// - Parameter error {String}: the error to log
    /// - Parameter completionHandler {String}: the callback handler
    private func logAndFail(level: String = "debug", error: String, completionHandler: @escaping (Error?, [String:Any]?) -> Void) {
        logAndFail(error: UserProfileError.general(error), completionHandler: completionHandler)
    }

    ///
    /// Error Handler
    ///
    /// - Parameter error {UserManagerError}: the error to log
    /// - Parameter completionHandler {String}: the callback handler
    private func logAndFail(level: String = "debug", error: UserProfileError, completionHandler: @escaping (Error?, [String: Any]?) -> Void) {
        log(level: level, msg: error.description)
        completionHandler(error, nil)
    }

    ///
    /// Logging Helper
    ///
    private func log(level: String, msg: String) {
        switch level {
        case "warn" : UserProfileManagerImpl.logger.warn(message: msg)
        case "error" : UserProfileManagerImpl.logger.error(message: msg)
        default: UserProfileManagerImpl.logger.debug(message: msg)
        }
    }

    ///
    /// Send URLRequest Executorg
    ///
    internal func send(request : URLRequest, handler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        URLSession.shared.dataTask(with: request, completionHandler: handler).resume()
    }

    ///
    /// Retrieves the latest access token
    ///
    /// - Returns: the raw access token
    internal func getLatestAccessToken() -> String? {
        return  appId.oauthManager?.tokenManager?.latestAccessToken?.raw
    }

    ///
    /// Retrieves the latest identity token subject field
    ///
    /// - Returns: the subject field from the latest identity token
    internal func getLatestIdentityTokenSubject() -> String? {
        return  appId.oauthManager?.tokenManager?.latestIdentityToken?.subject
    }

}
