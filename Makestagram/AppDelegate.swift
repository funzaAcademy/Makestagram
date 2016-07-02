//
//  AppDelegate.swift
//  Makestagram
//
//  Created by Benjamin Encz on 5/15/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import UIKit
import Parse

//implementing Login functionality
import FBSDKCoreKit
import ParseUI
import ParseFacebookUtilsV4

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
    
    var parseLoginHelper: ParseLoginHelper!
    
    override init() {
        super.init()
        
        parseLoginHelper = ParseLoginHelper {[unowned self] user, error in
            // Initialize the ParseLoginHelper with a callback
            if let error = error {
                // 1: This error handler method was included as part of the template project
                ErrorHandling.defaultErrorHandler(error)
            } else  if let _ = user {
                // if login was successful, display the TabBarController
                // 2
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let tabBarController = storyboard.instantiateViewControllerWithIdentifier("TabBarController")
                
                // 3 :When the code in this closure runs, our app will already have the login screen as its rootViewController.
                self.window?.rootViewController!.presentViewController(tabBarController, animated:true, completion:nil)
            }
        }
    }


  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Override point for customization after application launch.
    
    // Set up the Parse SDK
   
    let configuration = ParseClientConfiguration {
        $0.applicationId = "sanjayApp"
        $0.server = "https://sanapp.herokuapp.com/parse"
    }
    
    Parse.initializeWithConfiguration(configuration)
    
    //code to get the user to log in with a test user
    
    
    //define an access control list
    let acl = PFACL()
    
    //any user can read all objects with this ACL
    acl.publicReadAccess = true
   
    //only provide write access to the user that created the object
    PFACL.setDefaultACL(acl, withAccessForCurrentUser: true)
    
    //////////////////////////////
    // Initialize Facebook
    // 1
    PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)
    
    // check if we have logged in user
    // 2
    let user = PFUser.currentUser()
    
    let startViewController: UIViewController
    
    if (user != nil) {
        // 3
        // if we have a user, set the TabBarController to be the initial view controller
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        startViewController = storyboard.instantiateViewControllerWithIdentifier("TabBarController") as! UITabBarController
    } else {
        // 4
        // Otherwise set the LoginViewController to be the first
        let loginViewController = PFLogInViewController()
        loginViewController.fields = [.UsernameAndPassword, .LogInButton, .SignUpButton, .PasswordForgotten, .Facebook]
        loginViewController.delegate = parseLoginHelper
        loginViewController.signUpController?.delegate = parseLoginHelper
        
        startViewController = loginViewController
    }
    
    // 5
    self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
    self.window?.rootViewController = startViewController;
    self.window?.makeKeyAndVisible()
    ///////////////////////////
    
    //return true
    return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

    //MARK: Facebook Integration
    
    func applicationDidBecomeActive(application: UIApplication) {
        FBSDKAppEvents.activateApp()
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }


}

