import SwiftUI

/// The torso rests behind the card's top edge while the paws overlap its front.
struct HomeMascotIllustration: View {
    static let cardEdge: CGFloat = 0.86

    var body: some View {
        Image("HomeMascot")
            .resizable()
            .scaledToFit()
            .background {
                GeometryReader { geometry in
                    let size = geometry.size
                    // Small contact shadows sit directly beneath the paws, rather than surrounding the head.
                    Ellipse().fill(Color.black.opacity(0.14))
                        .frame(width: size.width * 0.19, height: 2.5)
                        .blur(radius: 1.5)
                        .position(x: size.width * 0.13, y: size.height * 0.915)
                    Ellipse().fill(Color.black.opacity(0.14))
                        .frame(width: size.width * 0.18, height: 2.5)
                        .blur(radius: 1.5)
                        .position(x: size.width * 0.64, y: size.height * 0.99)
                }
            }
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }
}
