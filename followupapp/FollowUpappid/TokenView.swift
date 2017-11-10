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

class TokenView: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    var idToken:IdentityToken?
    var accessToken:AccessToken?
    @IBOutlet weak var idTokenLabel: UILabel!
    @IBOutlet weak var accessTokenLabel: UILabel!
    
    @IBAction func closeView() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        // Adding a navigation bar and "Back" button
        let navBar: UINavigationBar = UINavigationBar(frame: CGRect(x: 0, y: 20, width: UIScreen.main.bounds.width, height: 40))
        self.view.addSubview(navBar);
        let navItem = UINavigationItem(title: "");
        let doneItem = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.plain, target: nil, action: #selector(TokenView.closeView));
        doneItem.tintColor = UIColor.black
        navItem.leftBarButtonItem = doneItem;
        navBar.setItems([navItem], animated: false);
        navBar.barTintColor = UIColor.init(red: 246/255, green: 247/255, blue: 251/255, alpha: 1)
        
        // Getting the access and id token data
        // And Formatting the tokens data into readable text
        if let idTokenPayload = idToken?.payload {
            idTokenLabel.text = try? Utils.JSONStringify(idTokenPayload as AnyObject, prettyPrinted: true)
            idTokenLabel.text = idTokenLabel.text?.replacingOccurrences(of: "\\/", with: "/")
        }
        
        if let accessTokenPayload = accessToken?.payload {
            accessTokenLabel.text = try? Utils.JSONStringify(accessTokenPayload as AnyObject, prettyPrinted: true)
            accessTokenLabel.text = accessTokenLabel.text?.replacingOccurrences(of: "\\/", with: "/")
        }
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
}

