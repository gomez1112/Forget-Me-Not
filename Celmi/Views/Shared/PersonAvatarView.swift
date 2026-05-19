import SwiftUI

#if canImport(UIKit)
import UIKit
private typealias CelmiPlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
private typealias CelmiPlatformImage = NSImage
#endif

struct PersonAvatarView: View {
    var name: String
    var imageData: Data?
    var size: CGFloat = 44
    var systemImage: String?

    var body: some View {
        Group {
            if let imageData, let image = CelmiPlatformImage(data: imageData) {
                Image(celmiPlatformImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: max(16, size * 0.42), weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(CelmiDesign.rose)
            } else {
                Text(initials)
                    .font(.system(size: max(14, size * 0.34), weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(CelmiDesign.rose)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        let value = parts.prefix(2).compactMap(\.first).map(String.init).joined()
        return value.isEmpty ? "?" : value.uppercased()
    }
}

private extension Image {
    init(celmiPlatformImage image: CelmiPlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: image)
        #elseif canImport(AppKit)
        self.init(nsImage: image)
        #endif
    }
}

