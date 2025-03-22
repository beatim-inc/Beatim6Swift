//
//  SearchSongsView.swift
//  MusicKit_Demo
//
//  Created by Shunzhe on 2022/01/22.
//

import SwiftUI
import MusicKit

struct SearchSongsView: View {
    
    @State private var searchTerm: String = ""
    @State private var searchResultSongs: MusicItemCollection<Song> = []
    @State private var isPerformingSearch: Bool = false
    @State private var musicSubscription: MusicSubscription?
    @State private var showDeleteAlert = false
    @Binding var currentArtistName: String?
    @EnvironmentObject var stepSoundManager: StepSoundManager
    @EnvironmentObject var spmManager: SPMManager
    @EnvironmentObject var songHistoryManager: SongHistoryManager
    var defaultBpm : Double

    @FocusState private var isSearchFieldFocused: Bool // 🎯 フォーカス状態を管理
    @State private var showCancelButton: Bool = false
    
    init(musicDefaultBpm: Double, currentArtistName: Binding<String?>){
        defaultBpm = musicDefaultBpm
        self._currentArtistName = currentArtistName
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 🔍 検索バー
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Song, Artist, Album...", text: $searchTerm, onEditingChanged: { isEditing in
                            showCancelButton = true
                        }, onCommit: {
                            performSearch()
                        })
                        .focused($isSearchFieldFocused)
                        .foregroundColor(.primary)
                        .submitLabel(.search)
                        
                        if !searchTerm.isEmpty {
                            Button(action: {
                                searchTerm = ""
                                searchResultSongs = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    if showCancelButton {
                        Button("Cancel") {
                            searchTerm = ""
                            isSearchFieldFocused = false
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                showCancelButton = false // フォーカス解除後にボタンを非表示にする
                                searchResultSongs = []
                            }
                        }
                        .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // 🔄 検索中インジケーター
                if isPerformingSearch {
                    ProgressView()
                        .padding()
                }
                
                
                // 🎵 検索結果リスト
                if !searchResultSongs.isEmpty {
                    List {
                        Section(header: Text("Search Results")) {
                            ForEach(searchResultSongs) { song in
                                SongInfoView(songItem: song, currentArtistName: $currentArtistName)
                            }
                        }
                        Section(footer: SpacerView()) {}
                    }
                    .listStyle(PlainListStyle())
                }
                else {
                    List {
                        Section(
                            header: HStack {
                                Text("Recommended Songs")
                                Spacer()
                                Button(action: {
                                    showDeleteAlert = true // ✅ ポップアップを表示
                                }) {
                                    Text("delete all")
                                        .foregroundColor(.red)
                                        .font(.subheadline)
                                }
                                .alert(isPresented: $showDeleteAlert) { // ✅ 削除確認ポップアップ
                                    Alert(
                                        title: Text("履歴を削除"),
                                        message: Text("本当に全ての履歴を削除しますか？"),
                                        primaryButton: .destructive(Text("削除")) {
                                            songHistoryManager.clearHistory() // ✅ 履歴削除
                                        },
                                        secondaryButton: .cancel()
                                    )
                                }
                            }
                        ) {
                            let sortedSongs = songHistoryManager.playedSongs.sorted {
                                evaluateFunction(for: $0) > evaluateFunction(for: $1)
                            }
                            
                            ForEach(sortedSongs, id: \.id) { song in
                                SongHistoryRowView(songID: song.id, currentArtistName: $currentArtistName)
                            }
                            .onDelete(perform: songHistoryManager.deleteSong) // 🔥 スワイプ削除を有効化
                        }
                        
                        Section(footer: SpacerView()) {}
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationBarHidden(true)
            .task {
                for await subscription in MusicSubscription.subscriptionUpdates {
                    self.musicSubscription = subscription
                }
            }
        }
        
    }

    // 🎯 検索処理をメソッド化（Enterキー & ボタン 両方で使用）
    private func performSearch() {
        Task {
            do {
                var request = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
                request.limit = 25
                self.isPerformingSearch = true
                let response = try await request.response()
                self.isPerformingSearch = false
                self.searchResultSongs = response.songs
                print("searchResultSongs: \(self.searchResultSongs)")
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    struct SpacerView: View {
        var body: some View {
            Color.clear
                .frame(height: 200) // 🎯 `MusicPlayerView` の高さに合わせて余白を確保
        }
    }
    
    // 🎵 SPM / BPM を計算し、非対称関数に適用
    private func evaluateFunction(for song: PlayedSong) -> Double {
        let bpm = song.bpm
        let spm = spmManager.spm
        let ratio = spm / bpm

        return asymmetricGaussian(ratio)
    }

    // 🎼 非対称関数（右緩やか・左急激）
    private func asymmetricGaussian(_ x: Double) -> Double {
        let x0 = 1.0
        let sigmaLeft = 0.042
        let sigmaRight = 0.127
        let sigma = x < x0 ? sigmaLeft : sigmaRight
        return exp(-((x - x0) * (x - x0)) / (2 * sigma * sigma))
    }
}

