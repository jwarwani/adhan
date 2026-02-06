import SwiftUI

/// View for collecting and sending user feedback
struct FeedbackView: View {

    // MARK: - Configuration

    /// Support email address - update this before App Store release
    private let supportEmail = "support@example.com"

    // MARK: - State

    @State private var feedbackType: FeedbackType = .bug
    @State private var descriptionText = ""
    @State private var includeLogs = true
    @State private var showMailComposer = false
    @State private var showMailNotAvailable = false

    @Environment(\.dismiss) private var dismiss

    // MARK: - Types

    enum FeedbackType: String, CaseIterable {
        case bug = "Bug Report"
        case feature = "Feature Request"
        case question = "Question"
        case prayerTimes = "Prayer Times Issue"
        case other = "Other"

        var icon: String {
            switch self {
            case .bug: return "ladybug"
            case .feature: return "lightbulb"
            case .question: return "questionmark.circle"
            case .prayerTimes: return "clock"
            case .other: return "ellipsis.circle"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        Form {
            // Feedback type
            Section {
                Picker("Type", selection: $feedbackType) {
                    ForEach(FeedbackType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }
            }

            // Description
            Section {
                TextEditor(text: $descriptionText)
                    .frame(minHeight: 120)
            } header: {
                Text("Description")
            } footer: {
                Text("Please describe your feedback in detail.")
            }

            // Logs toggle
            Section {
                Toggle(isOn: $includeLogs) {
                    Label("Include Diagnostic Logs", systemImage: "doc.text")
                }
            } footer: {
                Text("Logs help us understand what happened before the issue occurred. They don't contain personal information.")
            }

            // Device info (read-only)
            Section("Device Information") {
                DeviceInfoRow(label: "App Version", value: Bundle.main.appVersion)
                DeviceInfoRow(label: "iOS Version", value: UIDevice.current.systemVersion)
                DeviceInfoRow(label: "Device", value: UIDevice.current.modelName)
                DeviceInfoRow(label: "Environment", value: BuildEnvironment.configurationName)
            }

            // Send button
            Section {
                Button(action: sendFeedback) {
                    HStack {
                        Spacer()
                        Label("Send Feedback", systemImage: "paperplane.fill")
                        Spacer()
                    }
                }
                .disabled(descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("Send Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMailComposer) {
            MailComposerView(
                recipient: supportEmail,
                subject: emailSubject,
                body: buildEmailBody()
            )
        }
        .sheet(isPresented: $showMailNotAvailable) {
            NavigationView {
                MailNotAvailableView(
                    feedbackText: buildEmailBody(),
                    supportEmail: supportEmail
                )
                .navigationTitle("Send Feedback")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            showMailNotAvailable = false
                        }
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var emailSubject: String {
        "[\(feedbackType.rawValue)] Adhan App Feedback"
    }

    // MARK: - Actions

    private func sendFeedback() {
        if MailComposerView.canSendMail {
            showMailComposer = true
        } else {
            showMailNotAvailable = true
        }
    }

    private func buildEmailBody() -> String {
        var body = """
        Feedback Type: \(feedbackType.rawValue)

        Description:
        \(descriptionText)

        ---
        Device Information:
        App Version: \(Bundle.main.appVersion)
        iOS Version: \(UIDevice.current.systemVersion)
        Device: \(UIDevice.current.modelName)
        Device ID: \(UIDevice.current.modelIdentifier)
        Environment: \(BuildEnvironment.configurationName)
        Locale: \(Locale.current.identifier)
        Timezone: \(TimeZone.current.identifier)
        """

        // Add settings info
        let settings = AppSettings.shared
        body += """


        ---
        App Settings:
        Calculation Method: \(settings.calculationMethodEnum.displayName)
        Asr School: \(settings.asrSchoolEnum.displayName)
        Auto Location: \(settings.useAutoLocation)
        """

        if !settings.useAutoLocation {
            body += """

            Manual Location: \(settings.manualCityName) (\(settings.manualLatitude), \(settings.manualLongitude))
            """
        }

        // Add logs if enabled
        if includeLogs {
            body += """


            ---
            Recent Logs (\(AppLogger.shared.bufferCount) entries):
            \(AppLogger.shared.exportLogsAsString(count: 100))
            """
        }

        return body
    }
}

/// Row for displaying device info
struct DeviceInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}

#Preview {
    NavigationView {
        FeedbackView()
    }
}
