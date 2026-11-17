import SwiftUI

/// A phone field with a calling-code picker for every country.
struct PhoneField: View {
    @Binding var number: String

    @State private var country: PhoneCountry = .india
    @State private var showPicker = false

    var body: some View {
        HStack(spacing: 10) {
            Button { showPicker = true } label: {
                HStack(spacing: 4) {
                    Text(country.flag)
                    Text("+\(country.dial)")
                        .foregroundStyle(Theme.ink)
                    Image(systemName: "chevron.down").accessibilityHidden(true)
                        .scaledFont(11, weight: .bold)
                        .foregroundStyle(Theme.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Country code, \(country.name) plus \(country.dial). Change")

            Rectangle().fill(Theme.ink.opacity(0.12)).frame(width: 1, height: 22)

            TextField("Mobile number", text: Binding(
                get: {
                    let digits = PhoneNumber.national(of: number)
                    return PhoneNumber.stored(country: country, digits: digits)
                        .replacingOccurrences(of: "+\(country.dial) ", with: "")
                },
                set: { number = PhoneNumber.stored(country: country, digits: $0) }))
                .textContentType(.telephoneNumber)
                .keyboardType(.numberPad)
        }
        .onAppear {
            if let found = PhoneNumber.country(of: number) { country = found }
        }
        .onChange(of: number) { _, newValue in
            if let found = PhoneNumber.country(of: newValue), found != country { country = found }
        }
        .onChange(of: country) { _, newCountry in
            // Keep the digits already typed, with the new calling code.
            let digits = PhoneNumber.national(of: number)
            number = PhoneNumber.stored(country: newCountry, digits: digits)
        }
        .sheet(isPresented: $showPicker) {
            CountryCodeSheet(selection: $country)
        }
    }
}

/// A glass pop-up with one scrolling wheel of every country, in alphabetical order. No search.
struct CountryCodeSheet: View {
    @Binding var selection: PhoneCountry
    @Environment(\.dismiss) private var dismiss
    /// What the wheel shows. The phone field changes as the wheel turns.
    @State private var draft: PhoneCountry

    init(selection: Binding<PhoneCountry>) {
        _selection = selection
        _draft = State(initialValue: selection.wrappedValue)
    }

    private static let sorted: [PhoneCountry] = PhoneCountry.all.sorted {
        $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .scaledFont(15, weight: .semibold)
                        .foregroundStyle(Theme.ink)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial, in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }

            Picker("Country code", selection: $draft) {
                ForEach(Self.sorted) { country in
                    Text("\(country.name) (+\(country.dial))")
                        .tag(country)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .onChange(of: draft) { _, new in selection = new }
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial)
        .presentationCornerRadius(36)
    }
}
