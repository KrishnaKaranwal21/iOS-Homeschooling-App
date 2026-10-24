import SwiftUI
import PhotosUI

struct HostEventView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var kind: Event.Kind = .gathering
    @State private var about = ""
    @State private var coverItem: PhotosPickerItem?
    @State private var coverData: Data?
    @State private var date = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    @State private var starts = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
    @State private var ends = Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: .now) ?? .now
    @State private var mode: Event.Mode = .inPerson
    @State private var location = ""
    @State private var ages = "Ages 8–14"
    @State private var paid = false
    @State private var price = ""

    private let ageOptions = ["Ages 4–7", "Ages 8–14", "Ages 12+", "Family friendly", "All ages"]

    private var familyName: String {
        let name = state.child.name.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "Your family" : "\(name)’s family"
    }

    private var priceValue: Int? { Int(price.trimmingCharacters(in: .whitespaces)) }

    private var canCreate: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && (!paid || (priceValue ?? 0) > 0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hostingCard
                makeItYours
                whenAndWhere
                placeForEveryone
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background)
        .navigationTitle("Host an event")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryButton(title: "Create event", isDimmed: !canCreate, action: create)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(.bar)
        }
        .onChange(of: coverItem) { _, item in
            Task { coverData = try? await item?.loadTransferable(type: Data.self) }
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
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.pink))
    }

    private var makeItYours: some View {
        section("Make it yours") {
            labelled("Event title") {
                TextField("Nature explorers", text: $title)
                    .scaledFont(16, maxScale: 1.3)
                    .gatherField()
            }

            labelled("Category") {
                GatherSegmented(options: Event.Kind.allCases, selection: $kind) { $0.rawValue }
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

    private var coverPhotoRow: some View {
        PhotosPicker(selection: $coverItem, matching: .images) {
            HStack(spacing: 12) {
                if let coverData, let image = UIImage(data: coverData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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

            labelled(mode == .online ? "Meeting link" : "Location") {
                TextField(mode == .online ? "Link will be shared" : "Venue, then the area on a new line",
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
                Menu {
                    Picker("Age group", selection: $ages) {
                        ForEach(ageOptions, id: \.self) { Text($0).tag($0) }
                    }
                } label: {
                    HStack {
                        Text(ages)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.gatherText)
                    }
                    .scaledFont(16, maxScale: 1.3)
                    .foregroundStyle(Theme.ink)
                    .gatherField()
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
            category: "Community",
            kind: kind,
            start: begin,
            end: finish,
            host: familyName,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            mode: mode,
            ages: ages,
            about: about.trimmingCharacters(in: .whitespacesAndNewlines),
            price: paid ? priceValue : nil,
            symbol: "person.2.fill",
            coverData: coverData
        )
        state.add(event)
        dismiss()
    }
}
