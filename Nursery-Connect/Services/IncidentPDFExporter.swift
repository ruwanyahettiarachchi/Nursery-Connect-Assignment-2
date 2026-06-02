import Foundation
import PDFKit
import UIKit

enum IncidentPDFExporter {
    static func export(incident: Incident) -> URL? {
        let pdf = PDFDocument()

        let pageText = [
            "NurseryConnect — Incident Report",
            "",
            "Child: \(incident.childName)",
            "Date/Time: \(incident.date.formatted(date: .abbreviated, time: .shortened))",
            "Category: \(incident.category)",
            "Location: \(incident.location.isEmpty ? "—" : incident.location)",
            "Body part: \(incident.bodyPart)",
            "Body map: \(incident.bodyMapSide)\(incident.bodyMapRegion.isEmpty ? "" : " • \(incident.bodyMapRegion)")",
            "",
            "Description:",
            incident.descriptionText,
            "",
            "Immediate action taken:",
            incident.immediateActionTaken.isEmpty ? "—" : incident.immediateActionTaken,
            "",
            "Witnesses:",
            incident.witnesses.isEmpty ? "—" : incident.witnesses.map(\.name).joined(separator: ", "),
            "",
            "Manager countersignature:",
            incident.isManagerSigned ? "Signed by \(incident.managerSignedByName.isEmpty ? "Manager" : incident.managerSignedByName) at \(incident.managerSignedAt?.formatted(date: .abbreviated, time: .shortened) ?? "")" : "Pending",
            "Parent acknowledgement:",
            incident.isParentAcknowledged ? "Acknowledged at \(incident.parentAcknowledgedAt?.formatted(date: .abbreviated, time: .shortened) ?? "")" : "Pending",
        ].joined(separator: "\n")

        guard let page = makePage(text: pageText) else { return nil }
        pdf.insert(page, at: 0)

        let safeName = incident.childName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")

        let fileName = "Incident_\(safeName)_\(incident.date.formatted(.dateTime.year().month().day())).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        guard pdf.write(to: url) else { return nil }
        return url
    }

    private static func makePage(text: String) -> PDFPage? {
        let pageBounds = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)

        let data = renderer.pdfData { ctx in
            ctx.beginPage()

            let margin: CGFloat = 36
            let rect = CGRect(
                x: margin,
                y: margin,
                width: pageBounds.width - 2 * margin,
                height: pageBounds.height - 2 * margin
            )

            let paragraph = NSMutableParagraphStyle()
            paragraph.lineBreakMode = .byWordWrapping
            paragraph.lineSpacing = 2

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: paragraph,
            ]

            text.draw(in: rect, withAttributes: attrs)
        }

        // Easiest cross-version approach: create a 1-page PDF as an image-backed PDFPage.
        guard let image = UIImage(data: data) else { return nil }
        return PDFPage(image: image)
    }
}

