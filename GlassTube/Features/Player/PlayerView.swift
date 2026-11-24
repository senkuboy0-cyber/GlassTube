//
//  PlayerView.swift
//  GlassTube
//
//  Full-screen player: AVPlayerLayer video, liquid-glass controls,
//  spring-bouncing transport buttons, momentum drag-to-dismiss,
//  double-tap ±10 s and a velocity-aware scrubber.
//

import SwiftUI
import AVFoundation
import MediaPlayer
import Combine

// MARK: - Host (shown as overlay from RootContainer)

struct PlayerHostView: View {
    @EnvironmentObject private var app: AppEnvironment

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let stream = app.stream {
                PlayerView(stream: stream, item: app.nowPlaying ?? PlayerHostView.item(from: stream))
            } else if let error = app.streamError {
                PlayerErrorPanel(message: error)
            } else {
                PlayerLoadingPanel(item: app.nowPlaying)
            }
        }
    }

    private static func item(from stream: PlayerStream) -> VideoItem {
        VideoItem(
            id: stream.videoId,
            title: stream.title,
            channel: stream.author,
            viewsText: "",
            publishedText: "",
            durationText: "",
            thumbnail: stream.thumbnails.last
        )
    }
}

// MARK: - Player view

struct PlayerView: View {
    let stream: PlayerStream
    let item: VideoItem

    @EnvironmentObject private var app: AppEnvironment
    @StateObject private var model: PlayerViewModel
    @State private var controlsVisible = true
    @State private var controlsHideTask: Task<Void, Never>?
    @State private var dismissDrag: CGFloat = 0
    @State private var seekFlash: String?

    init(stream: PlayerStream, item: VideoItem) {
        self.stream = stream
        self.item = item
        _model = StateObject(wrappedValue: PlayerViewModel(stream: stream))
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                videoArea(height: geo.size.height * 0.46)
                Spacer(minLength: 0)
                metaPanel
            }
        }
        .offset(y: dismissDrag)
        .scaleEffect(1 - min(dismissDrag / 1400, 0.06), anchor: .top)
        .gesture(dismissGesture)
        .onAppear {
            model.activateAudioSession()
            scheduleHide()
        }
        .onDisappear {
            model.shutdown()
        }
    }

    // MARK: Video area

    private func videoArea(height: CGFloat) -> some View {
        ZStack {
            PlayerLayerView(player: model.player)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipped()

            // Double-tap seek zones + single tap toggles controls.
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { model.seekBy(-10); flashSeek("gobackward.10") }
                    .onTapGesture { toggleControls() }

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { model.seekBy(10); flashSeek("goforward.10") }
                    .onTapGesture { toggleControls() }
            }
            .frame(height: height)

            if let symbol = seekFlash {
                Image(systemName: symbol)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(24)
                    .background(.ultraThinMaterial, in: Circle())
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            }

            if controlsVisible {
                controlsOverlay(height: height)
            }
        }
        .frame(height: height)
    }

    private func controlsOverlay(height: CGFloat) -> some View {
        VStack {
            HStack(spacing: 10) {
                Button {
                    app.dismissPlayer()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(PressableStyle(scale: 0.88))

                Text(stream.title.isEmpty ? item.title : stream.title)
                    .font(Theme.body(14))
                    .lineLimit(1)
                    .foregroundStyle(.white)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)

            Spacer()

            HStack(spacing: 34) {
                circleButton("gobackward.10") {
                    model.seekBy(-10)
                    scheduleHide()
                }
                Button {
                    model.togglePlay()
                    Haptics.tap()
                    scheduleHide()
                } label: {
                    Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                }
                .buttonStyle(GlassPlayButtonStyle())
                circleButton("goforward.10") {
                    model.seekBy(10)
                    scheduleHide()
                }
            }
            .opacity(model.isBuffering ? 0.45 : 1)

            Spacer()

            VStack(spacing: 6) {
                GlassScrubber(model: model)
                HStack {
                    Text(model.formatTime(model.currentTime))
                        .font(Theme.mono)
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    Text(model.formatTime(model.duration))
                        .font(Theme.mono)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .frame(height: height)
        .transition(.opacity)
    }

    private func circleButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
        }
        .buttonStyle(GlassPlayButtonStyle())
    }

    // MARK: Meta panel

    private var metaPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Theme.coolGradient)
                    Text(String(item.channel.prefix(1)).uppercased())
                        .font(Theme.title(15, weight: .heavy))
                        .foregroundStyle(.white)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(stream.title.isEmpty ? item.title : stream.title)
                        .font(Theme.body(15.5))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(metaText)
                        .font(Theme.body(12.5))
                        .foregroundStyle(Theme.inkDim)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Button {
                    app.toggleWatchLater(item)
                } label: {
                    Image(systemName: app.isWatchLater(item) ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(app.isWatchLater(item) ? Theme.accent : Theme.inkDim)
                        .frame(width: 42, height: 42)
                }
            }

            HStack(spacing: 8) {
                GlassChip(systemImage: "play.tv", text: "Stream")
                if stream.hlsURL != nil {
                    GlassChip(systemImage: "dot.radiowaves.left.and.right", text: "HLS")
                }
                if stream.progressiveURL != nil {
                    GlassChip(systemImage: "arrow.down.forward.square", text: "MP4")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassPanel(.regular, cornerRadius: 26, shadow: false)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    private var metaText: String {
        var parts: [String] = []
        if !stream.author.isEmpty { parts.append(stream.author) }
        if !stream.viewCountText.isEmpty {
            if let count = Double(stream.viewCountText) {
                parts.append("\(Int(count).abbreviated) views")
            } else {
                parts.append("\(stream.viewCountText) views")
            }
        }
        if parts.isEmpty { parts.append(item.channel) }
        return parts.joined(separator: " · ")
    }

    // MARK: Gestures & helpers

    /// Drag down anywhere to dismiss — release velocity drives the decision
    /// (momentum), otherwise the view springs back.
    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onChanged { value in
                guard value.translation.height > 0,
                      value.translation.height > abs(value.translation.width) else { return }
                dismissDrag = value.translation.height
            }
            .onEnded { value in
                let velocity = value.velocity.height
                let projected = SpringPhysics.momentumTarget(
                    from: dismissDrag,
                    velocity: velocity,
                    influence: 0.35
                )
                if projected > 170 || velocity > 1000 {
                    app.dismissPlayer()
                } else {
                    withAnimation(Spring.bouncy) { dismissDrag = 0 }
                }
            }
    }

    private func toggleControls() {
        withAnimation(Spring.snappy) { controlsVisible.toggle() }
        scheduleHide()
    }

    private func scheduleHide() {
        controlsHideTask?.cancel()
        guard controlsVisible else { return }
        controlsHideTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            withAnimation(Spring.gentle) { controlsVisible = false }
        }
    }

    private func flashSeek(_ symbol: String) {
        withAnimation(Spring.bouncy) { seekFlash = symbol }
        Haptics.tick()
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation(Spring.gentle) { seekFlash = nil }
        }
    }
}

// MARK: - Scrubber

/// Velocity-aware scrubber: dragging scrubs live; release factors the fling
/// velocity into the seek target, then springs.
struct GlassScrubber: View {
    @ObservedObject var model: PlayerViewModel
    @State private var dragFraction: Double?

    var body: some View {
        GeometryReader { geo in
            let fraction = dragFraction ?? model.progressFraction
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.22))
                    .frame(height: 6)
                Capsule()
                    .fill(Theme.heroGradient)
                    .frame(width: max(0, geo.size.width * fraction), height: 6)
                Circle()
                    .fill(.white)
                    .frame(width: 16, height: 16)
                    .shadow(color: Theme.accent.opacity(0.6), radius: 6)
                    .offset(x: max(0, geo.size.width * fraction - 8))
            }
            .frame(height: 24)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragFraction = min(max(0, value.location.x / geo.size.width), 1)
                    }
                    .onEnded { value in
                        let target = min(max(0, value.location.x / geo.size.width), 1)
                        let velocityFraction = value.velocity.width / geo.size.width
                        let projected = SpringPhysics.momentumTarget(
                            from: target,
                            velocity: velocityFraction * 0.18,
                            influence: 1.0
                        )
                        model.seek(toFraction: min(max(0, projected), 1))
                        withAnimation(Spring.bouncy) { dragFraction = nil }
                    }
            )
        }
        .frame(height: 24)
    }
}

// MARK: - States

struct PlayerLoadingPanel: View {
    let item: VideoItem?

    var body: some View {
        VStack(spacing: 18) {
            if let item {
                Text(item.title)
                    .font(Theme.body(15))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            PhysicsLoadingDots(visible: true)
            Text("Resolving streams via InnerTube…")
                .font(Theme.mono)
                .foregroundStyle(Theme.inkDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PlayerErrorPanel: View {
    @EnvironmentObject private var app: AppEnvironment
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Theme.accentHot)
            Text(message)
                .font(Theme.body(14))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            HStack(spacing: 12) {
                Button {
                    app.stopPlayback()
                } label: {
                    Text("Close")
                }
                .buttonStyle(GlassButtonStyle())

                Button {
                    Task { await app.retryStream() }
                } label: {
                    Text("Retry")
                }
                .buttonStyle(GlassButtonStyle(tint: Theme.accentCool))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - AVPlayerLayer bridge

struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    final class PlayerContainerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
    }
}

// MARK: - View model

/// Plain ObservableObject (not actor-isolated): every mutation happens on the
/// main queue, so `@Published` changes are always delivered on the main actor.
final class PlayerViewModel: ObservableObject {

    let player: AVPlayer
    let stream: PlayerStream

    @Published private(set) var isPlaying = true
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var isBuffering = true

    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    var progressFraction: Double {
        guard duration > 0 else { return 0 }
        return min(max(0, currentTime / duration), 1)
    }

    init(stream: PlayerStream) {
        self.stream = stream
        duration = stream.durationSeconds

        if let url = stream.playbackURL {
            player = AVPlayer(playerItem: AVPlayerItem(url: url))
        } else {
            player = AVPlayer()
        }
        player.automaticallyWaitsToMinimizeStalling = true

        // 30 Hz time observer on the main queue.
        let interval = CMTime(seconds: 1.0 / 30.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            self.currentTime = max(0, time.seconds)
            if let itemDuration = self.player.currentItem?.duration,
               itemDuration.isNumeric,
               itemDuration.seconds > 0 {
                self.duration = itemDuration.seconds
            }
        }

        // Transport state via KVO publisher.
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                self.isBuffering = (status == .waitingToPlayAtSpecifiedRate)
                self.isPlaying = (status == .playing)
            }
            .store(in: &cancellables)

        // Loop when playback ends.
        NotificationCenter.default.publisher(
            for: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            guard let self else { return }
            self.player.seek(to: .zero)
            self.player.play()
        }
        .store(in: &cancellables)

        player.play()
    }

    // MARK: Transport

    func togglePlay() {
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
        updateNowPlayingInfo()
    }

    func seekBy(_ seconds: Double) {
        let target = max(0, min(duration, currentTime + seconds))
        player.seek(
            to: CMTime(seconds: target, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
        currentTime = target
        updateNowPlayingInfo()
    }

    func seek(toFraction fraction: Double) {
        let target = fraction * duration
        player.seek(
            to: CMTime(seconds: target, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
        currentTime = target
        updateNowPlayingInfo()
    }

    // MARK: System integration

    func activateAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        updateNowPlayingInfo()
    }

    func updateNowPlayingInfo() {
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = stream.title
        info[MPMediaItemPropertyArtist] = stream.author
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func shutdown() {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        player.pause()
    }

    // MARK: Formatting

    func formatTime(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
}

extension Int {
    /// 1234567 -> "1.2M", 12345 -> "12.3K".
    var abbreviated: String {
        switch self {
        case 1_000_000...:
            return String(format: "%.1fM", Double(self) / 1_000_000)
        case 1_000...:
            return String(format: "%.1fK", Double(self) / 1_000)
        default:
            return String(self)
        }
    }
}
