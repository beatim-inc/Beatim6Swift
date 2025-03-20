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
    @Binding var currentArtistName: String?
    @EnvironmentObject var stepSoundManager: StepSoundManager
    @EnvironmentObject var spmManager: SPMManager
    var defaultBpm : Double
    private var resultLimit: Int = 5

    @FocusState private var isSearchFieldFocused: Bool // 🎯 フォーカス状態を管理
    @State private var showCancelButton: Bool = false
    @EnvironmentObject var tabManager: TabSelectionManager // 🌟 タブ管理
    
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
                        TextField("アーティスト、曲、歌詞...", text: $searchTerm, onEditingChanged: { isEditing in
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
                    .onAppear {
                        if tabManager.lastSelectedTab == "search" {
                            isSearchFieldFocused = true // 🌟 2回目のタップでフォーカス
                        }
                    }
                    
                    if showCancelButton {
                        Button("キャンセル") {
                            searchTerm = ""
                            isSearchFieldFocused = false
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                showCancelButton = false // フォーカス解除後にボタンを非表示にする
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
                List {
                    if !searchResultSongs.isEmpty {
                        Section(header: Text("検索結果")) {
                            ForEach(searchResultSongs) { song in
                                SongInfoView(songItem: song, currentArtistName: $currentArtistName)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarHidden(true)
            .task {
                for await subscription in MusicSubscription.subscriptionUpdates {
                    self.musicSubscription = subscription
                }
            }
            .onAppear {
                print("🟢 onAppear: lastSelectedTab = \(tabManager.lastSelectedTab ?? "nil")")
                tabManager.lastSelectedTab = tabManager.selectedTab // 🌟 選択履歴を更新
            }
            .onChange(of: tabManager.selectedTab) { _, newValue in
                print("🔄 タブ変更: selectedTab = \(newValue), lastSelectedTab = \(tabManager.lastSelectedTab ?? "nil")")
                if newValue == "search" && tabManager.lastSelectedTab == "search" {
                    print("🔹 2回押されたのでフォーカスを設定")
                    isSearchFieldFocused = true // 🌟 2回目のタップでフォーカス
                }
                tabManager.lastSelectedTab = newValue
            }
        }
        
    }

    // 🎯 検索処理をメソッド化（Enterキー & ボタン 両方で使用）
    private func performSearch() {
        Task {
            do {
                let request = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
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
                .frame(height: 150) // 🎯 `MusicPlayerView` の高さに合わせて余白を確保
        }
    }
    
}

