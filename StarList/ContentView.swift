import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        StarListView(settingsManager: settingsManager)
    }
}
