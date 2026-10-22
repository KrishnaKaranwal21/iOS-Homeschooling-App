import SwiftUI

struct HostEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var about = ""
    @State private var category = "Gathering"
    @State private var date = Date.now
    @State private var starts = Date.now
    @State private var ends = Date.now.addingTimeInterval(7200)
    @State private var online = false
    @State private var location = ""
    @State private var ageGroup = "Ages 8–14"
    @State private var paid = false

    var body: some View {
        Form {
            Section("Make it yours") {
                TextField("Event title", text: $title)
                Picker("Category", selection: $category) { Text("Gathering").tag("Gathering"); Text("Workshop").tag("Workshop") }.pickerStyle(.segmented)
                TextField("A little about your event", text: $about, axis: .vertical).lineLimit(3...6)
            }
            Section("When & where") {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                DatePicker("Starts", selection: $starts, displayedComponents: .hourAndMinute)
                DatePicker("Ends", selection: $ends, displayedComponents: .hourAndMinute)
                Picker("How we'll meet", selection: $online) { Text("In person").tag(false); Text("Online").tag(true) }.pickerStyle(.segmented)
                TextField(online ? "Link will be shared" : "Location", text: $location)
            }
            Section("A place for everyone") {
                Picker("Age group", selection: $ageGroup) { ForEach(["Ages 4–7", "Ages 8–14", "All ages"], id: \.self, content: Text.init) }
                Picker("Pricing", selection: $paid) { Text("Free").tag(false); Text("Paid").tag(true) }.pickerStyle(.segmented)
            }
            Section { Button("Create event") { dismiss() }.disabled(title.isEmpty) }
        }
        .navigationTitle("Host an event").navigationBarTitleDisplayMode(.inline)
    }
}
