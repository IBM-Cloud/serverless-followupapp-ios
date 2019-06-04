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
import IBMCloudAppID
import BMSCore
import Alamofire

class AfterLoginViewController: UIViewController,UITextViewDelegate {

    
    @IBOutlet weak var toptext: UILabel!
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var successMsg: UILabel!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var feedbackText: UITextView!
    var accessToken:AccessToken?
    var idToken:IdentityToken?
   
    var firstLogin: Bool = false
    var hintMessage : String?
    
    override func viewDidLoad() {
        
        submitButton.isEnabled = false;
        feedbackText.delegate = self;
        self.profilePic.layer.cornerRadius = self.profilePic.frame.size.height / 2;
        self.profilePic.layer.masksToBounds = true;
        
        topBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector (self.topBarClicked(sender:))))
        
        
        showLoginInfo()
        UIApplication.shared.keyWindow?.rootViewController = self
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
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
        ServerlessAPI.sharedInstance.addUser(accessToken: accessToken!,idToken: idToken!)
    }
    
    class LoginDelegate : AuthorizationDelegate {
        
        let controller : AfterLoginViewController
        
        init(controller : AfterLoginViewController) {
            self.controller = controller
        }
      
        public func onAuthorizationSuccess(accessToken: AccessToken?, identityToken: IdentityToken?, refreshToken: RefreshToken?, response: Response?) {
          if let accessToken = accessToken {
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
        }
        
        public func onAuthorizationCanceled() {
            print("cancel")
        }
        
        public func onAuthorizationFailure(error: AuthorizationError) {
            print(error)
        }
    }
    
  @objc func topBarClicked(sender: UITapGestureRecognizer) {

        if (accessToken?.isAnonymous)! {
            AppID.sharedInstance.loginWidget?.launch(delegate: LoginDelegate(controller: self))
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
    
    /// Called by Submit button.
    ///
    /// - Parameter sender: Action to Save feedback.
    @IBAction func submitFeedback(_ sender: Any) {
        
        ServerlessAPI.sharedInstance.sendFeedback(accessToken: accessToken!,idToken: idToken!, message: feedbackText.text)
        let alert = UIAlertController(title: "Submitted", message: "Your feedback has been successfully submitted.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { action in
            self.feedbackText.text = ""
            self.textViewDidChange(self.feedbackText)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView == self.feedbackText {
            self.submitButton.isEnabled = !textView.text.isEmpty
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
  @objc func didBecomeActive(_ notification: Notification) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
}
