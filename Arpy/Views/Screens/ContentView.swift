import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SequencerViewModel()
    @StateObject private var keyboardMonitor = KeyboardMonitor()

    var body: some View {
        VStack(spacing: 20) {
            TransportBar(viewModel: viewModel)
            StepSequencerGrid(viewModel: viewModel)
            ControllerView(viewModel: viewModel)
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            keyboardMonitor.startMonitoring()
            keyboardMonitor.onShiftChanged = { isDown in
                if isDown {
                    viewModel.state.isMelodicShiftActive = true
                } else {
                    viewModel.state.isMelodicShiftActive = false
                }
            }
        }
        .onDisappear {
            keyboardMonitor.stopMonitoring()
        }
        .onKeyPress(.space) {
            viewModel.togglePlayStop()
            return .handled
        }
        .onKeyPress("1") {
            viewModel.padPressed(1)
            return .handled
        }
        .onKeyPress("2") {
            viewModel.padPressed(2)
            return .handled
        }
        .onKeyPress("3") {
            viewModel.padPressed(3)
            return .handled
        }
        .onKeyPress("4") {
            viewModel.padPressed(4)
            return .handled
        }
        .onKeyPress("m") {
            viewModel.toggleMute()
            return .handled
        }
        .focusable()
    }
}

#Preview {
    ContentView()
}
