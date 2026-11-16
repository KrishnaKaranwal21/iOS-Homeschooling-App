import Foundation
import Vision
import XCTest
@testable import Homeschool

/// The QR payload of a booking ticket: what it contains, what it must never contain, and that it stays stable.
@MainActor
final class BookingTicketTests: XCTestCase {
    func testBookingPayload() throws {
        let event = Event(title: "Family science morning", category: "Science", start: Date(timeIntervalSince1970: 1_800_000_000),
            end: Date(timeIntervalSince1970: 1_800_007_200), host: "Science Club", location: "Community Hall",
            ages: "Ages 6–10", about: "Experiments", symbol: "flask")
        let registrant = Registrant(parentName: "Sample Parent", email: "private@example.com", mobile: "1234567890",
            childName: "Sample Learner", childAge: "8", notes: "Private support information")
        let booking = Registration(eventID: event.id, registrant: registrant, registeredAt: .now, places: 2)
        let payload = try BookingCode(event: event, registration: booking).encoded()
        let code = try JSONDecoder().decode(BookingCode.self, from: payload)
        expect(code.booking == booking.id && code.reference == booking.code, "QR identifies the full booking")
        expect(code.type == "homeschool.booking" && code.version == 1, "Payload has a versioned namespace")
        expect(try BookingCode(event: event, registration: booking).encoded() == payload, "Repeated views keep the same QR")
        let otherBooking = Registration(eventID: event.id, registrant: registrant, registeredAt: .now)
        expect(BookingCode(event: event, registration: otherBooking).booking != code.booking, "Different bookings have different codes")
        var otherEvent = event
        otherEvent.start.addTimeInterval(86_400)
        expect(BookingCode(event: otherEvent, registration: booking).event != code.event, "Different event dates have different identities")
        let copy = Event(title: event.title, category: event.category, start: event.start, end: event.end,
            host: event.host, location: event.location, ages: event.ages, about: event.about, symbol: event.symbol)
        let saved = try JSONEncoder().encode(booking)
        let restored = try JSONDecoder().decode(Registration.self, from: saved).forEvent(copy.id)
        expect(restored.id == booking.id && restored.eventID == copy.id, "Restoration keeps the booking ID while remapping the catalog UUID")
        expect(try BookingCode(event: copy, registration: restored).encoded() == payload, "QR remains stable after restarting the catalog")
        expect(restored.places == 2 && restored.registrant == registrant, "Registration details survive persistence")
        let text = String(decoding: payload, as: UTF8.self)
        for privateValue in [registrant.parentName, registrant.email, registrant.mobile, registrant.childName, registrant.notes] {
            expect(!text.contains(privateValue), "QR excludes personal information")
        }
    }

    /// Renders the QR and reads it back with Vision. Vision's barcode model needs a real device or macOS, so the
    /// simulator skips it.
    func testGeneratedQRCanBeScanned() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Vision barcode inference is unavailable in the iOS simulator; run on a device.")
        #else
        let event = Event(title: "Family science morning", category: "Science", start: Date(timeIntervalSince1970: 1_800_000_000),
            end: Date(timeIntervalSince1970: 1_800_007_200), host: "Science Club", location: "Community Hall",
            ages: "Ages 6–10", about: "Experiments", symbol: "flask")
        let registrant = Registrant(parentName: "Sample Parent", email: "private@example.com", mobile: "1234567890",
            childName: "Sample Learner", childAge: "8", notes: "Private support information")
        let booking = Registration(eventID: event.id, registrant: registrant, registeredAt: .now, places: 2)
        let payload = try BookingCode(event: event, registration: booking).encoded()
        let text = String(decoding: payload, as: UTF8.self)
        guard let image = BookingCode.image(for: payload) else { return XCTFail("QR rendering failed") }
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        try VNImageRequestHandler(cgImage: image).perform([request])
        expect(request.results?.first?.payloadStringValue == text, "A real barcode reader decodes the generated QR")
        #endif
    }
}
