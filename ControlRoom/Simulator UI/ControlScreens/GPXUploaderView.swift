import SwiftUI
import UniformTypeIdentifiers
import CoreLocation

struct GPXUploaderView: View {
    @Binding var coords: [CLLocationCoordinate2D]
    @State private var gpxFileURL: URL?
    @State var dropHovering: Bool = false

    var body: some View {
        VStack {
            if let fileURL = gpxFileURL {
                Text("GPX File: \(fileURL.path)")
            } else {
                Text("Drag and drop a GPX file here")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 50)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(dropHovering ? Color.accentColor : Color.gray, lineWidth: 1)
        )
        .onDrop(of: [UTType.fileURL], isTargeted: $dropHovering) { providers in
            for provider in providers {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    if let data = item as? Data,
                       let fileURL = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            self.gpxFileURL = fileURL
                            if let gpxFileURL = self.gpxFileURL {
                                self.coords = Parser().parseCoordinates(fromGpxFile: gpxFileURL) ?? []
                            }
                        }
                    }
                }
            }
            return true
        }
    }
}

struct DocumentUploaderView_Previews: PreviewProvider {
    static var previews: some View {
        GPXUploaderView(coords: .constant([CLLocationCoordinate2D]()))
    }
}
