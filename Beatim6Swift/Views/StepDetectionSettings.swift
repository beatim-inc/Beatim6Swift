import SwiftUI

class StepDetectionParameters: ObservableObject {
    @Published var stepTrigger: Float = 10.0  // GXの閾値
    @Published var diffGxThreshold: Float = -50.0 // GXの変化量
    @Published var debounceTime: TimeInterval = 300 // ミリ秒
}

struct StepDetectionSettings: View {
    @ObservedObject var parameters: StepDetectionParameters

    var body: some View {
        VStack {
            Text("Step Detection Settings")
                .font(.headline)
                .padding()

            VStack(alignment: .leading) {
                Text("Step Trigger (GX)")
                Slider(value: $parameters.stepTrigger, in: 5...20, step: 0.5)
                Text("Current: \(parameters.stepTrigger, specifier: "%.1f")")
                    .font(.caption)

                Text("Diff GX Threshold")
                Slider(value: $parameters.diffGxThreshold, in: -100...0, step: 1)
                Text("Current: \(parameters.diffGxThreshold, specifier: "%.1f")")
                    .font(.caption)

                Text("Debounce Time (ms)")
                Slider(value: $parameters.debounceTime, in: 100...1000, step: 50)
                Text("Current: \(parameters.debounceTime, specifier: "%.0f") ms")
                    .font(.caption)
            }
            .padding()

            Spacer()
        }
        .padding()
    }
}
