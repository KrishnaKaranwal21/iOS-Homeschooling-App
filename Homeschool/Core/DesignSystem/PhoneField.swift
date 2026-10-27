import SwiftUI

// MARK: - Countries

struct PhoneCountry: Identifiable, Hashable {
    let iso: String
    let dial: String

    var id: String { iso }

    var name: String {
        Locale.current.localizedString(forRegionCode: iso) ?? iso
    }

    /// The flag, built from the two-letter region code.
    var flag: String {
        iso.unicodeScalars.compactMap { UnicodeScalar(127_397 + $0.value) }.map { String($0) }.joined()
    }

    static let india = PhoneCountry(iso: "IN", dial: "91")

    /// Shown first in the list.
    static let popular: [PhoneCountry] = ["IN", "US", "GB", "AE", "SG", "AU", "CA"].compactMap { iso in
        all.first { $0.iso == iso }
    }

    /// Every country and territory with its calling code.
    static let all: [PhoneCountry] = [
        ("AF","93"),("AL","355"),("DZ","213"),("AS","1684"),("AD","376"),("AO","244"),("AI","1264"),
        ("AG","1268"),("AR","54"),("AM","374"),("AW","297"),("AU","61"),("AT","43"),("AZ","994"),
        ("BS","1242"),("BH","973"),("BD","880"),("BB","1246"),("BY","375"),("BE","32"),("BZ","501"),
        ("BJ","229"),("BM","1441"),("BT","975"),("BO","591"),("BA","387"),("BW","267"),("BR","55"),
        ("IO","246"),("VG","1284"),("BN","673"),("BG","359"),("BF","226"),("BI","257"),("KH","855"),
        ("CM","237"),("CA","1"),("CV","238"),("KY","1345"),("CF","236"),("TD","235"),("CL","56"),
        ("CN","86"),("CO","57"),("KM","269"),("CK","682"),("CR","506"),("HR","385"),("CU","53"),
        ("CW","599"),("CY","357"),("CZ","420"),("CD","243"),("DK","45"),("DJ","253"),("DM","1767"),
        ("DO","1809"),("EC","593"),("EG","20"),("SV","503"),("GQ","240"),("ER","291"),("EE","372"),
        ("SZ","268"),("ET","251"),("FK","500"),("FO","298"),("FJ","679"),("FI","358"),("FR","33"),
        ("GF","594"),("PF","689"),("GA","241"),("GM","220"),("GE","995"),("DE","49"),("GH","233"),
        ("GI","350"),("GR","30"),("GL","299"),("GD","1473"),("GP","590"),("GU","1671"),("GT","502"),
        ("GN","224"),("GW","245"),("GY","592"),("HT","509"),("HN","504"),("HK","852"),("HU","36"),
        ("IS","354"),("IN","91"),("ID","62"),("IR","98"),("IQ","964"),("IE","353"),("IL","972"),
        ("IT","39"),("CI","225"),("JM","1876"),("JP","81"),("JO","962"),("KZ","7"),("KE","254"),
        ("KI","686"),("XK","383"),("KW","965"),("KG","996"),("LA","856"),("LV","371"),("LB","961"),
        ("LS","266"),("LR","231"),("LY","218"),("LI","423"),("LT","370"),("LU","352"),("MO","853"),
        ("MG","261"),("MW","265"),("MY","60"),("MV","960"),("ML","223"),("MT","356"),("MH","692"),
        ("MQ","596"),("MR","222"),("MU","230"),("YT","262"),("MX","52"),("FM","691"),("MD","373"),
        ("MC","377"),("MN","976"),("ME","382"),("MS","1664"),("MA","212"),("MZ","258"),("MM","95"),
        ("NA","264"),("NR","674"),("NP","977"),("NL","31"),("NC","687"),("NZ","64"),("NI","505"),
        ("NE","227"),("NG","234"),("NU","683"),("KP","850"),("MK","389"),("MP","1670"),("NO","47"),
        ("OM","968"),("PK","92"),("PW","680"),("PS","970"),("PA","507"),("PG","675"),("PY","595"),
        ("PE","51"),("PH","63"),("PL","48"),("PT","351"),("PR","1787"),("QA","974"),("CG","242"),
        ("RE","262"),("RO","40"),("RU","7"),("RW","250"),("WS","685"),("SM","378"),("ST","239"),
        ("SA","966"),("SN","221"),("RS","381"),("SC","248"),("SL","232"),("SG","65"),("SX","1721"),
        ("SK","421"),("SI","386"),("SB","677"),("SO","252"),("ZA","27"),("KR","82"),("SS","211"),
        ("ES","34"),("LK","94"),("SD","249"),("SR","597"),("SE","46"),("CH","41"),("SY","963"),
        ("TW","886"),("TJ","992"),("TZ","255"),("TH","66"),("TL","670"),("TG","228"),("TK","690"),
        ("TO","676"),("TT","1868"),("TN","216"),("TR","90"),("TM","993"),("TC","1649"),("TV","688"),
        ("UG","256"),("UA","380"),("AE","971"),("GB","44"),("US","1"),("UY","598"),("UZ","998"),
        ("VU","678"),("VA","379"),("VE","58"),("VN","84"),("VI","1340"),("WF","681"),("YE","967"),
        ("ZM","260"),("ZW","263")
    ].map { PhoneCountry(iso: $0.0, dial: $0.1) }
     .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
}

// MARK: - Stored format

/// Phone numbers are stored as "+91 98765 43210": a calling code, then the national number.
enum PhoneNumber {
    /// Countries that share a calling code, in the order they win a tie.
    private static let preferred = ["IN", "US", "GB", "RU"]

    static func country(of stored: String) -> PhoneCountry? {
        guard stored.hasPrefix("+") else { return nil }
        let digits = String(stored.dropFirst()).filter(\.isNumber)
        let matches = PhoneCountry.all.filter { digits.hasPrefix($0.dial) }
        guard let longest = matches.map(\.dial.count).max() else { return nil }
        let best = matches.filter { $0.dial.count == longest }
        return best.first { preferred.contains($0.iso) } ?? best.first
    }

    /// The digits after the calling code.
    static func national(of stored: String) -> String {
        guard let country = country(of: stored) else { return stored.filter(\.isNumber) }
        let digits = String(stored.dropFirst()).filter(\.isNumber)
        return String(digits.dropFirst(country.dial.count))
    }

    static func maxDigits(for country: PhoneCountry) -> Int {
        country.iso == "IN" ? 10 : max(4, 15 - country.dial.count)
    }

    /// "+91 98765 43210". Empty when there are no digits yet.
    static func stored(country: PhoneCountry, digits: String) -> String {
        let clean = String(digits.filter(\.isNumber).prefix(maxDigits(for: country)))
        guard !clean.isEmpty else { return "" }
        if country.iso == "IN", clean.count > 5 {
            return "+\(country.dial) \(clean.prefix(5)) \(clean.dropFirst(5))"
        }
        return "+\(country.dial) \(clean)"
    }
}

// MARK: - Field

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
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Country code, \(country.name) plus \(country.dial). Change")

            Rectangle().fill(Color.black.opacity(0.12)).frame(width: 1, height: 22)

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

struct CountryCodeSheet: View {
    @Binding var selection: PhoneCountry
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var results: [PhoneCountry] {
        PhoneCountry.all.filter {
            query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) || $0.dial.hasPrefix(query.replacingOccurrences(of: "+", with: ""))
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    Section("Popular") {
                        ForEach(PhoneCountry.popular) { row($0) }
                    }
                }
                Section(query.isEmpty ? "All countries" : "Results") {
                    ForEach(results) { row($0) }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search country or code")
            .navigationTitle("Country code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private func row(_ country: PhoneCountry) -> some View {
        Button {
            selection = country
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Text(country.flag).font(.title3)
                Text(country.name).foregroundStyle(Color.primary)
                Spacer()
                Text("+\(country.dial)").foregroundStyle(Color.secondary)
                if country == selection {
                    Image(systemName: "checkmark").foregroundStyle(Theme.tabSelected)
                }
            }
        }
    }
}
