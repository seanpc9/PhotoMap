//
//  PhotoMapViewController.swift
//  Photo Map
//
//  Created by Nicholas Aiwazian on 10/15/15.
//  Copyright © 2015 Timothy Lee. All rights reserved.
//

import UIKit
import MapKit

class PhotoMapViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, LocationsViewControllerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var curImage: UIImage!

    override func viewDidLoad() {
        super.viewDidLoad()

        //one degree of latitude is approximately 111 kilometers (69 miles) at all times.
        let burgRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake(37.2289788, -80.4258549),MKCoordinateSpanMake(0.1, 0.1))
        mapView.setRegion(burgRegion, animated: false)
        mapView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func imagePickerController(picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        // Get the image captured by the UIImagePickerController
        let editedImage = info[UIImagePickerControllerEditedImage] as! UIImage
        
        // Dismiss UIImagePickerController to go back to your original view controller
        dismissViewControllerAnimated(true, completion: nil)
        performSegueWithIdentifier("tagSegue", sender: editedImage)
    }
    
    @IBAction func onCamera(sender: AnyObject) {
        let vc = UIImagePickerController()
        vc.delegate = self
        vc.allowsEditing = true
        
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)) {
            vc.sourceType = UIImagePickerControllerSourceType.Camera
        } else {
            vc.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        }
        
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    func locationsPickedLocation(controller: LocationsViewController, latitude: NSNumber,longitude: NSNumber) {
        
        let locationCoordinate = CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue)
        let image = controller.userPic
        
        navigationController?.popToViewController(self, animated: true)
        
        let annotation = PicAnnotation()
        
        annotation.coordinate = locationCoordinate
        annotation.photo = image
        
        mapView.addAnnotation(annotation)
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        performSegueWithIdentifier("fullImageSegue", sender: (view.annotation as? PicAnnotation)?.photo)
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseID = "myAnnotationView"
        
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseID)
        if (annotationView == nil) {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            annotationView!.canShowCallout = true
            annotationView!.leftCalloutAccessoryView = UIImageView(frame: CGRect(x:0, y:0, width: 30, height:30))
            
            let detailsButton = UIButton(type: .InfoLight)
            annotationView?.rightCalloutAccessoryView = detailsButton
        }
        
        let resizeRenderImageView = UIImageView(frame: CGRectMake(0, 0, 45, 45))
        resizeRenderImageView.layer.borderColor = UIColor.whiteColor().CGColor
        resizeRenderImageView.layer.borderWidth = 3.0
        resizeRenderImageView.contentMode = UIViewContentMode.ScaleAspectFill
        resizeRenderImageView.image = (annotation as? PicAnnotation)?.photo
        
        UIGraphicsBeginImageContext(resizeRenderImageView.frame.size)
        resizeRenderImageView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let annotationPic = annotationView?.leftCalloutAccessoryView as! UIImageView
        annotationPic.image = thumbnail
        annotationView!.image = thumbnail
        
        return annotationView
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let locations = segue.destinationViewController as? LocationsViewController {
            locations.delegate = self
            locations.userPic = sender as! UIImage
        } else if let fullImageVC = segue.destinationViewController as? FullImageViewController {
            fullImageVC.image = sender as! UIImage
        }
    }

}
