import Foundation

public enum FriendlyFormatting {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter
    }()

    public static func formattedDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    public static func remainingTime(until date: Date, now: Date = Date()) -> String {
        let diff = Int(date.timeIntervalSince(now))
        guard diff > 0 else { return "已过期" }

        let days = diff / 86_400
        let hours = (diff % 86_400) / 3_600
        let minutes = (diff % 3_600) / 60

        if days > 0 {
            return "\(days)天 \(hours)小时"
        }
        if hours > 0 {
            return "\(hours)小时 \(minutes)分钟"
        }
        return "\(max(1, minutes))分钟"
    }

    public static func compactRemainingTime(until date: Date, now: Date = Date()) -> String {
        let diff = Int(date.timeIntervalSince(now))
        guard diff > 0 else { return "0m" }

        let days = diff / 86_400
        let hours = (diff % 86_400) / 3_600
        let minutes = (diff % 3_600) / 60

        if days > 0 {
            return hours > 0 ? "\(days)d\(hours)h" : "\(days)d"
        }
        if hours > 0 {
            return minutes > 0 ? "\(hours)h\(minutes)m" : "\(hours)h"
        }
        return "\(max(1, minutes))m"
    }
}
