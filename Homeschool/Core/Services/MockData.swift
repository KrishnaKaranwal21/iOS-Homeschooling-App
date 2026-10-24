import Foundation

enum MockData {
    static let tasks = [
        TaskItem(subject: "Maths", title: "Lets learn about Factorization"),
        TaskItem(subject: "English", title: "Adverbs the essentials"),
        TaskItem(subject: "Science", title: "Understand forces and motion"),
        TaskItem(subject: "Art", title: "Different types of artists and their forms", isDone: true),
        TaskItem(subject: "English", title: "Write a diary entry describing your first day", isDone: true),
        TaskItem(subject: "Science", title: "Create a food chain using five organisms.", isDone: true)
    ]
    static let events: [Event] = [
        Event(title: "Habit Training", category: "Habit", kind: .workshop,
              start: date(11, 7, 10), end: date(11, 7, 11, 30),
              host: "Sunita Chauhan", hostRole: "Workshop host",
              location: "Potheri Community Hall\nSRM Nagar, Potheri",
              ages: "Ages 8–14",
              about: "Build small routines that stick. A relaxed, hands-on morning of habit games and a simple plan to try at home.",
              price: 200, symbol: "repeat", coverName: "cover-habit", isRegistered: true),
        Event(title: "Little Scientists' Lab", category: "Science", kind: .workshop,
              start: date(11, 14, 10), end: date(11, 14, 12),
              host: "Curious Minds Club", hostRole: "Workshop host",
              location: "Community hall\nPotheri",
              ages: "Ages 6–10",
              about: "Big discoveries for little explorers. Simple experiments you can repeat at home.",
              symbol: "flask", coverName: "cover-science", isRegistered: true),
        Event(title: "Clay & create", category: "Art", kind: .workshop,
              start: date(11, 8, 11), end: date(11, 8, 13),
              host: "Makers Circle", hostRole: "Workshop host",
              location: "Studio 4\nPotheri",
              ages: "Ages 12+",
              about: "Shape, press and paint your own clay pieces. All materials are provided.",
              price: 350, symbol: "paintpalette", coverName: "cover-clay"),
        Event(title: "Nature explorers", category: "Nature", kind: .gathering,
              start: date(11, 12, 9), end: date(11, 12, 11),
              host: "Green Trails Club", hostRole: "Parent host",
              location: "Riverside Park\nPotheri",
              ages: "Family friendly",
              about: "Join us for a fun walk. Bring along your necessary items, as it can get adventurous.",
              symbol: "leaf", coverName: "cover-nature"),
        Event(title: "Little Coders Meetup", category: "Coding", kind: .gathering,
              start: date(11, 21, 16), end: date(11, 21, 17, 30),
              host: "Code Kids Chennai", hostRole: "Parent host", locality: "Guduvanchery",
              location: "Library room 2\nGuduvanchery",
              ages: "Ages 10+",
              about: "Show what you are building, swap ideas and try a new puzzle together.",
              symbol: "chevron.left.forwardslash.chevron.right", coverName: "cover-coding")
    ]

    private static func date(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute)) ?? .now
    }
    static let parents = [
        Parent(name: "Sara Patel", role: "Mum to Arya, 13", tags: "Space · Creative play", distanceKm: 0.8, about: "We love following Arya's big space questions and turning everyday things into creative play."),
        Parent(name: "Daniel", role: "Dad to Leo, 11", tags: "Nature · Little inventors", distanceKm: 1.4, about: "Weekend tinkerers and trail walkers."),
        Parent(name: "Preeti", role: "Mum to Ananya, 8 & Ankit, 5", tags: "Stories · Outdoor play", distanceKm: 2.6, about: "Story-time lovers."),
        Parent(name: "Sneha", role: "Mum to Noah, 7", tags: "Space · Arts & crafts", distanceKm: 4.2, about: "Arts, crafts and stargazing.")
    ]
    static let threads = [
        ChatThread(title: "Sara Patel", preview: "Shall we meet by the café at 10?", time: "9:36", unread: 2),
        ChatThread(title: "Oakwood homeschool circle", preview: "Emma: I'll bring the picnic blanket!", time: "9:24", unread: 5, isGroup: true),
        ChatThread(title: "Curious Minds Club", preview: "Leo: The moon experiment was a hit", time: "8:58", unread: 3, isGroup: true),
        ChatThread(title: "James Wilson", preview: "Thanks! Noah can't wait to join you.", time: "8:12"),
        ChatThread(title: "The Friday families", preview: "You: See you all next week!", time: "Thu", isGroup: true)
    ]
    static let messages = [
        Message(text: "Hi Sara! I'm Asha. I spotted your profile in the homeschooling community and thought I'd say hello.", time: "9:41", isMine: true),
        Message(text: "Hi Asha! Nice to meet you. Homeschooling can feel quiet sometimes, so it's great to connect with someone local.", time: "9:43", isMine: false),
        Message(text: "Exactly! We just moved here. Do you have a favorite park or meetup spot nearby?", time: "9:45", isMine: true),
        Message(text: "We love the library on Fridays and the nature walk by the creek on Wednesdays.", time: "9:47", isMine: false)
    ]
    static let roadmap = [
        RoadmapStep(id: 1, title: "Understand homeschooling", detail: "Learn how it works and your role.", symbol: "book"),
        RoadmapStep(id: 2, title: "Explore boards and learning pathways", detail: "Compare routes for your child's goals.", symbol: "signpost.right"),
        RoadmapStep(id: 3, title: "Understand admissions and assessments", detail: "Eligibility, subjects and key deadlines.", symbol: "graduationcap"),
        RoadmapStep(id: 4, title: "Build your child's learning plan", detail: "Find a routine that fits your family's time.", symbol: "calendar")
    ]
}
