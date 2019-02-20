//
//  Speed.swift
//  Pokemon GO Controller Mac
//
//  Created by BumMo Koo on 2016. 7. 27..
//  Copyright © 2016년 BumMo Koo. All rights reserved.
//

import Cocoa

enum Speed: Double {
  // meter per second
  // Egg-hatch-safe speed is about 10.5 km/h
  case walk = 1.2, run = 2.8, cycle = 8, drive = 16, race = 27
  
  var jitter: Double {
    switch self {
      // TODO: negative jitter
      case .walk: return Double.random(in: 0...0.000005)
      case .run: return Double.random(in: 0...0.00001)
      case .cycle: return Double.random(in: 0...0.00002)
      case .drive: return Double.random(in: 0...0.00004)
      case .race: return Double.random(in: 0...0.00006)
    }
  }
  
  var menuIndex: Int {
    switch self {
    case .run:
      return 1
    case .cycle:
      return 2
    case .drive:
      return 3
    case .race:
      return 4
    default:
      return 0
    }
  }
  
  init(menuIndex: Int) {
    switch menuIndex {
    case 1:
      self = .run
    case 2:
      self = .cycle
    case 3:
      self = .drive
    case 4:
      self = .race
    default:
      self = .walk
    }
  }
}
