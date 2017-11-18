import Foundation
import Dispatch

func main(args: [String:Any]) -> [String:Any]  {
    
    let str = ""
    var result: [String:Any] = [
        "status": str,
        "isactive": str
    ]
    
    guard let username = args["services.appid.clientId"] as? String,
        let password = args["services.appid.secret"] as? String,
        let tenantid = args["tenantid"] as? String,
        let token = args["accesstoken"] as? String
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
    let postData = "tenantid=\(tenantid)&token=\(token)"
    
    var request = URLRequest(url: URL(string: "https://appid-oauth.ng.bluemix.net/oauth/v3/\(tenantid)/introspect")! as URL,
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
                //var dictonary:[String : Bool]?
                
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
    return result
}
