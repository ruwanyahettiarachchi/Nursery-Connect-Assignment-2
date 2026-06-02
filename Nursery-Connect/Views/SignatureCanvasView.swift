import SwiftUI
import PencilKit

struct SignatureCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput // Allows fingers, styluses, and Apple Pencils
        canvasView.backgroundColor = UIColor.systemBackground
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 3.0)
        
        // Hide standard ruler and accessories for a clean signature area
        canvasView.isRulerActive = false
        canvasView.allowsFingerDrawing = true
        
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // No-op
    }
}
