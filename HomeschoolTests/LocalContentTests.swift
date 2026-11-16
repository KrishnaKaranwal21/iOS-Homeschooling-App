import Foundation
import UIKit
import XCTest
@testable import Homeschool

/// Chats, photos, voice notes and hosted events survive a restart and stay inside their account.
@MainActor
final class LocalContentTests: XCTestCase {
    func testLocalContent() throws {
        let account = "content-check-" + UUID().uuidString
        let other = account + "-other"
        defer {
            for key in [account, other] {
                LocalArchive.remove("chats", account: key)
                LocalArchive.remove("events", account: key)
            }
        }
        let image = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { context in
            UIColor.systemPurple.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        let photo = PickedImage(data: image.pngData()!)!
        let chats = ChatStore(account: account)
        chats.reload(withSamples: false, account: account)
        let id = chats.createGroup(title: "Our learning group", members: ["Parent One"])
        chats.send(text: "Bring a notebook", image: photo, in: id)
        chats.sendVoiceNote(Data([1, 2, 3, 4]), duration: 3, in: id)
        chats.toggleMute(id)
        let restored = ChatStore(account: account)
        let saved = restored.thread(id)!
        expect(saved.title == "Our learning group" && saved.members == ["Parent One"], "Group identity and members survive restart")
        expect(saved.messages.count == 2 && saved.messages[0].text == "Bring a notebook", "Messages survive restart without sample replacement")
        expect(saved.messages[0].image?.data == photo.data && saved.messages[0].image?.id == photo.id, "Photo bytes and identity survive restart")
        expect(saved.messages[1].audioData == Data([1, 2, 3, 4]) && saved.messages[1].audioDuration == 3, "Voice note bytes and duration survive restart")
        expect(saved.isMuted, "Conversation preferences survive restart")
        restored.reload(withSamples: false, account: other)
        expect(restored.threads.isEmpty, "Switching accounts cannot reveal another family's messages")
        restored.reload(withSamples: false, account: account)
        expect(restored.thread(id)?.messages.count == 2, "Switching back restores the original conversation")
        restored.toggleBlock(id)
        restored.simulateIncoming(in: id)
        expect(restored.thread(id)?.messages.count == 2, "Blocked contacts cannot send simulated messages")
        var event = Event(title: "Our workshop", category: "Science", start: Date().addingTimeInterval(86400),
            end: Date().addingTimeInterval(90000), host: "Parent", location: "Community hall", ages: "6–10", about: "Experiments", symbol: "flask")
        event.isHostedByMe = true
        event.coverImage = photo
        event.photos = [photo]
        event.faqs = [EventFAQ(question: "Materials?", answer: "Notebook")]
        event.questions = [EventQuestion(asker: "Parent One", text: "May I stay?", date: .now, answer: "Yes")]
        expect(LocalArchive.save([event], category: "events", account: account), "Hosted event archive writes successfully")
        let events = LocalArchive.load([Event].self, category: "events", account: account)!
        expect(events[0].id == event.id && events[0].storageKey == event.storageKey, "Event and ticket identities survive restart")
        expect(events[0].coverImage?.data == photo.data && events[0].photos[0].id == photo.id, "Cover and gallery images survive restart")
        expect(events[0].faqs[0].answer == "Notebook" && events[0].questions[0].answer == "Yes", "FAQs and host answers survive restart")
        expect(LocalArchive.load([Event].self, category: "events", account: other) == nil, "Hosted events stay in their own account namespace")
        restored.deleteSavedChats()
        expect(ChatStore(account: account).threads.isEmpty, "Deleted chats remain deleted after restart")
    }
}
