import SwiftUI

struct RegistrationView: View {
    let event: Event
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var registrant = Registrant()
    @State private var consent = false
    @State private var isPrefilled = false
    @State private var didLoad = false

    var body: some View {
        Form {
            Section {
                Text(event.title).font(.headline)
                Text("\(event.start.formatted(date: .abbreviated, time: .shortened)) · \(event.locationLines.title)")
                    .font(.caption)
            }

            Section {
                TextField("Full name", text: $registrant.parentName)
                    .textContentType(.name)
                TextField("Email address", text: $registrant.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("Mobile number", text: $registrant.mobile)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            } header: {
                Text("Parent or guardian")
            } footer: {
                if isPrefilled {
                    Text("Filled in from your last registration. Change anything you need.")
                }
            }

            Section("Little explorer") {
                TextField("Child's full name", text: $registrant.childName)
                TextField("Age", text: $registrant.childAge).keyboardType(.numberPad)
                TextField("Allergies or support needs (optional)", text: $registrant.notes)
            }

            Section {
                Toggle("I'm this child's parent or guardian and I'll stay with them throughout the event.", isOn: $consent)
            }

            Section {
                Button("Confirm registration") {
                    state.register(event, as: registrant)
                    dismiss()
                }
                .disabled(!isValid)
            }
        }
        .navigationTitle("Registration")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: prefill)
    }

    private var isValid: Bool {
        !registrant.parentName.isEmpty && registrant.email.contains("@") && !registrant.childName.isEmpty && consent
    }

    /// Reuse the last registration, or start with the child from setup.
    private func prefill() {
        guard !didLoad else { return }
        didLoad = true

        if let saved = state.savedRegistrant {
            registrant = saved
            isPrefilled = true
        } else {
            registrant.childName = state.child.name
            if let birthDate = state.child.birthDate {
                registrant.childAge = String(AgeRules.age(of: birthDate, on: .now))
            }
        }
    }
}
