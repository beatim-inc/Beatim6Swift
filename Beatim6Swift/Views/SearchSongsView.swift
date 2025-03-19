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
    
    init(musicDefaultBpm: Double, currentArtistName: Binding<String?>){
        defaultBpm = musicDefaultBpm
        self._currentArtistName = currentArtistName
    }
    
    var body: some View {
        
        Form {
            
            Section {
                TextField("Search term", text: $searchTerm)
                    .focused($isSearchFieldFocused) // 🎯 フォーカス適用
                    .onSubmit { // 🎯 Enter キーで検索実行
                        performSearch()
                    }
            }
            
            if isPerformingSearch {
                ProgressView()
            }
            
            ForEach(self.searchResultSongs) { song in
                SongInfoView(songItem: song, currentArtistName: $currentArtistName)
            }
            
        }
        .navigationTitle("Search Songs")
        .onAppear {
            isSearchFieldFocused = true // 🎯 画面表示時に自動フォーカス
        }
        .task {
            for await subscription in MusicSubscription.subscriptionUpdates {
                self.musicSubscription = subscription
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
    
}

