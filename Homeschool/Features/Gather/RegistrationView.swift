import SwiftUI

struct RegistrationView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var mobile = ""
    @State private var childName = ""
    @State private var age = ""
    @State private var notes = ""
    @State private var consent = false

    var body: some View {
        Form {
            Section {
                Text(event.title).font(.headline)
                Text("\(event.day) \(event.month) · \(event.place)").font(.caption)
            }
            Section("Parent or guardian") {
                TextField("Full name", text: $name)
                TextField("Email address", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("Mobile number", text: $mobile).keyboardType(.phonePad)
            }
            Section("Little explorer") {
                TextField("Child's full name", text: $childName)
                TextField("Age", text: $age).keyboardType(.numberPad)
                TextField("Allergies or support needs (optional)", text: $notes)
            }
            Section {
                Toggle("I'm this child's parent or guardian and I'll stay with them throughout the event.", isOn: $consent)
            }
            Section {
                Button("Confirm registration") { dismiss() }.disabled(!isValid)
            }
        }
        .navigationTitle("Registration")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var isValid: Bool {
        !name.isEmpty && email.contains("@") && !childName.isEmpty && consent
    }
}
