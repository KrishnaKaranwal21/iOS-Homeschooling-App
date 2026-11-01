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
              about: "Build small routines that stick. A relaxed, hands-on morning of habit games and a simple plan to try at home.\n\nExplore how everyday routines can support your child’s learning. Through habit games and shared ideas, think about the small steps your family can practise together. Bring your questions and leave with a simple routine to try at home.",
              price: 200, symbol: "repeat", coverName: "cover-habit"),
        Event(title: "Little Scientists' Lab", category: "Science", kind: .workshop,
              start: date(11, 14, 10), end: date(11, 14, 12),
              host: "Curious Minds Club", hostRole: "Workshop host",
              location: "Community hall\nPotheri",
              ages: "Ages 6–10",
              parentPresence: .optional,
              about: "Big discoveries for little explorers. Join a hands-on science session built around curiosity and simple experiments you can repeat at home.\n\nEncourage your child to ask questions, notice what changes and share what they discover. The focus is on exploring ideas together and making room for the next “why?” rather than rushing to an answer.",
              symbol: "flask", coverName: "cover-science"),
        Event(title: "Clay & create", category: "Art", kind: .workshop,
              start: date(11, 8, 11), end: date(11, 8, 13),
              host: "Makers Circle", hostRole: "Workshop host",
              location: "Studio 4\nPotheri",
              ages: "Ages 12+",
              parentPresence: .dropOffOnly,
              about: "Shape, press and paint your own clay pieces in a relaxed, hands-on workshop. All materials are provided.\n\nExplore what you can make with your hands, try different shapes and give your creation its own personality. This session is a chance to experiment, enjoy the process and create something that feels like yours.",
              price: 350, symbol: "paintpalette", coverName: "cover-clay"),
        Event(title: "Nature explorers", category: "Nature", kind: .gathering,
              start: date(11, 12, 9), end: date(11, 12, 11),
              host: "Green Trails Club", hostRole: "Parent host",
              location: "Riverside Park\nPotheri",
              ages: "Family friendly",
              parentPresence: .required,
              about: "Join us for a family-friendly walk and a little time discovering the world outside. Bring along the items your family needs for a comfortable outing.\n\nSlow down, look closely and share what catches your child’s attention along the way. There is room for curious questions, small discoveries and getting to know other families while you explore together.",
              symbol: "leaf", coverName: "cover-nature"),
        Event(title: "Little Coders Meetup", category: "Coding", kind: .gathering,
              start: date(11, 21, 16), end: date(11, 21, 17, 30),
              host: "Code Kids Chennai", hostRole: "Parent host", locality: "Guduvanchery",
              location: "Library room 2\nGuduvanchery",
              ages: "Ages 10+",
              parentPresence: .dropOffOnly,
              about: "Show what you are building, swap ideas and try a new puzzle together at Little Coders Meetup. A gathering for curious learners who enjoy making things with code.\n\nBring your questions and the ideas you would like to explore. Share your approach, hear how others think through a problem and enjoy the process of building and learning alongside one another.",
              symbol: "chevron.left.forwardslash.chevron.right", coverName: "cover-coding"),
        // Hosted by the signed-in parent, with questions from families (two still waiting for an answer).
        Event(title: "Backyard Bird Watch", category: "Nature", kind: .gathering,
              start: date(11, 15, 7, 30), end: date(11, 15, 9),
              host: "Asha Patel", hostRole: "Parent host",
              location: "Lake View Park\nPotheri",
              ages: "Ages 6–12",
              parentPresence: .required,
              about: "An early-morning walk to spot and sketch local birds. We share binoculars and a simple bird checklist.\n\nTake your time observing the birds around you and recording what you notice in your notebook. Families can compare discoveries, ask questions and enjoy a gentle start to the day outdoors. Check the FAQs below for what to bring and the rainy-day plan.",
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
               children: [ParentChild(name: "Arya", age: 13, level: "Level A", interests: ["Space", "Reading", "Art", "Nature"])],
               interests: ["Space", "Reading", "Art", "Nature"],
               lookingFor: ["Learning groups", "Weekend outings"],
               note: "New here, too.", place: "Potheri"),
        Parent(name: "Daniel", role: "Dad to Leo, 11", tags: "Nature · Little inventors", distanceKm: 1.4,
               about: "Happy to swap ideas for calmer learning days.",
               bio: "Weekend tinkerers and trail walkers. Leo builds something new every week and we like sharing what works.",
               children: [ParentChild(name: "Leo", age: 11, level: "Level A", interests: ["Coding", "Nature", "Sports"])],
               interests: ["Coding", "Nature", "Sports"],
               lookingFor: ["Swapping ideas", "Weekend outings"],
               note: "Happy to share.", place: "Guduvanchery"),
        Parent(name: "Preeti", role: "Mum to Ananya, 8 & Ankit, 5", tags: "Stories · Outdoor play", distanceKm: 2.9,
               about: "Stories, park days and learning with friends.",
               bio: "Story-time lovers. We spend a lot of time in the park and would like regular meet-ups for the kids.",
               children: [ParentChild(name: "Ananya", age: 8, level: "Level A", interests: ["Reading", "Animals"]),
                          ParentChild(name: "Ankit", age: 5, level: "Foundation", interests: ["Music", "Animals"])],
               interests: ["Reading", "Animals", "Music"],
               lookingFor: ["Playdates", "Learning groups"],
               note: "Let’s learn together.", place: "Urapakkam"),
        Parent(name: "Sneha", role: "Mum to Noah, 7", tags: "Space · Arts & crafts", distanceKm: 4.2,
               about: "Arts, crafts and stargazing on clear nights.",
               bio: "Arts, crafts and stargazing. Noah asks a new question about the sky every evening.",
               children: [ParentChild(name: "Noah", age: 7, level: "Foundation", interests: ["Space", "Art"])],
               interests: ["Space", "Art"],
               lookingFor: ["Playdates", "Weekend outings"],
               note: "Say hi!", place: "Kattankulathur")
    ]

    private static func parent(_ firstName: String) -> Parent { parents.first { $0.firstName == firstName } ?? parents[0] }
    private static func event(_ title: String) -> Event { events.first { $0.title == title } ?? events[0] }

    /// People I am already connected with at the start.
    static var initiallyConnected: Set<Parent.ID> { [parent("Daniel").id] }

    static var notifications: [AppNotification] {
        [
            AppNotification(symbol: "person.badge.plus", title: "Preeti wants to connect",
                            detail: "Mum to Ananya & Ankit · Urapakkam", time: "Today", isNew: true,
                            action: .connectionRequest(parent("Preeti").id)),
            AppNotification(symbol: "calendar.badge.plus", title: "Daniel and 1 other joined Clay & create",
                            detail: "Families you know are going. You might want to join too.", time: "Today", isNew: true,
                            action: .openEvent(event("Clay & create").id)),
            AppNotification(symbol: "bubble.left", title: "Daniel accepted your request",
                            detail: "You can message each other now.", time: "Yesterday", isNew: false,
                            action: .openChat(parent("Daniel").id)),
            AppNotification(symbol: "sparkles", title: "New gathering near you",
                            detail: "Nature explorers has spots open.", time: "2 days ago", isNew: false,
                            action: .openEvent(event("Nature explorers").id))
        ]
    }
    static let roadmap = [
        RoadmapStep(id: 1, title: "Understand homeschooling", detail: "Learn how it works and your role.", symbol: "book"),
        RoadmapStep(id: 2, title: "Explore boards and learning pathways", detail: "Compare routes for your child's goals.", symbol: "signpost.right"),
        RoadmapStep(id: 3, title: "Understand admissions and assessments", detail: "Eligibility, subjects and key deadlines.", symbol: "graduationcap"),
        RoadmapStep(id: 4, title: "Build your child's learning plan", detail: "Find a routine that fits your family's time.", symbol: "calendar")
    ]
}
