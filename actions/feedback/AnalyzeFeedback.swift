/**********
 * Analyze the provided feedback using IBM Watson Tone Analyzer
 * Service on IBM Cloud.
***********/
import Foundation
import Dispatch
import KituraNet

func main(args: [String:Any]) -> [String:Any]  {
    
    let str = ""
    var responseValue = ""
    var messageTemplate = ""
    let version = "2017-09-21"
    var result: [String:Any] = [
        "subject": str,
        "message": str
    ]
    guard let subject = args["subject"] as? String,
        let message = args["message"] as? String else
    {
        print("ERROR: Input parameters missing")
        return result
    }
    guard let username = args["services.ta.username"] as? String,
        let password = args["services.ta.password"] as? String
        else{
            print("Error: missing a required parameter for basic Auth.")
            return result
    }
    let loginString = username+":"+password
    let loginData = loginString.data(using: String.Encoding.utf8)!
    let base64LoginString = loginData.base64EncodedString()
    let headers = [
        "content-type": "application/json",
        "authorization": "Basic \(base64LoginString)",
        "cache-control": "no-cache",
        ]
    let parameters = ["text": "\(message)"] as [String : Any]
    
    let postData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
    
    var request = URLRequest(url: URL(string: (args["services.ta.url"] as? String)! + "/v3/tone?version=\(version)&sentences=true")! as URL,
                             cachePolicy: .useProtocolCachePolicy,
                             timeoutInterval: 10.0)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = headers
    request.httpBody = postData as? Data
    
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
                var responseString = String(data: data, encoding: .utf8)
                guard let data = responseString?.data(using: String.Encoding.utf8),
                    let dictonary = try? JSONSerialization.jsonObject(with: data, options:.allowFragments) as? [String:Any]
                    else {
                        return
                }
                if let myDictionary = dictonary
                {
                    var document_tone = myDictionary["document_tone"] as! [String:Any]
                    var tones = document_tone["tones"] as! [[String:Any]]
                    var tone_name = ""
                    var value = 0
                    
                    for tone in tones {
                        let score = Int(((tone["score"]!) as! Double)*100.0)
                        if(value <= score) {
                            value = score
                            tone_name = ((tone["tone_id"]! as! String));
                            print("TONE:",tone_name)
                        }
                    }
                    if(tone_name != nil && !tone_name.isEmpty)
                    {
                        let yourTargetUrl = URL(string: args["services.cloudant.url"] as! String)!
                        let components = URLComponents(url: yourTargetUrl, resolvingAgainstBaseURL: false)!
                        let cloudantDbName="moods"
                        
                        var requestOptionsGet: [ClientRequest.Options] = [ .method("GET"),
                                                                           .schema(components.scheme as String!),
                                                                           .hostname(components.host as String!),
                                                                           .username(components.user as String!),
                                                                           .password(components.password as String!),
                                                                           .port(443),
                                                                           .path("/\(cloudantDbName)/\(tone_name)")
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
                            print(output)
                            messageTemplate = output!["template"] as! String
                        }
                    }
                    else{
                        print("ERROR: No Tone detected.")
                    }
                    
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
    
    var response: [String:Any] = [
        "subject": subject,
        "message": messageTemplate
    ]
    return response
}

