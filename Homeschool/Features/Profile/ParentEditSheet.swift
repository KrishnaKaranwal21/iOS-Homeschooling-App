import SwiftUI

/// Sheet for editing the signed-in parent's name and mobile number.
struct ParentEditSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var mobile = ""
    @State private var loaded = false
    @State private var saveFailed = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Your details") {
                    TextField("Full name", text: $name)
                        .textContentType(.name)
                    PhoneField(number: $mobile)
                    LabeledContent("Email", value: state.account?.email ?? "")
                }
                Section {
                } footer: {
                    Text("Your email is how you sign in, so it can’t be changed here.")
                }
            }
            .navigationTitle("Your details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard state.updateAccount(name: name, mobile: mobile) else {
                            saveFailed = true
                            return
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                name = state.account?.name ?? ""
                mobile = state.account?.mobile ?? ""
            }
            .alert("Couldn’t save your details", isPresented: $saveFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your signed-in account couldn’t be restored. Your entries are still here. Please sign in again to save them.")
            }
        }
        .presentationDetents([.medium, .large])
    }
}
