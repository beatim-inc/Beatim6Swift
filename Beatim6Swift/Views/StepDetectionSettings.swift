import SwiftUI

struct StepDetectionSettings: View {
    @ObservedObject var parameters: StepDetectionParameters

    var body: some View {
        Form {
            VStack(alignment: .leading) {
                
                Text("Step Acceleration Threshold (G)")
                Slider(value: Binding(
                    get: { -parameters.azThreshould },  // スライダー表示値 (0 から 3)
                    set: { parameters.azThreshould = -$0 } // 内部値を 0 から -3 に変換
                ), in: 0...3, step: 0.1)
                .accentColor(.primary)
                HStack {
                    Text("Sensitive") // 敏感
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("Current: \(-parameters.azThreshould, specifier: "%.1f") G")
                        .font(.caption)
                    Spacer()
                    Text("Dull") // 鈍い
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()

                Text("Debounce Time (ms)")
                Slider(value: $parameters.debounceTime, in: 100...1000, step: 50).accentColor(.primary)
                HStack {
                    Text("Short")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("Current: \(parameters.debounceTime, specifier: "%.0f") ms")
                        .font(.caption)
                    Spacer()
                    Text("Long")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
        }
        .navigationTitle("Sensitivity Settings")
    }
}
