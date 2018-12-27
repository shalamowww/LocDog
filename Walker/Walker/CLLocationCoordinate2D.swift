//
//  CLLocationCoordinate2D.swift
//  Pokemon GO Controller Mac
//
//  Created by BumMo Koo on 2016. 7. 27..
//  Copyright © 2016년 BumMo Koo. All rights reserved.
//

import Cocoa
import MapKit

extension CLLocationCoordinate2D: Equatable {
  static public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
  }
}
