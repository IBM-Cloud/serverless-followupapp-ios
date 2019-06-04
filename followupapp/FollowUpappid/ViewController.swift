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

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var hint: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    class delegate : AuthorizationDelegate {
        public func onAuthorizationSuccess(accessToken: AccessToken?, identityToken: IdentityToken?, refreshToken: RefreshToken?, response: Response?) {
          if let accessToken = accessToken {
            let mainView  = UIApplication.shared.keyWindow?.rootViewController
            let afterLoginView  = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AfterLoginView") as? AfterLoginViewController
            afterLoginView?.accessToken = accessToken
            afterLoginView?.idToken = identityToken
            
            if accessToken.isAnonymous {
                TokenStorageManager.sharedInstance.storeToken(token: accessToken.raw)
            } else {
                TokenStorageManager.sharedInstance.clearStoredToken()
            }
            TokenStorageManager.sharedInstance.storeUserId(userId: accessToken.subject)
            
            DispatchQueue.main.async {
                mainView?.present(afterLoginView!, animated: true, completion: nil)
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
    
    @IBAction func log_in_anonymously(_ sender: Any) {
        AppID.sharedInstance.signinAnonymously(authorizationDelegate: delegate())
    }
    
    @IBAction func log_in(_ sender: AnyObject) {
      AppID.sharedInstance.loginWidget?.launch(delegate: delegate())
    }
}

