//ContentView.swift
import SwiftUI

@available(iOS 14.0, *)
struct ContentView: View {
    @StateObject private var imageTextRecognition = ImageTextRecognition()
    
    let directoryPath = "/Users/r/github/SwiftTextRecognition_BoundingBox/BusinessCompanion/Parking"
    @State private var saveDirectory: String = "/Users/r/github/SwiftTextRecognitoin_MisrecognizeDatasetImage/Parking" // Change each time!

    var body: some View {
        VStack {
            Text("Recognized Text and Files:")
                .font(.headline)
                .padding()
            
            List(imageTextRecognition.recognizedTextInfoList) { recognizedInfo in
                Section(header: Text("File: \(recognizedInfo.filename)")) {
                    if let uiImage = UIImage(contentsOfFile: "\(directoryPath)/\(recognizedInfo.filename)") {
                        let imageSize = uiImage.size
                        let aspectRatio = imageSize.width / imageSize.height
                        let displayedWidth: CGFloat = 300
                        let displayedHeight: CGFloat = displayedWidth / aspectRatio
                        
                        ZStack {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: displayedWidth, height: displayedHeight)
                            
                            GeometryReader { geometry in
                                ForEach(recognizedInfo.boundingBoxes.indices, id: \.self) { index in
                                    let box = recognizedInfo.boundingBoxes[index]
                                    let scaleX = displayedWidth / imageSize.width
                                    let scaleY = displayedHeight / imageSize.height
                                    let adjustedOriginX = box.rect.origin.x * scaleX
                                    let adjustedOriginY = box.rect.origin.y * scaleY
                                    let adjustedWidth = box.rect.width * scaleX
                                    let adjustedHeight = box.rect.height * scaleY

                                    Rectangle()
                                        .stroke(Color(imageTextRecognition.colorForCharacter(at: index, total: recognizedInfo.recognizedText.count)), lineWidth: 2)
                                        .frame(width: adjustedWidth, height: adjustedHeight)
                                        .position(x: adjustedOriginX + adjustedWidth / 2,
                                                  y: adjustedOriginY + adjustedHeight / 2)
                                }
                            }
                            .frame(width: displayedWidth, height: displayedHeight)
                        }
                        Button("Save Image with Bounding Boxes") {
                            saveImageWithBoundingBoxes(uiImage: uiImage, recognizedInfo: recognizedInfo, savePath: saveDirectory)
                        }
                        .padding(.top, 5)
                    }
                    
                    ForEach(recognizedInfo.recognizedText.indices, id: \.self) { index in
                        Text("\(recognizedInfo.recognizedText[index])")
                            .foregroundColor(Color(imageTextRecognition.colorForCharacter(at: index, total: recognizedInfo.recognizedText.count)))
                    }
                }
            }
            
            Button("Recognize Text") {
                imageTextRecognition.recognizeText(from: directoryPath)
            }
            .padding()

            Button("Save All Images with Bounding Boxes") {
                saveAllImagesWithBoundingBoxes()
            }
            .padding()

            HStack {
                Text("Save Directory:")
                TextField("Save path", text: $saveDirectory)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
            }
        }
        .onAppear {
            imageTextRecognition.recognizeText(from: directoryPath)
        }
    }
    
    func saveImageWithBoundingBoxes(uiImage: UIImage, recognizedInfo: RecognizedTextData, savePath: String) {
        let renderer = UIGraphicsImageRenderer(size: uiImage.size)
        let renderedImage = renderer.image { context in
            uiImage.draw(at: .zero)

            // Font settings for drawing recognized text
            let fontSize: CGFloat = 12
            let _: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize),
                .foregroundColor: UIColor.black // Default text color, can be customized
            ]

            for (index, box) in recognizedInfo.boundingBoxes.enumerated() {
                let rect = box.rect
                let convertedRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: rect.size.height)
                
                // Draw bounding box
                let path = UIBezierPath(rect: convertedRect)
                let color = imageTextRecognition.colorForCharacter(at: index, total: recognizedInfo.recognizedText.count) // Color for each character
                color.setStroke()
                path.lineWidth = 2
                path.stroke()

                // Draw recognized text inside or near the bounding box
                if index < recognizedInfo.recognizedText.count {
                    let recognizedText = recognizedInfo.recognizedText[index]

                    // Set text color same as bounding box color
                    let textColorAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: fontSize),
                        .foregroundColor: color
                    ]

                    // Calculate text position (above the bounding box)
                    let textOrigin = CGPoint(x: convertedRect.origin.x, y: convertedRect.origin.y - fontSize - 2) // Text above bounding box

                    // Draw full text without wrapping it inside the box width
                    let textRect = CGRect(origin: textOrigin, size: CGSize(width: uiImage.size.width, height: fontSize)) // Text spans full image width

                    // Draw text
                    recognizedText.draw(in: textRect, withAttributes: textColorAttributes)
                }
            }
        }

        let directoryName = URL(fileURLWithPath: directoryPath).lastPathComponent
        let recognizedTextForFilename = recognizedInfo.recognizedText.first?.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "_", options: .regularExpression) ?? "NoText"
        let combinedFilename = "\(directoryName)_\(recognizedInfo.filename)_\(recognizedTextForFilename.prefix(10)).png"
        let filePath = "\(savePath)/\(combinedFilename)"
        
        if let data = renderedImage.pngData() {
            do {
                try data.write(to: URL(fileURLWithPath: filePath))
                print("Image saved to \(filePath)")
            } catch {
                print("Failed to save image: \(error.localizedDescription)")
            }
        } else {
            print("Failed to save image.")
        }
    }
    func saveAllImagesWithBoundingBoxes() {
        for recognizedInfo in imageTextRecognition.recognizedTextInfoList {
            if let uiImage = UIImage(contentsOfFile: "\(directoryPath)/\(recognizedInfo.filename)") {
                saveImageWithBoundingBoxes(uiImage: uiImage, recognizedInfo: recognizedInfo, savePath: saveDirectory)
            }
        }
    }
}

