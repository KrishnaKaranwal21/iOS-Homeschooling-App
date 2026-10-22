import SwiftUI

struct EventDetailView: View {
    let event: Event
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: Theme.Radius.card).fill(Theme.lime).frame(height: 180)
                    VStack(alignment: .leading) { Text(event.title).font(.title.bold()); Label("\(event.day) \(event.month) · \(event.time)", systemImage: "calendar"); Label(event.place, systemImage: "mappin"); Label("Ages \(event.ages)", systemImage: "person.2") }.padding()
                }
                Text("Big discoveries for little explorers").font(.title3.bold())
                HStack { Chip(title: "90-minute walk"); Chip(title: "Free to join") }
                Label("Hosted by \(event.host)", systemImage: "leaf")
                Card(color: Theme.pink) { Label("A parent or guardian must stay with their child throughout the gathering.", systemImage: "person.fill.checkmark").font(.footnote) }
                NavigationLink { RegistrationView(event: event) } label: {
                    Text("Register").font(.headline).frame(maxWidth: .infinity, minHeight: 56).foregroundStyle(.white).background(Theme.ink, in: Capsule())
                }
            }.padding()
        }.background(Theme.background).navigationTitle("About the event").navigationBarTitleDisplayMode(.inline)
    }
}
