// AppIconGenerator.swift
// Generate app icon images programmatically
// Run this in a macOS playground or temporary view to export icons

import SwiftUI
import AppKit

#if DEBUG

/// Generates the KittyMusicController app icon using the actual kitty asset
@MainActor
struct AppIconView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Background gradient - extremely light pink
            RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.92, blue: 0.98),       // Extremely light pink
                    Color(red: 1.0, green: 0.88, blue: 0.96)        // Very subtle deeper tone
                ],
                center: .center,
                startRadius: 0,
                endRadius: size * 0.7
            )
            
            // Vinyl record shadow for depth
            Circle()
                .fill(Color.black.opacity(0.2))
                .frame(width: size * 0.7, height: size * 0.7)
                .blur(radius: size * 0.03)
                .offset(y: size * 0.025)
            
            // Vinyl record base - more saturated pink gradient
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.45, blue: 0.70),    // More saturated light pink
                            Color(red: 0.98, green: 0.35, blue: 0.62),   // More saturated medium pink
                            Color(red: 0.95, green: 0.30, blue: 0.58),   // More saturated deeper pink
                            Color(red: 0.98, green: 0.35, blue: 0.62),   // More saturated medium pink
                            Color(red: 1.0, green: 0.45, blue: 0.70)     // Back to saturated light pink
                        ]),
                        center: .center
                    )
                )
                .frame(width: size * 0.65, height: size * 0.65)
            
            // Vinyl shine effect - dramatic highlight
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0.5), location: 0.0),
                            .init(color: Color.white.opacity(0.0), location: 0.15),
                            .init(color: Color.white.opacity(0.0), location: 0.85),
                            .init(color: Color.white.opacity(0.5), location: 1.0)
                        ]),
                        center: .center
                    )
                )
                .frame(width: size * 0.65, height: size * 0.65)
                .blendMode(.overlay)
            
            // Vinyl light reflection - creates realistic shine
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.45, height: size * 0.25)
                .blur(radius: size * 0.015)
                .offset(x: -size * 0.05, y: -size * 0.15)
                .mask(
                    Circle()
                        .frame(width: size * 0.65, height: size * 0.65)
                )
            
            // Vinyl grooves - more refined and visible
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.4),
                            Color.black.opacity(0.3),
                            Color.white.opacity(0.4),
                            Color.black.opacity(0.3),
                            Color.white.opacity(0.4)
                        ]),
                        center: .center
                    ),
                    lineWidth: size * 0.012
                )
                .frame(width: size * 0.58, height: size * 0.58)
            
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.35),
                            Color.black.opacity(0.25),
                            Color.white.opacity(0.35),
                            Color.black.opacity(0.25),
                            Color.white.opacity(0.35)
                        ]),
                        center: .center
                    ),
                    lineWidth: size * 0.01
                )
                .frame(width: size * 0.48, height: size * 0.48)
            
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.black.opacity(0.2),
                            Color.white.opacity(0.3),
                            Color.black.opacity(0.2),
                            Color.white.opacity(0.3)
                        ]),
                        center: .center
                    ),
                    lineWidth: size * 0.008
                )
                .frame(width: size * 0.38, height: size * 0.38)
            
            // Center label shadow
            Circle()
                .fill(Color.black.opacity(0.15))
                .frame(width: size * 0.33, height: size * 0.33)
                .blur(radius: size * 0.012)
            
            // Center label with vinyl color gradient (filled hole) - more saturated
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.98, green: 0.42, blue: 0.65),   // More saturated lighter pink center
                            Color(red: 0.95, green: 0.35, blue: 0.60),   // More saturated medium pink
                            Color(red: 0.92, green: 0.30, blue: 0.56)    // More saturated deeper pink edge
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.15
                    )
                )
                .frame(width: size * 0.3, height: size * 0.3)
            
            // Center label shine
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.0)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: size * 0.12
                    )
                )
                .frame(width: size * 0.3, height: size * 0.3)
            
            // Stronger border on center label
            Circle()
                .stroke(Color.black.opacity(0.15), lineWidth: size * 0.004)
                .frame(width: size * 0.3, height: size * 0.3)
            
            // Kitty image from assets
            if let kittyImage = loadImageResource(named: "kitty-no-music", withExtension: "png") {
                Image(nsImage: kittyImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.38, height: size * 0.38)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: size * 0.004
                            )
                            .frame(width: size * 0.38, height: size * 0.38)
                    )
            } else {
                // Fallback if image not found
                Circle()
                    .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .frame(width: size * 0.25, height: size * 0.25)
            }
            
            // Music note accent with refined positioning and styling
            ZStack {
                // Music note shadow/outline - stronger
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.2, weight: .heavy))
                    .foregroundStyle(Color.black.opacity(0.4))
                    .blur(radius: size * 0.015)
                    .offset(x: size * 0.3, y: -size * 0.28)
                
                // Main music note with dramatic styling
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.2, weight: .heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color(red: 0.95, green: 0.97, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.6), radius: size * 0.03, x: size * 0.005, y: size * 0.015)
                    .shadow(color: Color(red: 0.98, green: 0.45, blue: 0.65).opacity(0.8), radius: size * 0.025)
                    .shadow(color: Color.white.opacity(0.5), radius: size * 0.008)
                    .offset(x: size * 0.3, y: -size * 0.28)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Helper Functions

/// Load image resource from bundle
private func loadImageResource(named name: String, withExtension ext: String) -> NSImage? {
    guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
        return nil
    }
    return NSImage(contentsOf: url)
}

/// Alternative: More minimal music-focused design
@MainActor
struct AppIconViewMinimal: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Background - solid color (square, no rounded corners - Xcode adds those)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.3, green: 0.6, blue: 0.9),  // Blue
                            Color(red: 0.5, green: 0.3, blue: 0.8)   // Purple
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Vinyl record
            VStack(spacing: 0) {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: size * 0.02)
                    .frame(width: size * 0.6, height: size * 0.6)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: size * 0.015)
                            .frame(width: size * 0.45, height: size * 0.45)
                    )
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: size * 0.15, height: size * 0.15)
                    )
            }
        }
        .frame(width: size, height: size)
    }
}

/// Helper to render and save icons
@MainActor
struct AppIconGenerator {
    /// Renders the icon view to an NSImage
    static func generateIcon(size: CGFloat, useMinimal: Bool = false) -> NSImage {
        let view = Group {
            if useMinimal {
                AppIconViewMinimal(size: size)
            } else {
                AppIconView(size: size)
            }
        }
        
        let renderer = ImageRenderer(content: view)
        // Use 1.0 scale so the rendered size matches exactly
        // The size parameter already accounts for @1x vs @2x
        renderer.scale = 1.0
        
        guard let cgImage = renderer.cgImage else {
            print("❌ Failed to create CGImage for size \(size)")
            return NSImage(size: NSSize(width: size, height: size))
        }
        
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
        return nsImage
    }
    
    /// Saves icon to documents folder with the given name
    static func saveIconToDesktop(size: CGFloat, name: String, useMinimal: Bool = false) {
        print("🎨 Starting to generate \(name)...")
        let image = generateIcon(size: size, useMinimal: useMinimal)
        
        guard let tiffData = image.tiffRepresentation else {
            print("❌ Failed to generate TIFF data for \(name)")
            return
        }
        
        guard let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            print("❌ Failed to create bitmap for \(name)")
            return
        }
        
        guard let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            print("❌ Failed to generate PNG data for \(name)")
            return
        }
        
        // Try Documents folder first, then Desktop
        let fileManager = FileManager.default
        var saveURL: URL?
        
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            // Create AppIcons subfolder in Documents
            let appIconsFolder = documentsURL.appendingPathComponent("AppIcons", isDirectory: true)
            try? fileManager.createDirectory(at: appIconsFolder, withIntermediateDirectories: true)
            saveURL = appIconsFolder
        } else if let desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first {
            saveURL = desktopURL
        }
        
        guard let folderURL = saveURL else {
            print("❌ Failed to get save location")
            return
        }
        
        let fileURL = folderURL.appendingPathComponent("\(name).png")
        
        do {
            try pngData.write(to: fileURL)
            print("✅ Saved icon to: \(fileURL.path)")
        } catch {
            print("❌ Failed to save icon \(name): \(error.localizedDescription)")
        }
    }
    
    /// Generates all required macOS app icon sizes
    static func generateAllSizes(useMinimal: Bool = false) {
        // macOS app icon sizes (1x and 2x for each point size)
        let sizes: [(size: CGFloat, name: String)] = [
            (16, "icon_16x16"),
            (32, "icon_16x16@2x"),
            (32, "icon_32x32"),
            (64, "icon_32x32@2x"),
            (128, "icon_128x128"),
            (256, "icon_128x128@2x"),
            (256, "icon_256x256"),
            (512, "icon_256x256@2x"),
            (512, "icon_512x512"),
            (1024, "icon_512x512@2x")
        ]
        
        print("\n🎨 Generating macOS app icons...")
        print("==================================================")
        
        for (size, name) in sizes {
            saveIconToDesktop(size: size, name: name, useMinimal: useMinimal)
        }
        
        print("==================================================")
        print("🎉 Generated all icon sizes!")
        print("📁 Location: ~/Documents/AppIcons/")
        print("\nDrag these files into Assets.xcassets > AppIcon")
    }
}

// MARK: - Preview

#Preview("Cat + Music Note Icon", traits: .fixedLayout(width: 512, height: 512)) {
    AppIconView(size: 512)
}

#Preview("Minimal Vinyl Icon", traits: .fixedLayout(width: 512, height: 512)) {
    AppIconViewMinimal(size: 512)
}

#Preview("Icon Generator") {
    IconGeneratorView()
}

// MARK: - Icon Generator View

/// Simple view with a button to generate all icon sizes
@MainActor
struct IconGeneratorView: View {
    @State private var isGenerating = false
    @State private var isComplete = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("App Icon Generator")
                .font(.title)
                .bold()
            
            AppIconView(size: 200)
            
            if isGenerating {
                ProgressView()
                    .progressViewStyle(.circular)
                Text("Generating icons...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else if isComplete {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Icons Generated Successfully!")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("Check ~/Documents/AppIcons/ for the PNG files")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Generate Again") {
                        isComplete = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Button(action: generateIcons) {
                    Label("Generate All Icon Sizes", systemImage: "square.and.arrow.down")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(40)
        .frame(width: 400, height: 500)
    }
    
    private func generateIcons() {
        isGenerating = true
        
        // Run on background thread to avoid blocking UI
        Task {
            await Task.yield() // Let UI update
            
            AppIconGenerator.generateAllSizes(useMinimal: false)
            
            await MainActor.run {
                isGenerating = false
                isComplete = true
            }
        }
    }
}

// MARK: - Usage Instructions
/*
 
 To generate your app icons:
 
 1. Add this file to your Xcode project temporarily
 2. Create a simple view in your app (or use Xcode Previews)
 3. Call: AppIconGenerator.generateAllSizes(useMinimal: false)
    - Or use `useMinimal: true` for the vinyl-only version
 4. Icons will be saved to your Desktop as PNG files
 5. In Xcode:
    - Select Assets.xcassets
    - Select AppIcon
    - Drag and drop each PNG into the appropriate size slot
 
 Alternatively, you can use the preview to screenshot the icon
 and manually resize it for different sizes.
 
 Icon Designs:
 - AppIconView: Playful design with cat ears + music note
 - AppIconViewMinimal: Clean vinyl record design
 
 */

#endif
