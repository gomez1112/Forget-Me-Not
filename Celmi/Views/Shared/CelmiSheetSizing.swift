import SwiftUI

extension View {
    @ViewBuilder
    func celmiSheetSizing(width: CGFloat = 560, height: CGFloat = 680) -> some View {
#if os(macOS)
        frame(
            minWidth: width,
            idealWidth: width,
            minHeight: height,
            idealHeight: height
        )
#else
        self
#endif
    }
}
