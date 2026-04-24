// UI/MenuBar/GlassEffectContainer.swift
// This file provides a reusable glass effect container component
// Location: UI/MenuBar/GlassEffectContainer.swift
// Status: NEW! Extracted from MenuBarContentView

import SwiftUI

/// Glass effect container with gradient background and shimmer overlay
struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content
    
    var body: some View {
        ZStack {
            content
        }
        .background(
            ZStack {
                // Base gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.92, blue: 0.98),
                        Color(red: 0.92, green: 0.88, blue: 0.96),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Shimmer overlay
                ShimmerSweepOverlay(cornerRadius: 12)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.3),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color(red: 0.82, green: 0.72, blue: 0.94).opacity(0.2),
            radius: 12,
            x: 0,
            y: 4
        )
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
