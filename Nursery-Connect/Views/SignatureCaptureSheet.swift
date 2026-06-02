import SwiftUI
import PencilKit

struct SignatureCaptureSheet: View {
    let title: String
    let subtitle: String
    let onSave: (Data) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var canvasView = PKCanvasView()
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)

            // Signature drawing area
            VStack {
                SignatureCanvasView(canvasView: $canvasView)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1.5)
                    )
                    .background(Color(UIColor.secondarySystemBackground))
                
                HStack {
                    Text("Draw with finger or Apple Pencil")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button {
                        canvasView.drawing = PKDrawing()
                    } label: {
                        Label("Clear", systemImage: "arrow.counterclockwise")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding(.horizontal, 2)
            }
            .padding(.horizontal)

            // Bottom Buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                Button("Save Signature") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .tint(NurseryTheme.accent)
                .frame(maxWidth: .infinity)
            }
            .padding([.horizontal, .bottom])
        }
        .padding()
        .presentationDetents([.height(340)])
        .alert("Empty Signature", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please draw your signature in the box before saving.")
        }
    }

    private func save() {
        let drawing = canvasView.drawing
        
        // Prevent saving an empty canvas
        guard !drawing.bounds.isEmpty else {
            showAlert = true
            return
        }

        // Render drawing as a UIImage
        let canvasSize = canvasView.bounds.size
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        let image = renderer.image { ctx in
            // Draw a white background first to avoid transparency issues in PDFs
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: canvasSize))
            
            // Draw the PencilKit strokes
            drawing.image(from: CGRect(origin: .zero, size: canvasSize), scale: 2.0)
                .draw(in: CGRect(origin: .zero, size: canvasSize))
        }

        if let pngData = image.pngData() {
            onSave(pngData)
            dismiss()
        }
    }
}

#Preview {
    Text("Signature Sheet Preview")
        .sheet(isPresented: .constant(true)) {
            SignatureCaptureSheet(
                title: "Manager Countersign",
                subtitle: "Confirm you have reviewed this incident report",
                onSave: { _ in }
            )
        }
}
