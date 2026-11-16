import SwiftUI

/// Gather events: the catalogue, registrations, bookings and bookmarks.
extension AppState {
    /// Loads this account's saved events (or the sample catalogue) and re-links the sample notifications to the
    /// restored event ids.
    func restoreEvents() {
        restoringEvents = true

        eventArchiveAccount = account.map {
            AccountStore.normalized($0.email)
        } ?? "local-family"

        let mockEvents = MockData.events.sorted { $0.start < $1.start }

        let savedEvents = LocalArchive.load(
            [Event].self,
            category: "events",
            account: eventArchiveAccount
        ) ?? mockEvents

        events = savedEvents.map { savedEvent in
            var updatedEvent = savedEvent

            if savedEvent.title == "Pond Life Walk",
               let mockEvent = mockEvents.first(where: {
                   $0.storageKey == savedEvent.storageKey
               }) {
                updatedEvent.coverName = mockEvent.coverName
            }

            return updatedEvent
        }

        restoringEvents = false

        // Persist the updated cover without resetting other event data.
        LocalArchive.save(
            events,
            category: "events",
            account: eventArchiveAccount
        )

        notifications = MockData.notifications.map { notification in
            var item = notification

            switch item.action {
            case .openEvent(let id), .openEventQuestions(let id):
                if let old = MockData.events.first(where: { $0.id == id }),
                   let restored = events.first(where: {
                       $0.storageKey == old.storageKey
                   }) {
                    if case .openEventQuestions = item.action {
                        item.action = .openEventQuestions(restored.id)
                    } else {
                        item.action = .openEvent(restored.id)
                    }
                }
            default:
                break
            }

            return item
        }
    }

    /// Reschedules reminders for the events the family registered for or saved.
    func syncGatheringReminders() {
        gatheringReminders.sync(events: events.filter { $0.isRegistered || bookmarkedKeys.contains($0.storageKey) },
                                enabled: preferences.notifyGatherings && stage == .main)
    }

    /// Creates a local event booking, updates its attending flag, and persists registrant and booking data; no
    /// payment gateway is called.
    func register(_ event: Event, as registrant: Registrant, accompanying: Bool = true, places: Int = 1) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        guard registrations[event.id] == nil else { return }
        events[index].updateRegistration(true)
        registrations[event.id] = Registration(eventID: event.id, registrant: registrant,
                                               registeredAt: .now,
                                               amountPaid: event.price.map { $0 * places },
                                               accompanying: accompanying, places: places)

        savedRegistrant = registrant
        storedRegistrant = Self.encode(registrant)
        saveBookings()
    }

    /// Free registrations can be cancelled at any time. Paid ones cannot, and are not refunded.
    func canCancel(_ event: Event) -> Bool {
        guard event.isRegistered else { return false }
        return !(registrations[event.id]?.isPaid ?? !event.isFree)
    }

    /// Removes an eligible free booking, updates the event count, and saves the changed booking collection.
    @discardableResult
    func cancelRegistration(for event: Event) -> Bool {
        guard canCancel(event),
              let index = events.firstIndex(where: { $0.id == event.id }), events[index].isRegistered else { return false }
        events[index].updateRegistration(false)
        registrations[event.id] = nil
        saveBookings()
        return true
    }

    /// Derives the account namespace used to separate locally stored event bookings.
    var bookingAccountKey: String {
        account.map { AccountStore.normalized($0.email) } ?? "local-family"
    }

    /// Exposes the encoded account-to-event booking map through a typed computed property.
    var bookingsByAccount: [String: [String: Registration]] {
        get { Self.decode([String: [String: Registration]].self, from: storedBookings) ?? [:] }
        set { storedBookings = Self.encode(newValue) }
    }

    /// Stores current event bookings under stable event keys and the active account while retaining out-of-
    /// catalogue bookings.
    func saveBookings() {
        // Retain bookings for events outside the current catalog as well.
        var saved = bookingsByAccount[bookingAccountKey] ?? [:]
        for event in events {
            // Stores or removes the event booking using its stable title-and-start key rather than its regenerated
            // UUID.
            saved[event.storageKey] = registrations[event.id]
        }
        bookingsByAccount[bookingAccountKey] = saved
    }

    /// Loads this account's bookings and marks the matching events as registered. New accounts get sample
    /// bookings on the demo events.
    func restoreBookings() {
        registrations = [:]

        let saved = bookingsByAccount[bookingAccountKey] ?? [:]

        let demoEventTitles: Set<String> = [
            "Mini Science Fair",
            "Creative Art & Craft Day",
            "Nature Discovery Walk"
        ]

        let sampleRegistrant = Registrant(
            parentName: "Asha Patel",
            email: "asha.patel@example.com",
            mobile: "+91 98765 43210",
            childName: "Maya",
            childAge: "10",
            notes: ""
        )
        for index in events.indices {
            let event = events[index]
            if var booking = saved[event.storageKey] {
                booking = booking.forEvent(event.id)
                registrations[event.id] = booking
                events[index].updateRegistration(true)
            } else if demoEventTitles.contains(event.title) {
                let booking = Registration(
                    eventID: event.id,
                    registrant: sampleRegistrant,
                    registeredAt: event.start,
                    amountPaid: event.price
                )
                registrations[event.id] = booking
                events[index].updateRegistration(true)
            } else {
                events[index].updateRegistration(false)
            }
        }
        saveBookings()
    }

    /// Adds a hosted or supplied event to the local Gather catalogue and preserves chronological ordering.
    func add(_ event: Event) {
        events.append(event)
        events.sort { $0.start < $1.start }
        // PROTOTYPE ONLY: a family asks the new host a question a little later.
        if event.isHostedByMe { simulateIncomingQuestion(for: event.id) }
    }

    /// Derives the saved-event list from the current catalogue and bookmark set instead of storing duplicate event
    /// objects.
    var savedEvents: [Event] {
        events.filter { isBookmarked($0) }
    }

    /// Checks a stable event key against the shared saved-event set.
    func isBookmarked(_ event: Event) -> Bool {
        bookmarkedKeys.contains(event.storageKey)
    }

    /// Clears both the observable bookmark set and its locally encoded storage.
    func clearSavedEvents() {
        bookmarkedKeys = []
        storedBookmarks = Self.encode([String]())
    }

    /// Adds or removes the stable event key and saves the sorted bookmark keys for future launches.
    func toggleBookmark(_ event: Event) {
        if !bookmarkedKeys.insert(event.storageKey).inserted {
            bookmarkedKeys.remove(event.storageKey)
        }
        storedBookmarks = Self.encode(bookmarkedKeys.sorted())
    }
}
