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
    
    let availableSounds = ["BassDrum", "Clap", "DJ Drum", "SnareDrum", "Walk", "Claverotor"]
    
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
        .navigationTitle("Instruments")
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
    
    let availableSounds = ["BassDrum", "Clap", "DJ Drum", "SnareDrum", "Walk", "Claverotor"]
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2) // 3列グリッド
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(availableSounds, id: \.self) { sound in
                    VStack {
                        Button(action: {
                            selectedSound = sound
                            stepSoundManager.playSoundOnce(soundName: sound, volume: volume) // サウンド再生関数を呼び出し
                        }) {
                            VStack {
                                Image(sound) // 各サウンドに対応するアイコン画像
                                    .resizable()
                                    .renderingMode(.template)
                                    .scaledToFit()
                                    .frame(width: 45, height: 45)
                                    .foregroundColor(selectedSound == sound ? Color(UIColor.systemBackground) : .primary) // 選択状態で色を変更
                            }
                            .padding()
                            .frame(width: 60, height: 60)
                            .background(selectedSound == sound ? Color.primary : Color(uiColor: .systemGray6))
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle()) // デフォルトのボタンスタイルを無効化
                        
                        Text(sound)
                            .font(.subheadline)
                            .foregroundColor(selectedSound == sound ? .primary : .secondary)
                    }
                }
            }
            .padding(.vertical, 8)
            
            HStack {
                Image(systemName: "speaker.slash.fill").foregroundColor(.gray)
                Spacer()
                CustomSlider(value: $volume, range: 0...2, step: 0.1)
                Spacer()
                Image(systemName: "speaker.wave.3.fill").foregroundColor(.gray)
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
