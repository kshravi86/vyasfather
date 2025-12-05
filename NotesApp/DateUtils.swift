import Foundation

/// Formats an inclusive date interval into a short human string (e.g. "Jan 1, 2024 - Jan 3, 2024").
func formatDateRange(start: Date, end: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy"
    return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
}

/// Formats the duration between two dates into a compact y/m/d string (e.g. "1y 2m 3d").
func formatDuration(start: Date, end: Date) -> String {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = .current
    let comps = cal.dateComponents([.year, .month, .day], from: start, to: end)
    let y = comps.year ?? 0
    let m = comps.month ?? 0
    let d = comps.day ?? 0
    var parts: [String] = []
    if y != 0 { parts.append("\(y)y") }
    if m != 0 { parts.append("\(m)m") }
    if d != 0 || parts.isEmpty { parts.append("\(d)d") }
    return parts.joined(separator: " ")
}
