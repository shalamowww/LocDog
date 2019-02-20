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
      if cameraFollows {
        updateCamera()
      }
    }
  }
  
  var favorites: [Favorite]? {
    didSet {
      preference.favorites = favorites
      updateFavoritesPins()
    }
  }
  
  var bearing: CGFloat = 0 {
    didSet {
      if cameraFollows {
        updateCamera()
      }
    }
  }
  
  var cameraFollows = true
  
  fileprivate var userLocationPin: MKPointAnnotation?
  fileprivate var userLocationView: MKAnnotationView!
  fileprivate var favoritesPins = [MKPointAnnotation]()
  
  fileprivate var rightMouseDownEvent: NSEvent?
  
  var navigator: Navigator?
  
  // MARK: View
  override func viewDidLoad() {
    super.viewDidLoad()
    mapView.delegate = self
    mapView.showsScale = true
    mapView.showsUserLocation = true
    mapView.showsBuildings = true
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
    } else {
      preference.userLocation = mapView.userLocation.coordinate
    }
    
    let recognizer = NSPanGestureRecognizer(target: self, action: #selector(userDraggedMap(_:)))
    recognizer.delegate = self
    mapView.addGestureRecognizer(recognizer)
  }
  
  func updateCamera() {
    guard let userLocation = userLocation else {
      return
    }
    let camera = MKMapCamera()
    camera.heading = CLLocationDirection(bearing)
    camera.centerCoordinate = userLocation
    camera.altitude = mapView.camera.altitude
    mapView.setCamera(camera, animated: true)
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
      switch event.keyCode {
        case 126, 13: // Up
          let a = 6378137.0, f = 1/298.257223563
          var geod = geod_geodesic()
          geod_init(&geod, a, f)
          var newLat: Double = 0.0
          var newLon: Double = 0.0
          var newAzi: Double = 0.0
          geod_direct(&geod, coordinate.latitude, coordinate.longitude, self.mapView.camera.heading, speed, &newLat, &newLon, &newAzi)
          self.userLocation = CLLocationCoordinate2D(latitude: newLat + self.speed.jitter - self.speed.jitter, longitude: newLon + self.speed.jitter - self.speed.jitter)
        case 125, 1: // Down
          let a = 6378137.0, f = 1/298.257223563
          var geod = geod_geodesic()
          geod_init(&geod, a, f)
          var newLat: Double = 0.0
          var newLon: Double = 0.0
          var newAzi: Double = 0.0
          geod_direct(&geod, coordinate.latitude, coordinate.longitude, self.mapView.camera.heading, -speed, &newLat, &newLon, &newAzi)
          self.userLocation = CLLocationCoordinate2D(latitude: newLat + self.speed.jitter - self.speed.jitter, longitude: newLon + self.speed.jitter - self.speed.jitter)
        case 123, 0: // Left
          self.bearing -= 15
        case 124, 2: // Right
          self.bearing += 15
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
  
  override func rightMouseDown(with theEvent: NSEvent) {
    rightMouseDownEvent = theEvent
    let menu = NSMenu(title: "Menu")
    menu.addItem(withTitle: "Walk to this location", action: #selector(handleMenu(_:)), keyEquivalent: "")
    menu.addItem(withTitle: "Run to this location", action: #selector(handleMenu(_:)), keyEquivalent: "")
    menu.addItem(withTitle: "Cycle to this location", action: #selector(handleMenu(_:)), keyEquivalent: "")
    menu.addItem(withTitle: "Drive to this location", action: #selector(handleMenu(_:)), keyEquivalent: "")
    menu.addItem(withTitle: "Race to this location", action: #selector(handleMenu(_:)), keyEquivalent: "")
    menu.addItem(NSMenuItem.separator())
    menu.addItem(withTitle: "Walk directly", action: #selector(handleMenu(_:)), keyEquivalent: "")
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
        if self!.cameraFollows {
          let a = 6378137.0, f = 1/298.257223563
          var geod = geod_geodesic()
          geod_init(&geod, a, f)
          let lat = self!.userLocation!.latitude
          let lon = self!.userLocation!.longitude
          var ps12 = 0.0
          var az1 = 0.0
          var az2 = 0.0
          geod_inverse(&geod, lat, lon, coordinate.latitude, coordinate.longitude, &ps12, &az1, &az2)
          self?.bearing = CGFloat(az1)
        }
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
      renderer.lineWidth = 7
      renderer.strokeColor = NSColor.init(calibratedRed: 0, green: 0.3, blue: 1, alpha: 0.5)
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
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    if annotation is MKUserLocation {
      return nil
    }
    
    let identifier = "MyPin"
    
    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
    
    if annotationView == nil {
      annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
      annotationView?.isEnabled = true
      let img = NSImage(named: "custom_pin")
      annotationView?.image = img
      userLocationView = annotationView
    } else {
      annotationView?.annotation = annotation
    }
    
    return annotationView
  }
}

extension ViewController: NSGestureRecognizerDelegate {
  @objc func userDraggedMap(_ recognizer: NSGestureRecognizer) {
    cameraFollows = false
  }
  
  func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: NSGestureRecognizer) -> Bool {
    return true
  }
}
