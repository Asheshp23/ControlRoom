//
//  CLLocationCoordinate2D-Identifiable.swift
//  ControlRoom
//
//  Created by Paul Hudson on 28/01/2021.
//  Copyright © 2021 Paul Hudson. All rights reserved.
//

import CoreLocation
import Foundation

extension CLLocationCoordinate2D: Identifiable {
    public var id: String {
        "\(latitude)-\(longitude)"
    }
    func location(withBearing bearing: Double, distance: CLLocationDistance) -> CLLocationCoordinate2D {
        let distanceKm = distance / 1000.0
        let distanceRadians = distanceKm / (6371.0) // Earth's radius in km

        let bearingRadians = bearing * Double.pi / 180.0

        let fromLatitude = latitude * Double.pi / 180.0
        let fromLongitude = longitude * Double.pi / 180.0

        let toLatitude = asin(sin(fromLatitude) * cos(distanceRadians) + cos(fromLatitude) * sin(distanceRadians) * cos(bearingRadians))
        let toLongitude = fromLongitude + atan2(sin(bearingRadians) * sin(distanceRadians) * cos(fromLatitude), cos(distanceRadians) - sin(fromLatitude) * sin(toLatitude))

        return CLLocationCoordinate2D(latitude: toLatitude * 180.0 / Double.pi, longitude: toLongitude * 180.0 / Double.pi)
    }
}
