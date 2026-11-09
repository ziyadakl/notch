/*
 * Atoll (DynamicIsland)
 * Copyright (C) 2024-2026 Atoll Contributors
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

import SwiftUI
import AppKit
import Defaults

struct TimerPreset: Identifiable, Codable, Hashable, Defaults.Serializable {
    struct ColorData: Codable, Hashable, Defaults.Serializable {
        var red: Double
        var green: Double
        var blue: Double
        var alpha: Double

        init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
        }

        init(color: Color) {
            let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
            self.red = nsColor.redComponent
            self.green = nsColor.greenComponent
            self.blue = nsColor.blueComponent
            self.alpha = nsColor.alphaComponent
        }

        var color: Color {
            Color(red: red, green: green, blue: blue, opacity: alpha)
        }
    }

    struct DurationComponents {
        var hours: Int
        var minutes: Int
        var seconds: Int
    }

    var id: UUID
    var name: String
    var duration: TimeInterval
    var colorData: ColorData

    init(id: UUID = UUID(), name: String, duration: TimeInterval, colorData: ColorData) {
        self.id = id
        self.name = name
        self.duration = duration
        self.colorData = colorData
    }

    init(id: UUID = UUID(), name: String, duration: TimeInterval, color: Color) {
        self.init(id: id, name: name, duration: duration, colorData: ColorData(color: color))
    }

    var color: Color {
        colorData.color
    }

    mutating func updateColor(_ newColor: Color) {
        colorData = ColorData(color: newColor)
    }

    var formattedDuration: String { Self.clockString(for: duration) }

    /// A length as a clock: "5:00", "25:00", "1:30:00".
    static func clockString(for duration: TimeInterval) -> String {
        let total = max(0, Int(duration.rounded()))
        let hours = total / 3600, minutes = (total % 3600) / 60, seconds = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%d:%02d", minutes, seconds)
    }

    static func components(for duration: TimeInterval) -> DurationComponents {
        let totalSeconds = max(0, Int(duration))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return DurationComponents(hours: hours, minutes: minutes, seconds: seconds)
    }

    static func duration(from components: DurationComponents) -> TimeInterval {
        TimeInterval(components.hours * 3600 + components.minutes * 60 + components.seconds)
    }

    /// Reads a typed length: "25" (minutes), "25:00", "1:30:00", "1h 30", "90s", "1.5h".
    /// Returns nil for empty, unreadable or non-positive input.
    static func parseDuration(_ input: String) -> TimeInterval? {
        let s = input.lowercased().trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty else { return nil }

        // Clock form: "mm:ss" or "h:mm:ss".
        if s.contains(":") {
            let parts = s.split(separator: ":").map { Int($0.trimmingCharacters(in: .whitespaces)) }
            guard parts.allSatisfy({ $0 != nil }) else { return nil }
            let values = parts.compactMap { $0 }
            switch values.count {
            case 2: return TimeInterval(values[0] * 60 + values[1])
            case 3: return TimeInterval(values[0] * 3600 + values[1] * 60 + values[2])
            default: return nil
            }
        }

        // A bare number means minutes.
        if let minutes = Double(s) { return minutes * 60 }

        // Unit form: "1h 30", "1h30m", "90s", "2 hr 5 min". A trailing bare number after hours is minutes.
        var total: Double = 0
        var number = ""
        var lastUnit: Character?
        var index = s.startIndex
        while index < s.endIndex {
            let c = s[index]
            if c.isNumber || c == "." {
                number.append(c)
            } else if c.isLetter {
                var word = String(c)
                var next = s.index(after: index)
                while next < s.endIndex, s[next].isLetter {
                    word.append(s[next])
                    next = s.index(after: next)
                }
                index = s.index(before: next)
                guard let value = Double(number) else { return nil }
                switch word.first {
                case "h": total += value * 3600; lastUnit = "h"
                case "m": total += value * 60; lastUnit = "m"
                case "s": total += value; lastUnit = "s"
                default: return nil
                }
                number = ""
            } else if c != " " {
                return nil
            }
            index = s.index(after: index)
        }
        if !number.isEmpty {
            guard let value = Double(number) else { return nil }
            total += lastUnit == "h" ? value * 60 : value
        }
        return total > 0 ? total : nil
    }

    static let defaultPresets: [TimerPreset] = [
        TimerPreset(name: String(localized:"Focus"), duration: 25 * 60, color: Color.orange),
        TimerPreset(name: String(localized:"Break"), duration: 5 * 60, color: Color.green),
        TimerPreset(name: String(localized:"Deep Work"), duration: 45 * 60, color: Color.purple)
    ]
}
