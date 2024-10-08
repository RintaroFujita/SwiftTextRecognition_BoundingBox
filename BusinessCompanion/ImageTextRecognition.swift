// ImageTextRecognition.swift
import Foundation
import Vision
import SwiftUI

class ImageTextRecognition: ObservableObject {
    @Published var recognizedTextInfoList: [RecognizedTextData] = []

    func colorForCharacter(at index: Int, total: Int) -> UIColor {
        let hue = CGFloat(index) / CGFloat(max(total, 1))  // Avoid divide by zero
        return UIColor(hue: hue, saturation: 0.7, brightness: 0.9, alpha: 1.0)
    }

    func recognizeText(from directoryPath: String) {
        recognizedTextInfoList.removeAll()

        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: directoryPath)
            
            let imageFiles = files.filter { $0.lowercased().hasSuffix(".png") || $0.lowercased().hasSuffix(".jpg") || $0.lowercased().hasSuffix(".jpeg") }
            
            for imageName in imageFiles {
                let fullImagePath = "\(directoryPath)/\(imageName)"
                
                guard let uiImage = UIImage(contentsOfFile: fullImagePath),
                      let cgImage = uiImage.cgImage else {
                    print("Unable to load image: \(imageName)")
                    continue
                }
                
                let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                let request = VNRecognizeTextRequest { request, error in
                    if let error = error {
                        print("Text recognition error for \(imageName): \(error)")
                        return
                    }
                    
                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        print("No text observations found for \(imageName)")
                        return
                    }
                    
                    let recognizedStrings = observations.compactMap { observation in
                        observation.topCandidates(1).first?.string
                    }

                    let confidenceLevels = observations.compactMap { observation in
                        observation.topCandidates(1).first?.confidence
                    }
                    
                    let boundingBoxes = observations.map { observation in
                        let boundingBox = observation.boundingBox
                        let convertedBox = BoundingBox(rect: self.convert(boundingBox: boundingBox, to: CGRect(origin: .zero, size: uiImage.size)))
                        return convertedBox
                    }

                    if !recognizedStrings.isEmpty {
                        DispatchQueue.main.async {
                            let recognizedInfo = RecognizedTextData(
                                filename: imageName,
                                recognizedText: recognizedStrings,
                                boundingBoxes: boundingBoxes
                            )
                            self.recognizedTextInfoList.append(recognizedInfo)

                            print("File: \(imageName)")
                            for (recognizedText, confidence) in zip(recognizedStrings, confidenceLevels) {
                                let confidencePercentage = confidence * 100
                                print("Recognized Text: \(recognizedText) (Confidence: \(confidencePercentage)%)")
                            }
                        }
                    }
                }
                
                do {
                    try requestHandler.perform([request])
                } catch {
                    print("Unable to perform the requests for \(imageName): \(error).")
                }
            }
        } catch {
            print("Failed to read directory: \(error)")
        }
    }

    // Convert bounding box coordinates to image coordinates
    func convert(boundingBox: CGRect, to bounds: CGRect) -> CGRect {
        let imageWidth = bounds.width
        let imageHeight = bounds.height

        var rect = boundingBox
        rect.origin.x *= imageWidth
        rect.origin.x += bounds.minX
        rect.origin.y = (1 - rect.maxY) * imageHeight + bounds.minY

        rect.size.width *= imageWidth
        rect.size.height *= imageHeight

        return rect
    }
}
