// Adapted from ClockHandKit 0.1.2 by GIL (https://github.com/giljihun/ClockHandKit)
//
// MIT License
//
// Copyright (c) 2026 GIL
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// What this does
// --------------
// Apple's Clock widget turns its hands with `WidgetKit._ClockHandRotationEffect`,
// a private modifier that the system keeps rotating by the current time without
// waking our extension. Third-party apps cannot name the type, so we look it up
// at runtime, build it from JSON (it is Decodable) and apply it as a modifier.
// If any step fails, the view is returned unchanged: the pet simply stands still
// instead of crashing.

import Foundation
import SwiftUI
import WidgetKit

/// JSON accepted by `WidgetKit._ClockHandRotationEffect`.
/// `honorIdealizedDate` is required by WidgetKit 27 and ignored by older versions.
private struct ClockHandPayload: Encodable {
    let period: TimeInterval
    let timeZone: TimeZone
    let anchor: UnitPoint

    private enum CodingKeys: String, CodingKey {
        case period
        case timeZone
        case anchor
        case honorIdealizedDate
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(period, forKey: .period)
        try container.encode(timeZone, forKey: .timeZone)
        // false: rotate by the real current time, not a preview time.
        try container.encode(false, forKey: .honorIdealizedDate)
        // UnitPoint is only Codable on iOS 26+, so encode it by hand.
        var anchorContainer = container.nestedUnkeyedContainer(forKey: .anchor)
        try anchorContainer.encode(Double(anchor.x))
        try anchorContainer.encode(Double(anchor.y))
    }
}

/// Builds the private modifier. Not cached: it is a tiny JSON round-trip and
/// Live Activity views are only rebuilt when their state changes.
private func clockHandModifier(period: TimeInterval, anchor: UnitPoint) -> (any ViewModifier)? {
    guard
        let type = _typeByName("9WidgetKit24_ClockHandRotationEffectV"),
        let decodable = type as? any Decodable.Type,
        let json = try? JSONEncoder().encode(
            ClockHandPayload(period: period, timeZone: .current, anchor: anchor)
        ),
        let value = try? JSONDecoder().decode(decodable, from: json),
        let modifier = value as? any ViewModifier
    else {
        return nil
    }
    return modifier
}

/// Opens the existential so SwiftUI gets a concrete modifier type.
private func applying<V: View, M: ViewModifier>(_ modifier: M, to view: V) -> some View {
    view.modifier(modifier)
}

extension View {
    /// Rotates the view a full turn every `period` seconds, driven by the
    /// system clock. Only animates inside widgets and Live Activities.
    func clockHandRotation(period: TimeInterval, anchor: UnitPoint = .center) -> AnyView {
        guard let modifier = clockHandModifier(period: period, anchor: anchor) else {
            return AnyView(self)
        }
        return AnyView(applying(modifier, to: self))
    }
}
