import SwiftUI

@available(iOS 14.0, *)
struct ContentView: View {
    @StateObject private var imageTextRecognition = ImageTextRecognition()
    
    let directoryPath = "/Users/r/Downloads/StructuringRecognizedTextOnADocument/BusinessCompanion/Desert"
    
    var body: some View {
        VStack {
            Text("Recognized Text and Files:")
                .font(.headline)
                .padding()
            
            List(imageTextRecognition.recognizedTextInfoList) { recognizedInfo in
                Section(header: Text("File: \(recognizedInfo.filename)")) {
                    // Display the image
                    if let uiImage = UIImage(contentsOfFile: "\(directoryPath)/\(recognizedInfo.filename)") {
                        let imageSize = uiImage.size
                        let aspectRatio = imageSize.width / imageSize.height
                        let displayedWidth: CGFloat = 300 // Display width
                        let displayedHeight: CGFloat = displayedWidth / aspectRatio // Maintain aspect ratio
                        
                        ZStack {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: displayedWidth, height: displayedHeight)
                            
                            // Overlay bounding boxes
                            GeometryReader { geometry in
                                ForEach(recognizedInfo.boundingBoxes, id: \.self) { box in
                                    // Scale calculations
                                    let scaleX = displayedWidth / imageSize.width
                                    let scaleY = displayedHeight / imageSize.height

                                    // Adjust bounding box position and size
                                    let adjustedOriginX = box.rect.origin.x * scaleX
                                    let adjustedOriginY = box.rect.origin.y * scaleY
                                    let adjustedWidth = box.rect.width * scaleX
                                    let adjustedHeight = box.rect.height * scaleY

                                    Rectangle()
                                        .stroke(Color.red, lineWidth: 2)
                                        .frame(width: adjustedWidth, height: adjustedHeight)
                                        .position(x: adjustedOriginX + adjustedWidth / 2,
                                                  y: adjustedOriginY + adjustedHeight / 2)
                                }
                            }
                            .frame(width: displayedWidth, height: displayedHeight) // Ensure the GeometryReader has the same size as the image
                        }
                    }
                    
                    // Display recognized text
                    ForEach(recognizedInfo.recognizedText, id: \.self) { text in
                        Text(text)
                    }
                }
            }
            
            Button("Recognize Text") {
                imageTextRecognition.recognizeText(from: directoryPath)
            }
            .padding()
        }
        .onAppear {
            imageTextRecognition.recognizeText(from: directoryPath) // Automatically recognize text
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, *) {
            ContentView()
        } else {
            // Fallback for older versions
        }
    }
}
