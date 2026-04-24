// UI/MenuBar/MenuBarContentView.swift
// This file contains the main menu bar UI components
// Location: UI/MenuBar/MenuBarContentView.swift

import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var appState: AppState
    let coordinator: PlaybackCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            retroTVSection
            if appState.errorMessage != nil {
                Divider()
                footer
            }
        }
        .frame(width: 340)
    }

    private var retroTVSection: some View {
        NowPlayingShowcaseView(
            artworkURL: appState.playback?.artworkURL,
            isPlaying: appState.playback?.isPlaying ?? false,
            hasPlayback: appState.playback != nil,
            progressFraction: appState.playback?.progressFraction ?? 0,
            isDisabled: appState.isPerformingAction,
            title: appState.playback?.title ?? "Nothing playing",
            artist: appState.playback?.artistLine ?? "Play media on your Mac to start", 
            album: appState.playback?.album,

            onPrevious: { Task { await coordinator.previousTrack() } },
            onPlayPause: { Task { await coordinator.playPause() } },
            onNext: { Task { await coordinator.nextTrack() } }
        )
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let errorMessage = appState.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct NowPlayingShowcaseView: View {
    let artworkURL: URL?
    let isPlaying: Bool
    let hasPlayback: Bool
    let progressFraction: Double
    let isDisabled: Bool
    let title: String
    let artist: String
    let album: String?
    let onPrevious: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void
    @State private var frozenVinylAngle: Double = 0
    @State private var spinStartDate: Date?
    @State private var playButtonBounce = false
    @State private var stopperOverrideEngaged: Bool?
    @State private var needlePulse = false
    @State private var floatingNotes: [FloatingMusicNote] = FloatingMusicNote.makeRandomSet()

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            VStack(spacing: 10) {
                HStack(spacing: 0) {
                    albumArtCard

                    VStack(spacing: 8) {
                        companionKittyView
                    }
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .top) {
                        appShortcutsRow
                            .offset(y: -50)
                    }
                }
                .padding(.leading, 8)
                .padding(.horizontal, 12)
                .padding(.top, 25)

                Divider()
                    .overlay(Color.white.opacity(0.45))
                    .padding(.horizontal, 8)

                VStack(spacing: 8) {
                    VStack(spacing: 4) {
                        MarqueeText(text: title, isActive: isPlaying)
                            .multilineTextAlignment(.center)
                        Text(artist)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        if let album, !album.isEmpty {
                            Text(album)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    HStack(spacing: 8) {
                        TransportControlButton(
                            systemName: "backward.fill",
                            isProminent: false,
                            action: onPrevious
                        )
                        .disabled(isDisabled)

                        TransportControlButton(
                            systemName: stopperIsEngaged ? "pause.fill" : "play.fill",
                            isProminent: true,
                            pulse: playButtonBounce,
                            action: triggerPlayPause
                        )
                        .disabled(isDisabled)

                        TransportControlButton(
                            systemName: "forward.fill",
                            isProminent: false,
                            action: onNext
                        )
                        .disabled(isDisabled)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 25)
                .overlay {
                    if stopperIsEngaged {
                        floatingNotesAccent
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.00, green: 0.97, blue: 0.99),
                                Color(red: 0.98, green: 0.94, blue: 0.97),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.82), lineWidth: 1)
            )
            .shadow(color: Color(red: 0.82, green: 0.72, blue: 0.84).opacity(0.14), radius: 8, y: 3)
        }
        .frame(maxWidth: .infinity)
        .task {
            await cycleFloatingNotes()
        }
    }

    private var albumArtCard: some View {
        ZStack {
            TimelineView(.animation) { timeline in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.00, green: 0.82, blue: 0.90),
                                Color(red: 0.97, green: 0.58, blue: 0.76),
                                Color(red: 0.87, green: 0.28, blue: 0.58),
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: 82
                        )
                    )
                    .overlay {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.22), lineWidth: 1.5)
                    }
                    .overlay {
                        // Subtle groove rings for a vinyl-like texture.
                        ZStack {
                            ForEach([26.0, 40.0, 54.0, 68.0], id: \.self) { radius in
                                Circle()
                                    .stroke(Color.black.opacity(0.12), lineWidth: 0.8)
                                    .padding(radius)
                            }
                        }
                    }
                    .overlay {
                        GlitterFlecksOverlay()
                            .clipShape(Circle())
                    }
                    .overlay {
                        centerArtworkLabel
                    }
                    .rotationEffect(.degrees(vinylAngle(at: timeline.date)))
            }
            .shadow(
                color: Color.black.opacity(needlePulse ? 0.28 : 0.18),
                radius: needlePulse ? 12 : 8,
                y: needlePulse ? 6 : 4
            )
            .frame(width: 150, height: 150)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.38), lineWidth: 1)
            )

            vinylStopper
        }
        .frame(width: 150, height: 150)
        .onAppear {
            syncSpinState()
        }
        .onChange(of: isPlaying) {
            syncSpinState()
            stopperOverrideEngaged = nil
        }
        .onChange(of: stopperOverrideEngaged) {
            syncSpinState()
        }
    }

    private var centerArtworkLabel: some View {
        ZStack {
            Group {
                if hasPlayback, let artworkURL {
                    AsyncImage(url: artworkURL) { phase in
                        if case let .success(image) = phase {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            kittyNoMusicImage
                        }
                    }
                } else {
                    kittyNoMusicImage
                }
            }
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
            }
            .padding(6)

            Circle()
                .trim(from: 0, to: progressFraction)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(red: 1.00, green: 0.52, blue: 0.83),
                            Color(red: 0.84, green: 0.72, blue: 1.00),
                            Color(red: 1.00, green: 0.78, blue: 0.92),
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(1)
        }
        .frame(width: 72, height: 72)
    }

    private var companionKittyView: some View {
        AnimatedGIFView(resourceName: "dancing-kitty", isAnimating: isPlaying)
            .frame(width: 60, height: 60)
            .offset(y: 10)
    }

    private var appShortcutsRow: some View {
        HStack(spacing: 8) {
            AppShortcutIconButton(
                symbol: "waveform.circle.fill",
                tint: Color(red: 1.00, green: 0.43, blue: 0.74),
                helpText: "Open Spotify"
            ) {
                AppCommands.openMediaApp(.spotify)
            }

            AppShortcutIconButton(
                symbol: "apple.logo",
                tint: Color(red: 0.97, green: 0.36, blue: 0.68),
                helpText: "Open Apple Music"
            ) {
                AppCommands.openMediaApp(.appleMusic)
            }

            AppShortcutIconButton(
                symbol: "play.circle.fill",
                tint: Color(red: 0.93, green: 0.29, blue: 0.61),
                helpText: "Open YT Music"
            ) {
                AppCommands.openMediaApp(.ytMusic)
            }
        }
    }

    private var floatingNotesAccent: some View {
        TimelineView(.animation) { timeline in
            ZStack {
                ForEach(floatingNotes) { note in
                    Image(systemName: "music.note")
                        .font(.system(size: note.size, weight: .semibold))
                        .foregroundStyle(
                            Color(red: 0.84, green: 0.31, blue: 0.58).opacity(note.opacity)
                        )
                        .offset(
                            x: note.horizontalOffset,
                            y: noteYPosition(note: note, at: timeline.date)
                        )
                }
            }
            .frame(width: 320, height: 140)
            .offset(y: -10)
            .animation(.easeInOut(duration: 0.5), value: floatingNotes)
        }
        .allowsHitTesting(false)
    }

    private var artworkPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.90, green: 0.88, blue: 0.94),
                    Color(red: 0.84, green: 0.78, blue: 0.90),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Group {
                if let kittyImage = loadImageResource(named: "kitty-no-music", withExtension: "png") {
                    Image(nsImage: kittyImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                }
            }
            .frame(width: 52, height: 52)
            .background(
                Circle()
                    .fill(Color.white.opacity(0.78))
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.88), lineWidth: 1)
            )
        }
    }

    private var kittyNoMusicImage: some View {
        Group {
            if let kittyImage = loadImageResource(named: "kitty-no-music", withExtension: "png") {
                Image(nsImage: kittyImage)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else if let fallbackImage = NSImage(named: "dancing-kitty") {
                Image(nsImage: fallbackImage)
                    .resizable()
                    .scaledToFill()
            } else {
                artworkPlaceholder
            }
        }
    }

    private var vinylStopper: some View {
        Button(action: handleStopperTap) {
            ZStack(alignment: .top) {
                ZStack(alignment: .top) {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.95),
                                    Color(red: 0.86, green: 0.86, blue: 0.90),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 9, height: 84)
                        .overlay {
                            Capsule()
                                .stroke(Color.black.opacity(0.12), lineWidth: 0.8)
                        }

                    Circle()
                        .fill(Color(red: 0.96, green: 0.90, blue: 0.95))
                        .frame(width: 20, height: 20)
                        .overlay {
                            Circle()
                                .stroke(Color.black.opacity(0.14), lineWidth: 0.8)
                        }
                        .scaleEffect(needlePulse ? 1.16 : 1.0)
                        .shadow(
                            color: Color.white.opacity(needlePulse ? 0.55 : 0.18),
                            radius: needlePulse ? 5 : 1
                        )
                        .offset(y: 67)
                }
                .offset(y: -5)
                .rotationEffect(.degrees(stopperIsEngaged ? 22 : -12), anchor: .top)

                Circle()
                    .fill(Color(red: 0.25, green: 0.25, blue: 0.30))
                    .frame(width: 14, height: 14)
                    .offset(y: -5)
            }
            .frame(width: 44, height: 98)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .offset(x: 80, y: -46)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: stopperIsEngaged)
        .help(stopperIsEngaged ? "Click stopper to stop." : "Click stopper to resume.")
    }

    private var stopperIsEngaged: Bool {
        stopperOverrideEngaged ?? isPlaying
    }

    private func handleStopperTap() {
        stopperOverrideEngaged = !stopperIsEngaged
        triggerPlayPause()
    }

    private func triggerPlayPause() {
        playButtonBounce = true
        needlePulse = true
        onPlayPause()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            needlePulse = false
            try? await Task.sleep(for: .milliseconds(220))
            playButtonBounce = false
        }
    }

    private func syncSpinState() {
        let now = Date()
        if stopperIsEngaged {
            spinStartDate = now
        } else {
            if let spinStartDate {
                frozenVinylAngle = normalizedAngle(
                    frozenVinylAngle + (now.timeIntervalSince(spinStartDate) / 4.0) * 360
                )
            }
            self.spinStartDate = nil
        }
    }

    private func vinylAngle(at date: Date) -> Double {
        guard stopperIsEngaged, let spinStartDate else { return frozenVinylAngle }
        let delta = (date.timeIntervalSince(spinStartDate) / 4.0) * 360
        return normalizedAngle(frozenVinylAngle + delta)
    }

    private func normalizedAngle(_ angle: Double) -> Double {
        angle.truncatingRemainder(dividingBy: 360)
    }

    private func loadImageResource(named resourceName: String, withExtension resourceExtension: String) -> NSImage? {
        if let url = resolvedResourceURL(named: resourceName, withExtension: resourceExtension),
           let image = NSImage(contentsOf: url) {
            return image
        }
        return NSImage(named: resourceName)
    }

    private func resolvedResourceURL(named resourceName: String, withExtension resourceExtension: String) -> URL? {
        let candidateBundles = [Bundle.main] + Bundle.allBundles + Bundle.allFrameworks
        for bundle in candidateBundles {
            if let url = bundle.url(forResource: resourceName, withExtension: resourceExtension) {
                return url
            }
        }

        // Local-development fallback when images are kept in project root /Frameworks.
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let localFrameworkResource = projectRoot
            .appendingPathComponent("Frameworks")
            .appendingPathComponent("\(resourceName).\(resourceExtension)")
        if FileManager.default.fileExists(atPath: localFrameworkResource.path) {
            return localFrameworkResource
        }
        return nil
    }

    private func cycleFloatingNotes() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(1200))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.45)) {
                    floatingNotes = FloatingMusicNote.makeRandomSet()
                }
            }
        }
    }

    private func noteYPosition(note: FloatingMusicNote, at date: Date) -> CGFloat {
        let time = date.timeIntervalSinceReferenceDate
        let wave = sin(((time + note.phase) / note.period) * .pi * 2)
        return note.baseVerticalOffset - (wave * note.bounceAmplitude)
    }

}

private struct FloatingMusicNote: Identifiable, Equatable {
    let id = UUID()
    let horizontalOffset: CGFloat
    let baseVerticalOffset: CGFloat
    let bounceAmplitude: CGFloat
    let period: Double
    let phase: Double
    let size: CGFloat
    let opacity: Double

    static func makeRandomSet() -> [FloatingMusicNote] {
        let count = Int.random(in: 2...4)
        let anchors: [(CGFloat, CGFloat)] = [
            (-132, 26), (-120, 38), (120, 38), (132, 26),
            (-126, 2), (126, 2), (-108, -30), (108, -30)
        ]
        return anchors.shuffled().prefix(count).map { anchor in
            FloatingMusicNote(
                horizontalOffset: anchor.0 + CGFloat.random(in: -6...6),
                baseVerticalOffset: anchor.1 + CGFloat.random(in: -5...5),
                bounceAmplitude: CGFloat.random(in: 1.4...3.2),
                period: Double.random(in: 1.0...1.8),
                phase: Double.random(in: 0...2),
                size: CGFloat.random(in: 11...16),
                opacity: Double.random(in: 0.58...0.9)
            )
        }
    }
}

private struct AnimatedGIFView: NSViewRepresentable {
    let resourceName: String
    var isAnimating: Bool = true

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.clear.cgColor
        container.layer?.masksToBounds = true

        let imageView = NSImageView()
        imageView.wantsLayer = true
        imageView.layer?.backgroundColor = NSColor.clear.cgColor
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        imageView.animates = isAnimating
        imageView.canDrawSubviewsIntoLayer = false
        imageView.image = loadImage()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let imageView = nsView.subviews.first as? NSImageView else { return }
        if imageView.image == nil {
            imageView.image = loadImage()
        }
        if !isAnimating {
            // Reset image so non-playing state stays on a stable still frame.
            imageView.image = loadImage()
        }
        imageView.animates = isAnimating
    }

    private func resolvedGIFURL() -> URL? {
        let candidateBundles = [Bundle.main] + Bundle.allBundles + Bundle.allFrameworks
        for bundle in candidateBundles {
            if let url = bundle.url(forResource: resourceName, withExtension: "gif") {
                return url
            }
        }

        // Local-development fallback when GIF is kept in project root /Frameworks.
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let localFrameworkGIF = projectRoot
            .appendingPathComponent("Frameworks")
            .appendingPathComponent("\(resourceName).gif")
        if FileManager.default.fileExists(atPath: localFrameworkGIF.path) {
            return localFrameworkGIF
        }
        return nil
    }

    private func loadImage() -> NSImage? {
        if let url = resolvedGIFURL(), let image = NSImage(contentsOf: url) {
            return image
        }
        return NSImage(named: resourceName)
    }
}

private struct AppShortcutIconButton: View {
    let symbol: String
    let tint: Color
    let helpText: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color.white.opacity(isHovered ? 0.98 : 0.92))
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.92), lineWidth: 1)
                )
                .shadow(color: tint.opacity(isHovered ? 0.28 : 0.12), radius: isHovered ? 5 : 2)
                .scaleEffect(isHovered ? 1.08 : 1.0)
        }
        .buttonStyle(.plain)
        .help(helpText)
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.75)) {
                isHovered = hovering
            }
        }
    }
}

private struct TransportControlButton: View {
    let systemName: String
    let isProminent: Bool
    var pulse: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: isProminent ? .bold : .semibold))
                .foregroundStyle(isProminent ? Color.white : Color(red: 1.0, green: 0.16, blue: 0.62))
                .frame(width: isProminent ? 38 : 34, height: isProminent ? 32 : 30)
                .background {
                    Capsule()
                        .fill(backgroundFill)
                }
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.9), lineWidth: 1)
                }
                .overlay {
                    if isHovered {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(
                                isProminent
                                    ? Color.white.opacity(0.95)
                                    : Color(red: 1.0, green: 0.45, blue: 0.76).opacity(0.9)
                            )
                            .offset(x: 12, y: -11)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .shadow(color: isHovered ? Color(red: 1.0, green: 0.50, blue: 0.80).opacity(0.35) : .clear, radius: 8)
                .scaleEffect(isHovered ? 1.06 : 1.0)
                .scaleEffect(pulse ? 1.12 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.58), value: pulse)
    }

    private var backgroundFill: some ShapeStyle {
        if isProminent {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.30, blue: 0.72),
                        Color(red: 1.0, green: 0.16, blue: 0.62),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        return AnyShapeStyle(Color.white.opacity(0.94))
    }
}

private struct GlitterFlecksOverlay: View {
    private struct Fleck: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
    }

    private let flecks: [Fleck] = (0..<26).map { _ in
        Fleck(
            x: .random(in: 0.08...0.92),
            y: .random(in: 0.08...0.92),
            size: .random(in: 1.2...2.6),
            opacity: .random(in: 0.18...0.44)
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(flecks) { fleck in
                    Circle()
                        .fill(Color.white.opacity(fleck.opacity))
                        .frame(width: fleck.size, height: fleck.size)
                        .position(x: fleck.x * proxy.size.width, y: fleck.y * proxy.size.height)
                }
            }
        }
    }
}

private struct FloatingHeartsOverlay: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.2)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                heart(t: t, phase: 0.0, x: -10, baseY: 12, size: 7, color: Color(red: 1.0, green: 0.52, blue: 0.80))
                heart(t: t, phase: 1.4, x: 8, baseY: 10, size: 6, color: Color(red: 0.86, green: 0.74, blue: 1.0))
                heart(t: t, phase: 2.2, x: 0, baseY: 16, size: 5, color: Color.white.opacity(0.95))
            }
        }
        .allowsHitTesting(false)
    }

    private func heart(t: TimeInterval, phase: Double, x: CGFloat, baseY: CGFloat, size: CGFloat, color: Color) -> some View {
        let wave = (sin((t + phase) * 1.8) + 1) * 0.5
        return Image(systemName: "heart.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(color.opacity(0.35 + wave * 0.45))
            .offset(x: x + CGFloat(sin((t + phase) * 1.2) * 2.5), y: baseY - CGFloat(wave * 10))
    }
}

private struct ShimmerSweepOverlay: View {
    let cornerRadius: CGFloat
    @State private var sweep = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.28),
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width * 0.42, height: height * 1.5)
                .rotationEffect(.degrees(22))
                .offset(x: sweep ? width * 0.95 : -width * 0.75)
                .onAppear {
                    withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) {
                        sweep = true
                    }
                }
        }
        .blendMode(.screen)
        .allowsHitTesting(false)
    }
}

private struct MarqueeText: View {
    let text: String
    let isActive: Bool
    private let spacing: CGFloat = 28

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var offsetX: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                if isActive && textWidth > width {
                    HStack(spacing: spacing) {
                        textLabel
                        textLabel
                    }
                    .offset(x: offsetX)
                    .onAppear {
                        containerWidth = width
                        startScrolling()
                    }
                    .onChange(of: width) { newWidth in
                        containerWidth = newWidth
                        startScrolling()
                    }
                    .onChange(of: text) { _ in
                        startScrolling()
                    }
                    .onChange(of: isActive) { _ in
                        startScrolling()
                    }
                } else {
                    Text(text)
                        .font(.headline)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .frame(maxWidth: .infinity)
            .clipped()
        }
        .frame(height: 22)
    }

    private var textLabel: some View {
        Text(text)
            .font(.headline)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .readWidth { textWidth = $0 }
    }

    private func startScrolling() {
        guard isActive, textWidth > containerWidth else {
            offsetX = 0
            return
        }

        offsetX = 0
        let distance = textWidth + spacing
        let duration = max(5, Double(distance / 22))
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            offsetX = -distance
        }
    }
}

private struct WidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private extension View {
    func readWidth(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(key: WidthPreferenceKey.self, value: proxy.size.width)
            }
        )
        .onPreferenceChange(WidthPreferenceKey.self, perform: onChange)
    }
}

private struct SourceBadge: View {
    let source: PlaybackSource

    var body: some View {
        Text(source.rawValue.capitalized)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(backgroundColor.opacity(0.18))
            .foregroundStyle(backgroundColor)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch source {
        case .desktop:
            return .green
        case .error:
            return .red
        }
    }
}
