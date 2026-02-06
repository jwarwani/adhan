import SwiftUI

/// Main settings view for the Adhan app
struct SettingsView: View {

    @ObservedObject var settings: AppSettings
    @Binding var isPresented: Bool

    @State private var showingResetConfirmation = false

    // Gold accent color matching app theme
    private let goldColor = Color(red: 0.85, green: 0.65, blue: 0.13)

    var body: some View {
        NavigationView {
            Form {
                // Prayer Calculation Section
                Section {
                    Picker("Method", selection: $settings.calculationMethod) {
                        ForEach(CalculationMethod.allCases, id: \.rawValue) { method in
                            VStack(alignment: .leading) {
                                Text(method.displayName)
                            }
                            .tag(method.rawValue)
                        }
                    }

                    Picker("Asr School", selection: $settings.asrSchool) {
                        ForEach(AsrSchool.allCases, id: \.rawValue) { school in
                            Text(school.displayName).tag(school.rawValue)
                        }
                    }
                } header: {
                    Text("Prayer Calculation")
                } footer: {
                    Text("Method: \(settings.calculationMethodEnum.commonRegions)")
                }

                // Location Section
                Section {
                    Toggle("Use automatic location", isOn: $settings.useAutoLocation)

                    if !settings.useAutoLocation {
                        NavigationLink {
                            LocationSettingsView(settings: settings)
                        } label: {
                            HStack {
                                Text("Location")
                                Spacer()
                                Text(settings.manualCityName.isEmpty ? "Not set" : settings.manualCityName)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Location")
                } footer: {
                    if settings.useAutoLocation {
                        Text("Prayer times will be calculated based on your current GPS location.")
                    } else {
                        Text("Prayer times will be calculated for your selected location.")
                    }
                }

                // Prayer Alerts Section
                Section {
                    PrayerAlertRow(prayer: "Fajr", mode: $settings.alertModeFajr)
                    PrayerAlertRow(prayer: "Dhuhr", mode: $settings.alertModeDhuhr)
                    PrayerAlertRow(prayer: "Asr", mode: $settings.alertModeAsr)
                    PrayerAlertRow(prayer: "Maghrib", mode: $settings.alertModeMaghrib)
                    PrayerAlertRow(prayer: "Isha", mode: $settings.alertModeIsha)
                } header: {
                    Text("Prayer Alerts")
                } footer: {
                    Text("Choose how you want to be notified for each prayer time.")
                }

                // About Section
                Section("About") {
                    NavigationLink {
                        FeedbackView()
                    } label: {
                        Label("Send Feedback", systemImage: "envelope")
                    }

                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.appVersion)
                            .foregroundColor(.secondary)
                    }

                    if BuildEnvironment.allowDebugFeatures {
                        HStack {
                            Text("Environment")
                            Spacer()
                            Text(BuildEnvironment.configurationName)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Reset Section
                Section {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Reset to Defaults")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(goldColor)
                }
            }
            .confirmationDialog(
                "Reset Settings",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset to Defaults", role: .destructive) {
                    settings.resetToDefaults()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset all settings to their default values. This cannot be undone.")
            }
        }
    }
}

/// Row component for per-prayer alert mode selection
struct PrayerAlertRow: View {
    let prayer: String
    @Binding var mode: String

    var currentMode: PrayerAlertMode {
        PrayerAlertMode(rawValue: mode) ?? .adhan
    }

    var body: some View {
        Picker(prayer, selection: $mode) {
            ForEach(PrayerAlertMode.allCases, id: \.rawValue) { alertMode in
                Label(alertMode.displayName, systemImage: alertMode.icon)
                    .tag(alertMode.rawValue)
            }
        }
    }
}

/// View for manual location settings
struct LocationSettingsView: View {
    @ObservedObject var settings: AppSettings

    @State private var cityName = ""
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var showError = false
    @State private var errorMessage = ""

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                TextField("City Name", text: $cityName)
                    .textContentType(.addressCity)
            } header: {
                Text("Location Name")
            } footer: {
                Text("This name is displayed in the app.")
            }

            Section {
                TextField("Latitude", text: $latitude)
                    .keyboardType(.decimalPad)

                TextField("Longitude", text: $longitude)
                    .keyboardType(.decimalPad)
            } header: {
                Text("Coordinates")
            } footer: {
                Text("Enter decimal coordinates (e.g., 40.7128 for latitude, -74.0060 for longitude).")
            }

            Section {
                Button("Save Location") {
                    saveLocation()
                }
                .disabled(cityName.isEmpty || latitude.isEmpty || longitude.isEmpty)
            }

            if !settings.manualCityName.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current: \(settings.manualCityName)")
                            .font(.headline)
                        Text("Lat: \(settings.manualLatitude, specifier: "%.4f"), Lon: \(settings.manualLongitude, specifier: "%.4f")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Saved Location")
                }
            }
        }
        .navigationTitle("Set Location")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Pre-fill with existing values
            if !settings.manualCityName.isEmpty {
                cityName = settings.manualCityName
                latitude = String(settings.manualLatitude)
                longitude = String(settings.manualLongitude)
            }
        }
        .alert("Invalid Coordinates", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func saveLocation() {
        guard let lat = Double(latitude),
              let lon = Double(longitude) else {
            errorMessage = "Please enter valid decimal numbers for coordinates."
            showError = true
            return
        }

        // Validate ranges
        guard lat >= -90 && lat <= 90 else {
            errorMessage = "Latitude must be between -90 and 90."
            showError = true
            return
        }

        guard lon >= -180 && lon <= 180 else {
            errorMessage = "Longitude must be between -180 and 180."
            showError = true
            return
        }

        settings.setManualLocation(latitude: lat, longitude: lon, cityName: cityName)
        AppLogger.shared.info("Manual location set: \(cityName) (\(lat), \(lon))", category: "settings")
        dismiss()
    }
}

#Preview("Settings") {
    SettingsView(
        settings: AppSettings.shared,
        isPresented: .constant(true)
    )
}

#Preview("Location Settings") {
    NavigationView {
        LocationSettingsView(settings: AppSettings.shared)
    }
}
