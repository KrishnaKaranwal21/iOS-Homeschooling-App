import Foundation

/// One NIOS exam registration window.
struct ExamWindow: Identifiable, Equatable {
    let id: String
    /// "April–May 2027 exams"
    let session: String
    /// Last date to register without a late fee.
    let lastDate: Date
    /// false while NIOS has not published its notice and the date follows the usual pattern.
    let isConfirmed: Bool
}

/// Registration dates by level.
///
/// These dates change every session. Update the lists below when NIOS publishes a new notice
/// (https://sdmis.nios.ac.in). Nothing else in the app needs to change.
enum ExamCalendar {
    static let noticeURL = URL(string: "https://sdmis.nios.ac.in")!

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
    }

    /// Secondary (Class 10) and Senior Secondary (Class 12) public exams.
    /// April–May exams: exam fee window ends around 20 December (expected, notice not out yet).
    /// October–November exams: exam fee window ends around 20 June (expected).
    private static let publicExamWindows: [ExamWindow] = [
        ExamWindow(id: "2027-04", session: "April–May 2027 exams",
                   lastDate: date(2026, 12, 20), isConfirmed: false),
        ExamWindow(id: "2027-10", session: "October–November 2027 exams",
                   lastDate: date(2027, 6, 20), isConfirmed: false)
    ]

    /// OBE Levels A, B and C: NIOS does not publish one date for everyone. Exams are arranged by each
    /// accredited agency (the last round ran 1 to 28 February 2026), so there is nothing to count down to.
    static let obeNote = "Set by your NIOS accredited agency. There is no common last date, so ask your agency."

    static func hasFixedDates(for level: String) -> Bool {
        level == "Grade 10" || level == "Grade 12"
    }

    /// The first window whose last date has not passed yet.
    static func nextWindow(for level: String, today: Date = .now) -> ExamWindow? {
        guard hasFixedDates(for: level) else { return nil }
        let startOfToday = Calendar.current.startOfDay(for: today)
        return publicExamWindows.first { $0.lastDate >= startOfToday }
    }
}
