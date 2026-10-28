import ActivityKit
import SwiftUI
import WidgetKit

@main
struct PixelIslandWidgetBundle: WidgetBundle {
    var body: some Widget {
        PixelIslandLiveActivity()
    }
}

/// The pet on the Dynamic Island and on the lock screen.
struct PixelIslandLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PixelIslandAttributes.self) { context in
            LockScreenIslandView(state: context.state, isStale: context.isStale, mode: context.state.liveActivityMode)
                .activityBackgroundTint(Theme.lockBackground)
                .activitySystemActionForegroundColor(Theme.cream)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(state: context.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(state: context.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(state: context.state, isStale: context.isStale, mode: context.state.liveActivityMode)
                }
            } compactLeading: {
                CompactLeadingView(state: context.state, mode: context.state.liveActivityMode)
            } compactTrailing: {
                CompactTrailingView(state: context.state, isStale: context.isStale, mode: context.state.liveActivityMode)
            } minimal: {
                MinimalIslandView(state: context.state, mode: context.state.liveActivityMode)
            }
            .keylineTint(context.state.keyline.color)
        }
    }
}
