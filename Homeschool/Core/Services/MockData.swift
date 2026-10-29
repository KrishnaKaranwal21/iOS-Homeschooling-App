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
              parentPresence: .required,
              about: "Build small routines that stick. A relaxed, hands-on morning of habit games and a simple plan to try at home.",
              price: 200, symbol: "repeat", coverName: "cover-habit"),
        Event(title: "Little Scientists' Lab", category: "Science", kind: .workshop,
              start: date(11, 14, 10), end: date(11, 14, 12),
              host: "Curious Minds Club", hostRole: "Workshop host",
              location: "Community hall\nPotheri",
              ages: "Ages 6–10",
              parentPresence: .optional,
              about: "Big discoveries for little explorers. Simple experiments you can repeat at home.",
              symbol: "flask", coverName: "cover-science"),
        Event(title: "Clay & create", category: "Art", kind: .workshop,
              start: date(11, 8, 11), end: date(11, 8, 13),
              host: "Makers Circle", hostRole: "Workshop host",
              location: "Studio 4\nPotheri",
              ages: "Ages 12+",
              parentPresence: .dropOffOnly,
              about: "Shape, press and paint your own clay pieces. All materials are provided.",
              price: 350, symbol: "paintpalette", coverName: "cover-clay"),
        Event(title: "Nature explorers", category: "Nature", kind: .gathering,
              start: date(11, 12, 9), end: date(11, 12, 11),
              host: "Green Trails Club", hostRole: "Parent host",
              location: "Riverside Park\nPotheri",
              ages: "Family friendly",
              parentPresence: .required,
              about: "Join us for a fun walk. Bring along your necessary items, as it can get adventurous.",
              symbol: "leaf", coverName: "cover-nature"),
        Event(title: "Little Coders Meetup", category: "Coding", kind: .gathering,
              start: date(11, 21, 16), end: date(11, 21, 17, 30),
              host: "Code Kids Chennai", hostRole: "Parent host", locality: "Guduvanchery",
              location: "Library room 2\nGuduvanchery",
              ages: "Ages 10+",
              parentPresence: .dropOffOnly,
              about: "Show what you are building, swap ideas and try a new puzzle together.",
              symbol: "chevron.left.forwardslash.chevron.right", coverName: "cover-coding"),
        // Hosted by the signed-in parent, with questions from families (two still waiting for an answer).
        Event(title: "Backyard Bird Watch", category: "Nature", kind: .gathering,
              start: date(11, 15, 7, 30), end: date(11, 15, 9),
              host: "Asha Patel", hostRole: "Parent host",
              location: "Lake View Park\nPotheri",
              ages: "Ages 6–12",
              parentPresence: .required,
              about: "An early-morning walk to spot and sketch local birds. We share binoculars and a simple bird checklist.",
              faqs: [
                EventFAQ(question: "What should we bring?",
                         answer: "Water, a hat and a notebook. Binoculars are shared, but bring your own if you have a pair."),
                EventFAQ(question: "What if it rains?",
                         answer: "We move to the community hall next door and look at bird photos and nests instead.")
              ],
              symbol: "leaf", isHostedByMe: true, registeredCount: 6,
              questions: [
                EventQuestion(asker: "Sara Patel", text: "Is the walk suitable for a 5 year old?",
                              date: Date.now.addingTimeInterval(-3_600)),
                EventQuestion(asker: "Daniel", text: "Is there parking near the park entrance?",
                              date: Date.now.addingTimeInterval(-26 * 3_600)),
                EventQuestion(asker: "Meera", text: "Do we need to register siblings separately?",
                              date: Date.now.addingTimeInterval(-3 * 86_400),
                              answer: "No, one registration covers siblings. Just add their names in the notes.")
              ])
    ]

    private static func date(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute)) ?? .now
    }
    static let parents = [
        Parent(name: "Sara Patel", role: "Mum to Arya, 13", tags: "Space · Creative play", distanceKm: 0.8,
               about: "Finding our rhythm with art and outdoor days.",
               bio: "We love following Arya’s big space questions and turning everyday things into creative play. We’d love to meet other curious families.",
               children: [ParentChild(name: "Arya", age: 13, level: "Level A")],
               interests: ["Space", "Reading", "Art", "Nature"],
               lookingFor: ["Learning groups", "Weekend outings"],
               note: "New here, too."),
        Parent(name: "Daniel", role: "Dad to Leo, 11", tags: "Nature · Little inventors", distanceKm: 1.4,
               about: "Happy to swap ideas for calmer learning days.",
               bio: "Weekend tinkerers and trail walkers. Leo builds something new every week and we like sharing what works.",
               children: [ParentChild(name: "Leo", age: 11, level: "Level A")],
               interests: ["Coding", "Nature", "Sports"],
               lookingFor: ["Swapping ideas", "Weekend outings"],
               note: "Happy to share."),
        Parent(name: "Preeti", role: "Mum to Ananya, 8 & Ankit, 5", tags: "Stories · Outdoor play", distanceKm: 2.9,
               about: "Stories, park days and learning with friends.",
               bio: "Story-time lovers. We spend a lot of time in the park and would like regular meet-ups for the kids.",
               children: [ParentChild(name: "Ananya", age: 8, level: "Level A"),
                          ParentChild(name: "Ankit", age: 5, level: "Foundation")],
               interests: ["Reading", "Animals", "Music"],
               lookingFor: ["Playdates", "Learning groups"],
               note: "Let’s learn together."),
        Parent(name: "Sneha", role: "Mum to Noah, 7", tags: "Space · Arts & crafts", distanceKm: 4.2,
               about: "Arts, crafts and stargazing on clear nights.",
               bio: "Arts, crafts and stargazing. Noah asks a new question about the sky every evening.",
               children: [ParentChild(name: "Noah", age: 7, level: "Foundation")],
               interests: ["Space", "Art"],
               lookingFor: ["Playdates", "Weekend outings"],
               note: "Say hi!")
    ]

    static let notifications = [
        AppNotification(symbol: "person.badge.plus", title: "New parent nearby",
                        detail: "Sneha joined about 4 km from you.", time: "Today", isNew: true),
        AppNotification(symbol: "bubble.left.and.text.bubble.right", title: "A host answered your question",
                        detail: "Your question about the clay workshop has an answer.", time: "Yesterday", isNew: true),
        AppNotification(symbol: "calendar", title: "Gathering reminder",
                        detail: "Your next gathering is coming up this week.", time: "2 days ago"),
        AppNotification(symbol: "checkmark.shield", title: "Your location stays private",
                        detail: "Families only see an approximate distance.", time: "Last week")
    ]
    static let roadmap = [
        RoadmapStep(id: 1, title: "Understand homeschooling", detail: "Learn how it works and your role.", symbol: "book"),
        RoadmapStep(id: 2, title: "Explore boards and learning pathways", detail: "Compare routes for your child's goals.", symbol: "signpost.right"),
        RoadmapStep(id: 3, title: "Understand admissions and assessments", detail: "Eligibility, subjects and key deadlines.", symbol: "graduationcap"),
        RoadmapStep(id: 4, title: "Build your child's learning plan", detail: "Find a routine that fits your family's time.", symbol: "calendar")
    ]
}
