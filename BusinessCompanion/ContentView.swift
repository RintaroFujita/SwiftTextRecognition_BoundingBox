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
                    // 画像を表示
                    if let uiImage = UIImage(contentsOfFile: "\(directoryPath)/\(recognizedInfo.filename)") {
                        let imageSize = uiImage.size
                        let aspectRatio = imageSize.width / imageSize.height
                        let displayedWidth: CGFloat = 300 // 表示する幅
                        let displayedHeight: CGFloat = displayedWidth / aspectRatio // アスペクト比を維持
                        
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: displayedWidth, height: displayedHeight)
                            .overlay(
                                // バウンディングボックスを表示する
                                GeometryReader { geometry in
                                    ForEach(recognizedInfo.boundingBoxes, id: \.self) { box in
                                        // スケールを計算
                                        let scaleX = displayedWidth / imageSize.width
                                        let scaleY = displayedHeight / imageSize.height

                                        // バウンディングボックスの位置とサイズをスケールに基づいて調整
                                        let adjustedOriginX = box.rect.origin.x * scaleX
                                        let adjustedOriginY = box.rect.origin.y * scaleY
                                        let adjustedWidth = box.rect.width * scaleX
                                        let adjustedHeight = box.rect.height * scaleY

                                        Rectangle()
                                            .stroke(Color.red, lineWidth: 2)
                                            .frame(width: adjustedWidth, height: adjustedHeight)
                                            .position(x: adjustedOriginX + adjustedWidth / 2,
                                                      y: adjustedOriginY + adjustedHeight / 2) // 中心に配置
                                            .offset(x: -geometry.size.width / 2, y: -geometry.size.height / 2) // 位置調整
                                    }
                                }
                            )
                    }
                    
                    // 認識されたテキストを表示
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
            imageTextRecognition.recognizeText(from: directoryPath) // 自動的にテキストを認識
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, *) {
            ContentView()
        } else {
            // 古いバージョンのフォールバック
        }
    }
}
