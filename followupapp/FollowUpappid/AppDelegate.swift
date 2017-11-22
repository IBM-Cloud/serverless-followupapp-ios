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
import BMSCore
import BMSPush
import BluemixAppID
@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var pushAppGUID: String?
    var pushClientSecret: String?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //Initialize BMSCore SDK.
        let myBMSClient = BMSClient.sharedInstance
        myBMSClient.initialize(bluemixRegion:BMSClient.Region.sydney ) // TODO: Change to the region of push notifications service.
        myBMSClient.requestTimeout = 10.0 // seconds
        
        // Initialize the AppID instance with your tenant ID and region
        // App Id initialization
        // NOTE: Enable Keychain Sharing capability in Xcode
        if let contents = Bundle.main.path(forResource:"BMSCredentials", ofType: "plist"), let dictionary = NSDictionary(contentsOfFile: contents) {
            let region = AppID.REGION_US_SOUTH
            let bmsclient = BMSClient.sharedInstance
                let backendGUID = dictionary["authTenantId"] as? String
                let serverlessBackendURL = dictionary["serverlessBackendUrl"] as? String
                pushAppGUID = dictionary["pushAppGuid"] as? String
                pushClientSecret = dictionary["pushClientSecret"] as? String
                bmsclient.initialize(bluemixRegion: region)
                let appid = AppID.sharedInstance
                appid.initialize(tenantId: backendGUID!, bluemixRegion: region)
                let appIdAuthorizationManager = AppIDAuthorizationManager(appid:appid)
                bmsclient.authorizationManager = appIdAuthorizationManager
            TokenStorageManager.sharedInstance.initialize(tenantId: backendGUID!)
            ServerlessAPI.sharedInstance.initialize(tenantId: backendGUID!,serverlessBackendURL: serverlessBackendURL!)
        }
        
        
        //Request for user permission to send push notifications
        let notificationSettings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(notificationSettings)
        UIApplication.shared.registerForRemoteNotifications()
        return true
    }    
    
    func application(_ application: UIApplication, open url: URL, options :[UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return AppID.sharedInstance.application(application, open: url, options: options)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let push =  BMSPushClient.sharedInstance
        push.initializeWithAppGUID(appGUID: pushAppGUID!, clientSecret: pushClientSecret!)
        push.registerWithDeviceToken(deviceToken: deviceToken) { (response, statusCode, error) -> Void in
            if error.isEmpty {
                print( "Response during device registration : \(String(describing: response))")
                print( "status code during device registration : \(String(describing: statusCode))")
            } else{
                print( "Error during device registration \(error) ")
                print( "Error during device registration \n  - status code: \(String(describing: statusCode)) \n Error :\(error) \n")
            }
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

