/************
 ** Preparing the text and deviceIDs for sending push notifications.
 ************/

import KituraNet
import Dispatch
import Foundation

func main(args: [String:Any]) -> [String:Any] {
    print("Received:",args)
    
    var str = ""
    var responseValue = ""
    var name = ""
    var deviceIds = ""
    var notificationText = ""
    
    var responseData:[String:Any] = [
        "deviceIds": str,
        "text": str
    ]
    
    guard let subject = args["subject"] as? String,
        let message = args["message"] as? String
        else {
            
            print("Error: missing a required parameter.")
            return responseData
    }
    
    let yourTargetUrl = URL(string: args["services.cloudant.url"] as! String)!
    let components = URLComponents(url: yourTargetUrl, resolvingAgainstBaseURL: false)!
    let cloudantDbName = "users"
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
                responseValue = responseStr
            }
        } catch {
            print("Error: \(error)")
        }
    }
    req.end()
    
    if let data = responseValue.data(using: String.Encoding.utf8)
    {
        let output = try? JSONSerialization.jsonObject(with: data, options: []) as! [String:String]
        print("OUTPUT:",output)
        if(output != nil)
        {
            name = output!["name"] as! String
            deviceIds = output!["deviceid"] as! String
            notificationText = message.replacingOccurrences(of: "{{name}}", with: name)
            print("OUTPUT:",output!)
            
        }
    }
    responseData = [
        "deviceIds": [deviceIds],
        "text": notificationText
    ]
    
    return responseData
}

