import SwiftUI
import PencilKit
import SwiftData

struct ManagerSigningSheet: View {
    let incident: Incident

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedManager = NurseryStaff.all.first ?? "Sam Taylor"
    @State private var canvasView = PKCanvasView()
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("Manager Countersign")
                    .font(.headline)
                Text("Verify this incident report and sign below")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)

            Form {
                Section("Staff Member") {
                    Picker("Manager Name", selection: $selectedManager) {
                        ForEach(NurseryStaff.all, id: \.self) { staff in
                            Text(staff).tag(staff)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Signature") {
                    VStack(alignment: .leading, spacing: 8) {
                        SignatureCanvasView(canvasView: $canvasView)
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                            .background(Color(UIColor.secondarySystemBackground))
                        
                        HStack {
                            Text("Draw signature")
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
                    .padding(.vertical, 4)
                }
            }
            .scrollDisabled(true)
            .frame(height: 280)

            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                Button("Save & Sign") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .tint(NurseryTheme.accent)
                .frame(maxWidth: .infinity)
            }
            .padding([.horizontal, .bottom])
        }
        .background(Color(UIColor.systemGroupedBackground))
        .presentationDetents([.height(440)])
        .alert("Signature Required", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please provide a signature before saving.")
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
            incident.managerSignedByName = selectedManager
            incident.managerSignedAt = Date()
            incident.managerSignatureData = pngData
            incident.managerCountersignRequired = false
            
            try? modelContext.save()
            WatchSummarySync.publish(from: modelContext)
            
            dismiss()
        }
    }
}
