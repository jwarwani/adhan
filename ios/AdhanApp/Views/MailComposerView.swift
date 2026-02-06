import SwiftUI
import MessageUI

/// SwiftUI wrapper for MFMailComposeViewController
struct MailComposerView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String
    var isHTML: Bool = false

    @Environment(\.dismiss) private var dismiss

    /// Check if mail can be sent on this device
    static var canSendMail: Bool {
        MFMailComposeViewController.canSendMail()
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients([recipient])
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: isHTML)
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            // Log the result
            switch result {
            case .cancelled:
                AppLogger.shared.info("Mail composer cancelled", category: "general")
            case .saved:
                AppLogger.shared.info("Mail saved as draft", category: "general")
            case .sent:
                AppLogger.shared.info("Mail sent successfully", category: "general")
            case .failed:
                AppLogger.shared.error("Mail failed to send: \(error?.localizedDescription ?? "unknown")", category: "general")
            @unknown default:
                break
            }

            dismiss()
        }
    }
}

/// Fallback view when Mail is not configured on the device
struct MailNotAvailableView: View {
    let feedbackText: String
    let supportEmail: String

    @State private var showCopiedConfirmation = false

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            // Title
            Text("Mail Not Configured")
                .font(.title2)
                .fontWeight(.semibold)

            // Instructions
            Text("Mail is not set up on this device. Please copy the feedback information and email it manually.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            // Email address
            VStack(spacing: 8) {
                Text("Send to:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(supportEmail)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.blue)
            }

            // Copy button
            Button(action: copyToClipboard) {
                HStack {
                    Image(systemName: showCopiedConfirmation ? "checkmark" : "doc.on.doc")
                    Text(showCopiedConfirmation ? "Copied!" : "Copy Feedback to Clipboard")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(showCopiedConfirmation)
        }
        .padding()
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = feedbackText

        withAnimation {
            showCopiedConfirmation = true
        }

        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedConfirmation = false
            }
        }
    }
}

#Preview("Mail Composer Available") {
    Text("Mail Composer Preview")
}

#Preview("Mail Not Available") {
    MailNotAvailableView(
        feedbackText: "Sample feedback text...",
        supportEmail: "support@example.com"
    )
}
