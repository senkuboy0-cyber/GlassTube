//
//  YouTubeClient.swift
//  GlassTube
//
//  Swift mirror of InnerTubeX's YouTubeClient profiles
//  (MetrolistGroup/innertubex —
//  src/commonMain/kotlin/com/metrolist/innertubex/models/YouTubeClient.kt).
//  Values match innertubex v0.13.1 exactly, so responses stay consistent
//  between the Kotlin library and this client.
//

import Foundation

/// An InnerTube client identity: name, version, numeric id and device profile.
struct YouTubeClient: Hashable {
    let clientName: String
    let clientVersion: String
    let clientId: String
    let userAgent: String
    let osName: String?
    let osVersion: String?
    let deviceMake: String?
    let deviceModel: String?
    let androidSdkVersion: String?
    let platform: String?

    /// API-only web client (search / browse). Matches innertubex `WEB`.
    static let web = YouTubeClient(
        clientName: "WEB",
        clientVersion: "2.20260708.00.00",
        clientId: "1",
        userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0",
        osName: nil,
        osVersion: nil,
        deviceMake: nil,
        deviceModel: nil,
        androidSdkVersion: nil,
        platform: nil
    )

    /// Native iOS player profile. Matches innertubex `IOS`.
    static let ios = YouTubeClient(
        clientName: "IOS",
        clientVersion: "21.26.4",
        clientId: "5",
        userAgent: "com.google.ios.youtube/21.26.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)",
        osName: "iPhone",
        osVersion: "18.3.2.22D82",
        deviceMake: "Apple",
        deviceModel: "iPhone16,2",
        androidSdkVersion: nil,
        platform: nil
    )

    /// Android VR playback fallback (yt-dlp profile).
    /// Matches innertubex `ANDROID_VR_1_65_10`.
    static let androidVR = YouTubeClient(
        clientName: "ANDROID_VR",
        clientVersion: "1.65.10",
        clientId: "28",
        userAgent: "com.google.android.apps.youtube.vr.oculus/1.65.10 (Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip",
        osName: "Android",
        osVersion: "12L",
        deviceMake: "Oculus",
        deviceModel: "Quest 3",
        androidSdkVersion: "32",
        platform: nil
    )

    /// YouTube Music web identity, used for search suggestions.
    /// Matches innertubex `WEB_REMIX`.
    static let webRemix = YouTubeClient(
        clientName: "WEB_REMIX",
        clientVersion: "1.20260707.12.00",
        clientId: "67",
        userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0",
        osName: nil,
        osVersion: nil,
        deviceMake: nil,
        deviceModel: nil,
        androidSdkVersion: nil,
        platform: nil
    )

    /// Playback fallback order — mirrors innertubex's client fallback strategy.
    static let playbackOrder: [YouTubeClient] = [.ios, .androidVR, .web]
}
