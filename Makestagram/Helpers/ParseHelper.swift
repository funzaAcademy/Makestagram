//
//  ParseHelper.swift
//  Makestagram
//
//  Created by Sanjay noronha on 6/16/16.
//  Copyright © 2016 Make School. All rights reserved.
//

import Foundation
import Parse

class ParseHelper {
    
    // Note that the constant names follow this pattern:
    // Parse[ClassName][FieldName].
    // Following Relation
    static let ParseFollowClass       = "Follow"
    static let ParseFollowFromUser    = "fromUser"
    static let ParseFollowToUser      = "toUser"
    
    // Like Relation
    static let ParseLikeClass         = "Like"
    static let ParseLikeToPost        = "post"
    static let ParseLikeFromUser      = "user"
    
    // Post Relation
    static let ParsePostUser          = "user"
    static let ParsePostCreatedAt     = "createdAt"
    
    // Flagged Content Relation
    static let ParseFlaggedContentClass    = "FlaggedContent"
    static let ParseFlaggedContentFromUser = "fromUser"
    static let ParseFlaggedContentToPost   = "toPost"
    
    // User Relation
    static let ParseUserUsername      = "username"
    
    static func likePost(user: PFUser, post: Post) {
        
        print(" in the parse helper likePost method")
        let likeObject = PFObject(className: ParseLikeClass)
        likeObject[ParseLikeFromUser] = user
        likeObject[ParseLikeToPost] = post
        
        likeObject.saveInBackgroundWithBlock { (succeeded: Bool, error: NSError? ) in
            if succeeded {
                print("Save successful")
            } else {
                print("Save unsuccessful: \(error?.userInfo)")
            }
            
        }
    }
    
    static func unlikePost(user: PFUser, post: Post) {
        
        print(" in the parse helper unlikePost method")
        let query = PFQuery(className: ParseLikeClass)
        query.whereKey(ParseLikeFromUser, equalTo: user)
        query.whereKey(ParseLikeToPost, equalTo: post)
        
        query.findObjectsInBackgroundWithBlock { (results: [PFObject]?, error: NSError?) -> Void in
            // 2
            if let results = results {
                for like in results {
                    like.deleteInBackgroundWithBlock(nil)
                }
            }
        }
    }
    
    static func likesForPost(post: Post, completionBlock: PFQueryArrayResultBlock) {
        
        let query = PFQuery(className: "Like")
        query.whereKey("post", equalTo: post)
        // 2
        query.includeKey("user")
        
        query.findObjectsInBackgroundWithBlock(completionBlock)
        
    }
    
    
    
    
    static func timelineRequestForCurrentUser(range: Range<Int>, completionBlock: PFQueryArrayResultBlock) {
        
        let followingQuery = PFQuery(className: ParseFollowClass)
        followingQuery.whereKey(ParseFollowFromUser, equalTo:PFUser.currentUser()!)
        
        let postsFromFollowedUsers = Post.query()
        postsFromFollowedUsers!.whereKey(ParsePostUser, matchesKey: ParseFollowToUser, inQuery: followingQuery)
        
        let postsFromThisUser = Post.query()
        postsFromThisUser!.whereKey(ParsePostUser, equalTo: PFUser.currentUser()!)
        
        let query = PFQuery.orQueryWithSubqueries([postsFromFollowedUsers!, postsFromThisUser!])
        query.includeKey(ParsePostUser)
        query.orderByDescending(ParsePostCreatedAt)
        
        //Range literals can be defined like this: 5..10
        
        // 2 how many elements that match our query shall be skipped
        query.skip = range.startIndex
        
        // 3: how many elements we want to load.
        query.limit = range.endIndex - range.startIndex
        
        query.findObjectsInBackgroundWithBlock(completionBlock)
    }
    
    // MARK: Following
    
    /**
     Fetches all users that the provided user is following.
     
     :param: user The user whose followees you want to retrieve
     :param: completionBlock The completion block that is called when the query completes
     */
    static func getFollowingUsersForUser(user: PFUser, completionBlock: PFQueryArrayResultBlock) {
        let query = PFQuery(className: ParseFollowClass)
        
        query.whereKey(ParseFollowFromUser, equalTo:user)
        query.findObjectsInBackgroundWithBlock(completionBlock)
    }
    
    /**
     Establishes a follow relationship between two users.
     
     :param: user    The user that is following
     :param: toUser  The user that is being followed
     */
    static func addFollowRelationshipFromUser(user: PFUser, toUser: PFUser) {
        let followObject = PFObject(className: ParseFollowClass)
        followObject.setObject(user, forKey: ParseFollowFromUser)
        followObject.setObject(toUser, forKey: ParseFollowToUser)
        
        followObject.saveInBackgroundWithBlock(nil)
    }
    
    /**
     Deletes a follow relationship between two users.
     
     :param: user    The user that is following
     :param: toUser  The user that is being followed
     */
    static func removeFollowRelationshipFromUser(user: PFUser, toUser: PFUser) {
        let query = PFQuery(className: ParseFollowClass)
        query.whereKey(ParseFollowFromUser, equalTo:user)
        query.whereKey(ParseFollowToUser, equalTo: toUser)
        
        query.findObjectsInBackgroundWithBlock { (results: [PFObject]?, error: NSError?) -> Void in
            
            let results = results ?? []
            
            for follow in results {
                follow.deleteInBackgroundWithBlock(nil)
            }
        }
    }
    
    // MARK: Users
    
    /**
     Fetch all users, except the one that's currently signed in.
     Limits the amount of users returned to 20.
     
     :param: completionBlock The completion block that is called when the query completes
     
     :returns: The generated PFQuery
     */
    
    
    /* It's noteworthy that both of these methods return a PFQuery object. This allows the FriendSearchViewController to keep a reference to current active request. As the user types into the search field, we will kick off a new search request every time the text changes; you will see that later in the code for the FriendSearchViewController.
    */
    static func allUsers(completionBlock: PFQueryArrayResultBlock) -> PFQuery {
        let query = PFUser.query()!
        // exclude the current user
        query.whereKey(ParseHelper.ParseUserUsername,
                       notEqualTo: PFUser.currentUser()!.username!)
        query.orderByAscending(ParseHelper.ParseUserUsername)
        query.limit = 20
        
        query.findObjectsInBackgroundWithBlock(completionBlock)
        
        return query
    }
    
    /**
     Fetch users whose usernames match the provided search term.
     
     :param: searchText The text that should be used to search for users
     :param: completionBlock The completion block that is called when the query completes
     
     :returns: The generated PFQuery
     */
    static func searchUsers(searchText: String, completionBlock: PFQueryArrayResultBlock) -> PFQuery {
        /*
         NOTE: We are using a Regex to allow for a case insensitive compare of usernames.
         Regex can be slow on large datasets. For large amount of data it's better to store
         lowercased username in a separate column and perform a regular string compare.
         
         The FriendSearchViewController will use the reference to the current query to cancel the current request before starting a new one. That way we can prevent a fast-typing user from starting many requests to start in parallel.
         */
        let query = PFUser.query()!.whereKey(ParseHelper.ParseUserUsername,
                                             matchesRegex: searchText, modifiers: "i")
        
        query.whereKey(ParseHelper.ParseUserUsername,
                       notEqualTo: PFUser.currentUser()!.username!)
        
        query.orderByAscending(ParseHelper.ParseUserUsername)
        query.limit = 20
        
        query.findObjectsInBackgroundWithBlock(completionBlock)
        
        return query
    }
    
    
}

//Add the following extension to the end of the ParseHelper.swift class
//(outside of the class definition of ParseHelper):
extension PFObject {
    
    public override func isEqual(object: AnyObject?) -> Bool {
        if (object as? PFObject)?.objectId == self.objectId {
            
            print("I should get printed")
            return true
        } else {
            return super.isEqual(object)
        }
    }
    
}