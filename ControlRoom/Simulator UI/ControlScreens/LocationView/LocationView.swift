//
//  LocationView.swift
//  ControlRoom
//
//  Created by Stefano Mondino on 13/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import MapKit
import SwiftUI
import CoreLocation

/// Map view to change simulated user's position
struct LocationView: View {
    @ObservedObject var controller: SimulatorsController
    let simulator: Simulator
    static let DEFAULT_LAT = 37.323056
    static let DEFAULT_LNG = -122.031944

    @State var directionDeg: Double = 25.0
    @State var rotationTarget = RotationTarget.arrow
    @State var distance: Double = 200
    @State var distanceUnit = MeasurementUnits.metric
    @State private var latitudeText = "\(DEFAULT_LAT)"
    @State private var longitudeText = "\(DEFAULT_LNG)"
    /// The location that is being simulated
    @State private var currentLocation = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: DEFAULT_LAT, longitude: DEFAULT_LNG),
        span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15))
    @State private var pinnedLocation: CLLocationCoordinate2D?

    /// A randomly generated location offset from the currentLocation.
    /// Non-nil only when jittering is enabled.
    @State private var jitteredLocation: CLLocationCoordinate2D?
    @State private var simulatedLocation: CLLocationCoordinate2D?
    @State private var simulatableLocations: [CLLocationCoordinate2D] = []
    @State var currentIndex = 0
    @State private var isJittering: Bool = false
    @State private var isSimulating: Bool = false
    @State private var selectedOption = "Update coordinates using text field"
    private let options = [
        "entering values in a text field",
        "importing a GPX file",
        "moving it with entered distance and selected direction"
    ]
    private let simulaterTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let jitterTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var annotations: [CLLocationCoordinate2D] {
        if let pinnedLocation = pinnedLocation {
            return [pinnedLocation]
        } else {
            return []
        }
    }

    /// User-facing text describing `currentLocation`
    var locationText: String {
        let location = jitteredLocation ?? currentLocation.center
        return String(format: "%.5f, %.5f", location.latitude, location.longitude)
    }

    var latLongTF: some View {
        VStack {
            HStack(spacing: 10.0) {
                TextField("Latitude", text: $latitudeText)
                    .textFieldStyle(.roundedBorder)

                TextField("Longitude", text: $longitudeText)
                    .textFieldStyle(.roundedBorder)
            }

            Button("Update coordinates") {
                if let latitude = Double(latitudeText),
                   let longitude = Double(longitudeText) {
                    self.currentLocation = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                        span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15))
                }
            }
        }
    }

    var gpxUploaderView: some View {
        VStack {
            GPXUploaderView(coords: $simulatableLocations)
            if !simulatableLocations.isEmpty {
                HStack {
                    Button {
                        if currentIndex == simulatableLocations.count {
                            currentIndex = 0
                        }
                        isSimulating = !isSimulating
                        simulateLocation()
                    } label: {
                      Text(isSimulating ? "Stop" : (currentIndex == simulatableLocations.count) ? "Restart" : (currentIndex > 0) ? "Resume" : "Start")
                    }
                }
            }
        }
    }

    var headingAndDistanceView: some View {
        VStack(alignment: .leading) {
            Section("Distance") {
                HStack {
                    Slider(value: $distance, in: 0...2000, step: 10)
                        .padding(.trailing)
                        .accentColor(Color.red)
                    Text("\(Int(distance.rounded(.down)))")

                    Picker("", selection: $distanceUnit) {
                        Text(MeasurementUnits.metric.rawValue).tag(MeasurementUnits.metric)
                        Text(MeasurementUnits.imperial.rawValue).tag(MeasurementUnits.imperial)
                    }
                    .frame(width: 60)
                }.padding(.vertical, 5)
            }
            Section("Direction") {
                HStack {
                    Slider(value: $directionDeg, in: 0...360, step: 1)
                        .padding(.trailing)
                        .accentColor(Color.red)
                    Text("\(Int(directionDeg.rounded(.down)))°")
                }.padding(.vertical, 5)
            }
            HeadingView(
                region: $currentLocation,
                simulator: simulator,
                distance: distance,
                distanceUnit: distanceUnit,
                directionDeg: directionDeg,
                rotationTarget: rotationTarget
            )
        }
        .frame(maxWidth: .infinity)
    }

    var body: some View {
        Form {
            VStack {
                Text("Move the map wherever you want, then click Activate to update the simulator to match your centered coordinate.")

                Picker(selection: $selectedOption, label: Text("Update coordinates by:")) {
                    ForEach(options, id: \.self) { option in
                        Text(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                if selectedOption == "entering values in a text field" {
                    latLongTF
                } else if selectedOption == "importing a GPX file" {
                    gpxUploaderView
                } else {
                    headingAndDistanceView
                }
                ZStack {
                    Map(coordinateRegion: $currentLocation, annotationItems: annotations) { location in
                        MapMarker(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude), tint: .red)
                    }
                    .cornerRadius(5)

                    Circle()
                        .stroke(Color.blue, lineWidth: 4)
                        .frame(width: 20)
                }
                .padding(.bottom, 10)
                .keyboardShortcut(/*@START_MENU_TOKEN@*/.defaultAction/*@END_MENU_TOKEN@*/)

                HStack {
                    Text("Coordinates: \(locationText)")
                        .textSelection(.enabled)
                    Spacer()
                    Toggle("Jitter location", isOn: $isJittering)
                        .toggleStyle(.checkbox)
                    Button("Activate", action: changeLocation)
                }
            }
        }
        .tabItem {
            Text("Location")
        }
        .padding()
        .onReceive(jitterTimer) { _ in
            guard isJittering else {
                jitteredLocation = nil
                return
            }

            jitterLocation()
        }
        .onReceive(simulaterTimer) { _ in
            guard isSimulating else {
                simulatedLocation = nil
                return
            }

            simulateLocation()
        }
    }

    /// Updates the simulated location to the value of `currentLocation`.
    func changeLocation() {
        let coordinate = jitteredLocation ?? currentLocation.center
        pinnedLocation = coordinate

        SimCtl.execute(.location(deviceId: simulator.udid, latitude: coordinate.latitude, longitude: coordinate.longitude))
    }

    func changeSimulationLocation() {
        let coordinate = simulatedLocation ?? currentLocation.center
        pinnedLocation = coordinate

        SimCtl.execute(.location(deviceId: simulator.udid, latitude: coordinate.latitude, longitude: coordinate.longitude))
        self.currentLocation = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
            span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15))
    }

    /// Randomly generates a new location slightly offset from the currentLocation
    private func jitterLocation() {
        let lat = currentLocation.center.latitude + (Double.random(in: -0.0001...0.0001))
        let long = currentLocation.center.longitude + (Double.random(in: -0.0001...0.0001))
        jitteredLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
        changeLocation()
    }

    private func simulateLocation() {
        if currentIndex < simulatableLocations.count {
            let element = simulatableLocations[currentIndex]
            currentIndex += 1
            simulatedLocation = CLLocationCoordinate2D(latitude: element.latitude, longitude: element.longitude)
            changeSimulationLocation()
        } else {
          isSimulating = false
        }
    }
    func toggleRotationTarget() {
        rotationTarget = rotationTarget == .point ? .arrow : .point
    }
}
