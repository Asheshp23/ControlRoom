import Foundation
import CoreLocation

class Parser {
    private let coordinateParser = CoordinatesParser()

    func parseCoordinates(fromGpxFile filePath: URL) -> [CLLocationCoordinate2D]? {
        guard let data = try? Data(contentsOf: filePath) else { return nil }
        coordinateParser.prepare()
        let parser = XMLParser(data: data)
        parser.delegate = coordinateParser
        let success = parser.parse()
        guard success else { return nil }
        return coordinateParser.coordinates
    }
}

class CoordinatesParser: NSObject, XMLParserDelegate {
    private(set) var coordinates = [CLLocationCoordinate2D]()

    func prepare() {
        coordinates = [CLLocationCoordinate2D]()
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        guard elementName == "trkpt" || elementName == "wpt" else { return }
        guard let latString = attributeDict["lat"], let lonString = attributeDict["lon"] else { return }
        guard let lat = Double(latString), let lon = Double(lonString) else { return }
        guard let latDegrees = CLLocationDegrees(exactly: lat), let lonDegrees = CLLocationDegrees(exactly: lon) else { return }
        coordinates.append(CLLocationCoordinate2D(latitude: latDegrees, longitude: lonDegrees))
    }
}
