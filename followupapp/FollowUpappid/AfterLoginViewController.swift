/* *     Copyright 2016, 2017 IBM Corp.
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */


import UIKit
import BluemixAppID
import BMSCore
import Alamofire
import SwiftyJSON

class AfterLoginViewController: UIViewController {

    
    @IBOutlet weak var toptext: UILabel!
    @IBOutlet weak var profilePic: UIImageView!
    
    @IBOutlet weak var hintMessageView: UILabel!
    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var nextLabel: UILabel!
    @IBOutlet weak var successMsg: UILabel!
    // function for displaying login
  //  @IBOutlet weak var warningText: UILabel!
    
    
    var accessToken:AccessToken?
    var idToken:IdentityToken?
    var firstLogin: Bool = false
    var hintMessage : String?
    
    override func viewDidLoad() {
   
        self.profilePic.layer.cornerRadius = self.profilePic.frame.size.height / 2;
        self.profilePic.layer.masksToBounds = true;
        
        topBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector (self.topBarClicked(sender:))))
        
        
        showLoginInfo()
        UIApplication.shared.keyWindow?.rootViewController = self
        super.viewDidLoad()
    }

    func showLoginInfo() {
        
        // Getting and presenting the user picture
        if !(accessToken?.isAnonymous)! {
            if let picUrl = idToken?.picture, let url = URL(string: picUrl), let data = try? Data(contentsOf: url) {
                self.profilePic.image = UIImage(data: data)
            }
            toptext.text = "";
        } else {
            toptext.text = " Login";
    
        }
        
        let displayName = idToken?.name ?? (idToken?.email?.components(separatedBy: "@"))?[0] ?? "Guest"
        self.successMsg.text = "Welcome " + displayName + ""
        ServerlessAPI.sharedInstance.userData(accessToken: accessToken!,idToken: idToken!)
    }
    
    class LoginDelegate : AuthorizationDelegate {
        
        let controller : AfterLoginViewController
        
        init(controller : AfterLoginViewController) {
            self.controller = controller
        }
        
        public func onAuthorizationSuccess(accessToken: AccessToken, identityToken: IdentityToken, response:Response?) {
            
            controller.accessToken = accessToken;
            controller.idToken = identityToken;
            
            if accessToken.isAnonymous {
                TokenStorageManager.sharedInstance.storeToken(token: accessToken.raw)
            } else {
                TokenStorageManager.sharedInstance.clearStoredToken()
            }
            TokenStorageManager.sharedInstance.storeUserId(userId: accessToken.subject)
            
            
            DispatchQueue.main.async {
                self.controller.showLoginInfo()
               
            }
            
        }
        
        public func onAuthorizationCanceled() {
            print("cancel")
        }
        
        public func onAuthorizationFailure(error: AuthorizationError) {
            print(error)
        }
    }
    
    func topBarClicked(sender: UITapGestureRecognizer) {

        if (accessToken?.isAnonymous)! {
            AppID.sharedInstance.loginWidget?.launch(accessTokenString: TokenStorageManager.sharedInstance.loadStoredToken(), delegate: LoginDelegate(controller: self))
        }
    }

    @IBAction func showToken(_ sender: Any) {
    
            DispatchQueue.main.async {
                let tokenView  = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TokenView") as? TokenView
                tokenView?.accessToken = self.accessToken
                print("Token:",self.accessToken!)
                tokenView?.idToken = self.idToken
                self.present(tokenView!, animated: true, completion: nil)
            }

    }
    
    @IBAction func submitFeedback(_ sender: Any) {
        
        var accessTokenValue: String?
        var idTokenValue: String?
        
        if let idTokenPayload = idToken?.payload {
            idTokenValue = try? Utils.JSONStringify(idTokenPayload as AnyObject, prettyPrinted: true)
            idTokenValue = idTokenValue?.replacingOccurrences(of: "\\/", with: "/")
        }
        
        if let accessTokenPayload = accessToken?.payload {
           accessTokenValue = try? Utils.JSONStringify(accessTokenPayload as AnyObject, prettyPrinted: true)
           accessTokenValue = accessTokenValue?.replacingOccurrences(of: "\\/", with: "/")
        }
        
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer " + accessTokenValue! + idTokenValue!,
            "Accept": "application/json"
        ]
        
        
        print("ID TOKEN", idTokenValue!)
      
        
        var data = [String:String]()
        data["test"] = "test123"
        print("Authorization",headers["Authorization"]!)
        let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [])
        let jsonString = String(data: jsonData!, encoding: .utf8)
        print(jsonString! as Any)

        
        //print("JSONDATA",jsonData.stringValue)
        
        let parameters : Parameters = [
            "cloudantId": "test",
            "cloudantDbName": "feedback",
            "cloudantBody": jsonString!,
        ]
        
        
        Alamofire.request("https://openwhisk.ng.bluemix.net/api/v1/web/Dev-Advocates_demos/serverlessfollowup/add-user",method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            debugPrint(response)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    /*func updateUI() {
        DispatchQueue.main.async {
            self.selectionIcon1.isHidden = !self.foodSelection.contains("pizza")
            self.selectionIcon2.isHidden = !self.foodSelection.contains("hamburger")
            self.selectionIcon3.isHidden = !self.foodSelection.contains("salad")
            self.hintMessageView.text = self.hintMessage
        }
        
    }*/
    
    
}


