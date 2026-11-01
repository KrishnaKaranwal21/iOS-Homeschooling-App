import Foundation
import CryptoKit
import CoreImage.CIFilterBuiltins

/// An event-specific booking identifier, without contact details or child information.
/// A check-in service must validate this against its booking records before admitting someone.
struct BookingCode: Codable, Equatable {
    let type: String
    let version: Int
    let event: String
    let booking: UUID
    let reference: String

    init(event: Event, registration: Registration) {
        type = "homeschool.booking"
        version = 1
        self.event = SHA256.hash(data: Data(event.storageKey.utf8)).map { String(format: "%02x", $0) }.joined()
        booking = registration.id
        reference = registration.code
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }

    static func image(for data: Data) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "Q"
        guard let output = filter.outputImage else { return nil }
        // Keep a clean quiet zone, square modules and integer scaling for reliable scanning.
        let bordered = output.composited(over: CIImage(color: .white).cropped(to: output.extent.insetBy(dx: -4, dy: -4)))
        let scaled = bordered.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        return CIContext().createCGImage(scaled, from: scaled.extent)
    }
}
