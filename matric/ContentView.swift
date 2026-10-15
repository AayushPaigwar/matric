import SwiftUI

struct ContentView: View {
    var body: some View {
        WindowLayoutView()
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
