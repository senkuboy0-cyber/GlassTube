//
//  InnerTube.swift
//  GlassTube
//
//  Swift InnerTube engine — an independent, iOS-native port of the
//  InnerTubeX API surface (https://github.com/MetrolistGroup/innertubex).
//
//  Endpoint paths, client profiles, the header contract and the player
//  fallback chain all mirror innertubex v0.13.1:
//    - POST /youtubei/v1/search          (WEB)
//    - POST /youtubei/v1/browse          (WEB)
//    - POST /youtubei/v1/player          (IOS -> ANDROID_VR -> WEB)
//    - POST /youtubei/v1/music/get_search_suggestions (WEB_REMIX)
//  See KotlinBridge/README.md for linking the original Kotlin framework.
//

import Foundation

/// A resolved, playable video stream.
struct PlayerStream {
    let videoId: String
    let title: String
    let author: String
    let durationSeconds: Double
    let viewCountText: String
    let hlsURL: URL?
    let progressiveURL: URL?
    let thumbnails: [URL]

    var playable: Bool { hlsURL != nil || progressiveURL != nil }

    /// Preferred transport: HLS plays natively in AVPlayer and adapts.
    var playbackURL: URL? {
        hlsURL ?? progressiveURL
    }
}

enum InnerTubeError: LocalizedError {
    case http(Int)
    case badPayload(String)
    case unplayable(String)

    var errorDescription: String? {
        switch self {
        case .http(let code):            return "YouTube returned HTTP \(code)"
        case .badPayload(let why):       return "Unexpected response: \(why)"
        case .unplayable(let reason):    return reason
        }
    }
}

/// The InnerTube client. Mirrors innertubex's `InnerTube` class.
final class InnerTube {

    struct LocaleSetting {
        var hl: String = "en"
        var gl: String = "US"
    }

    // Matches innertubex InnerTube.kt constants.
    private let apiBase = "https://www.youtube.com/youtubei/v1"
    private let musicAPIBase = "https://music.youtube.com/youtubei/v1"
    private let origin = "https://www.youtube.com"

    var locale = LocaleSetting()
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Public API (mirrors innertubex)

    /// POST /youtubei/v1/search — mirrors `InnerTube.search`.
    func search(_ query: String, params: String? = nil) async throws -> [VideoItem] {
        var body: [String: Any] = [
            "context": context(for: .web),
            "query": query,
        ]
        if let params, !params.isEmpty {
            body["params"] = params
        }

        let data = try await post("search", client: .web, body: body)
        let json = try JSONSerialization.jsonObject(with: data)

        var items: [VideoItem] = []
        var seen = Set<String>()
        for key in ["videoRenderer", "lockupViewModel"] {
            for renderer in JSON.findAll(key, in: json) {
                let item: VideoItem?
                if key == "lockupViewModel" {
                    item = VideoItem(lockupViewModel: renderer)
                } else {
                    item = VideoItem(renderer: renderer)
                }
                if let item, !seen.contains(item.id) {
                    seen.insert(item.id)
                    items.append(item)
                }
            }
        }
        return items
    }

    /// POST /youtubei/v1/browse — mirrors `InnerTube.browse`
    /// (home feed, trending, music, gaming).
    func browse(_ browseId: String) async throws -> [VideoItem] {
        let body: [String: Any] = [
            "context": context(for: .web),
            "browseId": browseId,
        ]

        let data = try await post("browse", client: .web, body: body)
        let json = try JSONSerialization.jsonObject(with: data)

        var items: [VideoItem] = []
        var seen = Set<String>()
        for key in ["videoRenderer", "gridVideoRenderer", "compactVideoRenderer", "lockupViewModel"] {
            for renderer in JSON.findAll(key, in: json) {
                let item: VideoItem?
                if key == "lockupViewModel" {
                    item = VideoItem(lockupViewModel: renderer)
                } else {
                    item = VideoItem(renderer: renderer)
                }
                if let item, !seen.contains(item.id) {
                    seen.insert(item.id)
                    items.append(item)
                }
            }
        }
        return items
    }

    /// POST /youtubei/v1/music/get_search_suggestions —
    /// mirrors `InnerTube.getSearchSuggestions`.
    func suggestions(_ input: String) async throws -> [String] {
        let body: [String: Any] = [
            "context": context(for: .webRemix),
            "input": input,
        ]

        let data = try await post(
            "music/get_search_suggestions",
            client: .webRemix,
            body: body,
            base: musicAPIBase,
            originOverride: "https://music.youtube.com"
        )
        let json = try JSONSerialization.jsonObject(with: data)

        var result: [String] = []
        if let root = json as? [String: Any],
           let contents = root["contents"] as? [Any] {
            for entry in contents {
                guard let dict = entry as? [String: Any],
                      let suggestion = JSON.dict(dict, "searchSuggestionRenderer"),
                      let text = JSON.runsText(JSON.dict(suggestion, "content")) else { continue }
                result.append(text)
            }
        }
        return result
    }

    /// POST /youtubei/v1/player — mirrors `InnerTube.player` with the
    /// IOS -> ANDROID_VR -> WEB fallback chain (innertubex ClientFallbackStrategy).
    func player(_ videoId: String) async throws -> PlayerStream {
        var lastError: Error = InnerTubeError.badPayload("no client produced a player response")

        for client in YouTubeClient.playbackOrder {
            do {
                let body: [String: Any] = [
                    "context": context(for: client),
                    "videoId": videoId,
                    "contentCheckOk": true,
                    "racyCheckOk": true,
                ]
                let data = try await post("player", client: client, body: body)
                let stream = try parsePlayerResponse(data, videoId: videoId, clientName: client.clientName)
                if stream.playable {
                    return stream
                }
                lastError = InnerTubeError.unplayable("Player status not OK via \(client.clientName)")
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    // MARK: - Transport (header contract mirrors innertubex `ytClient`)

    private func post(
        _ endpoint: String,
        client: YouTubeClient,
        body: [String: Any],
        base: String? = nil,
        originOverride: String? = nil
    ) async throws -> Data {
        guard let url = URL(string: "\(base ?? apiBase)/\(endpoint)?prettyPrint=false") else {
            throw InnerTubeError.badPayload("bad endpoint url")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("1", forHTTPHeaderField: "X-Goog-Api-Format-Version")
        request.setValue(client.clientId, forHTTPHeaderField: "X-YouTube-Client-Name")
        request.setValue(client.clientVersion, forHTTPHeaderField: "X-YouTube-Client-Version")

        let effectiveOrigin = originOverride ?? origin
        request.setValue(effectiveOrigin, forHTTPHeaderField: "Origin")
        request.setValue(effectiveOrigin, forHTTPHeaderField: "X-Origin")
        request.setValue(effectiveOrigin + "/", forHTTPHeaderField: "Referer")
        request.setValue("\(locale.hl),\(locale.gl);q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.setValue(client.userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw InnerTubeError.badPayload("non-HTTP response")
        }
        guard (200...299).contains(http.statusCode) else {
            throw InnerTubeError.http(http.statusCode)
        }
        return data
    }

    /// InnerTube `context` object — mirrors innertubex `YouTubeClient.toContext`.
    private func context(for client: YouTubeClient) -> [String: Any] {
        var clientDict: [String: Any] = [
            "clientName": client.clientName,
            "clientVersion": client.clientVersion,
            "gl": locale.gl,
            "hl": locale.hl,
        ]
        // innertubex sets includeUserAgentInContext on native clients.
        if client.clientName == "IOS" || client.clientName == "ANDROID" || client.clientName == "ANDROID_VR" {
            clientDict["userAgent"] = client.userAgent
        }
        if let osName = client.osName { clientDict["osName"] = osName }
        if let osVersion = client.osVersion { clientDict["osVersion"] = osVersion }
        if let make = client.deviceMake { clientDict["deviceMake"] = make }
        if let model = client.deviceModel { clientDict["deviceModel"] = model }
        if let sdk = client.androidSdkVersion { clientDict["androidSdkVersion"] = sdk }
        if let platform = client.platform { clientDict["platform"] = platform }

        return [
            "client": clientDict,
            "user": ["lockedSafetyMode": false],
        ]
    }

    // MARK: - Player parsing

    private func parsePlayerResponse(
        _ data: Data,
        videoId: String,
        clientName: String
    ) throws -> PlayerStream {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw InnerTubeError.badPayload("player body is not JSON")
        }

        let playability = JSON.dict(json, "playabilityStatus")
        let status = playability.flatMap { JSON.string($0, "status") } ?? ""
        guard status == "OK" else {
            let reason = playability.flatMap { JSON.string($0, "reason") } ?? "not playable"
            throw InnerTubeError.unplayable("\(reason) (via \(clientName))")
        }

        guard let details = JSON.dict(json, "videoDetails") else {
            throw InnerTubeError.badPayload("missing videoDetails")
        }

        let streaming = JSON.dict(json, "streamingData")

        let hls = streaming
            .flatMap { JSON.string($0, "hlsManifestUrl") }
            .flatMap { URL(string: $0) }

        var progressive: URL?
        if let formats = streaming?["formats"] as? [[String: Any]] {
            let mp4 = formats
                .filter { (($0["url"] as? String) ?? "").isEmpty == false }
                .filter { (($0["mimeType"] as? String) ?? "").contains("video/mp4") }
                .sorted { (JSON.number($0, "bitrate") ?? 0) > (JSON.number($1, "bitrate") ?? 0) }
            if let best = mp4.first, let urlString = best["url"] as? String {
                progressive = URL(string: urlString)
            }
        }

        let thumbs = (details["thumbnail"] as? [String: Any])
            .flatMap { $0["thumbnails"] as? [[String: Any]] } ?? []
        let thumbURLs = thumbs.compactMap { ($0["url"] as? String).flatMap { URL(string: $0) } }

        return PlayerStream(
            videoId: JSON.string(details, "videoId") ?? videoId,
            title: JSON.string(details, "title") ?? "",
            author: JSON.string(details, "author") ?? "",
            durationSeconds: Double(JSON.string(details, "lengthSeconds") ?? "0") ?? 0,
            viewCountText: JSON.string(details, "viewCount") ?? "",
            hlsURL: hls,
            progressiveURL: progressive,
            thumbnails: thumbURLs
        )
    }
}
