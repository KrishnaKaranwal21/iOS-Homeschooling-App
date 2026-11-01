import SwiftUI

/// Resolution-independent artwork for the coral companion. The original peeking pose and
/// proportions are retained so it fits the existing cards without a bitmap or a hard crop.
struct HomeMascotView: View {
    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 200, y: size.height / 165)

            let coral = Gradient(stops: [
                .init(color: Color(hex: 0xFFC0A9), location: 0),
                .init(color: Color(hex: 0xF59B82), location: 0.46),
                .init(color: Color(hex: 0xDE7867), location: 1)
            ])
            let roundedSkin = Gradient(stops: [
                .init(color: Color(hex: 0xFFD5BB), location: 0),
                .init(color: Color(hex: 0xFFB297), location: 0.38),
                .init(color: Color(hex: 0xEC8C75), location: 0.76),
                .init(color: Color(hex: 0xD77562), location: 1)
            ])
            let skin = GraphicsContext.Shading.radialGradient(roundedSkin,
                center: CGPoint(x: 86, y: 65), startRadius: 0, endRadius: 98)
            let purple = GraphicsContext.Shading.linearGradient(Gradient(colors: [
                Color(hex: 0xCFB8FF), Color(hex: 0x9B7AE2), Color(hex: 0x7054B6)
            ]), startPoint: CGPoint(x: 30, y: 100), endPoint: CGPoint(x: 165, y: 154))

            // The cape is drawn first so the face and resting paws sit in front of it.
            var cape = Path()
            cape.move(to: CGPoint(x: 48, y: 97))
            cape.addCurve(to: CGPoint(x: 2, y: 122), control1: CGPoint(x: 33, y: 100), control2: CGPoint(x: 5, y: 103))
            cape.addCurve(to: CGPoint(x: 28, y: 150), control1: CGPoint(x: 12, y: 119), control2: CGPoint(x: 7, y: 146))
            cape.addCurve(to: CGPoint(x: 83, y: 151), control1: CGPoint(x: 47, y: 142), control2: CGPoint(x: 58, y: 159))
            cape.addCurve(to: CGPoint(x: 147, y: 156), control1: CGPoint(x: 108, y: 146), control2: CGPoint(x: 124, y: 164))
            cape.addCurve(to: CGPoint(x: 198, y: 127), control1: CGPoint(x: 168, y: 157), control2: CGPoint(x: 186, y: 147))
            cape.addCurve(to: CGPoint(x: 152, y: 99), control1: CGPoint(x: 183, y: 115), control2: CGPoint(x: 167, y: 102))
            cape.closeSubpath()
            context.fill(cape, with: purple)

            var fold = Path()
            fold.move(to: CGPoint(x: 37, y: 111))
            fold.addCurve(to: CGPoint(x: 19, y: 139), control1: CGPoint(x: 24, y: 119), control2: CGPoint(x: 25, y: 129))
            fold.addCurve(to: CGPoint(x: 70, y: 144), control1: CGPoint(x: 42, y: 131), control2: CGPoint(x: 47, y: 146))
            context.stroke(fold, with: .color(Color(hex: 0xE4D4FF).opacity(0.6)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            context.stroke(fold.applying(Self.mirror), with: .color(Color(hex: 0x5E419C).opacity(0.3)), style: StrokeStyle(lineWidth: 2, lineCap: .round))

            var leftTuft = Path()
            leftTuft.move(to: CGPoint(x: 96, y: 43))
            leftTuft.addCurve(to: CGPoint(x: 66, y: 15), control1: CGPoint(x: 79, y: 39), control2: CGPoint(x: 61, y: 31))
            leftTuft.addCurve(to: CGPoint(x: 94, y: 17), control1: CGPoint(x: 70, y: 1), control2: CGPoint(x: 90, y: 5))
            leftTuft.addCurve(to: CGPoint(x: 102, y: 39), control1: CGPoint(x: 99, y: 24), control2: CGPoint(x: 101, y: 31))
            leftTuft.closeSubpath()
            context.fill(leftTuft, with: .linearGradient(coral, startPoint: CGPoint(x: 69, y: 9), endPoint: CGPoint(x: 99, y: 43)))

            var rightTuft = Path()
            rightTuft.move(to: CGPoint(x: 99, y: 43))
            rightTuft.addCurve(to: CGPoint(x: 109, y: 5), control1: CGPoint(x: 94, y: 25), control2: CGPoint(x: 98, y: 10))
            rightTuft.addCurve(to: CGPoint(x: 129, y: 16), control1: CGPoint(x: 121, y: -3), control2: CGPoint(x: 134, y: 3))
            rightTuft.addCurve(to: CGPoint(x: 104, y: 43), control1: CGPoint(x: 127, y: 28), control2: CGPoint(x: 112, y: 37))
            rightTuft.closeSubpath()
            context.fill(rightTuft, with: .linearGradient(coral, startPoint: CGPoint(x: 107, y: 4), endPoint: CGPoint(x: 119, y: 39)))

            var body = Path()
            body.move(to: CGPoint(x: 43, y: 98))
            body.addCurve(to: CGPoint(x: 100, y: 38), control1: CGPoint(x: 44, y: 64), control2: CGPoint(x: 65, y: 37))
            body.addCurve(to: CGPoint(x: 168, y: 99), control1: CGPoint(x: 139, y: 34), control2: CGPoint(x: 165, y: 64))
            body.addCurve(to: CGPoint(x: 109, y: 151), control1: CGPoint(x: 174, y: 133), control2: CGPoint(x: 144, y: 151))
            body.addCurve(to: CGPoint(x: 43, y: 98), control1: CGPoint(x: 72, y: 155), control2: CGPoint(x: 39, y: 131))
            body.closeSubpath()
            var bodyContext = context
            bodyContext.addFilter(.shadow(color: Color(hex: 0x713C49).opacity(0.14), radius: 3, x: 0, y: 3))
            bodyContext.fill(body, with: skin)

            var faceLight = context
            faceLight.clip(to: body)
            faceLight.fill(body, with:
                .radialGradient(Gradient(colors: [.white.opacity(0.18), .white.opacity(0)]), center: CGPoint(x: 82, y: 58), startRadius: 0, endRadius: 60))
            for x: CGFloat in [62, 145] {
                context.fill(body, with:
                    .radialGradient(Gradient(colors: [Color(hex: 0xE9787B).opacity(0.45), Color(hex: 0xF69988).opacity(0)]),
                        center: CGPoint(x: x, y: 110), startRadius: 1, endRadius: 14))
            }

            // Small, glossy eyes keep their character even at avatar size.
            for eye in [CGRect(x: 65, y: 81, width: 11, height: 18), CGRect(x: 123, y: 82, width: 11, height: 18)] {
                context.fill(Path(ellipseIn: eye), with: .linearGradient(Gradient(colors: [Color(hex: 0x322222), Color(hex: 0x171719)]),
                    startPoint: eye.origin, endPoint: CGPoint(x: eye.midX, y: eye.maxY)))
                context.fill(Path(ellipseIn: CGRect(x: eye.minX + 2, y: eye.minY + 2, width: 3.5, height: 5)), with: .color(.white.opacity(0.95)))
                context.fill(Path(ellipseIn: CGRect(x: eye.maxX - 3.5, y: eye.maxY - 4.5, width: 1.5, height: 2)), with: .color(.white.opacity(0.3)))
            }
            var brows = Path()
            brows.move(to: CGPoint(x: 64, y: 72))
            brows.addQuadCurve(to: CGPoint(x: 72, y: 70), control: CGPoint(x: 67, y: 69))
            brows.move(to: CGPoint(x: 126, y: 71))
            brows.addQuadCurve(to: CGPoint(x: 134, y: 74), control: CGPoint(x: 131, y: 70))
            context.stroke(brows, with: .color(Color(hex: 0x51332D)), style: StrokeStyle(lineWidth: 2.3, lineCap: .round))
            var smile = Path()
            smile.move(to: CGPoint(x: 88, y: 111))
            smile.addCurve(to: CGPoint(x: 113, y: 110), control1: CGPoint(x: 93, y: 122), control2: CGPoint(x: 108, y: 122))
            context.stroke(smile, with: .color(Color(hex: 0x57362F)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

            // The paws overlap the body and cape, with soft shading and finger seams.
            var paw = Path()
            paw.move(to: CGPoint(x: 9, y: 122))
            paw.addCurve(to: CGPoint(x: 27, y: 115), control1: CGPoint(x: 8, y: 110), control2: CGPoint(x: 22, y: 108))
            paw.addCurve(to: CGPoint(x: 42, y: 115), control1: CGPoint(x: 30, y: 104), control2: CGPoint(x: 41, y: 107))
            paw.addCurve(to: CGPoint(x: 56, y: 125), control1: CGPoint(x: 51, y: 110), control2: CGPoint(x: 59, y: 117))
            paw.addCurve(to: CGPoint(x: 40, y: 143), control1: CGPoint(x: 61, y: 138), control2: CGPoint(x: 52, y: 147))
            paw.addCurve(to: CGPoint(x: 22, y: 140), control1: CGPoint(x: 34, y: 146), control2: CGPoint(x: 25, y: 144))
            paw.addCurve(to: CGPoint(x: 9, y: 122), control1: CGPoint(x: 7, y: 145), control2: CGPoint(x: 1, y: 136))
            paw.closeSubpath()
            for mirrored in [false, true] {
                let transform = mirrored ? Self.mirror : .identity
                let outline = paw.applying(transform)
                var pawContext = context
                pawContext.addFilter(.shadow(color: Color(hex: 0x7A4054).opacity(0.16), radius: 2, x: 0, y: 2))
                pawContext.fill(outline, with: .radialGradient(roundedSkin,
                    center: CGPoint(x: mirrored ? 177 : 23, y: 112), startRadius: 0, endRadius: 42))
                var seams = Path()
                seams.move(to: CGPoint(x: 27, y: 120))
                seams.addQuadCurve(to: CGPoint(x: 25, y: 131), control: CGPoint(x: 24, y: 126))
                seams.move(to: CGPoint(x: 42, y: 120))
                seams.addQuadCurve(to: CGPoint(x: 40, y: 133), control: CGPoint(x: 39, y: 126))
                context.stroke(seams.applying(transform), with: .color(Color(hex: 0xC37364).opacity(0.42)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            }

            var sparkles = Path()
            sparkles.move(to: CGPoint(x: 165, y: 49)); sparkles.addLine(to: CGPoint(x: 169, y: 38))
            sparkles.move(to: CGPoint(x: 177, y: 61)); sparkles.addLine(to: CGPoint(x: 187, y: 55))
            context.stroke(sparkles, with: .color(Color(hex: 0xB69AEF)), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
        }
        .aspectRatio(175.0 / 144.0, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private static let mirror = CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: 200, ty: 0)
}

#Preview("Native mascot") {
    VStack(spacing: 30) {
        HomeMascotView().frame(width: 280)
        HStack(spacing: 24) {
            HomeMascotView().frame(width: 64)
            HomeMascotView().frame(width: 120)
        }
    }.padding(32).background(Theme.background)
}
