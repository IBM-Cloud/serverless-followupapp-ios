/***************
 ** Validate an user access token through Introspect endpoint of
 ** App ID Service on IBM Cloud.
 ***************/
import Foundation
import Dispatch
import SwiftyJSON


func main(args: [String:Any]) -> [String:Any]  {
    
    var args: [String:Any] = args
    let str = ""
    var result: [String:Any] = [
        "status": str,
        "isactive": str
    ]
    
    guard let requestHeaders = args["__ow_headers"] as! [String:Any]?,
        let authorizationHeader = requestHeaders["authorization"] as? String
        else {
            print("Error: Authorization headers missing.")
            result["ERROR"] = "Authorization headers missing."
            return result
    }
    
    guard let authorizationComponents = authorizationHeader.components(separatedBy: " ") as [String]?,
        let bearer = authorizationComponents[0] as? String, bearer == "Bearer",
        let accessToken = authorizationComponents[1] as? String,
        let idToken = authorizationComponents[2] as? String
        else {
            print("Error: Authorization header is malformed.")
            result["ERROR"] = "Authorization header is malformed."
            return result
    }
    guard let username = args["services.appid.clientId"] as? String,
        let password = args["services.appid.secret"] as? String,
        let tenantid = args["tenantid"] as? String
        else{
            print("Error: missing a required parameter for basic Auth.")
            result["ERROR"] = "missing a required parameter for basic Auth."
            return result
    }
    let loginString = username+":"+password
    let loginData = loginString.data(using: String.Encoding.utf8)!
    let base64LoginString = loginData.base64EncodedString()
    let headers = [
        "content-type": "application/x-www-form-urlencoded",
        "authorization": "Basic \(base64LoginString)",
        "cache-control": "no-cache",
        ]
    let postData = "tenantid=\(tenantid)&token=\(accessToken)"
    
    var request = URLRequest(url: URL(string: (args["services.appid.url"] as? String)! + "/introspect")! as URL,
                             cachePolicy: .useProtocolCachePolicy,
                             timeoutInterval: 10.0)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = headers
    request.httpBody = postData.data(using: .utf8)
    
    let semaphore = DispatchSemaphore(value: 0)
    let sessionConfiguration = URLSessionConfiguration.default;
    let urlSession = URLSession(
        configuration:sessionConfiguration, delegate: nil, delegateQueue: nil)
    let dataTask = urlSession.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
        guard let data = data, error == nil else {
            print("Error: \(String(describing: error?.localizedDescription))")
            return
        }
        if let httpStatus = response as? HTTPURLResponse {
            if httpStatus.statusCode == 200
            {
                let responseString = String(data: data, encoding: .utf8)
                guard let data = responseString?.data(using: String.Encoding.utf8),
                    let dictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Bool]
                    else {
                        return
                }
                if let myDictionary = dictionary
                {
                    print(" isActive : \(myDictionary["active"]!)")
                    result = [
                        "status": String(httpStatus.statusCode),
                        "isactive": myDictionary["active"]!
                    ]
                }
            }
            else
            {
                print("Unexpected response:\(httpStatus.statusCode)")
                print("\(httpStatus)")
                result["ERROR"] = httpStatus
            }
        }
        print("operation concluded")
        semaphore.signal()
    })
    
    dataTask.resume()
    _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    
    
    if(result["isactive"] != nil && result["isactive"]! as! Bool)
    {
        
        let parsedAccessToken = parseToken(from: accessToken)["payload"]
        let parsedIdToken = parseToken(from: idToken)["payload"]
        
        var _accessToken = ""
        var _idToken = ""
        
        if let accessTokenString = parsedAccessToken.rawString() {
            _accessToken = accessTokenString
        } else {
            print("ERROR: accessTokenString is nil")
        }
        
        if let idTokenString = parsedIdToken.rawString() {
            _idToken = idTokenString
        } else {
            print("ERROR: idTokenString is nil")
        }
        args["_accessToken"] = _accessToken
        args["_idToken"] = _idToken
        return args
    }
        
    else{
        result["ERROR"] = "Invalid Token or the token has expired"
        return result
    }
}

extension String{
    
    func base64decodedData() -> Data? {
        let missing = self.characters.count % 4
        
        var ending = ""
        if missing > 0 {
            let amount = 4 - missing
            ending = String(repeating: "=", count: amount)
        }
        let base64 = self.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/") + ending
        return Data(base64Encoded: base64, options: Data.Base64DecodingOptions())
    }
}


func parseToken(from tokenString:String) -> JSON {
    print("parseToken")
    var json = JSON([:])
    let tokenComponents = tokenString.components(separatedBy: ".")
    
    guard tokenComponents.count == 3 else {
        print("ERROR: Invalid access token format")
        return json
    }
    
    let jwtHeaderData = tokenComponents[0].base64decodedData()
    let jwtPayloadData = tokenComponents[1].base64decodedData()
    let jwtSignature = tokenComponents[2]
    
    guard jwtHeaderData != nil && jwtPayloadData != nil else {
        print("ERROR: Invalid access token format")
        return json
    }
    
    let jwtHeader = JSON(data: jwtHeaderData!)
    let jwtPayload = JSON(data: jwtPayloadData!)
    
    json["header"] = jwtHeader
    json["payload"] = jwtPayload
    json["signature"] = JSON(jwtSignature)
    return json
}
