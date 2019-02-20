//
//  PreferenceManager.swift
//  Pokemon GO Controller Mac
//
//  Created by BumMo Koo on 2016. 7. 26..
//  Copyright © 2016년 BumMo Koo. All rights reserved.
//

import Cocoa
import MapKit

class PreferenceManager {
  
  fileprivate var errorLogged = false
  
  static let defaultManager = PreferenceManager()
  
  fileprivate let defaults = UserDefaults.standard
  
  var speed: Speed = Speed.walk {
    didSet {
      defaults.set(speed.rawValue, forKey: "speed")
      defaults.synchronize()
    }
  }
  
  var userLocation: CLLocationCoordinate2D? {
    didSet {
      // Save
      guard let userLocation = userLocation else {
        defaults.removeObject(forKey: "userLocation")
        return
      }
      let coordinateValue = NSValue(mkCoordinate: userLocation)
      let coordinateData = NSArchiver.archivedData(withRootObject: coordinateValue)
      defaults.set(coordinateData, forKey: "userLocation")
      defaults.synchronize()
      
      saveUserLocationToGpx()
    }
  }
  
  var favorites: [Favorite]? {
    didSet {
      // Save
      guard let favorites = favorites else {
        defaults.removeObject(forKey: "favorites")
        return
      }
      var favoritesData = [Data]()
      for favorite in favorites {
        let favoriteData = NSKeyedArchiver.archivedData(withRootObject: favorite)
        favoritesData.append(favoriteData)
      }
      defaults.set(favoritesData, forKey: "favorites")
      defaults.synchronize()
    }
  }
  
  // MARK: Initializer
  init() {
    if let speed = Speed(rawValue:defaults.double(forKey: "speed")) {
      self.speed = speed
    }
    if let coordinateData = defaults.object(forKey: "userLocation") as? Data {
      if let coordinateValue = NSUnarchiver.unarchiveObject(with: coordinateData) as? NSValue {
        userLocation = coordinateValue.mkCoordinateValue
      }
    }
    if let favoritesData = defaults.array(forKey: "favorites") as? [Data] {
      var favorites = [Favorite]()
      for favoriteData in favoritesData {
        if let favorite = NSKeyedUnarchiver.unarchiveObject(with: favoriteData) as? Favorite {
          favorites.append(favorite)
        }
      }
      self.favorites = favorites
    }
  }
  
  // MARK: Gpx
  fileprivate func saveUserLocationToGpx() {
    guard let userLocation = userLocation else {
      return
    }
    GpxManager.saveGpxFile(userLocation.latitude, longitude: userLocation.longitude)
    //updateLocationOnDevice()
  }
  
  // MARK: Favorites
  func addFavorite(coordinate: CLLocationCoordinate2D, name: String? = nil) {
    let favorite = Favorite(coordinate: coordinate, name: name)
    favorites?.append(favorite)
  }
  
  func removeFavorite(_ favorite: Favorite) {
    guard let favorites = favorites else {
      return
    }
    if let index = favorites.index(of: favorite) {
      self.favorites!.remove(at: index)
    }
  }
  
  fileprivate func updateLocationOnDevice() {
    // by using this code I tried to get rid of the location update script
    // but it turned out that calling Apple Script from the code is not working as expected
    // also you would have to allow Xcode and Walker to control your system
    // in Settings -> Privacy -> Accessibility and Automation, so I dropped it
    let myAppleScript = """
    set proxyIndex to 0

    tell application "Xcode"
      set openedProjects to name of every workspace document
      repeat with a from 1 to count of openedProjects
        if item a of openedProjects contains "Locator" then set proxyIndex to a
      end repeat
    end tell

    tell application "System Events" to tell process "Xcode"
      click menu item "Simulated Location" of menu 1 of menu item "Simulate Location" of menu 1 in menu bar item "Debug" in menu bar 1
    end tell
    """
    var error: NSDictionary?
    if let scriptObject = NSAppleScript(source: myAppleScript) {
      if let outputString = scriptObject.executeAndReturnError(&error).stringValue {
        print(outputString)
      } else if errorLogged == false, error != nil {
        errorLogged = true
        print("error: ", error!)
      }
    }
  }
}
