//
//  PhotoTakingHelper.swift
//  Makestagram
//
//  Created by Sanjay noronha on 6/14/16.
//  Copyright © 2016 Make School. All rights reserved.
//

// Popover to allow the user to choose between taking a new photo or selecting one from library.
// Depending on the user's selection, presenting the camera or photo library.
// Returning the image that the user has taken or selected.

import UIKit


    
    typealias PhotoTakingHelperCallback = UIImage? -> Void
    
    class PhotoTakingHelper : NSObject {
        
        // View controller on which AlertViewController and UIImagePickerController are presented
        
        weak var viewController: UIViewController!
       
        var callback: PhotoTakingHelperCallback
        
        var imagePickerController: UIImagePickerController?
        
        init(viewController: UIViewController, callback: PhotoTakingHelperCallback) {
            self.viewController = viewController
            self.callback = callback
            
            super.init()
            
            showPhotoSourceSelection()
        }
        
        func showPhotoSourceSelection() {
            
            // Allow user to choose between photo library and camera
            let alertController = UIAlertController(title: nil, message: "Where do you want to get your picture from?", preferredStyle: .ActionSheet)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let photoLibraryAction = UIAlertAction(title: "Photo from Library", style: .Default) { (action) in
                self.showImagePickerController(.PhotoLibrary)
            }
            
            alertController.addAction(photoLibraryAction)
            // Only show camera option if rear camera is available
            if (UIImagePickerController.isCameraDeviceAvailable(.Rear)) {
                let cameraAction = UIAlertAction(title: "Photo from Camera", style: .Default) { (action) in
                    self.showImagePickerController(.Camera)
                }
                
                alertController.addAction(cameraAction)
            }
            
            viewController.presentViewController(alertController, animated: true, completion: nil)
        }
        
        func showImagePickerController(sourceType: UIImagePickerControllerSourceType) {
            
            imagePickerController = UIImagePickerController()
            imagePickerController!.sourceType = sourceType
            imagePickerController!.delegate = self
            
            self.viewController.presentViewController(imagePickerController!, animated: true, completion: nil)
        }

        
    }

extension PhotoTakingHelper : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
       // viewController.dismissViewControllerAnimated(false, completion: nil)
       // callback(info[UIImagePickerControllerOriginalImage] as? UIImage)
        viewController.dismissViewControllerAnimated(false) {
            self.callback(info[UIImagePickerControllerOriginalImage] as? UIImage)
        }
        
    }
    

    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        
        viewController.dismissViewControllerAnimated(true, completion: nil)
    
    }
}
