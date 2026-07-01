import SwiftUI

@main
struct OBSIDIANApp: App {
    var body: some Scene {
        WindowGroup {
            MainDashboardView()
                .preferredColorScheme(.dark)
                .environment(\.layoutDirection, .rightToLeft)
        }
    }
}
