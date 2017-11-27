/********************************************
 *** Add feedback to Cloudant NoSQL DB on IBM Cloud.
 ********************************************/

import KituraNet
import Dispatch
import Foundation
import SwiftyJSON

func main(args: [String:Any]) -> [String:Any] {
    
    var str = ""
    var subject = ""
    var cloudantBody = [String:String]()
    var cloudantBodyStr : String? = ""
    
    var status:[String:Any] = [
        "ok": str,
        "response": str
    ]
    
    var body:[String:Any] = [
        "body": status
    ]
    
    guard let accessToken = args["_accessToken"] as? String
        else{
            print("UNAUTHORIZED: Missing tokens")
            status["ERROR"] = "UNAUTHORIZED: Missing tokens"
            return status
    }
    
    guard let message = args["message"] as? String
        else{
            print("ERROR: Input message missing")
            status["ERROR"] = "Input message missing"
            return status
    }
    
    if let accessTokenFromString = accessToken.data(using: .utf8, allowLossyConversion: false) {
        let accessTokenJSON = JSON(data: accessTokenFromString)
        subject = accessTokenJSON["sub"].stringValue
        cloudantBody["subject"] = subject
        cloudantBody["message"] = message
    }
    
    let cloudantDbName = "feedback"
    
    let yourTargetUrl = URL(string: args["services.cloudant.url"] as! String)!
    let components = URLComponents(url: yourTargetUrl, resolvingAgainstBaseURL: false)!
    var requestOptions: [ClientRequest.Options] = [ .method("POST"),
                                                    .schema(components.scheme as String!),
                                                    .hostname(components.host as String!),
                                                    .username(components.user as String!),
                                                    .password(components.password as String!),
                                                    .port(443),
                                                    .path("/\(cloudantDbName)")
    ]
    
    var headers = [String:String]()
    headers["Accept"] = "application/json"
    headers["Content-Type"] = "application/json"
    requestOptions.append(.headers(headers))
    
    let cloudantJSON = JSON(cloudantBody)
    if let rawString = cloudantJSON.rawString() {
        cloudantBodyStr = rawString
    } else {
        print("ERROR: json.rawString is nil")
    }
    
    if (cloudantBodyStr == "") {
        str = "Error: Unable to serialize cloudantBody parameter as a String instance"
        status["ERROR"] = str
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
                }
            }
            req.end(data);
        }
    }
    status = [
        "ok": "true",
        "response": str
    ]
    body = [
        "body": status
    ]
    return body
}
