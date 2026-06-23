import AppKit

struct CaptionOverlay {
    let text: String

    func draw(in rect: CGRect) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let fontSize = max(42, rect.width * 0.055)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraph,
        ]

        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let measured = attributedText.boundingRect(
            with: CGSize(width: rect.width * 0.84, height: rect.height),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
        )
        let textRect = CGRect(
            x: rect.midX - rect.width * 0.42,
            y: rect.midY - measured.height / 2,
            width: rect.width * 0.84,
            height: measured.height,
        )
        attributedText.draw(with: textRect, options: [.usesLineFragmentOrigin, .usesFontLeading])
    }
}
