/***************
 ** Validate an user access token through Introspect endpoint of
 ** App ID Service on IBM Cloud.
 ***************/
import Foundation
import Dispatch

func main(args: [String:Any]) -> [String:Any]  {
    
    let str = ""
    var result: [String:Any] = [
        "status": str,
        "isactive": str
    ]
    guard let requestHeaders = args["__ow_headers"] as! [String:Any]?,
        let authorizationHeader = requestHeaders["authorization"] as? String
        else {
            print("Error: Authorization headers missing.")
            return result
    }
    
    guard let authorizationComponents = authorizationHeader.components(separatedBy: " ") as [String]?,
        let bearer = authorizationComponents[0] as? String, bearer == "Bearer",
        let accessToken = authorizationComponents[1] as? String,
        let idToken = authorizationComponents[2] as? String
        else {
            print("Error: Authorization header is malformed.")
            return result
    }
    guard let username = args["services.appid.clientId"] as? String,
        let password = args["services.appid.secret"] as? String,
        let tenantid = args["tenantid"] as? String
        //let accessToken = args["accesstoken"] as? String
        else{
            print("Error: missing a required parameter for basic Auth.")
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
                    let dictonary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Bool]
                    else {
                        return
                }
                if let myDictionary = dictonary
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
            }
        }
        print("operation concluded")
        semaphore.signal()
    })
    
    dataTask.resume()
    _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    //semaphore.wait()
    guard let cloudantBody = args["cloudantBody"] as? String,
        let cloudantId = args["cloudantId"] as? String,
        let cloudantDbName = args["cloudantDbName"] as? String
        else{
            print("Cloudant parameters missing.")
            return result
    }
    var args: [String:Any] = [
        "_accessToken": str,
        "_idToken": str
    ]
    if(result["isactive"] != nil && result["isactive"]! as! Bool)
    {
        args = [
            "_accessToken": accessToken,
            "_idToken": idToken,
            "cloudantBody" : cloudantBody,
            "cloudantId" : cloudantId,
            "cloudantDbName" : cloudantDbName
        ]
        return args
    }
    return args
}

