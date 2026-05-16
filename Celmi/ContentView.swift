import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        RootView()
    }
}

#Preview {
    ContentView()
        .modelContainer(CelmiDataContainer.preview)
        .environment(CelmiModel.preview)
        .environment(EntitlementService.preview)
        .environment(EntitlementService.preview.store)
}
