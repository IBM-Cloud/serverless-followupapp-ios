//
//  ServerlessAPI.swift
//  FollowUpappid
//
//  Created by Vidyasagar Machupalli on 16/11/17.
//  Copyright © 2017 Oded Betzalel. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import BluemixAppID

public class ServerlessAPI{
    
    var idToken:IdentityToken?
    var accessToken:AccessToken?
    var tenantId : String?
    var serverlessBackendURL: String?
    
    public static var sharedInstance = ServerlessAPI()
    
    public func initialize(tenantId : String!,serverlessBackendURL : String!) {
        self.tenantId = tenantId
        self.serverlessBackendURL = serverlessBackendURL
    }
    
    func addUser(accessToken:AccessToken?, idToken:IdentityToken?)
    {
        
        self.accessToken = accessToken
        self.idToken = idToken
        
        print("NAME",idToken?.name as Any)
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(String(describing: accessToken!.raw)) \(String(describing: idToken!.raw))",
            "Accept": "application/json"
        ]
    
        var data = [String:String]()
        data["subject"] = accessToken?.subject
        data["deviceid"] = idToken?.oauthClient?.deviceId
        
        if !(accessToken?.isAnonymous)! {
            data["name"] = idToken?.name ?? (idToken?.email?.components(separatedBy: "@"))?[0] ?? "Guest"
            data["image"] = idToken?.picture
            data["email"] = idToken?.email
        }
        else{
            data["name"] = "Guest"
        }
        let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [])
        let jsonString = String(data: jsonData!, encoding: .utf8)
        
        let args : Parameters = [
            "cloudantId": accessToken?.subject! as Any,
            "cloudantDbName": "users",
            "tenantid": tenantId!,
            "cloudantBody": jsonString!,
            ]
        
        Alamofire.request("\(serverlessBackendURL!)/register-user-sequence",method: .post, parameters: args, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            debugPrint(response)
        }
    }
    
    func sendFeedback(accessToken:AccessToken?, idToken:IdentityToken?, message: String?)
    {
        
        self.accessToken = accessToken
        self.idToken = idToken
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(String(describing: accessToken!.raw)) \(String(describing: idToken!.raw))",
            "Accept": "application/json"
        ]
        
        var data = [String:String]()
        data["message"] = message
        data["subject"] = accessToken?.subject!
        let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [])
        let jsonString = String(data: jsonData!, encoding: .utf8)
        
        let args : Parameters = [
            "cloudantId": accessToken?.subject! as Any,
            "cloudantDbName": "feedback",
            "tenantid": tenantId!,
            "cloudantBody": jsonString!,
            ]
        
        Alamofire.request("\(serverlessBackendURL!)/save-feedback-sequence",method: .post, parameters: args, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            debugPrint(response)
        }
    }
    
}
