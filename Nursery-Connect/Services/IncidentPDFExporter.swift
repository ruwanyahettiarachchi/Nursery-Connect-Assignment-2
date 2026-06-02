import Foundation
import PDFKit
import UIKit

enum IncidentPDFExporter {
    static func export(incident: Incident) -> URL? {
        let pdf = PDFDocument()

        guard let page = makePage(for: incident) else { return nil }
        pdf.insert(page, at: 0)

        let safeName = incident.childName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")

        let fileName = "Incident_\(safeName)_\(incident.date.formatted(.dateTime.year().month().day())).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        guard pdf.write(to: url) else { return nil }
        return url
    }

    private static func makePage(for incident: Incident) -> PDFPage? {
        let pageBounds = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)

        let data = renderer.pdfData { ctx in
            ctx.beginPage()

            var yOffset: CGFloat = 40
            let margin: CGFloat = 40
            let contentWidth = pageBounds.width - (2 * margin)

            // Helper to draw a text block
            func drawString(_ text: String, font: UIFont, color: UIColor = .black, alignment: NSTextAlignment = .left, bottomPadding: CGFloat = 8) {
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = alignment
                paragraph.lineBreakMode = .byWordWrapping
                paragraph.lineSpacing = 1.5

                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraph
                ]

                let stringSize = text.boundingRect(
                    with: CGSize(width: contentWidth, height: .infinity),
                    options: .usesLineFragmentOrigin,
                    attributes: attrs,
                    context: nil
                ).size

                let rect = CGRect(x: margin, y: yOffset, width: contentWidth, height: stringSize.height)
                text.draw(in: rect, withAttributes: attrs)
                yOffset += stringSize.height + bottomPadding
            }

            // Header Title
            drawString(
                "NURSERYCONNECT — INCIDENT REPORT",
                font: UIFont.boldSystemFont(ofSize: 18),
                color: UIColor(red: 0.12, green: 0.62, blue: 0.68, alpha: 1.0),
                alignment: .center,
                bottomPadding: 20
            )

            // Metadata card container
            let startBoxY = yOffset
            yOffset += 10 // padding top inside box

            func drawKeyValueRow(key: String, value: String) {
                let keyFont = UIFont.boldSystemFont(ofSize: 11)
                let valFont = UIFont.systemFont(ofSize: 11)

                let keyString = "\(key):"
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byWordWrapping

                let keyAttrs: [NSAttributedString.Key: Any] = [
                    .font: keyFont,
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: paragraph
                ]
                let valAttrs: [NSAttributedString.Key: Any] = [
                    .font: valFont,
                    .foregroundColor: UIColor.darkGray,
                    .paragraphStyle: paragraph
                ]

                let keyWidth: CGFloat = 130
                // Draw Key
                let keyRect = CGRect(x: margin + 12, y: yOffset, width: keyWidth, height: 16)
                keyString.draw(in: keyRect, withAttributes: keyAttrs)

                // Draw Value
                let valRect = CGRect(x: margin + 12 + keyWidth, y: yOffset, width: contentWidth - keyWidth - 24, height: 16)
                value.draw(in: valRect, withAttributes: valAttrs)

                yOffset += 20
            }

            drawKeyValueRow(key: "Child Name", value: incident.childName)
            drawKeyValueRow(key: "Date & Time", value: incident.date.formatted(date: .abbreviated, time: .shortened))
            drawKeyValueRow(key: "Category", value: incident.category)
            drawKeyValueRow(key: "Location", value: incident.location.isEmpty ? "—" : incident.location)
            drawKeyValueRow(key: "Body Part Affected", value: incident.bodyPart)
            drawKeyValueRow(key: "Body Map Area", value: "\(incident.bodyMapSide)\(incident.bodyMapRegion.isEmpty ? "" : " · \(incident.bodyMapRegion)")")
            drawKeyValueRow(key: "Immediate Action", value: incident.immediateActionTaken.isEmpty ? "—" : incident.immediateActionTaken)
            
            let witnessesText = incident.witnesses.isEmpty ? "—" : incident.witnesses.map(\.name).joined(separator: ", ")
            drawKeyValueRow(key: "Witnesses", value: witnessesText)

            yOffset += 4 // bottom padding
            let endBoxY = yOffset

            // Draw outer border card rectangle around details
            let borderRect = CGRect(x: margin, y: startBoxY, width: contentWidth, height: endBoxY - startBoxY)
            let path = UIBezierPath(roundedRect: borderRect, cornerRadius: 8)
            path.lineWidth = 0.8
            UIColor.systemGray4.setStroke()
            path.stroke()

            yOffset += 16

            // Description Heading
            drawString("Incident Description", font: UIFont.boldSystemFont(ofSize: 13), bottomPadding: 4)
            drawString(incident.descriptionText, font: UIFont.systemFont(ofSize: 10), color: .darkGray, bottomPadding: 20)

            // Workflow Signatures Section
            drawString("Workflow & Countersignatures", font: UIFont.boldSystemFont(ofSize: 13), bottomPadding: 12)

            let sigWidth = (contentWidth - 16) / 2
            let managerSigX = margin
            let parentSigX = margin + sigWidth + 16

            // Helper to draw signature box
            func drawSignatureBox(x: CGFloat, title: String, signeeName: String?, dateText: String?, signatureData: Data?) {
                let boxHeight: CGFloat = 110
                let boxRect = CGRect(x: x, y: yOffset, width: sigWidth, height: boxHeight)
                
                // Draw border box
                let sigPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 6)
                sigPath.lineWidth = 0.8
                UIColor.systemGray4.setStroke()
                sigPath.stroke()

                // Fonts
                let titleFont = UIFont.boldSystemFont(ofSize: 9)
                let nameFont = UIFont.systemFont(ofSize: 8)
                let textAttrs: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.black]
                let subAttrs: [NSAttributedString.Key: Any] = [.font: nameFont, .foregroundColor: UIColor.gray]
                
                // Title drawing
                let titleRect = CGRect(x: x + 8, y: yOffset + 8, width: sigWidth - 16, height: 12)
                title.draw(in: titleRect, withAttributes: textAttrs)

                if let signatureData, let uiImage = UIImage(data: signatureData) {
                    // Draw signature image centered in the box
                    let imgRect = CGRect(x: x + 16, y: yOffset + 24, width: sigWidth - 32, height: 55)
                    uiImage.draw(in: imgRect)
                } else {
                    // Draw "Pending Signature" placeholder
                    let placeholderFont = UIFont.italicSystemFont(ofSize: 9)
                    let pAttrs: [NSAttributedString.Key: Any] = [.font: placeholderFont, .foregroundColor: UIColor.lightGray]
                    let pRect = CGRect(x: x + 8, y: yOffset + 44, width: sigWidth - 16, height: 12)
                    "Pending Digital Signature".draw(in: pRect, withAttributes: pAttrs)
                }

                // Date and details
                if let signeeName, !signeeName.isEmpty, let dateText {
                    let infoText = "\(signeeName) · \(dateText)"
                    let infoRect = CGRect(x: x + 8, y: yOffset + boxHeight - 18, width: sigWidth - 16, height: 10)
                    infoText.draw(in: infoRect, withAttributes: subAttrs)
                }
            }

            // Draw Manager
            let managerDateText = incident.managerSignedAt?.formatted(date: .abbreviated, time: .shortened)
            drawSignatureBox(
                x: managerSigX,
                title: "Nursery Manager Sign-off",
                signeeName: incident.isManagerSigned ? incident.managerSignedByName : nil,
                dateText: managerDateText,
                signatureData: incident.managerSignatureData
            )

            // Draw Parent
            let parentDateText = incident.parentAcknowledgedAt?.formatted(date: .abbreviated, time: .shortened)
            drawSignatureBox(
                x: parentSigX,
                title: "Parent / Guardian Acknowledgment",
                signeeName: incident.isParentAcknowledged ? "Acknowledged" : nil,
                dateText: parentDateText,
                signatureData: incident.parentSignatureData
            )

            yOffset += 124

            // Footer Regulatory Note
            let footerFont = UIFont.systemFont(ofSize: 8)
            let footerColor = UIColor.gray
            let footerText = "This report complies with Early Years Foundation Stage (EYFS) safeguarding and statutory record-keeping regulations. Handled in accordance with UK GDPR. Managed locally via NurseryConnect."
            drawString(footerText, font: footerFont, color: footerColor, alignment: .center)
        }

        // Return a single image page for standard rendering
        guard let image = UIImage(data: data) else { return nil }
        return PDFPage(image: image)
    }
}
