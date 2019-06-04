//
//  ServerlessAPI.swift
//  FollowUpappid
//
//  Created by Vidyasagar Machupalli on 16/11/17.
//  Copyright © 2017 Oded Betzalel. All rights reserved.
//

import Foundation
import Alamofire
import IBMCloudAppID

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
    
    
    /// Send a request to serverless action to a user after validating the accesstoken
    ///
    /// - Parameters:
    ///   - accessToken: Provided by App ID
    ///   - idToken: Provided by App ID
    ///   - deviceId: the device ID used for push notifications
  func addUser(accessToken:AccessToken?, idToken:IdentityToken?, deviceId: String)
    {
        self.accessToken = accessToken
        self.idToken = idToken
        
        print("NAME",idToken?.name as Any)
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(String(describing: accessToken!.raw)) \(String(describing: idToken!.raw))",
            "Accept": "application/json"
        ]
    
        let args : Parameters = [
            "tenantid": tenantId!,
            "deviceId": deviceId,
            ]
        
        Alamofire.request("\(serverlessBackendURL!)/users-add-sequence",method: .post, parameters: args, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            debugPrint(response)
        }
    }
    
    /// Calls serverless action to add feedback to database.
    ///
    /// - Parameters:
    ///   - accessToken: Provided by AppID service.
    ///   - idToken: Provided by AppID service
    ///   - message: As entered in Feedback Text View
    func sendFeedback(accessToken:AccessToken?, idToken:IdentityToken?, message: String?)
    {
        
        self.accessToken = accessToken
        self.idToken = idToken
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(String(describing: accessToken!.raw)) \(String(describing: idToken!.raw))",
            "Accept": "application/json"
        ]
        
        let args : Parameters = [
            "tenantid": tenantId!,
            "message": message!,
            ]
        
        Alamofire.request("\(serverlessBackendURL!)/feedback-put-sequence",method: .post, parameters: args, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            debugPrint(response)
        }
    }
    
}
