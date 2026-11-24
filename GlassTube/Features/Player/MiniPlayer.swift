//
//  MiniPlayer.swift
//  GlassTube
//
//  Bottom mini-player bar: tap or fling upward to expand the full player,
//  fling down to stop — both decisions use momentum projection.
//

import SwiftUI

struct MiniPlayerBar: View {
    @EnvironmentObject private var app: AppEnvironment
    let item: VideoItem

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(Theme.body(13.5))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(item.channel)
                    .font(Theme.body(11.5))
                    .foregroundStyle(Theme.inkDim)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button {
                withAnimation(Spring.opulent) { app.isPlayerPresented = true }
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Theme.accent)
            }
            .buttonStyle(PressableStyle(scale: 0.85))

            Button {
                app.stopPlayback()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.inkDim)
            }
            .buttonStyle(PressableStyle(scale: 0.85))
        }
        .padding(10)
        .glassPanel(.thick, cornerRadius: 20, shadow: true)
        .padding(.horizontal, 14)
        .offset(y: dragOffset)
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    // Follow upward flings 1:1; damp downward drags.
                    dragOffset = value.translation.height < 0
                        ? value.translation.height
                        : value.translation.height * 0.3
                }
                .onEnded { value in
                    let velocity = value.velocity.height
                    let projected = SpringPhysics.momentumTarget(
                        from: dragOffset,
                        velocity: velocity,
                        influence: 0.3
                    )
                    if projected < -70 || velocity < -700 {
                        // Fling up -> expand the full player.
                        Haptics.thump()
                        withAnimation(Spring.opulent) { app.isPlayerPresented = true }
                    } else if projected > 120 || velocity > 900 {
                        // Fling down -> stop playback.
                        app.stopPlayback()
                    } else {
                        withAnimation(Spring.bouncy) { dragOffset = 0 }
                    }
                }
        )
        .onTapGesture {
            withAnimation(Spring.opulent) { app.isPlayerPresented = true }
        }
    }

    private var thumbnail: some View {
        ZStack {
            AsyncImage(url: item.thumbnail) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Rectangle().fill(Theme.bgSoft)
                }
            }
            .frame(width: 64, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Image(systemName: "play.fill")
                .font(.system(size: 12))
                .foregroundStyle(.white)
        }
    }
}
