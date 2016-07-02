//
//  PostTableViewCell.swift
//  Makestagram
//
//  Created by Sanjay noronha on 6/16/16.
//  Copyright © 2016 Make School. All rights reserved.
//

import UIKit
import Bond
import Parse

class PostTableViewCell: UITableViewCell {

    var postDisposable: DisposableType?
    var likeDisposable: DisposableType?
    
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var likesIconImageView: UIImageView!
    @IBOutlet weak var postImageView: UIImageView!
    
    var post: Post? {
        didSet {
           
            postDisposable?.dispose()
            likeDisposable?.dispose()
            
            // free memory of image stored with post that is no longer displayed
            // 1
            if let oldValue = oldValue where oldValue != post {
                // 2
                oldValue.image.value = nil
            }
            
            if let post = post {
                // 2 : The observe method is provided by the Bond framewor
                //post.image.bindTo(postImageView.bnd_image)
                
                postDisposable = post.image.bindTo(postImageView.bnd_image)
                
                //The code defined by the closure 
                //will be executed every time post.likes receives a new value
                likeDisposable = post.likes.observe { (value: [PFUser]?) -> () in
                    
                    // 3 : The parameter named value in the closure definition
                    // will contain the actual contents of post.likes; that is, 
                    // the Observable wrapper will have been removed.
                    if let value = value {
                        // 4
                        self.likesLabel.text = self.stringFromUserList(value)
                        // 5 :The contains function is supposed to check 
                        //   whether or not an object is contained in a provided list
                        self.likeButton.selected = value.contains(PFUser.currentUser()!)
                        // 6
                        self.likesIconImageView.hidden = (value.count == 0)
                    } else {
                        // 7
                        self.likesLabel.text = ""
                        self.likeButton.selected = false
                        self.likesIconImageView.hidden = true
                    }
                }
            }
        }
    }
    

    @IBAction func likeButtonTapped(sender: AnyObject) {
        
        post?.toggleLikePost(PFUser.currentUser()!)
    }
    
    
    @IBAction func moreButtonTapped(sender: AnyObject) {
    }
    
    func stringFromUserList(userList: [PFUser]) -> String {
        // 1 : Typically you use map to create a different representation of the same thing
        let usernameList = userList.map { user in user.username! }
        // 2
        let commaSeparatedUserList = usernameList.joinWithSeparator(", ")
        
        return commaSeparatedUserList
    }

}
