//
//  PicAnnotation.swift
//  Photo Map
//
//  Created by Sean Crenshaw on 3/26/16.
//  Copyright © 2016 Timothy Lee. All rights reserved.
//

import UIKit
import MapKit

class PicAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
    var photo: UIImage!
    var title: String? {
        return "\(coordinate.latitude)"
    }
    
}
