import SwiftUI
import UniformTypeIdentifiers

// MARK: - BookingTicketView

/// Full-screen booking ticket with its QR code, plus saving it as an image or sharing it.
struct BookingTicketView: View {
    let event: Event
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var qrImage: Image?
    @State private var ticketData: Data?
    @State private var showDownload = false
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
        .scrollBlurHeader { header }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if registration != nil && current.isRegistered { exportActions }
        }
        .task(id: registration?.id) {
            guard let registration, current.isRegistered else { return }
            prepareTicket(registration)
        }
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
                    Image(systemName: "xmark").scaledFont(17, weight: .regular)
                        .foregroundStyle(Theme.ink).frame(width: 44, height: 44).gatherGlass(in: Circle())
                }.buttonStyle(.plain).accessibilityLabel("Close ticket")
                Spacer()
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
    }

    private func ticket(_ booking: Registration) -> some View {
        BookingTicketCard(event: current, registration: booking, qrImage: qrImage)
    }

    private var exportActions: some View {
        HStack(spacing: 12) {
            ShareLink(item: TicketImage(data: ticketData ?? Data()), preview: SharePreview(exportName)) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(Theme.ink).background(Theme.field, in: Capsule())
            }
            .accessibilityIdentifier("ticket.share")
            Button { showDownload = true } label: {
                Label("Download", systemImage: "arrow.down.to.line")
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(Color(hex: 0xFFFFFF))
                    .background(Color(hex: 0x333238), in: Capsule())
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
            qrImage = Image(decorative: qr, scale: 1)
            let renderer = ImageRenderer(content: ticket(booking)
                .frame(width: 390).padding(20).background(Theme.background)
                .environment(\.colorScheme, .light).environment(\.dynamicTypeSize, .large))
            renderer.scale = 3
            guard let data = renderer.uiImage?.pngData() else { throw TicketExportError.renderFailed }
            ticketData = data
        } catch { errorMessage = "The ticket couldn’t be prepared. Please try again." }
    }
}

// MARK: - TicketExportError

/// Why exporting a ticket image failed.
enum TicketExportError: Error { case renderFailed }

// MARK: - TicketImageDocument

/// A PNG of the ticket, used by the system file exporter.
struct TicketImageDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.png] }
    let data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

// MARK: - TicketImage

/// A PNG of the ticket that `ShareLink` hands to the system share sheet.
struct TicketImage: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { $0.data }
    }
}
