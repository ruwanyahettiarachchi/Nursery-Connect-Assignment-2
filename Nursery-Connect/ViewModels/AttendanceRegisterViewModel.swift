import Foundation

enum AttendanceStatus: Equatable {
    case notRecorded
    case signedIn(since: Date)
    case signedOut
    case absent

    var label: String {
        switch self {
        case .notRecorded: return "Not signed in"
        case .signedIn: return "Signed in"
        case .signedOut: return "Signed out"
        case .absent: return "Absent"
        }
    }

    var systemImage: String {
        switch self {
        case .notRecorded: return "clock"
        case .signedIn: return "checkmark.circle.fill"
        case .signedOut: return "arrow.right.circle.fill"
        case .absent: return "xmark.circle.fill"
        }
    }
}

struct AttendanceRegisterViewModel {
    let children: [Child]
    let records: [AttendanceRecord]
    let referenceDate: Date

    init(children: [Child], records: [AttendanceRecord], referenceDate: Date = Date()) {
        self.children = children
        self.records = records
        self.referenceDate = referenceDate
    }

    var todayRecords: [AttendanceRecord] {
        records.filter { Calendar.current.isDate($0.date, inSameDayAs: referenceDate) }
    }

    func record(for child: Child) -> AttendanceRecord? {
        todayRecords.first { $0.childName == child.name }
    }

    func status(for child: Child) -> AttendanceStatus {
        guard let record = record(for: child) else { return .notRecorded }
        if record.isAbsent { return .absent }
        if record.signOutTime != nil { return .signedOut }
        if let signIn = record.signInTime { return .signedIn(since: signIn) }
        return .notRecorded
    }

    var presentCount: Int {
        todayRecords.filter(\.isPresent).count
    }

    var absentCount: Int {
        todayRecords.filter(\.isAbsent).count
    }

    var signedOutCount: Int {
        todayRecords.filter { $0.signOutTime != nil }.count
    }

    static func startOfDay(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
}
