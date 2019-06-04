/*******************************
 **** Add User to Cloudant NoSQL DB
 ******************************/

import KituraNet
import Dispatch
import Foundation
import SwiftyJSON

func main(args: [String:Any]) -> [String:Any] {
    print("Received:",args)
    
    var str = ""
    var subject = ""
    var name = "Guest"
    var deviceId = args["deviceId"] as? String
    var picture = ""
    var email = ""
    var cloudantBody = [String:String]()
    var cloudantBodyStr : String? = ""
    
    var status:[String:Any] = [
        "ok": str,
        "response": str
    ]
    
    var body:[String:Any] = [
        "body": status
    ]
    
    guard let accessToken = args["_accessToken"] as? String,
        let idToken = args["_idToken"] as? String
        else{
            print("Unauthorized ERROR: Missing tokens")
            status["ERROR"] = "Unauthorized ERROR: Missing tokens"
            return status
    }
    
    if let accessTokenFromString = accessToken.data(using: .utf8, allowLossyConversion: false) {
        let accessTokenJSON = JSON(data: accessTokenFromString)
        subject = accessTokenJSON["sub"].stringValue
        cloudantBody["subject"] = subject
    }
    
    if let idTokenFromString = idToken.data(using: .utf8, allowLossyConversion: false) {
        let idTokenJSON = JSON(data: idTokenFromString)
        name = idTokenJSON["name"].stringValue.isEmpty ? "Guest" : idTokenJSON["name"].stringValue
        cloudantBody["name"] = name
        cloudantBody["deviceid"] = deviceId
        if(idTokenJSON["amr"][0].stringValue != "appid_anon")
        {
            picture = idTokenJSON["picture"].stringValue
            email = idTokenJSON["email"].stringValue
            cloudantBody["picture"] = picture
            cloudantBody["email"] = email
        }
    }
    
    let cloudantDbName = "users"
    let yourTargetUrl = URL(string: args["services.cloudant.url"] as! String)!
    let components = URLComponents(url: yourTargetUrl, resolvingAgainstBaseURL: false)!
    
    var requestOptionsGet: [ClientRequest.Options] = [ .method("GET"),
                                                       .schema(components.scheme as String!),
                                                       .hostname(components.host as String!),
                                                       .username(components.user as String!),
                                                       .password(components.password as String!),
                                                       .port(443),
                                                       .path("/\(cloudantDbName)/\(subject)")
    ]
    
    var headers = [String: String]()
    headers["Accept"] = "application/json"
    headers["Content-Type"] = "application/json"
    requestOptionsGet.append(.headers(headers))
    
    let req = HTTP.request(requestOptionsGet) { response in
        do {
            if let response = response,
                let responseStr = try response.readString() {
                str = responseStr
            }
        } catch {
            print("Error: \(error)")
            status["Error"] = error
        }
    }
    req.end()
    
    if let data = str.data(using: String.Encoding.utf8)
    {
        let output = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:String]
        if(output != nil && output?!["error"] == "not_found")
        {
            var requestOptions: [ClientRequest.Options] = [ .method("PUT"),
                                                            .schema(components.scheme as String!),
                                                            .hostname(components.host as String!),
                                                            .username(components.user as String!),
                                                            .password(components.password as String!),
                                                            .port(443),
                                                            .path("/\(cloudantDbName)/\(subject)")
            ]
            
            var headers = [String:String]()
            headers["Accept"] = "application/json"
            headers["Content-Type"] = "application/json"
            requestOptions.append(.headers(headers))
            let cloudantJSON = JSON(cloudantBody)
            if let rawString = cloudantJSON.rawString() {
                cloudantBodyStr = rawString
            } else {
                print("ERROR: cloudantJSON.rawString is nil")
            }
            
            if (cloudantBodyStr == "") {
                str = "Error: Unable to serialize cloudantBody parameter as a String instance"
                status["Error"] = str
                return status
            }
            else {
                let requestData:Data? = cloudantBodyStr!.data(using: String.Encoding.utf8, allowLossyConversion: true)
                
                if let data = requestData {
                    
                    let req = HTTP.request(requestOptions) { response in
                        do {
                            if let responseUnwrapped = response,
                                let responseStr = try responseUnwrapped.readString() {
                                str = responseStr
                            }
                        } catch {
                            print("Error \(error)")
                            status["Error"] = error
                        }
                    }
                    req.end(data);
                }
            }
            status = [
                "ok": "true",
                "response": str
            ]
        }
            
        else{
            status["ERROR"] = "User already exists"
            
        }
        
    }
    body = [
        "body": status
    ]
    return body
}
