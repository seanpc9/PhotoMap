//
//  LocationsViewController.swift
//  Photo Map
//
//  Created by Timothy Lee on 10/20/14.
//  Copyright (c) 2014 Timothy Lee. All rights reserved.
//

import UIKit

// Protocol definition - top of LocationsViewController.swift
protocol LocationsViewControllerDelegate : class {
    func locationsPickedLocation(controller: LocationsViewController, latitude: NSNumber, longitude: NSNumber)
}

class LocationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var userPic: UIImage!
    
    weak var delegate : LocationsViewControllerDelegate!

    let CLIENT_ID = "QA1L0Z0ZNA2QVEEDHFPQWK0I5F1DE3GPLSNW4BZEBGJXUCFL"
    let CLIENT_SECRET = "W2AOE1TYC4MHK5SZYOUGX0J3LVRALMPB4CXT3ZH21ZCPUMCU"

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!

    var results: NSArray = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
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
        let venue = results[indexPath.row] as! NSDictionary
        
        let lat = venue.valueForKeyPath("location.lat") as! NSNumber
        let lng = venue.valueForKeyPath("location.lng") as! NSNumber
        
        let latString = "\(lat)"
        let lngString = "\(lng)"
        
        print(latString + " " + lngString)
        
        delegate.locationsPickedLocation(self, latitude: lat, longitude: lng)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPathForCell(cell)!
        
        // This is the selected venue
        let venue = results[indexPath.row] as! NSDictionary
        
        let lat = venue.valueForKeyPath("location.lat") as! NSNumber
        let lng = venue.valueForKeyPath("location.lng") as! NSNumber
        
        let latString = "\(lat)"
        let lngString = "\(lng)"
        
        print(latString + " " + lngString)
    }
}
