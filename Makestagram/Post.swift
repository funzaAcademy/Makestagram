//
//  Post.swift
//  Makestagram
//
//  Created by Sanjay noronha on 6/14/16.
//  Copyright © 2016 Make School. All rights reserved.
//

import Foundation
import Parse
import Bond
import ConvenienceKit

// 1
class Post : PFObject, PFSubclassing {
    
    // 2
    @NSManaged var imageFile: PFFile?
    @NSManaged var user: PFUser?
    
    static var imageCache: NSCacheSwift<String, UIImage>!
    
    var likes: Observable<[PFUser]?> = Observable(nil)
    
    //var image: UIImage?
    var image: Observable<UIImage?> = Observable(nil)
    
    var photoUploadTask: UIBackgroundTaskIdentifier? //to help background tasks continue when the app is shut down
    
    //MARK: PFSubclassing Protocol
    
    //  Boilerplate code
    static func parseClassName() -> String {
        return "Post"
    }
    
    //  Boilerplate code
    override init () {
        super.init()
    }
    
    //  Boilerplate code
    override class func initialize() {
        var onceToken : dispatch_once_t = 0;
        dispatch_once(&onceToken) {
            // inform Parse about this subclass
            self.registerSubclass()
            Post.imageCache = NSCacheSwift<String, UIImage>()
        }
        
        
    }
    
    func doesUserLikePost(user: PFUser) -> Bool {
        if let likes = likes.value {
            return likes.contains(user)
        } else {
            return false
        }
    }
    
    func toggleLikePost(user: PFUser) {
        if (doesUserLikePost(user)) {
            // if post is liked, unlike it now
            // 1
            
            //removing the user from the local cache stored in the likes property,
            likes.value = likes.value?.filter { $0 != user }
            ParseHelper.unlikePost(user, post: self)
        } else {
            // if this post is not liked yet, like it now
            // 2
            likes.value?.append(user)
            ParseHelper.likePost(user, post: self)
        }
    }
    
    func fetchLikes() {
        // 1
        if (likes.value != nil) {
            return
        }
        
        // 2
        ParseHelper.likesForPost(self, completionBlock: { (likes: [PFObject]?, error: NSError?) -> Void in
            
            // 3
            // The filter method takes a closure and returns an array that
            // only contains the objects from the original array that 
            // meet the requiremenstated in that closure.
            
            // We are removing all likes that belong to users that
            // no longer exist in our Makestagram app (because their account
            // as been deleted).
            
            let validLikes = likes?.filter { like in like[ParseHelper.ParseLikeFromUser] != nil }
            
            // 4
            // unlike filter, map does not remove objects but replaces them.
            // In this particular case we are replacing the likes in the array
            // with the users that are associated with the like.
            self.likes.value = validLikes?.map { like in
                let fromUser = like[ParseHelper.ParseLikeFromUser] as! PFUser
                
                return fromUser
            }
        })
    }
    
    func downloadImage() {
        // if image is not downloaded yet, get it
        // Parse automatically takes care of caching our downloads
        // and storing them on disk.
        
        // This means if we request an image that has been downloaded recently,
        // it will be fetched from the iPhone's local storage instead of from 
        // the Parse server.
        // 1
        
        // We attempt to assign a value to image.value directly from the cache,
        // using self.imageFile.name as key. If this assignment is successful the
        // entire download block will be skipped.
        image.value = Post.imageCache[self.imageFile!.name]
        
        if (image.value == nil) {
            // 2
            imageFile?.getDataInBackgroundWithBlock { (data: NSData?, error: NSError?) -> Void in
                if let data = data {
                    let image = UIImage(data: data, scale:1.0)!
                    // 3
                    self.image.value = image
                    Post.imageCache[self.imageFile!.name] = image
                }
            }
        }
    }
    
    func uploadPost() {
        if let image = image.value {
            
            guard let imageData = UIImageJPEGRepresentation(image, 0.8) else {return}
            guard let imageFile = PFFile(name: "o.jpg", data: imageData) else {return}
            
            self.imageFile = imageFile
            self.user = PFUser.currentUser()
            saveInBackgroundWithBlock(nil)
            
            // 1
            photoUploadTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
                UIApplication.sharedApplication().endBackgroundTask(self.photoUploadTask!)
            }
            
            // 2
            saveInBackgroundWithBlock() { (success: Bool, error: NSError?) in
                // 3
                UIApplication.sharedApplication().endBackgroundTask(self.photoUploadTask!)
            }
        }
    }
    
}
