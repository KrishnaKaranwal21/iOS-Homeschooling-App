import SwiftUI

struct RegistrationView: View {
    let event: Event
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var registrant = Registrant()
    @State private var staysWithChild = true
    @State private var consent = false
    @State private var acceptsNoRefund = false
    @State private var isPrefilled = false
    @State private var didLoad = false

    // MARK: Rules that depend on the host's parent policy

    /// Whether the parent will be at the event, taking the host's rule into account.
    private var isAccompanying: Bool {
        switch event.parentPresence {
        case .required:   return true
        case .optional:   return staysWithChild
        case .notAllowed: return false
        }
    }

    private var childLabel: String {
        let name = registrant.childName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "your child" : name
    }

    private var consentText: String {
        isAccompanying
            ? "I’m this child’s parent or guardian and consent to their participation. I’ll stay with them throughout the event."
            : "I’m this child’s parent or guardian and consent to their participation without me. I’ll drop them off and collect them on time."
    }

    private var isValid: Bool {
        !registrant.parentName.trimmingCharacters(in: .whitespaces).isEmpty
            && registrant.email.contains("@")
            && !registrant.childName.trimmingCharacters(in: .whitespaces).isEmpty
            && consent
            && (event.isFree || acceptsNoRefund)
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Registration").pageTitle()
                eventCard
                parentSection
                childSection
                attendanceSection
                paymentSection
                confirmArea
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: prefill)
        .animation(.snappy, value: staysWithChild)
    }

    // MARK: Sections

    private var eventCard: some View {
        HStack(spacing: 16) {
            EventCover(event: event)
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .scaledFont(21, weight: .bold, maxScale: 1.25)
                    .tracking(-0.4)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                Text("\(event.start.formatted(.dateTime.weekday(.wide))) · \(event.time)")
                    .scaledFont(15, maxScale: 1.3)
                    .foregroundStyle(Theme.ink)
                Text(event.mode == .online
                     ? "Online"
                     : "\(event.locationLines.title) · \(event.locality)")
                    .scaledFont(14, maxScale: 1.3)
                    .foregroundStyle(Theme.ink.opacity(0.8))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Theme.lilac))
        .accessibilityElement(children: .combine)
    }

    private var parentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            heading("Parent or guardian")
            Text(isPrefilled
                 ? "Filled in from your last registration. Change anything you need."
                 : "We’ll send the event details to you. All fields are required unless marked optional.")
                .scaledFont(15, maxScale: 1.3)
                .foregroundStyle(Theme.gatherText)

            field("Full name") {
                TextField("Your full name", text: $registrant.parentName)
                    .textContentType(.name)
            }
            field("Email address") {
                TextField("you@example.com", text: $registrant.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            field("Mobile number") {
                TextField("+91 98765 43210", text: $registrant.mobile)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }
        }
    }

    private var childSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            heading("Little explorer")

            HStack(alignment: .top, spacing: 12) {
                field("Child’s full name") {
                    TextField("Child’s name", text: $registrant.childName)
                        .textContentType(.givenName)
                }
                field("Age") {
                    TextField("8", text: $registrant.childAge)
                        .keyboardType(.numberPad)
                }
                .frame(width: 112)
            }

            field("Allergies or support needs (optional)") {
                TextField("Anything we should know?", text: $registrant.notes)
            }
        }
    }

    /// Changes with the host's parent policy: a question, a notice, or just the consent.
    private var attendanceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            switch event.parentPresence {
            case .required:
                EmptyView()

            case .optional:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Will you stay with \(childLabel)?")
                        .scaledFont(16, weight: .semibold, maxScale: 1.3)
                        .foregroundStyle(Theme.ink)
                    GatherSegmented(options: [true, false], selection: $staysWithChild) {
                        $0 ? "I’ll stay" : "Drop-off"
                    }
                    Text("The host welcomes parents but doesn’t require them.")
                        .scaledFont(13, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                }

            case .notAllowed:
                notice(icon: "figure.walk.departure",
                       text: "Parents can’t stay at this event. Please drop off and collect \(childLabel) on time.")
            }

            checkbox(consentText, isOn: $consent)
        }
    }

    @ViewBuilder private var paymentSection: some View {
        if !event.isFree {
            VStack(alignment: .leading, spacing: 14) {
                heading("Payment")
                notice(icon: "exclamationmark.triangle.fill",
                       text: "No refunds. \(event.priceText) is non-refundable, even if you don’t attend. Paid places can’t be cancelled.",
                       tint: Color.orange)
                checkbox("I understand this payment won’t be refunded.", isOn: $acceptsNoRefund)
            }
        }
    }

    private var confirmArea: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: event.isFree ? "Confirm registration" : "Pay \(event.priceText) & confirm",
                          isDimmed: !isValid) {
                guard isValid else { return }
                state.register(event, as: registrant, accompanying: isAccompanying)
                dismiss()
            }

            Text(event.isFree
                 ? "Your confirmation will be sent by email. You can cancel any time."
                 : "Your confirmation will be sent by email.")
                .scaledFont(14, maxScale: 1.3)
                .foregroundStyle(Theme.gatherText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 4)
    }

    // MARK: Building blocks

    private func heading(_ text: String) -> some View {
        Text(text)
            .scaledFont(24, weight: .bold, maxScale: 1.3)
            .tracking(-0.5)
            .foregroundStyle(Theme.ink)
            .accessibilityAddTraits(.isHeader)
    }

    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .scaledFont(15, maxScale: 1.3)
                .foregroundStyle(Theme.ink)
            content()
                .scaledFont(17, maxScale: 1.3)
                .foregroundStyle(Theme.ink)
                .gatherField()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func checkbox(_ text: String, isOn: Binding<Bool>) -> some View {
        Button { isOn.wrappedValue.toggle() } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .opacity(isOn.wrappedValue ? 1 : 0)
                    .frame(width: 30, height: 30)
                    .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(isOn.wrappedValue ? Theme.lavender : Color.white))
                    .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(isOn.wrappedValue ? Color.clear : Theme.lilacBorder, lineWidth: 1.5))
                Text(text)
                    .scaledFont(15, maxScale: 1.3)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isOn.wrappedValue)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isOn.wrappedValue ? [.isButton, .isSelected] : .isButton)
    }

    private func notice(icon: String, text: String, tint: Color = Theme.gatherAccent) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundStyle(tint)
            Text(text)
                .scaledFont(15, weight: .medium, maxScale: 1.3)
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.chipFill))
    }

    // MARK: Prefill

    /// Reuse the last registration, or start with the child from setup.
    private func prefill() {
        guard !didLoad else { return }
        didLoad = true

        if let saved = state.savedRegistrant {
            registrant = saved
            isPrefilled = true
        } else {
            if let account = state.account {
                registrant.parentName = account.name
                registrant.email = account.email
                registrant.mobile = account.mobile ?? ""
            }
            registrant.childName = state.child.name
            if let birthDate = state.child.birthDate {
                registrant.childAge = String(AgeRules.age(of: birthDate, on: .now))
            }
        }
    }
}
