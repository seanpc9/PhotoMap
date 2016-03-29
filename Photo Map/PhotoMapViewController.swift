//
//  PhotoMapViewController.swift
//  Photo Map
//
//  Created by Nicholas Aiwazian on 10/15/15.
//  Copyright © 2015 Timothy Lee. All rights reserved.
//

import UIKit
import MapKit

class PhotoMapViewController: UIViewController, UIImagePickerControllerDelegate, LocationsViewControllerDelegate, UINavigationControllerDelegate, MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var curImage: UIImage!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    let CLIENT_ID = "QA1L0Z0ZNA2QVEEDHFPQWK0I5F1DE3GPLSNW4BZEBGJXUCFL"
    let CLIENT_SECRET = "W2AOE1TYC4MHK5SZYOUGX0J3LVRALMPB4CXT3ZH21ZCPUMCU"
    
    var results: NSArray = []

    override func viewDidLoad() {
        super.viewDidLoad()

        //one degree of latitude is approximately 111 kilometers (69 miles) at all times.
        let burgRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake(37.2289788, -80.4258549),MKCoordinateSpanMake(0.1, 0.1))
        mapView.setRegion(burgRegion, animated: false)
        mapView.delegate = self
        
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        
        searchBar.placeholder = "Basketball"
        
        fetchNear()
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
        
        // curImage = editedImage
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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("LocationCell") as! LocationCell
        
        cell.location = results[indexPath.row] as! NSDictionary
        
        return cell
    }
    
    func searchBar(searchBar: UISearchBar, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        let newText = NSString(string: searchBar.text!).stringByReplacingCharactersInRange(range, withString: text)
        fetchLocations(newText)
        
        return true
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        fetchLocations(searchBar.text!)
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
    
    func fetchNear(near: String = "Blacksburg, VA") {        // Let user input String for near
        let baseUrlString = "https://api.foursquare.com/v2/venues/search?"
        let queryString = "client_id=\(CLIENT_ID)&client_secret=\(CLIENT_SECRET)&v=20141020&near=\(near)"
        
        let url = NSURL(string: baseUrlString + queryString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)!
        let request = NSURLRequest(URL: url)
        
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue()
        )
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: { (dataOrNil, response, error) in
            if let data = dataOrNil {
                if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                    data, options:[]) as? NSDictionary {
                    NSLog("response: \(responseDictionary)")
                    let test = responseDictionary.valueForKeyPath("response.venues") as! NSArray
                    if (test.count != 0) {
                        self.results = responseDictionary.valueForKeyPath("response.venues") as! NSArray
                        self.tableView.reloadData()
                    }
                }
            }
        });
        task.resume()
    }
    
    func fetchLocations(query: String, near: String = "Blacksburg, VA") {        // Let user input String for near
        let baseUrlString = "https://api.foursquare.com/v2/venues/search?"
        let queryString = "client_id=\(CLIENT_ID)&client_secret=\(CLIENT_SECRET)&v=20141020&near=\(near)&query=\(query)"
        
        let url = NSURL(string: baseUrlString + queryString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)!
        let request = NSURLRequest(URL: url)
        
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue()
        )
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: { (dataOrNil, response, error) in
            if let data = dataOrNil {
                if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                    data, options:[]) as? NSDictionary {
                    NSLog("response: \(responseDictionary)")
                    let test = responseDictionary.valueForKeyPath("response.venues") as! NSArray
                    if (test.count != 0) {
                        self.results = responseDictionary.valueForKeyPath("response.venues") as! NSArray
                        self.tableView.reloadData()
                    }
                }
            }
        });
        task.resume()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let vc = LocationsViewController()
        vc.delegate = self
        
        let venue = results[indexPath.row] as! NSDictionary
        
        let lat = venue.valueForKeyPath("location.lat") as! NSNumber
        let lng = venue.valueForKeyPath("location.lng") as! NSNumber
        
        let latString = "\(lat)"
        let lngString = "\(lng)"
        
        print(latString + " " + lngString)
        
        locationsPickedLocation(vc, latitude: lat, longitude: lng)
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
