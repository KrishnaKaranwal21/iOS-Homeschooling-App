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
    /// The children who will join. Each one needs a place, so the price follows this count.
    @State private var selectedIDs: Set<Child.ID> = []

    /// Children from setup that have a name. With none, the parent types the child's details instead.
    private var kids: [Child] {
        state.children.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private var selectedKids: [Child] { kids.filter { selectedIDs.contains($0.id) } }

    /// Places to pay for: one per selected child (or one when the child is typed in by hand).
    private var placeCount: Int { kids.isEmpty ? 1 : max(selectedKids.count, 1) }
    private var isMultiple: Bool { placeCount > 1 }

    private var totalPrice: Int? { event.price.map { $0 * placeCount } }
    private var totalText: String {
        guard let totalPrice else { return "Free" }
        return totalPrice.formatted(.currency(code: "INR").precision(.fractionLength(0)))
    }

    // MARK: Rules that depend on the host's parent policy

    /// Whether the parent will be at the event, taking the host's rule into account.
    private var isAccompanying: Bool {
        switch event.parentPresence {
        case .required:   return true
        case .optional:   return staysWithChild
        case .dropOffOnly: return false
        }
    }

    private var childLabel: String {
        let name = registrant.childName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "your child" : name
    }

    private var consentText: String {
        let who = isMultiple ? "these children’s" : "this child’s"
        return isAccompanying
            ? "I’m \(who) parent or guardian and consent to their participation. I’ll stay with them throughout the event."
            : "I’m \(who) parent or guardian and consent to their participation without me. I’ll drop them off and collect them on time."
    }

    private var isValid: Bool {
        !registrant.parentName.trimmingCharacters(in: .whitespaces).isEmpty
            && registrant.email.contains("@")
            && !registrant.childName.trimmingCharacters(in: .whitespaces).isEmpty
            && (kids.isEmpty || !selectedKids.isEmpty)
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
        .scrollNavigationTitle("Registration")
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: prefill)
        .onChange(of: selectedIDs) { applySelection() }
        .animation(.snappy, value: staysWithChild)
    }

    // MARK: Sections

    private var eventCard: some View {
        HStack(spacing: 16) {
            EventCover(event: event)
                .frame(width: 84, height: 84)
                .clipShape(.rect(cornerRadius: 18))
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
        .background(Theme.lilac, in: .rect(cornerRadius: 28))
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
                PhoneField(number: $registrant.mobile)
            }
        }
    }

    private var childSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            heading(isMultiple ? "Little explorers" : "Little explorer")

            if kids.isEmpty {
                // No child saved in setup yet: type the details in.
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
            } else if kids.count == 1 {
                // Only one child: they are selected automatically.
                field("Registering") {
                    childRow(name: kids[0].name, detail: ageText(for: kids[0]))
                }
            } else {
                // Two or more children: tick everyone who will join. Each one is a paid place.
                VStack(alignment: .leading, spacing: 8) {
                    Text("Who is coming?")
                        .scaledFont(15, maxScale: 1.3)
                        .foregroundStyle(Theme.ink)
                    Text("Select each child who will join. You pay for one place per child.")
                        .scaledFont(13, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                    VStack(spacing: 8) {
                        ForEach(kids) { kid in kidRow(kid) }
                    }
                }
            }

            field("Allergies or support needs (optional)") {
                TextField("Anything we should know?", text: $registrant.notes)
            }
        }
    }

    private func childRow(name: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Text(String(name.prefix(1)).uppercased())
                .scaledFont(15, weight: .bold, maxScale: 1.2)
                .foregroundStyle(Theme.ink)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Theme.lavender))
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .lineLimit(1)
                if !detail.isEmpty {
                    Text(detail)
                        .scaledFont(13, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func ageText(for child: Child) -> String {
        child.birthDate.map { "Age \(AgeRules.age(of: $0, on: .now))" } ?? ""
    }

    private func kidRow(_ kid: Child) -> some View {
        let isSelected = selectedIDs.contains(kid.id)
        return Button { toggle(kid) } label: {
            HStack(spacing: 12) {
                childRow(name: kid.name, detail: ageText(for: kid))
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.gatherAccent : Theme.gatherText)
            }
            .scaledFont(17, maxScale: 1.3)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(isSelected ? Theme.lilac : Color.white, in: .rect(cornerRadius: 16))
            .roundedStroke(isSelected ? Theme.gatherAccent : Theme.cardBorder,
                           cornerRadius: 16, lineWidth: isSelected ? 1.5 : 1)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// At least one child always stays selected.
    private func toggle(_ kid: Child) {
        if selectedIDs.contains(kid.id) {
            if selectedIDs.count > 1 { selectedIDs.remove(kid.id) }
        } else {
            selectedIDs.insert(kid.id)
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
                    Text("You are welcome to stay or drop off \(childLabel).")
                        .scaledFont(13, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                }

            case .dropOffOnly:
                notice(icon: "figure.walk.departure",
                       text: "This is an independent session for learners. Please drop off and collect \(childLabel) on time.")
            }

            checkbox(consentText, isOn: $consent)
        }
    }

    @ViewBuilder private var paymentSection: some View {
        if !event.isFree {
            VStack(alignment: .leading, spacing: 14) {
                heading("Payment")
                costSummary
                notice(icon: "exclamationmark.triangle.fill",
                       text: "No refunds. \(totalText) is non-refundable, even if you don’t attend. Paid places can’t be cancelled.",
                       tint: Color.orange)
                checkbox("I understand this payment won’t be refunded.", isOn: $acceptsNoRefund)
            }
        }
    }

    /// Price per child, how many children, and the total.
    private var costSummary: some View {
        VStack(spacing: 10) {
            if isMultiple {
                summaryRow("Price per child", event.priceText)
                summaryRow("Children", "× \(placeCount)")
                Rectangle().fill(Color.black.opacity(0.08)).frame(height: 1)
            }
            summaryRow("Total", totalText, isTotal: true)
        }
        .padding(16)
        .background(Color.white, in: .rect(cornerRadius: 18))
        .roundedStroke(Theme.cardBorder, cornerRadius: 18)
        .animation(.snappy, value: placeCount)
        .accessibilityElement(children: .combine)
    }

    private func summaryRow(_ title: String, _ value: String, isTotal: Bool = false) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
        }
        .scaledFont(isTotal ? 18 : 16, weight: isTotal ? .bold : .regular, maxScale: 1.3)
        .foregroundStyle(Theme.ink)
    }

    private var confirmArea: some View {
        VStack(spacing: 12) {
            Button(event.isFree ? "Confirm registration" : "Pay \(totalText) & confirm") {
                guard isValid else { return }
                state.register(event, as: registrant, accompanying: isAccompanying, places: placeCount)
                dismiss()
            }
            .buttonStyle(.primaryHomeschool(isDimmed: !isValid))

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
                    .background(isOn.wrappedValue ? Theme.lavender : Color.white, in: .rect(cornerRadius: 9))
                    .roundedStroke(isOn.wrappedValue ? Color.clear : Theme.lilacBorder, cornerRadius: 9, lineWidth: 1.5)
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
        .background(Theme.chipFill, in: .rect(cornerRadius: 18))
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

        // The child's details come from the family's children. With one child it is picked for them.
        if kids.count == 1 {
            selectedIDs = [kids[0].id]
        } else if kids.count > 1 {
            selectedIDs = [kids.contains { $0.id == state.child.id } ? state.child.id : kids[0].id]
        }
        applySelection()
    }

    /// Copies the selected children into the registration.
    private func applySelection() {
        guard !kids.isEmpty else { return }
        let selected = selectedKids
        registrant.childName = selected.map(\.name).joined(separator: " & ")
        registrant.childAge = selected
            .compactMap { child in child.birthDate.map { String(AgeRules.age(of: $0, on: .now)) } }
            .joined(separator: " & ")
    }
}
