import SwiftUI
import PhotosUI

struct HostEventView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var kind: Event.Kind = .gathering
    @State private var category: String?
    @State private var place: Place?
    @State private var showLocationPicker = false
    @State private var about = ""
    @State private var coverItem: PhotosPickerItem?
    @State private var coverImage: PickedImage?
    @State private var date = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    @State private var starts = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
    @State private var ends = Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: .now) ?? .now
    @State private var mode: Event.Mode = .inPerson
    @State private var location = ""
    @State private var agePreset = "Ages 8–14"
    @State private var minAge = ""
    @State private var maxAge = ""
    @State private var parentPresence: Event.ParentPresence = .required
    @State private var faqDrafts: [FAQDraft] = []
    @State private var paid = false
    @State private var price = ""

    private let ageOptions = ["Ages 4–7", "Ages 8–14", "Ages 12+", "Family friendly", "All ages"]
    private let customAgeTag = "Custom range"

    private var isCustomAge: Bool { agePreset == customAgeTag }
    private var minAgeValue: Int? { Int(minAge.trimmingCharacters(in: .whitespaces)) }
    private var maxAgeValue: Int? { Int(maxAge.trimmingCharacters(in: .whitespaces)) }

    private var isCustomAgeValid: Bool {
        guard let low = minAgeValue, (0...99).contains(low) else { return false }
        if maxAge.trimmingCharacters(in: .whitespaces).isEmpty { return true }
        guard let high = maxAgeValue else { return false }
        return high >= low && high <= 99
    }

    /// The text saved on the event, e.g. "Ages 5–9", "Ages 10+" or "Age 7".
    private var ages: String {
        guard isCustomAge, let low = minAgeValue else { return agePreset }
        guard let high = maxAgeValue else { return "Ages \(low)+" }
        return low == high ? "Age \(low)" : "Ages \(low)–\(high)"
    }

    private var familyName: String {
        let name = state.child.name.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "Your family" : "\(name)’s family"
    }

    private var priceValue: Int? { Int(price.trimmingCharacters(in: .whitespaces)) }

    private var canCreate: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && category != nil
            && (mode == .online || place != nil)
            && (!isCustomAge || isCustomAgeValid)
            && (!paid || (priceValue ?? 0) > 0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Host an event").pageTitle()
                hostingCard
                makeItYours
                whenAndWhere
                placeForEveryone
                faqEditor
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button("Create event", action: create)
                .buttonStyle(.primaryHomeschool(isDimmed: !canCreate))
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(.bar)
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerSheet(allowsWorld: false, selection: place) { place = $0 }
        }
        .onChange(of: coverItem) { _, item in
            Task {
                if let image = try? await item?.loadTransferable(type: Image.self) {
                    coverImage = PickedImage(image: image)
                } else {
                    coverImage = nil
                }
            }
        }
    }

    // MARK: Sections

    private var hostingCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "person")
                .scaledFont(18, maxScale: 1.2)
                .foregroundStyle(Theme.ink)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color(hex: 0xC98A72)))

            VStack(alignment: .leading, spacing: 1) {
                Text("Hosting as")
                    .scaledFont(12, maxScale: 1.3)
                    .foregroundStyle(Theme.gatherText)
                Text(familyName)
                    .scaledFont(16, weight: .semibold, maxScale: 1.3)
                    .foregroundStyle(Theme.ink)
            }
            Spacer(minLength: 8)
            Text("Parent host")
                .scaledFont(12, maxScale: 1.3)
                .foregroundStyle(Theme.gatherText)
        }
        .padding(14)
        .background(Theme.pink, in: .rect(cornerRadius: 20))
    }

    private var makeItYours: some View {
        section("Make it yours") {
            labelled("Event title") {
                TextField("Nature explorers", text: $title)
                    .scaledFont(16, maxScale: 1.3)
                    .gatherField()
            }

            labelled("Type") {
                GatherSegmented(options: Event.Kind.allCases, selection: $kind) { $0.rawValue }
            }

            labelled("Category") {
                categoryChips
            }

            labelled("A little about your event") {
                TextField("Tell families what to expect", text: $about, axis: .vertical)
                    .scaledFont(16, maxScale: 1.3)
                    .lineLimit(4...8)
                    .gatherField(minHeight: 112)
            }

            coverPhotoRow
        }
    }

    private var categoryChips: some View {
        FlowLayout(spacing: 10) {
            ForEach(Event.categories, id: \.self) { name in
                Button { category = name } label: {
                    Label(name, systemImage: Event.symbol(for: name))
                        .scaledFont(15, weight: name == category ? .semibold : .regular, maxScale: 1.3)
                        .foregroundStyle(name == category ? Theme.ink : Theme.gatherText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(name == category ? Theme.lavender : Theme.chipFill))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(name == category ? .isSelected : [])
            }
        }
        .animation(.snappy, value: category)
    }

    private var areaButton: some View {
        Button { showLocationPicker = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "mappin.and.ellipse").foregroundStyle(Theme.gatherAccent)
                Text(place?.name ?? "Search a city or area")
                    .foregroundStyle(place == nil ? Theme.gatherText : Theme.ink)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.gatherText)
            }
            .scaledFont(16, maxScale: 1.3)
            .gatherField()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var coverPhotoRow: some View {
        PhotosPicker(selection: $coverItem, matching: .images) {
            HStack(spacing: 12) {
                if let coverImage {
                    coverImage.image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(.rect(cornerRadius: 10))
                    Text("Change cover photo")
                } else {
                    Image(systemName: "photo.badge.plus")
                        .foregroundStyle(Theme.gatherText)
                    Text("Add a cover photo")
                }
                Spacer(minLength: 0)
            }
            .scaledFont(16, maxScale: 1.3)
            .foregroundStyle(Theme.ink)
            .gatherField(minHeight: 56)
        }
        .buttonStyle(.plain)
    }

    private var whenAndWhere: some View {
        section("When & where") {
            labelled("Date") {
                GatherDateField(date: $date)
            }

            HStack(alignment: .top, spacing: 12) {
                labelled("Starts") { GatherTimeField(date: $starts) }
                labelled("Ends") { GatherTimeField(date: $ends) }
            }

            labelled("How we’ll meet") {
                GatherSegmented(options: Event.Mode.allCases, selection: $mode) { $0.rawValue }
            }

            if mode == .inPerson {
                labelled("Area") { areaButton }
            }

            labelled(mode == .online ? "Meeting link" : "Venue") {
                TextField(mode == .online ? "Link will be shared" : "Venue name and street address",
                          text: $location, axis: .vertical)
                    .scaledFont(16, maxScale: 1.3)
                    .lineLimit(2...4)
                    .gatherField(minHeight: 64)
            }
        }
    }

    private var placeForEveryone: some View {
        section("A place for everyone") {
            labelled("Age group") {
                VStack(alignment: .leading, spacing: 10) {
                    Menu {
                        Picker("Age group", selection: $agePreset) {
                            ForEach(ageOptions + [customAgeTag], id: \.self) { Text($0).tag($0) }
                        }
                    } label: {
                        HStack {
                            Text(isCustomAge ? "Custom range" : agePreset)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Theme.gatherText)
                        }
                        .scaledFont(16, maxScale: 1.3)
                        .foregroundStyle(Theme.ink)
                        .gatherField()
                    }

                    if isCustomAge {
                        HStack(spacing: 12) {
                            TextField("From", text: $minAge)
                                .keyboardType(.numberPad)
                                .scaledFont(16, maxScale: 1.3)
                                .gatherField()
                            Text("to").foregroundStyle(Theme.gatherText)
                            TextField("To (optional)", text: $maxAge)
                                .keyboardType(.numberPad)
                                .scaledFont(16, maxScale: 1.3)
                                .gatherField()
                        }
                        Text(isCustomAgeValid
                             ? "Shown as “\(ages)”. Leave “To” empty for an open range."
                             : "Enter a starting age. “To” must be the same or higher.")
                            .scaledFont(13, maxScale: 1.3)
                            .foregroundStyle(isCustomAgeValid ? Theme.gatherText : Color.red)
                    }
                }
                .animation(.snappy, value: isCustomAge)
            }

            labelled("Parents & guardians") {
                VStack(alignment: .leading, spacing: 8) {
                    Menu {
                        Picker("Parents & guardians", selection: $parentPresence) {
                            ForEach(Event.ParentPresence.allCases) { Text($0.rawValue).tag($0) }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: parentPresence.symbol)
                                .foregroundStyle(Theme.gatherAccent)
                            Text(parentPresence.rawValue)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Theme.gatherText)
                        }
                        .scaledFont(16, maxScale: 1.3)
                        .foregroundStyle(Theme.ink)
                        .gatherField()
                    }
                    Text(parentPresence.detail)
                        .scaledFont(13, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                }
            }

            labelled("Pricing") {
                GatherSegmented(options: [false, true], selection: $paid) { $0 ? "Paid" : "Free" }
            }

            if paid {
                labelled("Price per child (₹)") {
                    TextField("200", text: $price)
                        .keyboardType(.numberPad)
                        .scaledFont(16, maxScale: 1.3)
                        .gatherField()
                }
                .transition(.opacity)
            }
        }
        .animation(.snappy, value: paid)
    }

    // MARK: Helpers

    private func section<Content: View>(_ heading: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(heading)
                .scaledFont(24, weight: .bold, maxScale: 1.3)
                .tracking(-0.5)
                .foregroundStyle(Theme.ink)
            content()
        }
    }

    // MARK: FAQs

    private struct FAQDraft: Identifiable {
        let id = UUID()
        var question = ""
        var answer = ""
    }

    /// Questions families often ask. Hosts can answer up to five of their own.
    private var faqEditor: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Questions and answers").cardTitle()
            Text("Optional. Answer what families usually ask, such as what to bring.")
                .caption()

            ForEach($faqDrafts) { $draft in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        TextField("Question", text: $draft.question)
                            .scaledFont(16, weight: .medium, maxScale: 1.3)
                        Button(role: .destructive) {
                            faqDrafts.removeAll { $0.id == draft.id }
                        } label: {
                            Image(systemName: "trash").foregroundStyle(Color.red)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove this question")
                    }
                    TextField("Answer", text: $draft.answer, axis: .vertical)
                        .lineLimit(2...5)
                        .scaledFont(15, maxScale: 1.3)
                }
                .gatherField(minHeight: 52)
            }

            if faqDrafts.count < 5 {
                Button { faqDrafts.append(FAQDraft()) } label: {
                    Label("Add a question", systemImage: "plus.circle.fill")
                        .scaledFont(16, weight: .semibold, maxScale: 1.2)
                        .foregroundStyle(Theme.tabSelected)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func labelled<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .scaledFont(15, weight: .semibold, maxScale: 1.3)
                .foregroundStyle(Theme.ink)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Create

    private func merged(_ day: Date, with time: Date) -> Date {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
        return Calendar.current.date(bySettingHour: parts.hour ?? 0, minute: parts.minute ?? 0,
                                     second: 0, of: day) ?? day
    }

    private func create() {
        guard canCreate else { return }
        let begin = merged(date, with: starts)
        var finish = merged(date, with: ends)
        if finish <= begin { finish = begin.addingTimeInterval(2 * 3600) }

        let event = Event(
            title: title.trimmingCharacters(in: .whitespaces),
            category: category ?? "Community",
            kind: kind,
            start: begin,
            end: finish,
            host: familyName,
            locality: mode == .inPerson ? (place?.name ?? "") : "Online",
            country: mode == .inPerson ? (place?.country ?? "") : "",
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            mode: mode,
            ages: ages,
            parentPresence: parentPresence,
            about: about.trimmingCharacters(in: .whitespacesAndNewlines),
            faqs: faqDrafts
                .map { EventFAQ(question: $0.question.trimmingCharacters(in: .whitespacesAndNewlines),
                                answer: $0.answer.trimmingCharacters(in: .whitespacesAndNewlines)) }
                .filter { !$0.question.isEmpty && !$0.answer.isEmpty },
            price: paid ? priceValue : nil,
            symbol: Event.symbol(for: category ?? ""),
            coverImage: coverImage,
            isHostedByMe: true
        )
        state.add(event)
        dismiss()
    }
}
