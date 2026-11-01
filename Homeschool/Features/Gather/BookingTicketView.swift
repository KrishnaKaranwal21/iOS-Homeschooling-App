import SwiftUI
import UniformTypeIdentifiers

struct BookingTicketView: View {
    let event: Event
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var qrImage: UIImage?
    @State private var ticketData: Data?
    @State private var showDownload = false
    @State private var shareFile: TicketShareFile?
    @State private var errorMessage: String?
    @State private var savedNotice = false

    private var current: Event { state.events.first { $0.id == event.id } ?? event }
    private var registration: Registration? { state.registrations[event.id] }
    private var exportName: String { "HomeSchool-Ticket-\(registration?.code ?? "booking")" }

    var body: some View {
        ScrollView {
            if let registration, current.isRegistered {
                VStack(spacing: 28) {
                    ticket(registration)
                    Text("Show this ticket to the organizer at check-in.")
                        .scaledFont(13, maxScale: 1.35).foregroundStyle(Theme.secondary)
                        .multilineTextAlignment(.center)
                    if let errorMessage {
                        Text(errorMessage).font(.subheadline).foregroundStyle(Theme.secondary)
                        Button("Try again") { prepareTicket(registration) }.tint(Theme.accent)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 40).padding(.bottom, 30)
                .frame(maxWidth: 560).frame(maxWidth: .infinity)
            } else {
                ContentUnavailableView("No active booking", systemImage: "ticket",
                    description: Text("Register for this event to get your booking ticket."))
                    .padding(.top, 60)
            }
        }
        .background {
            LinearGradient(colors: [Theme.field, Theme.background, Theme.background], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        }
        .safeAreaInset(edge: .top, spacing: 0) { header }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if registration != nil && current.isRegistered { exportActions }
        }
        .task(id: registration?.id) {
            guard let registration, current.isRegistered else { return }
            prepareTicket(registration)
        }
        .sheet(item: $shareFile) { item in TicketShareSheet(url: item.url) }
        .fileExporter(isPresented: $showDownload, document: TicketImageDocument(data: ticketData ?? Data()),
            contentType: .png, defaultFilename: exportName) { result in
                switch result {
                case .success: savedNotice = true
                case .failure(let error):
                    if (error as NSError).code != NSUserCancelledError { errorMessage = "The ticket couldn’t be saved. Please try again." }
                }
            }
        .alert("Ticket saved", isPresented: $savedNotice) {
            Button("OK", role: .cancel) {}
        } message: { Text("Your ticket image is ready to use offline.") }
        .toolbarVisibility(.hidden, for: .navigationBar)
    }

    private var header: some View {
        ZStack {
            Text("Ticket").scaledFont(18, weight: .bold, maxScale: 1.3).foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Theme.ink).frame(width: 44, height: 44).gatherGlass(in: Circle())
                }.buttonStyle(.plain).accessibilityLabel("Close ticket")
                Spacer()
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(Theme.field.opacity(0.95))
    }

    private func ticket(_ booking: Registration) -> some View {
        BookingTicketCard(event: current, registration: booking, qrImage: qrImage)
    }

    private var exportActions: some View {
        HStack(spacing: 12) {
            Button(action: shareTicket) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(Theme.ink).background(Theme.field, in: Capsule())
            }
            .accessibilityIdentifier("ticket.share")
            Button { showDownload = true } label: {
                Label("Download", systemImage: "arrow.down.to.line")
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(Color.adaptive(0xFFFFFF, 0x171719))
                    .background(Color.adaptive(0x333238, 0xF1F0F4), in: Capsule())
            }
            .accessibilityIdentifier("ticket.download")
        }
        .scaledFont(15, weight: .semibold, maxScale: 1.3).buttonStyle(.plain)
        .disabled(ticketData == nil)
        .opacity(ticketData == nil ? 0.5 : 1)
        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 16)
        .background(Theme.background.opacity(0.95))
    }

    @MainActor private func prepareTicket(_ booking: Registration) {
        ticketData = nil
        errorMessage = nil
        do {
            let payload = try BookingCode(event: current, registration: booking).encoded()
            guard let qr = BookingCode.image(for: payload) else { throw TicketExportError.renderFailed }
            qrImage = UIImage(cgImage: qr)
            let renderer = ImageRenderer(content: ticket(booking)
                .frame(width: 390).padding(20).background(Color(hex: 0x101012))
                .environment(\.colorScheme, .dark).environment(\.dynamicTypeSize, .large))
            renderer.scale = 3
            guard let data = renderer.uiImage?.pngData() else { throw TicketExportError.renderFailed }
            ticketData = data
        } catch { errorMessage = "The ticket couldn’t be prepared. Please try again." }
    }

    private func shareTicket() {
        guard let ticketData, let registration else { return }
        do {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent("BookingTickets", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent("\(exportName)-\(registration.id.uuidString).png")
            try ticketData.write(to: url, options: .atomic)
            shareFile = TicketShareFile(url: url)
        } catch { errorMessage = "The ticket couldn’t be shared. Please try again." }
    }
}

private enum TicketExportError: Error { case renderFailed }

struct BookingTicketCard: View {
    let event: Event
    let registration: Registration
    let qrImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Group {
                if let qrImage {
                    Image(uiImage: qrImage).interpolation(.none).resizable().scaledToFit()
                        .accessibilityLabel("Booking QR code. Reference \(registration.code)")
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityLabel("Preparing booking QR code")
                }
            }
            .frame(maxWidth: 184).aspectRatio(1, contentMode: .fit).padding(8).background(.white, in: .rect(cornerRadius: 10))
            .frame(maxWidth: .infinity).padding(.top, 40).padding(.bottom, 8)

            DashedLine(vertical: false).stroke(Theme.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
                .frame(height: 1).padding(.vertical, 4)
            VStack(alignment: .leading, spacing: 7) {
                Text(event.title).scaledFont(19, weight: .bold, maxScale: 1.35).foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(event.mode == .online ? "Online event" : event.locationLines.title)
                    .scaledFont(14, maxScale: 1.35).foregroundStyle(Theme.secondary)
            }
            VStack(spacing: 12) {
                detail("Name", registration.registrant.parentName)
                detail("Group", event.host)
                detail("Date", event.start.formatted(.dateTime.day().month(.abbreviated).year()))
                detail("Time", event.timeWithZone)
                detail(registration.places == 1 ? "Learner" : "Learners", registration.registrant.childName)
                if registration.places > 1 { detail("Places", String(registration.places)) }
                detail("Booking", registration.code)
            }
            .padding(.top, 3)
        }
        .padding(.horizontal, 22).padding(.bottom, 30)
        .background(Theme.surface, in: TicketNotchShape())
        .overlay { TicketNotchShape().stroke(Theme.cardBorder.opacity(0.35), lineWidth: 0.5) }
        .accessibilityIdentifier("ticket.booking")
    }

    private func detail(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(label).foregroundStyle(Theme.secondary).frame(width: 65, alignment: .leading)
            Text(value.isEmpty ? "—" : value).foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .trailing).multilineTextAlignment(.trailing)
        }
        .scaledFont(13, maxScale: 1.35).fixedSize(horizontal: false, vertical: true)
    }
}

private struct TicketNotchShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 20
        let notch: CGFloat = 32
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX - notch, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.midX, y: rect.minY), radius: notch, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

private struct TicketImageDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.png] }
    let data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

private struct TicketShareFile: Identifiable {
    let id = UUID()
    let url: URL
}

private struct TicketShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in try? FileManager.default.removeItem(at: url) }
        return controller
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
