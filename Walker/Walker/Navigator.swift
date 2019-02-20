//
//  Navigator.swift
//  Pokemon GO Controller Mac
//
//  Created by BumMo Koo on 2016. 7. 27..
//  Copyright © 2016년 BumMo Koo. All rights reserved.
//

import Cocoa
import MapKit
import MapboxDirections

class Navigator {
  fileprivate let sourceCoordinate: CLLocationCoordinate2D
  fileprivate let destinationCoordinate: CLLocationCoordinate2D
  fileprivate let transportType: MKDirectionsTransportType
  
  fileprivate var route: MKRoute?
  fileprivate var points: [MKMapPoint]?
  
  fileprivate var stepStart: MKMapPoint?
  fileprivate var stepEnd: MKMapPoint?
  fileprivate var stepCount = -1
  
  fileprivate var speed = Speed.walk
  fileprivate var currentCoordinate: CLLocationCoordinate2D?
  
  fileprivate var progressHandler: ((CLLocationCoordinate2D) -> ())?
  fileprivate let directions = Directions(accessToken: "pk.eyJ1IjoiZXRoYW1pbmUiLCJhIjoiY2pxbW0xeDEwMDA5cTN4bzNvMGQ1bXA2MSJ9.dvcKyNBbbZkbP2nqi_dsVQ")
  
  public var directRoute = false
  
  var paused: Bool = false {
    didSet {
      if paused == false {
        self.moveAlongStep()
      }
    }
  }
  
  init(sourceCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D, transportType: MKDirectionsTransportType) {
    self.sourceCoordinate = sourceCoordinate
    self.destinationCoordinate = destinationCoordinate
    self.transportType = transportType
  }
  
  func findRoute(_ handler: @escaping (_ route: MKRoute?) -> ()) {
    let source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: sourceCoordinate.latitude, longitude: sourceCoordinate.longitude), addressDictionary: nil))
    let destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: destinationCoordinate.latitude, longitude: destinationCoordinate.longitude), addressDictionary: nil))
    let originalTransportType = transportType
    let request = MKDirections.Request()
    request.source = source
    request.destination = destination
    request.requestsAlternateRoutes = false
    request.transportType = originalTransportType
    let directions = MKDirections(request: request)
    directions.calculate { [weak self] (response, error) in
      guard let route = response?.routes.first else {
        print("Failed to get directions for type \(originalTransportType), requesting for an automobile")
        request.transportType = MKDirectionsTransportType.automobile
        MKDirections(request: request).calculate(completionHandler: { [weak self] (responseAny, errorAny) in
          guard let routeAny = responseAny?.routes.first else {
            print("Failed to get any directions :(")
            return
          }
          self?.route = routeAny
          self?.copyRoutePoints()
          handler(responseAny?.routes.first)
        })
        return
      }
      self?.route = route
      self?.copyRoutePoints()
      handler(response?.routes.first)
    }
  }
  
  fileprivate func copyRoutePoints() {
    guard let route = route else {
      return
    }
    let pointsPointer = route.polyline.points()
    var points = [MKMapPoint]()
    for index in 0 ..< route.polyline.pointCount {
      let point = pointsPointer[index]
      points.append(point)
    }
    self.points = points
  }
  
  func startNavigation(speed: Speed, progress: ((_ coordinate: CLLocationCoordinate2D) -> ())?) {
    self.speed = speed
    self.progressHandler = progress
    stepStart = points?.removeFirst()
    stepEnd = points?.removeFirst()
    guard let stepStart = stepStart else {
      return
    }
    currentCoordinate = stepStart.coordinate
    progressHandler?(currentCoordinate!)
    moveAlongRoute()
  }
  
  fileprivate func moveAlongRoute() {
    guard
      let points = points,
      let currentCoordinate = currentCoordinate,
      let stepEnd = stepEnd else {
        return
    }
    
    if points.count == 0 {
      return
    }
    if currentCoordinate == stepEnd.coordinate {
      if points.count > 0 {
        stepStart = stepEnd
        self.stepEnd = self.points?.removeFirst()
        moveAlongStep()
      }
      return
    }
    
    moveAlongStep()
  }
  
  fileprivate func moveAlongStep() {
    guard
      let startPoint = self.stepStart,
      let endPoint = self.stepEnd,
      let currentCoordinate = currentCoordinate else {
        return
    }
    let currentMapPoint = MKMapPoint.init(currentCoordinate)
    let meterPerMapPoint = MKMetersPerMapPointAtLatitude(currentCoordinate.latitude)
    let speed = self.speed.rawValue / meterPerMapPoint
    let xSide = endPoint.x - startPoint.x
    let ySide = endPoint.y - startPoint.y
    let zSide = sqrt(pow(xSide, 2) + pow(ySide, 2))
    let xDelta = speed * xSide / zSide
    let yDelta = speed * ySide / zSide
    let finalX = currentMapPoint.x + xDelta
    let finalY = currentMapPoint.y + yDelta
    let finalPoint = MKMapPoint(x: finalX, y: finalY)
    let finalCoordinate = finalPoint.coordinate
    
    if stepCount == -1 {
      stepCount = Int(zSide / speed)
    }
    
    if stepCount == 0 {
      let finalCoordinate = endPoint.coordinate
      self.currentCoordinate = finalCoordinate
      progressHandler?(finalCoordinate)
      self.stepCount = -1
      self.moveAlongRoute()
      return
    } else {
      self.currentCoordinate = finalCoordinate
      progressHandler?(finalCoordinate)
    }
    stepCount -= 1
    
    if paused {
      return
    }

    let time = DispatchTime.now() + Double(Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(deadline: time) { [weak self] in
      self?.moveAlongStep()
    }
  }
  
  func resetRoute() {
    points = nil
    stepStart = nil
    stepEnd = nil
    stepCount = -1
  }
}
