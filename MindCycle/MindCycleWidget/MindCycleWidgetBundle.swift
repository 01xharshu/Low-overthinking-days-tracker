// MindCycleWidgetBundle.swift
// MindCycleWidget
//
// Widget extension for macOS Desktop/Notification Center widgets.
// Shows days since last entry, predicted window, and current phase.

import WidgetKit
import SwiftUI

@main
struct MindCycleWidgetBundle: WidgetBundle {
    var body: some Widget {
        MindCycleWidget()
    }
}
