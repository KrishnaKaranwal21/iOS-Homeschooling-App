import Foundation

// MARK: - SubjectOption

struct SubjectOption: Identifiable, Hashable {
    let name: String
    var code: String? = nil
    var id: String { name }
}

// MARK: - SubjectGroup

struct SubjectGroup: Identifiable {
    let id: String
    let title: String
    var note: String? = nil
    var unit: String = "subject"
    let options: [SubjectOption]
    var minPick: Int = 0
    var maxPick: Int? = nil
    /// Higher limit that is only valid when the learner registers the full subject ceiling.
    var maxPickAtFullLoad: Int? = nil
    /// Minimum depends on how many subjects the other groups already provide.
    var fillsTotal: Bool = false
    var locked: Bool = false
    var preselect: [String] = []
}

// MARK: - LevelCurriculum

struct LevelCurriculum {
    let level: String
    let equivalent: String
    let summary: String
    let minSubjects: Int
    let maxSubjects: Int?
    let groups: [SubjectGroup]
}

// MARK: - Requirement

struct Requirement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let met: Bool
}

// MARK: - SubjectKey

enum SubjectKey {
    static func make(_ group: SubjectGroup, _ option: SubjectOption) -> String {
        group.id + "|" + option.name
    }
}

// MARK: - LevelCurriculum extensions

extension LevelCurriculum {
    func isSelected(_ group: SubjectGroup, _ option: SubjectOption, in selected: Set<String>) -> Bool {
        group.locked || selected.contains(SubjectKey.make(group, option))
    }

    func count(in group: SubjectGroup, selected: Set<String>) -> Int {
        group.options.filter { isSelected(group, $0, in: selected) }.count
    }

    /// The same subject listed in two groups only counts once.
    func uniqueTotal(selected: Set<String>) -> Int {
        var names = Set<String>()
        for group in groups {
            for option in group.options where isSelected(group, option, in: selected) {
                names.insert(option.name)
            }
        }
        return names.count
    }

    func effectiveMin(_ group: SubjectGroup, selected: Set<String>) -> Int {
        guard group.fillsTotal else { return group.minPick }
        let others = uniqueTotal(selected: selected) - count(in: group, selected: selected)
        return max(group.minPick, minSubjects - others)
    }

    func allowedMax(_ group: SubjectGroup, selected: Set<String>) -> Int? {
        guard let base = group.maxPick else { return nil }
        if let full = group.maxPickAtFullLoad, let cap = maxSubjects,
           uniqueTotal(selected: selected) == cap {
            return full
        }
        return base
    }

    func isGroupSatisfied(_ group: SubjectGroup, selected: Set<String>) -> Bool {
        let c = count(in: group, selected: selected)
        if c < effectiveMin(group, selected: selected) { return false }
        if let m = allowedMax(group, selected: selected), c > m { return false }
        return true
    }

    func isComplete(selected: Set<String>) -> Bool {
        let total = uniqueTotal(selected: selected)
        if total < minSubjects { return false }
        if let m = maxSubjects, total > m { return false }
        return groups.allSatisfy { isGroupSatisfied($0, selected: selected) }
    }

    func rangeText(for group: SubjectGroup, selected: Set<String>) -> String {
        let minValue = effectiveMin(group, selected: selected)
        var text: String
        if let max = group.maxPick {
            text = minValue == max ? "pick \(max)" : (minValue > 0 ? "pick \(minValue)–\(max)" : "up to \(max)")
        } else if minValue > 0 {
            text = "pick at least \(minValue)"
        } else {
            text = "optional"
        }
        if let full = group.maxPickAtFullLoad, let cap = maxSubjects {
            text += " (\(full) only with \(cap) subjects)"
        }
        return text
    }

    var totalRangeText: String {
        if let m = maxSubjects {
            return m == minSubjects ? "need \(m)" : "need \(minSubjects)–\(m)"
        }
        return "need at least \(minSubjects)"
    }

    func progressText(selected: Set<String>) -> String {
        "\(uniqueTotal(selected: selected)) selected · \(totalRangeText)"
    }

    func requirements(selected: Set<String>) -> [Requirement] {
        var list: [Requirement] = []
        for group in groups {
            if group.locked {
                list.append(Requirement(id: group.id, title: group.title,
                                        detail: "\(group.options.count) added for you", met: true))
            } else if group.minPick > 0 || group.fillsTotal {
                let c = count(in: group, selected: selected)
                list.append(Requirement(id: group.id, title: group.title,
                                        detail: "\(c) chosen · \(rangeText(for: group, selected: selected))",
                                        met: isGroupSatisfied(group, selected: selected)))
            }
        }
        let total = uniqueTotal(selected: selected)
        var totalMet = total >= minSubjects
        if let m = maxSubjects, total > m { totalMet = false }
        list.append(Requirement(id: "total", title: "Total subjects",
                                detail: "\(total) chosen · \(totalRangeText)", met: totalMet))
        return list
    }

    /// What the learner still has to do, or nil when everything is fine.
    func hint(selected: Set<String>) -> String? {
        let total = uniqueTotal(selected: selected)
        for group in groups where !group.locked {
            let c = count(in: group, selected: selected)
            let need = effectiveMin(group, selected: selected)
            if c < need {
                return "Pick at least \(need) \(Curriculum.plural(need, group.unit)) in \(group.title)."
            }
            if let m = allowedMax(group, selected: selected), c > m {
                if let cap = maxSubjects, group.maxPickAtFullLoad != nil {
                    return "\(c) \(Curriculum.plural(c, group.unit)) are only allowed with \(cap) subjects in total. Add subjects or remove one."
                }
                return "Remove \(c - m). Only \(m) \(Curriculum.plural(m, group.unit)) allowed in \(group.title)."
            }
        }
        if total < minSubjects {
            let n = minSubjects - total
            return "Choose \(n) more subject\(n == 1 ? "" : "s") to continue."
        }
        if let m = maxSubjects, total > m {
            let n = total - m
            return "Remove \(n) subject\(n == 1 ? "" : "s"). The maximum is \(m)."
        }
        return nil
    }
}

// MARK: - LevelCurriculum extensions

extension LevelCurriculum {
    /// Shown only when the selection is valid and has more subjects than the minimum.
    /// It informs, it never discourages: choosing more is always fine up to the maximum.
    func extraSubjectsNote(selected: Set<String>) -> String? {
        let total = uniqueTotal(selected: selected)
        guard total > minSubjects, isComplete(selected: selected) else { return nil }

        let extra = total - minSubjects
        let base = "Minimum is \(minSubjects). You\u{2019}ve chosen \(total), \(extra) more than the minimum."
        guard let maxValue = maxSubjects else { return base }
        return total < maxValue
            ? base + " You can choose up to \(maxValue)."
            : base + " \(maxValue) is the maximum."
    }
}

// MARK: - LevelCurriculum extensions

extension LevelCurriculum {
    /// Short red inline message for a group, or nil when the group is fine.
    func groupIssue(_ group: SubjectGroup, selected: Set<String>) -> String? {
        guard !group.locked else { return nil }
        let count = self.count(in: group, selected: selected)
        let need = effectiveMin(group, selected: selected)
        if count < need {
            let missing = need - count
            if count == 0 {
                return "Select at least \(need) \(Curriculum.plural(need, group.unit))"
            }
            return "Select \(missing) more \(Curriculum.plural(missing, group.unit))"
        }
        if let m = allowedMax(group, selected: selected), count > m {
            let extra = count - m
            return "Remove \(extra) \(Curriculum.plural(extra, group.unit))"
        }
        if let full = group.maxPickAtFullLoad, let cap = maxSubjects,
           let base = group.maxPick, count > base, count <= full {
            return "Add more subjects to reach \(cap), or remove 1 \(group.unit)"
        }
        return nil
    }

    /// Full list of problems, shown when the learner taps Continue too early.
    func issues(selected: Set<String>) -> [String] {
        var list: [String] = []
        for group in groups {
            if let text = groupIssue(group, selected: selected) {
                list.append("\(text) in \(group.title).")
            }
        }
        if list.isEmpty {
            let total = uniqueTotal(selected: selected)
            if total < minSubjects {
                let n = minSubjects - total
                list.append("Select \(n) more subject\(n == 1 ? "" : "s") in total.")
            } else if let m = maxSubjects, total > m {
                let n = total - m
                list.append("Remove \(n) subject\(n == 1 ? "" : "s"). The maximum is \(m).")
            }
        }
        return list
    }
}
