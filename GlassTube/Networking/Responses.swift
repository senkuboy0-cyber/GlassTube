//
//  Responses.swift
//  GlassTube
//
//  Defensive InnerTube response parsing. Instead of pinning a full decoder
//  tree to YouTube's shifting layout, we walk the JSON and collect the
//  renderer dictionaries we care about — the same resilience strategy
//  innertubex applies internally.
//

import Foundation

// MARK: - JSON traversal helpers

enum JSON {

    static func dict(_ container: [String: Any], _ key: String) -> [String: Any]? {
        container[key] as? [String: Any]
    }

    static func array(_ container: [String: Any], _ key: String) -> [Any]? {
        container[key] as? [Any]
    }

    static func string(_ container: [String: Any], _ key: String) -> String? {
        container[key] as? String
    }

    static func number(_ container: [String: Any], _ key: String) -> Double? {
        if let n = container[key] as? NSNumber { return n.doubleValue }
        if let s = container[key] as? String { return Double(s) }
        return nil
    }

    /// Joins `runs: [{text: "..."}]` into a plain string.
    /// `key` optionally names the child dictionary holding `runs`.
    static func runsText(_ container: [String: Any]?, _ key: String? = nil) -> String? {
        guard let container else { return nil }
        let node: [String: Any]? = key.flatMap { container[$0] as? [String: Any] } ?? container
        guard let runs = node?["runs"] as? [[String: Any]] else { return nil }
        let texts = runs.compactMap { $0["text"] as? String }
        return texts.isEmpty ? nil : texts.joined()
    }

    /// Recursively finds every dictionary named `key` at any depth.
    static func findAll(_ key: String, in node: Any, limit: Int = 400) -> [[String: Any]] {
        var found: [[String: Any]] = []
        var queue: [Any] = [node]

        while !queue.isEmpty, found.count < limit {
            let current = queue.removeFirst()
            if let dict = current as? [String: Any] {
                for (k, v) in dict {
                    if k == key, let match = v as? [String: Any] {
                        found.append(match)
                    }
                    queue.append(v)
                }
            } else if let array = current as? [Any] {
                queue.append(contentsOf: array)
            }
        }
        return found
    }
}

// MARK: - Renderers → VideoItem

extension VideoItem {

    /// Parses videoRenderer / gridVideoRenderer / compactVideoRenderer.
    init?(renderer r: [String: Any]) {
        guard let id = JSON.string(r, "videoId") else { return nil }

        let title = JSON.runsText(JSON.dict(r, "title"))
            ?? JSON.string(r, "title")
            ?? ""

        let channel = JSON.runsText(JSON.dict(r, "ownerText"))
            ?? JSON.runsText(JSON.dict(r, "longBylineText"))
            ?? JSON.runsText(JSON.dict(r, "shortBylineText"))
            ?? ""

        let views = JSON.runsText(JSON.dict(r, "shortViewCountText"))
            ?? JSON.runsText(JSON.dict(r, "viewCountText"))
            ?? ""

        let published = JSON.runsText(JSON.dict(r, "publishedTimeText")) ?? ""
        let duration = JSON.runsText(JSON.dict(r, "lengthText")) ?? ""
        let thumbnail = Self.bestThumbnail(from: JSON.dict(r, "thumbnail"))

        self.init(
            id: id,
            title: title,
            channel: channel,
            viewsText: views,
            publishedText: published,
            durationText: duration,
            thumbnail: thumbnail
        )
    }

    /// Newer YouTube layouts sometimes deliver `lockupViewModel`;
    /// parse it defensively so feeds keep working across layout changes.
    init?(lockupViewModel v: [String: Any]) {
        guard let id = JSON.string(v, "contentId"), id.count == 11 else { return nil }

        let metadata = JSON.dict(v, "metadata").flatMap { JSON.dict($0, "lockupMetadataViewModel") }
        let title = metadata.flatMap { JSON.dict($0, "title") }.flatMap { JSON.string($0, "content") } ?? ""
        guard !title.isEmpty else { return nil }

        var parts: [String] = []
        if let rows = (metadata?["metadata"] as? [String: Any])?["metadataRows"] as? [Any] {
            for row in rows {
                guard let rowDict = row as? [String: Any],
                      let metadataParts = rowDict["metadataParts"] as? [Any] else { continue }
                for part in metadataParts {
                    if let partDict = part as? [String: Any],
                       let textVM = partDict["text"] as? [String: Any],
                       let text = textVM["content"] as? String {
                        parts.append(text)
                    }
                }
            }
        }

        let thumbnail = JSON.dict(v, "contentImage")
            .flatMap { JSON.dict($0, "thumbnailViewModel") }
            .flatMap { JSON.dict($0, "image") }
            .flatMap { sources -> URL? in
                guard let list = sources["sources"] as? [[String: Any]] else { return nil }
                let sorted = list.sorted {
                    (JSON.number($0, "width") ?? 0) > (JSON.number($1, "width") ?? 0)
                }
                guard let urlString = sorted.first.flatMap({ JSON.string($0, "url") }) else { return nil }
                return URL(string: urlString.hasPrefix("//") ? "https:" + urlString : urlString)
            }

        self.init(
            id: id,
            title: title,
            channel: parts.joined(separator: " · "),
            viewsText: "",
            publishedText: "",
            durationText: "",
            thumbnail: thumbnail
        )
    }

    /// Picks the largest thumbnail from a `thumbnail.thumbnails` container.
    static func bestThumbnail(from container: [String: Any]?) -> URL? {
        guard let list = container?["thumbnails"] as? [[String: Any]] else { return nil }
        let sorted = list.sorted {
            (JSON.number($0, "width") ?? 0) > (JSON.number($1, "width") ?? 0)
        }
        guard let urlString = sorted.first.flatMap({ JSON.string($0, "url") }) else { return nil }
        return URL(string: urlString.hasPrefix("//") ? "https:" + urlString : urlString)
    }
}
