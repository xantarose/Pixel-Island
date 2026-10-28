import Foundation

/// Cleans pet names typed by the user or received in a pair code.
///
/// Removes invisible and control characters (newlines, zero-width spaces,
/// right-to-left overrides that can make text render "backwards"), squeezes
/// spaces and limits the length so a name can't break the island layout.
enum NameSanitizer {
    static let maxLength = 16

    /// Zero-width joiner glues emoji like 👩‍❤️‍👨 together, so it stays.
    private static let allowedFormatScalars: Set<UInt32> = [0x200D]

    /// Final form: invisible characters removed, spaces squeezed, trimmed.
    static func clean(_ raw: String) -> String {
        let squeezed = removeInvisible(raw)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return String(squeezed.prefix(maxLength))
    }

    /// While typing: same safety, but spaces are kept so "Мой кот" can be typed.
    static func cleanWhileTyping(_ raw: String) -> String {
        let flat = removeInvisible(raw)
            .components(separatedBy: .newlines)
            .joined(separator: " ")
        return String(flat.prefix(maxLength))
    }

    private static func removeInvisible(_ raw: String) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in raw.unicodeScalars {
            switch scalar.properties.generalCategory {
            case .control, .lineSeparator, .paragraphSeparator, .privateUse, .surrogate, .unassigned:
                if scalar == "\n" || scalar == "\t" {
                    scalars.append(" ")
                }
            case .format where !allowedFormatScalars.contains(scalar.value):
                continue
            default:
                scalars.append(scalar)
            }
        }
        return String(scalars)
    }
}
