//
//  ContentView.swift
//  ArmenianKeyboard
//
//  Main view with setup instructions
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Armenian Keyboard")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("System-wide QWERTY Armenian keyboard with word suggestions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)

                    Divider()
                        .padding(.vertical, 10)

                    // Setup Instructions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Setup Instructions")
                            .font(.title2)
                            .fontWeight(.semibold)

                        InstructionStep(
                            number: 1,
                            title: "Open Settings",
                            description: "Go to Settings on your iPhone or iPad"
                        )

                        InstructionStep(
                            number: 2,
                            title: "Navigate to Keyboards",
                            description: "Tap General → Keyboard → Keyboards"
                        )

                        InstructionStep(
                            number: 3,
                            title: "Add Keyboard",
                            description: "Tap 'Add New Keyboard...' and select 'Armenian' under Third-Party Keyboards"
                        )

                        InstructionStep(
                            number: 4,
                            title: "Allow Full Access (Optional)",
                            description: "For word suggestions, enable 'Allow Full Access' in keyboard settings. Your typing data stays on your device."
                        )

                        InstructionStep(
                            number: 5,
                            title: "Start Using",
                            description: "Tap and hold the globe icon 🌐 on any keyboard to switch to Armenian"
                        )
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.vertical, 10)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.title2)
                            .fontWeight(.semibold)

                        FeatureRow(icon: "globe", title: "QWERTY Layout", description: "Standard QWERTY-based Armenian character mapping")
                        FeatureRow(icon: "text.bubble", title: "Word Suggestions", description: "Smart word predictions as you type")
                        FeatureRow(icon: "paintbrush", title: "Native Design", description: "Matches iOS keyboard appearance")
                        FeatureRow(icon: "lock.shield", title: "Privacy First", description: "All processing happens on your device")
                    }
                    .padding(.horizontal)

                    // Open Settings Button
                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Open Settings")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
