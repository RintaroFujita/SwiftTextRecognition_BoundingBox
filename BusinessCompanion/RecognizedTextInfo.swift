import Foundation
import CoreGraphics

// バウンディングボックスの構造体を定義
struct BoundingBox: Hashable { // Hashableに準拠させる
    let rect: CGRect

    // Hashableプロトコルに必要なメソッドを実装
    func hash(into hasher: inout Hasher) {
        hasher.combine(rect.origin.x)
        hasher.combine(rect.origin.y)
        hasher.combine(rect.size.width)
        hasher.combine(rect.size.height)
    }

    static func == (lhs: BoundingBox, rhs: BoundingBox) -> Bool {
        return lhs.rect == rhs.rect
    }
}

// 画像ファイル名と認識したテキストをリンクする構造体を定義
struct RecognizedTextData: Identifiable {
    let id = UUID()
    let filename: String
    let recognizedText: [String]
    let boundingBoxes: [BoundingBox] // バウンディングボックスを追加
}
