//
//  Favorite.swift
//  Pokemon GO Controller Mac
//
//  Created by BumMo Koo on 2016. 7. 26..
//  Copyright © 2016년 BumMo Koo. All rights reserved.
//

import Cocoa
import MapKit

class Favorite: NSObject, NSCoding {
  var coordinate: CLLocationCoordinate2D
  var name: String?
  
  init(coordinate: CLLocationCoordinate2D, name: String? = nil) {
    self.coordinate = coordinate
    self.name = name
    super.init()
  }
  
  required init?(coder aDecoder: NSCoder) {
    let coordinateData = aDecoder.decodeObject(forKey: "coordinate") as! Data
    self.coordinate = (NSUnarchiver.unarchiveObject(with: coordinateData) as! NSValue).mkCoordinateValue
    self.name = aDecoder.decodeObject(forKey: "name") as? String
    super.init()
  }
  
  func encode(with aCoder: NSCoder) {
    let coordinateValue = NSValue(mkCoordinate: coordinate)
    let coordinateData = NSArchiver.archivedData(withRootObject: coordinateValue)
    aCoder.encode(coordinateData, forKey: "coordinate")
    aCoder.encode(name, forKey: "name")
  }
}

func ==(lhs: Favorite, rhs: Favorite) -> Bool {
  return lhs.coordinate.latitude == rhs.coordinate.latitude && lhs.coordinate.longitude == rhs.coordinate.longitude && lhs.name == rhs.name
}
