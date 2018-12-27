//
//  ViewController.swift
//  Pokemon GO Controller Mac
//
//  Created by BumMo Koo on 2016. 7. 26..
//  Copyright © 2016년 BumMo Koo. All rights reserved.
//

import Cocoa
import MapKit

class ViewController: NSViewController {
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var coordinateVisualEffectView: NSVisualEffectView!
  @IBOutlet weak var coordinateTextField: NSTextField!
  
  fileprivate var preference = PreferenceManager.defaultManager
  
  var speed: Speed = Speed.walk {
    didSet {
      preference.speed = speed
      updateSpeedPopUpButton()
    }
  }
  
  var userLocation: CLLocationCoordinate2D? {
    didSet {
      preference.userLocation = userLocation
      updateUserLocationPin()
      updateCoordinateTextField()
    }
  }
  
  var favorites: [Favorite]? {
    didSet {
      preference.favorites = favorites
      updateFavoritesPins()
    }
  }
  
  fileprivate var userLocationPin: MKPointAnnotation?
  fileprivate var favoritesPins = [MKPointAnnotation]()
  
  fileprivate var rightMouseDownEvent: NSEvent?
  
  var navigator: Navigator?
  
  // MARK: View
  override func viewDidLoad() {
    super.viewDidLoad()
    mapView.delegate = self
    mapView.showsScale = true
    mapView.showsUserLocation = true
    coordinateVisualEffectView.layer?.cornerRadius = 9.0
    speed = preference.speed
    userLocation = preference.userLocation
    favorites = preference.favorites
    handleKeyPress()
    
    // Move map
    if let userLocation = userLocation {
      let latitudeDelta = UnitConverter.latitudeDegrees(fromMeter: 1000)
      let longitudeDelta = UnitConverter.longitudeDegress(fromMeter: 1000, latitude: userLocation.latitude)
      let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
      let region = MKCoordinateRegion(center: userLocation, span: span)
      mapView.setRegion(region, animated: true)
    }
  }
  
  fileprivate func updateSpeedPopUpButton() {
    let windowController = view.window?.windowController as? WindowController
    windowController?.updateSpeedPopUpButton()
  }
  
  fileprivate func updateCoordinateTextField() {
    if let latitude = userLocation?.latitude, let longitude = userLocation?.longitude {
      coordinateTextField.stringValue = "\(latitude), \(longitude)"
    }
  }
  
  fileprivate func updateUserLocationPin() {
    guard let userLocation = userLocation else {
      return
    }
    if userLocationPin == nil {
      userLocationPin = MKPointAnnotation()
      mapView.addAnnotation(userLocationPin!)
    }
    userLocationPin?.coordinate = userLocation
  }
  
  fileprivate func updateFavoritesPins() {
    mapView.removeAnnotations(favoritesPins)
    guard let favorites = favorites else {
      return
    }
    for favorite in favorites {
      let annotation = MKPointAnnotation()
      annotation.coordinate = favorite.coordinate
      annotation.title = favorite.name
      mapView.addAnnotation(annotation)
      favoritesPins.append(annotation)
    }
  }
  
  // MARK: Action
  @objc fileprivate func handleTeleportMenu(_ sender: NSMenuItem) {
//    guard let point = rightMouseDownEvent?.locationInWindow else {
//      return
//    }
//    let coordinate = mapView.convert(point, toCoordinateFrom: view)
//    favorites?.append(Favorite(coordinate: coordinate))
//    rightMouseDownEvent = nil
    guard let point = rightMouseDownEvent?.locationInWindow else {
      return
    }
    mapView.removeOverlays(mapView.overlays)
    let coordinate = mapView.convert(point, toCoordinateFrom: view)
    userLocation = coordinate
  }
  
  fileprivate func handleKeyPress() {
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (event) -> NSEvent? in
      guard let coordinate = self.userLocation else {
        return event
      }
      let speed = self.speed.rawValue
      let latitudeDelta = UnitConverter.latitudeDegrees(fromMeter: speed)
      let longitudeDelta = UnitConverter.longitudeDegress(fromMeter: speed, latitude: coordinate.latitude)
      switch event.keyCode {
        case 126, 13: // Up
          self.userLocation = CLLocationCoordinate2D(latitude: coordinate.latitude + latitudeDelta + self.speed.jitter - self.speed.jitter, longitude: coordinate.longitude + self.speed.jitter - self.speed.jitter)
        case 125, 1: // Down
          self.userLocation = CLLocationCoordinate2D(latitude: coordinate.latitude - latitudeDelta + self.speed.jitter - self.speed.jitter, longitude: coordinate.longitude + self.speed.jitter - self.speed.jitter)
        case 123, 0: // Left
          self.userLocation = CLLocationCoordinate2D(latitude: coordinate.latitude + self.speed.jitter - self.speed.jitter, longitude: coordinate.longitude - longitudeDelta + self.speed.jitter - self.speed.jitter)
        case 124, 2: // Right
          self.userLocation = CLLocationCoordinate2D(latitude: coordinate.latitude + self.speed.jitter - self.speed.jitter, longitude: coordinate.longitude + longitudeDelta + self.speed.jitter - self.speed.jitter)
        case 49:
          self.navigator?.paused = !(self.navigator?.paused ?? false)
        default:
          return event
      }
      return nil
    }
  }
}

extension ViewController {
//  override func mouseUp(with theEvent: NSEvent) {
//    mapView.removeOverlays(mapView.overlays)
//    let point = theEvent.locationInWindow
//    let coordinate = mapView.convert(point, toCoordinateFrom: view)
//    userLocation = coordinate
//  }
  
  override func rightMouseDown(with theEvent: NSEvent) {
    rightMouseDownEvent = theEvent
    let menu = NSMenu(title: "Menu")
    menu.addItem(withTitle: "Walk to this location", action: #selector(handleMenu(_:)), keyEquivalent: "")
    menu.addItem(withTitle: "Run to this location", action: #selector(handleMenu(_:)), keyEquivalent: "")
    menu.addItem(withTitle: "Cycle to this location", action: #selector(handleMenu(_:)), keyEquivalent: "")
    menu.addItem(withTitle: "Drive to this location", action: #selector(handleMenu(_:)), keyEquivalent: "")
    menu.addItem(withTitle: "Race to this location", action: #selector(handleMenu(_:)), keyEquivalent: "")
    menu.addItem(NSMenuItem.separator())
    menu.addItem(withTitle: "Teleport here", action: #selector(handleTeleportMenu(_:)), keyEquivalent: "")
    NSMenu.popUpContextMenu(menu, with: theEvent, for: mapView)
  }
  
  @objc func handleMenu(_ sender: NSMenuItem) {
    guard let index = sender.menu?.index(of: sender) else {
      return
    }
    self.speed = Speed(menuIndex: index)
    
    guard let userLocation = userLocation else {
      return
    }
    guard let point = rightMouseDownEvent?.locationInWindow else {
      return
    }
    let coordinate = mapView.convert(point, toCoordinateFrom: view)
    rightMouseDownEvent = nil
    
    print("STARTING \(self.speed) TO LOCATION")
    
    let transportType: MKDirectionsTransportType = speed.rawValue >= Speed.drive.rawValue ? .automobile : .walking
    navigator = Navigator(sourceCoordinate: userLocation, destinationCoordinate: coordinate, transportType: transportType)
    navigator?.findRoute({ [weak self] (route) in
      if let overlays = self?.mapView.overlays {
        self?.mapView.removeOverlays(overlays)
      }
      guard let route = route else {
        return
      }
      self?.mapView.addOverlay(route.polyline, level: .aboveRoads)
      self?.navigator?.startNavigation(speed: self!.speed, progress: { (coordinate) in
        self?.userLocation = coordinate
      })
    })
  }
}

extension ViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if overlay is MKPolyline {
      let renderer = MKPolylineRenderer(overlay: overlay)
      renderer.lineCap = .round
      renderer.lineWidth = 3
      renderer.strokeColor = NSColor.blue
      return renderer
    }
    return MKOverlayRenderer()
  }
  
  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    guard
      let annotation = view.annotation,
      let window = view.window,
      let favorite = favorites?.filter({ $0.coordinate == annotation.coordinate }).first,
      let index = favorites?.index(of: favorite) else {
        return
    }
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = "Confirm deleting this pin?"
    alert.addButton(withTitle: "Confirm")
    alert.addButton(withTitle: "Cancel")
    alert.beginSheetModal(for: window, completionHandler: { [weak self] (response) in
      switch response {
      case NSApplication.ModalResponse.alertFirstButtonReturn:
        self?.favorites?.remove(at: index)
      default: break
      }
    })
  }
}
