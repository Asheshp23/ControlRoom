//
//  HeadingView'.swift
//  ControlRoom
//
//  Created by Apdev on 2023-05-23.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import SwiftUI
import MapKit

enum MeasurementUnits: String {
    case metric = "m"
    case imperial = "ft"
}

enum RotationTarget: String {
    case point = "Sample Point"
    case arrow = "Heading Arrow"
}

struct HeadingView: View {
    @Binding var region: MKCoordinateRegion
    let simulator: Simulator
    let distance: Double
    let distanceUnit: MeasurementUnits
    let directionDeg: Double
    let rotationTarget: RotationTarget

    let maxCircleSize: CGFloat = 18
    let minCircleSize: CGFloat = 4

    var circleSize: CGFloat {
        let maxDist = 1000.0
        let minDist = 100.0

        let clampedDist = [minDist, distance, maxDist].sorted()[1]
        let scaledDist = (clampedDist - minDist) / (maxDist - minDist)

        return maxCircleSize - CGFloat(scaledDist) * (maxCircleSize - minCircleSize)
    }

    var circle: some View {
        ZStack(alignment: .center) {
            ZStack(alignment: .top) {
                Circle()
                    .strokeBorder(.red.opacity(0.5), lineWidth: 2)
                    .frame(width: 80, height: 80)
                    .padding(maxCircleSize / 2 - 2)
            }
            .rotationEffect(rotationTarget == .point ? Angle(degrees: directionDeg) : .zero)
            .animation(.spring(), value: rotationTarget)
            .animation(.spring(), value: directionDeg)

            Image(systemName: "location.north.fill") // or arrow.up or location.north.line.fill
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30.0, height: 30.0)
                .foregroundColor(.gray)
                .rotationEffect(rotationTarget == .arrow ? Angle(degrees: directionDeg) : .zero)
                .padding(35)
                .background(.gray.opacity(0.1))
                .clipShape(Circle())
                .animation(.spring(), value: rotationTarget)
                .animation(.spring(), value: directionDeg)
        }
    }

    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .center, spacing: 5) {
                circle
                Text("\(Int(distance)) \(distanceUnit.rawValue)")
                    .font(.body.bold())
                    .foregroundColor(.gray)
            }
            Button {
                let coordinate = region.center.location(withBearing: directionDeg, distance: distance)
                SimCtl.execute(.location(deviceId: simulator.udid, latitude: coordinate.latitude, longitude: coordinate.longitude))
                self.region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15))
            } label: {
                Text("Move")
            }
        }
    }
}
