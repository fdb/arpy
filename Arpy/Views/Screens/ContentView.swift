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
                viewModel.state.isMelodicShiftActive = isDown
            }
            keyboardMonitor.onKeyDown = { keyCode in
                switch keyCode {
                case 49: viewModel.togglePlayStop()  // Space
                case 18: viewModel.padPressed(1)     // 1
                case 19: viewModel.padPressed(2)     // 2
                case 20: viewModel.padPressed(3)     // 3
                case 21: viewModel.padPressed(4)     // 4
                case 46: viewModel.toggleMute()      // M
                default: break
                }
            }
        }
        .onDisappear {
            keyboardMonitor.stopMonitoring()
        }
    }
}

#Preview {
    ContentView()
}
