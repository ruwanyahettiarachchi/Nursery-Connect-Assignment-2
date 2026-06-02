import SwiftUI
import PencilKit
import SwiftData

struct ParentSigningSheet: View {
    let incident: Incident

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var canvasView = PKCanvasView()
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("Parent / Guardian Acknowledgment")
                    .font(.headline)
                Text("Sign below to acknowledge receipt of this report")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)

            VStack(alignment: .leading, spacing: 8) {
                SignatureCanvasView(canvasView: $canvasView)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1.5)
                    )
                    .background(Color(UIColor.secondarySystemBackground))
                
                HStack {
                    Text("Draw signature inside the box")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Clear") {
                        canvasView.drawing = PKDrawing()
                    }
                    .font(.caption.weight(.semibold))
                    .tint(.red)
                }
            }
            .padding(.horizontal)

            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                Button("Save & Acknowledge") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .tint(NurseryTheme.accent)
                .frame(maxWidth: .infinity)
            }
            .padding([.horizontal, .bottom])
        }
        .presentationDetents([.height(340)])
        .alert("Signature Required", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please provide a signature to acknowledge receipt.")
        }
    }

    private func save() {
        let drawing = canvasView.drawing
        guard !drawing.bounds.isEmpty else {
            showAlert = true
            return
        }

        let canvasSize = canvasView.bounds.size
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: canvasSize))
            drawing.image(from: CGRect(origin: .zero, size: canvasSize), scale: 2.0)
                .draw(in: CGRect(origin: .zero, size: canvasSize))
        }

        if let pngData = image.pngData() {
            incident.parentAcknowledgedAt = Date()
            incident.parentSignatureData = pngData
            
            try? modelContext.save()
            WatchSummarySync.publish(from: modelContext)
            
            dismiss()
        }
    }
}
