import SwiftUI
import MapKit
import PhotosUI
import EventKitUI

struct EventLocationSection: View {
    let event: Event
    @Environment(AppState.self) private var state
    @State private var resolved: ResolvedEventPlace?
    @State private var loading = true

    private var mapsURL: URL {
        var components = URLComponents(string: "https://maps.apple.com")!
        components.queryItems = [URLQueryItem(name: "q", value: "\(event.location.replacingOccurrences(of: "\n", with: ", ")), \(event.locality), \(event.country)")]
        if let resolved, resolved.isVenue {
            components.queryItems?.append(URLQueryItem(name: "ll", value: "\(resolved.coordinate.latitude),\(resolved.coordinate.longitude)"))
        }
        return components.url!
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Text("Location").scaledFont(23, weight: .bold, maxScale: 1.3).foregroundStyle(Theme.ink)
                Spacer()
                Image(systemName: event.mode == .online ? "video" : "mappin.and.ellipse")
                    .font(.system(size: 24, weight: .light)).foregroundStyle(Theme.accent).accessibilityHidden(true)
            }
            if event.mode == .online {
                onlineDetails
            } else {
                Link(destination: mapsURL) {
                    ZStack {
                        if let resolved {
                            Map(initialPosition: .region(MKCoordinateRegion(center: resolved.mapCoordinate,
                                latitudinalMeters: resolved.isVenue ? 1600 : 4500, longitudinalMeters: resolved.isVenue ? 1600 : 4500))) {
                                Annotation(resolved.isVenue ? event.locationLines.title : event.locality, coordinate: resolved.mapCoordinate) {
                                    VStack(spacing: 0) {
                                        if event.registeredCount > 0 {
                                            Text("\(event.registeredCount)").font(.caption.bold()).foregroundStyle(Theme.ink)
                                                .padding(.horizontal, 8).padding(.vertical, 4).background(Theme.surface, in: Capsule())
                                        }
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.system(size: 42)).foregroundStyle(Color(hex: 0xF2A070), .white)
                                    }
                                }
                            }
                            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .including([.park, .school, .library])))
                            .mapControlVisibility(.hidden).allowsHitTesting(false)
                        } else {
                            Theme.field
                            VStack(spacing: 12) {
                                if loading { ProgressView() }
                                Image(systemName: "map").font(.system(size: 34, weight: .light)).foregroundStyle(Theme.accent)
                                Text(loading ? "Finding the event location…" : "Open location in Maps")
                                    .font(.subheadline).foregroundStyle(Theme.secondary)
                            }
                        }
                    }
                    .frame(height: 220).clipShape(.rect(cornerRadius: 24))
                    .contentShape(.rect(cornerRadius: 24))
                }
                .buttonStyle(.plain).accessibilityLabel("Open \(event.locationLines.title) in Maps")
                VStack(alignment: .leading, spacing: 14) {
                    Text(event.locationLines.title).scaledFont(17, weight: .semibold, maxScale: 1.3).foregroundStyle(Theme.ink)
                    HStack(alignment: .top, spacing: 14) {
                        RoundedRectangle(cornerRadius: 2).fill(Theme.ink).frame(width: 3)
                        VStack(alignment: .leading, spacing: 7) {
                            Text(event.addressDetailText)
                            if let resolved, !resolved.isVenue {
                                Text("The map shows the event area. Use the venue address above for your visit.")
                            }
                        }
                        .scaledFont(15, maxScale: 1.35).foregroundStyle(Theme.secondary).lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    }.fixedSize(horizontal: false, vertical: true)
                    Link("Open in Maps", destination: mapsURL).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.accent)
                }
            }
        }
        .padding(.top, 8)
        .task(id: event.storageKey) {
            loading = true
            resolved = await state.eventLocations.resolve(event)
            loading = false
        }
        .accessibilityIdentifier("event.location")
    }

    private var onlineDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Online event", systemImage: "video.fill").font(.headline).foregroundStyle(Theme.ink)
            if event.isRegistered, let url = URL(string: event.location), ["https", "http"].contains(url.scheme?.lowercased() ?? "") {
                Link("Join online event", destination: url).foregroundStyle(Theme.accent)
            } else {
                Text("The organizer shares joining details with registered attendees.")
                    .foregroundStyle(Theme.secondary).font(.subheadline)
            }
        }
    }
}

struct EventPhotosSection: View {
    let event: Event
    @Environment(AppState.self) private var state
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var preview: PickedImage?
    @State private var errorMessage: String?
    private var photos: [PickedImage] { state.events.first { $0.id == event.id }?.photos ?? event.photos }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Text("Photos").scaledFont(23, weight: .bold, maxScale: 1.3).foregroundStyle(Theme.ink)
                Spacer()
                if !photos.isEmpty {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Image(systemName: "plus").frame(width: 44, height: 44)
                    }.foregroundStyle(Theme.accent).accessibilityLabel("Add an event photo")
                }
            }
            if photos.isEmpty {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack(spacing: 18) {
                        Image(systemName: "camera").font(.system(size: 26, weight: .light))
                        Text("Be the first one to share a photo from this event!")
                            .scaledFont(15, maxScale: 1.35).multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(Theme.secondary).padding(22).frame(maxWidth: .infinity, minHeight: 100)
                    .overlay(RoundedRectangle(cornerRadius: 23).strokeBorder(Theme.cardBorder, style: StrokeStyle(lineWidth: 1.2, dash: [9, 7])))
                }.buttonStyle(.plain)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(photos) { photo in
                            Button { preview = photo } label: {
                                photo.image.resizable().scaledToFill().frame(width: 150, height: 115)
                                    .clipShape(.rect(cornerRadius: 18))
                            }.buttonStyle(.plain).accessibilityLabel("View event photo")
                        }
                    }
                }.scrollIndicators(.hidden)
            }
            if let errorMessage { Text(errorMessage).font(.caption).foregroundStyle(Theme.secondary) }
        }
        .padding(.top, 12)
        .task(id: selectedPhoto) {
            guard let selectedPhoto else { return }
            do {
                guard let image = try await selectedPhoto.loadTransferable(type: Image.self) else {
                    errorMessage = "This photo couldn’t be loaded. Try another image."
                    return
                }
                guard !Task.isCancelled, let index = state.events.firstIndex(where: { $0.id == event.id }) else { return }
                state.events[index].photos.append(PickedImage(image: image))
                errorMessage = nil
            } catch { errorMessage = "This photo couldn’t be loaded. Try another image." }
        }
        .fullScreenCover(item: $preview) { photo in
            NavigationStack {
                photo.image.resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.background).navigationTitle("Event photo").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { preview = nil } } }
            }
        }
    }
}

/// EventKit's system editor lets the family choose a calendar and confirm the save.
struct EventCalendarSheet: UIViewControllerRepresentable {
    let event: Event
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator { dismiss() } }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        let store = EKEventStore()
        controller.eventStore = store
        let calendarEvent = EKEvent(eventStore: store)
        calendarEvent.title = event.title
        calendarEvent.startDate = event.start
        calendarEvent.endDate = event.end
        calendarEvent.location = event.location.replacingOccurrences(of: "\n", with: ", ")
        calendarEvent.notes = "\(event.about)\nHosted by \(event.host)."
        controller.event = calendarEvent
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: EKEventEditViewController, context: Context) {}

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let onFinish: () -> Void
        init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) { onFinish() }
    }
}
