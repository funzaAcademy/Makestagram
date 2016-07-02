//
//  TimelineViewController.swift
//  Makestagram
//
//  Created by Sanjay noronha on 6/13/16.
//  Copyright © 2016 Make School. All rights reserved.
//

import UIKit
import Parse
import ConvenienceKit

// When working with the TimelineComponent, we
// are no longer responsible for updating the table view 
// and starting the queries. Instead that will be handled for us.

// Next, our TimelineViewController needs to implement the TimelineComponentTarget
// protocol. The TimelineComponent needs our cooperation in a couple of different ways, and this protocol defines which methods and properties need to be available on classes that want to work with it.

class TimelineViewController: UIViewController,TimelineComponentTarget  {

    //Note that you need to provide two different types in the angled brackets: the type of object you are displaying (Post) and the class that will be the target of the TimelineComponent (that's the TimelineViewController in our case).
    var timelineComponent: TimelineComponent<Post, TimelineViewController>!
   
     var photoTakingHelper: PhotoTakingHelper?
    
    let defaultRange = 0...4 //itially show the newest 5 posts
    let additionalRangeSize = 5 //When the user reaches the end of the timeline, we load an additional 5.
   
    
    
    @IBOutlet weak var tableView: UITableView!
    
    //var posts: [Post] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // The target is the object to which the
        // TimelineComponent shall add its functionality.
        timelineComponent = TimelineComponent(target: self)
        self.tabBarController?.delegate = self
        tableView.delegate = self

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}


//MARK: UITabBarControllerDelegate
extension TimelineViewController: UITabBarControllerDelegate {
    
     func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        
        if ( viewController is PhotoViewController) {
            
            // add photo taking code.
            
            takePhoto()
            return false
        }
        
        return true
        
        
    }
    
    func takePhoto() {
        // instantiate photo taking class, provide callback for when photo  is selected
        photoTakingHelper = PhotoTakingHelper(viewController: self.tabBarController!) { (image: UIImage?) in

            let post = Post()
            post.image.value = image
            post.uploadPost()
   
        }
    
    
    }

}


//MARK: UITableViewDataSource Delegate
extension TimelineViewController: UITableViewDataSource {
    
    override func viewDidAppear(animated: Bool) {
        
            super.viewDidAppear(animated)
        
            timelineComponent.loadInitialIfRequired()
        
          /*  ParseHelper.timelineRequestForCurrentUser { (result: [PFObject]?, error: NSError?) -> Void in
                // 8
                
                self.posts = result as? [Post] ?? []
                
                self.tableView.reloadData()
                
            } */
    }
    
    

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return timelineComponent.content.count
        //return posts.count
        
    }
    
    
        func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as! PostTableViewCell
            
            // let post = posts[indexPath.row]
            let post = timelineComponent.content[indexPath.row]
            post.downloadImage()  //will continue on a background thread
            post.fetchLikes()
            cell.post = post
            
            return cell
            
        }
        
        
    }
    

extension TimelineViewController {
    
    //A method that loads a certain portion of the timeline and calls the completionBlock when it's done.
    
    func loadInRange(range: Range<Int>, completionBlock: ([Post]?) -> Void) {
        // 1
        ParseHelper.timelineRequestForCurrentUser(range) { (result: [PFObject]?, error: NSError?) -> Void in
            // 2
            let posts = result as? [Post] ?? []
            // 3
            completionBlock(posts)
        }
    }
    
    
}

//  Whenever a cell becomes visible, we are required to call the targetWillDisplayEntry: method and pass the index of the currently displayed cell. That way the TimelineComponent will know when the user has scrolled to the bottom of the timeline.
extension TimelineViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        timelineComponent.targetWillDisplayEntry(indexPath.row)
    }
    
}

