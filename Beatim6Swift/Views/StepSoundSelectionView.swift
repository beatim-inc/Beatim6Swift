//
//  StepSoundSelectionView.swift
//  Beatim6Swift
//
//  Created by Ryota-Nitto on 2025-02-19.
//

import SwiftUI

struct StepSoundSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedRightStepSound: String
    @Binding var selectedLeftStepSound: String
    var setSoundName: (String) -> Void
    @EnvironmentObject var stepSoundManager: StepSoundManager
    // 高さを格納するための @State 変数
    @State private var stepSoundViewHeight: CGFloat = 0
    
    let availableSounds = ["None", "BassDrum", "Clap", "DJ Drum", "SnareDrum", "Walk1", "Walk2", "Claverotor1", "Claverotor2"]
    
    var body: some View {
        VStack (alignment: .leading){
            HStack(alignment: .top, spacing: 20) {
                StepSoundPickerView(
                    title: "Left",
                    selectedSound: $stepSoundManager.leftStepSoundName,
                    volume: $stepSoundManager.leftStepVolume
                )
                .background(GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            stepSoundViewHeight = geo.size.height
                        }
                        .onChange(of: geo.size.height) { _, newHeight in
                            stepSoundViewHeight = newHeight
                        }
                })
                Divider()
                    .frame(height: stepSoundViewHeight)
                StepSoundPickerView(
                    title: "Right",
                    selectedSound: $stepSoundManager.rightStepSoundName,
                    volume: $stepSoundManager.rightStepVolume
                )
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Step Instruments")
    }
    
    // 高さを取得するための PreferenceKey
    struct ViewHeightKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
}

struct StepSoundPickerView: View {
    let title: String
    @Binding var selectedSound: String
    @Binding var volume: Float
    @State private var isPickerExpanded = false
    @EnvironmentObject var stepSoundManager: StepSoundManager
    
    let availableSounds = ["None", "BassDrum", "Clap", "DJ Drum", "SnareDrum", "Walk1", "Walk2", "Claverotor1", "Claverotor2"]
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3) // 3列グリッド
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
            
            Image("\(selectedSound)") // Placeholder for actual images
                .resizable()
                .renderingMode(.template)
                .foregroundColor(.primary)
                .scaledToFit()
                .frame(width: 80, height: 80)
                .padding(.vertical, 10)
            
            Text("\(selectedSound)")
                .font(.subheadline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(availableSounds, id: \.self) { sound in
                    Button(action: {
                        selectedSound = sound
                        stepSoundManager.playSoundOnce(soundName: sound, volume: volume) // サウンド再生関数を呼び出し
                    }) {
                        VStack {
                            Image(sound) // 各サウンドに対応するアイコン画像
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundColor(selectedSound == sound ? Color(UIColor.systemBackground) : .primary) // 選択状態で色を変更
                        }
                        .padding()
                        .frame(width: 45, height: 45)
                        .background(selectedSound == sound ? Color.primary : Color(uiColor: .systemGray6))
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle()) // デフォルトのボタンスタイルを無効化
                }
            }
            .padding(.vertical, 8)
            
            VStack {
                CustomSlider(value: $volume, range: 0...2, step: 0.1)
                HStack {
                    Text("Low").font(.caption).foregroundColor(.gray)
                    Spacer()
                    Text("Volume: \(volume, specifier: "%.1f")").font(.caption)
                    Spacer()
                    Text("High").font(.caption).foregroundColor(.gray)
                }
            }
        }
    }
}

struct CustomSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float
    
    var body: some View {
        VStack {
            Slider(value: $value, in: range, step: step)
                .accentColor(.primary)
        }
    }
}
