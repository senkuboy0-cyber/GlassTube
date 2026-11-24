//
//  Models.swift
//  GlassTube
//
//  Client-side models shared across features. Network responses are parsed
//  defensively (see Responses.swift) into these stable structs.
//

import Foundation

struct VideoItem: Identifiable, Hashable, Codable {
    /// YouTube video id, e.g. "dQw4w9WgXcQ".
    let id: String
    var title: String
    var channel: String
    var viewsText: String
    var publishedText: String
    var durationText: String
    var thumbnail: URL?

    var durationSeconds: Double? {
        VideoItem.parseDuration(durationText)
    }

    var displayDuration: String {
        durationText.isEmpty ? "--:--" : durationText
    }

    /// Parses "4:13" / "1:02:07" style text into seconds.
    static func parseDuration(_ text: String) -> Double? {
        let parts = text.split(separator: ":").compactMap { Double($0) }
        guard !parts.isEmpty else { return nil }
        var seconds = 0.0
        for part in parts {
            seconds = seconds * 60 + part
        }
        return seconds
    }

    /// Watch/share URL for this video.
    var watchURL: URL? {
        URL(string: "https://youtu.be/\(id)")
    }
}
