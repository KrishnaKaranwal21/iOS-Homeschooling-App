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
    static let events = [
        Event(title: "Little Scientists' Lab", day: 17, month: "OCT", time: "10:00 AM", host: "Curious Minds Club", place: "Community hall", ages: "6–10", symbol: "flask", isRegistered: true),
        Event(title: "Nature explorers", day: 17, month: "OCT", time: "9:00 AM", host: "Green Trails Club", place: "Riverside Park · Potheri", ages: "All", symbol: "leaf"),
        Event(title: "Clay & create", day: 18, month: "OCT", time: "11:00 AM", host: "Makers Circle", place: "Studio 4", ages: "6–10", symbol: "paintpalette")
    ]
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
