import Foundation
import WidgetKit

struct WidgetRefreshService: Sendable {
    @MainActor
    func refreshAllTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
