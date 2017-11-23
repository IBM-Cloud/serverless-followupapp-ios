/**
 * Add User to Cloudant NoSQL DB
 */

import KituraNet
import Dispatch
import Foundation

func main(args: [String:Any]) -> [String:Any] {
    
    var str = ""
    var result:[String:Any] = [
        "cloudantId": str,
        "cloudantResult": str
    ]
    
    var resultGet: [String:Any] = [
        "document": str
    ]
    
    guard let accessToken = args["_accessToken"] as? String,
        let idToken = args["_idToken"] as? String
        else{
            print("Unauthorized: Missing tokens")
            return result
    }
    
    guard let cloudantBody = args["cloudantBody"] as? String,
        let cloudantId = args["cloudantId"] as? String,
        let cloudantDbName = args["cloudantDbName"] as? String else {
            
            print("Error: missing a required parameter for writing a Cloudant document.")
            return result
    }
    
    let yourTargetUrl = URL(string: args["services.cloudant.url"] as! String)!
    let components = URLComponents(url: yourTargetUrl, resolvingAgainstBaseURL: false)!
    
    var requestOptionsGet: [ClientRequest.Options] = [ .method("GET"),
                                                       .schema(components.scheme as String!),
                                                       .hostname(components.host as String!),
                                                       .username(components.user as String!),
                                                       .password(components.password as String!),
                                                       .port(443),
                                                       .path("/\(cloudantDbName)/\(cloudantId)")
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
        }
    }
    req.end()
    /*resultGet = [
     "document": str
     ]*/
    
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
                                                            .path("/\(cloudantDbName)/\(cloudantId)")
            ]
            
            var headers = [String:String]()
            headers["Accept"] = "application/json"
            headers["Content-Type"] = "application/json"
            requestOptions.append(.headers(headers))
            
            
            if (cloudantBody == "") {
                str = "Error: Unable to serialize cloudantBody parameter as a String instance"
            }
            else {
                let requestData:Data? = cloudantBody.data(using: String.Encoding.utf8, allowLossyConversion: true)
                
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
            
            result = [
                "cloudantId": cloudantId,
                "cloudantResult": str
            ]
        }
    }
    
    return result
}
