//
//  MomMateApp.swift
//  MomMate
//
//  Application entry point.
//

import SwiftUI

@main
struct MomMateApp: App {
    init() {
#if DEBUG
        DebugSelfChecks.run()
#endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
