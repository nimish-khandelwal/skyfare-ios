//
//  SkyFareApp.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import SwiftUI

@main
struct SkyFareApp: App {
    private let dependencies: AppDependencies

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        dependencies = isUITesting ? .sample : .live()
    }

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
        }
    }
}
