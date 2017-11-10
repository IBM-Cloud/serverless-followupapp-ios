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
import BluemixAppID


let tokenServiceName = "appid_access_token_"
let userIdServiceName = "appid_userId_"

public class TokenStorageManager {
    
    var tenantId : String?
    
    public static var sharedInstance = TokenStorageManager()
    
    public func initialize(tenantId : String!) {
        self.tenantId = tenantId
    }
    
    public func storeToken(token: String?) {
        save(key: tokenServiceName + tenantId!, value: token)
    }
    
    public func loadStoredToken() -> String? {
        return load(key: tokenServiceName + tenantId!)
    }
    
    public func storeUserId(userId: String?) {
        save(key: userIdServiceName + tenantId!, value: userId)
    }
    
    public func loadUserId() -> String? {
        return load(key: userIdServiceName + tenantId!)
    }
    
    private func save(key: String, value: String?) {
        var kcq : [String:Any] = [:]
        kcq[kSecClass as String] = kSecClassGenericPassword
        kcq[kSecAttrService as String] = key
        
        SecItemDelete(kcq as CFDictionary)
        
        if value != nil {
            kcq[kSecValueData as String] = value!.data(using: .utf8)!
            SecItemAdd(kcq as CFDictionary, nil)
        }
    }
    
    private func load(key: String) -> String? {
        var kcq : [String:Any] = [:]
        kcq[kSecClass as String] = kSecClassGenericPassword
        kcq[kSecAttrService as String] = key
        kcq[kSecReturnData as String] = kCFBooleanTrue
        kcq[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var dataRef : AnyObject?
        let status = SecItemCopyMatching(kcq as CFDictionary, &dataRef)
        let data = dataRef as? Data
        if status == errSecSuccess && data != nil {
            return String(data: data!, encoding: .utf8)
        }
        return nil
    }
    
    public func clearStoredToken() {
        self.storeToken(token: nil)
    }
}
