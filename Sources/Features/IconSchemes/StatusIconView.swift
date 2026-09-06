import AppKit
import SwiftUI

/// Renders a `StatusIcon`: SF Symbol or template asset image (with the
/// scheme's fallback symbol while the artwork is missing).
/// Asset artwork is sized explicitly — compiled vector assets must not be
/// trusted to carry an intrinsic size.
struct StatusIconView: View {
    let icon: StatusIcon
    var assetSize: CGFloat = 16

    var body: some View {
        switch icon {
        case .systemSymbol(let name):
            Image(systemName: name)
        case .asset(let name, let fallback):
            if NSImage(named: NSImage.Name(name)) != nil {
                Image(name)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: assetSize, height: assetSize)
            } else {
                Image(systemName: fallback)
            }
        }
    }
}
