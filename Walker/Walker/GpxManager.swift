//
//  GpxManager.swift
//  Pokemon GO Controller Mac
//
//  Created by BumMo Koo on 2016. 7. 26..
//  Copyright © 2016년 BumMo Koo. All rights reserved.
//

import Cocoa

class GpxManager {
  class func saveGpxFile(_ latitude: Double, longitude: Double) {
    let filePath = #file
    let projectURL = URL(fileURLWithPath: filePath).deletingLastPathComponent().deletingLastPathComponent()
    let fileURL = projectURL.deletingLastPathComponent().appendingPathComponent("Simulated Location.gpx")
    let xmlContent = "<gpx creator=\"Xcode\" version=\"1.1\"><wpt lat=\"\(latitude)\" lon=\"\(longitude)\"><name>Simulated Location</name></wpt></gpx>"
    do {
      try xmlContent.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
    } catch {
      print(error)
    }
  }
}
