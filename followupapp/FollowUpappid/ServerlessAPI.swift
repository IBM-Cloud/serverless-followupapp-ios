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
    public static var sharedInstance = ServerlessAPI()
    
    var accessTokenValue: String?
    var idTokenValue: String?
    
    func userData(accessToken:AccessToken?, idToken:IdentityToken?)
    {
        /*if let idTokenPayload = idToken?.payload {
            idTokenValue = try? Utils.JSONStringify(idTokenPayload as AnyObject, prettyPrinted: true)
            idTokenValue = idTokenValue?.replacingOccurrences(of: "\\/", with: "/")
        }
        
        if let accessTokenPayload = accessToken?.payload {
            accessTokenValue = try? Utils.JSONStringify(accessTokenPayload as AnyObject, prettyPrinted: true)
            accessTokenValue = accessTokenValue?.replacingOccurrences(of: "\\/", with: "/")
        }*/
        self.accessToken = accessToken
        self.idToken = idToken
        
        print("NAME",idToken?.name as Any)
        let headers: HTTPHeaders = [
            "Authorization": "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==",
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
        let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [])
        let jsonString = String(data: jsonData!, encoding: .utf8)
        print(jsonString! as Any)
        print("RAW",accessToken?.raw as Any)
        
        //print("JSONDATA",jsonData.stringValue)
        
        let parameters : Parameters = [
            "cloudantHost": "71156b90-c890-4ea0-878a-441dbcd2bd6f-bluemix.cloudant.com",
            "cloudantId": accessToken?.subject! as Any,
            "cloudantDbName": "users",
            "cloudantPassword": "abbe8ea9ac7b60f72b1ca2eeb9dea649d5899746fe6564420bad1f3e65bbae3f",
            "cloudantBody": jsonString!,
            "cloudantUsername": "71156b90-c890-4ea0-878a-441dbcd2bd6f-bluemix"
        ]
        
        
        Alamofire.request("https://openwhisk.ng.bluemix.net/api/v1/web/Dev-Advocates_demos/default/AddUser.json",method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            debugPrint(response)
        }
    }
    
}
