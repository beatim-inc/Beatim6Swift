//
//  SearchSongsView.swift
//  MusicKit_Demo
//
//  Created by Shunzhe on 2022/01/22.
//

import SwiftUI
import MusicKit

struct SearchSongsView: View {
    
    enum SearchCategory: String, CaseIterable {
        case artist = "アーティスト"
        case song = "曲"
    }
    
    @State private var searchTerm: String = ""
    @State private var selectedCategory: SearchCategory = .artist
    @State private var searchResultSongs: MusicItemCollection<Song> = []
    @State private var searchResultArtists: MusicItemCollection<Artist> = []
    @State private var fetchedTopSongs: [FetchedSong] = []
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
        VStack {
            // 🔍 検索バー
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField(
                        selectedCategory == .artist ? "Artist" :
                            selectedCategory == .song ? "Song" : "Search",
                        text: $searchTerm,
                        onEditingChanged: { isEditing in
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
                            searchResultArtists = []
                            fetchedTopSongs = []
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
                            searchResultArtists = []
                            fetchedTopSongs = []
                        }
                    }
                    .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Picker("Search Type", selection: $selectedCategory) {
                ForEach(SearchCategory.allCases, id: \..self) { category in
                    Text(category.rawValue)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // 🔄 検索中インジケーター
            if isPerformingSearch {
                ProgressView()
                    .padding()
            }
            
            
            // 🎵 検索結果リスト
            if selectedCategory == .song && !searchResultSongs.isEmpty {
                List {
                    Section(header: Text("Search Results")) {
                        ForEach(searchResultSongs) { song in
                            SongInfoView(songItem: song, currentArtistName: $currentArtistName)
                        }
                    }
                    Section(footer: SpacerView()) {}
                }
                .listStyle(PlainListStyle())
            } else if selectedCategory == .artist && !searchResultArtists.isEmpty {
                List {
                    ForEach(searchResultArtists, id: \.id) { artist in
                        NavigationLink(
                            destination: ArtistTopSongsView(
                                artist: artist,
                                currentArtistName: $currentArtistName
                            )
                            .environmentObject(spmManager)
                            .environmentObject(songHistoryManager)) {
                            HStack {
                                AsyncImage(url: artist.artwork?.url(width: 40, height: 40)) { image in
                                    image.resizable()
                                } placeholder: {
                                    Color.gray
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())

                                Text(artist.name)
                                    .font(.headline)
                                    .padding(.leading, 8)
                            }
                        }
                    }
                    Section(footer: SpacerView()) {}
                }
                .listStyle(PlainListStyle())
            } else {
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
                isPerformingSearch = true
                
                var request = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self, Artist.self])
                request.limit = 25
                let response = try await request.response()
                self.searchResultSongs = response.songs
                self.searchResultArtists = response.artists

                isPerformingSearch = false
            } catch {
                print("Error: \(error.localizedDescription)")
                isPerformingSearch = false
            }
        }
    }
    
    
    
    private func evaluateFunction(for song: FetchedSong) -> Double {
        guard let bpm = song.bpm else { return 0 }
        let spm = spmManager.spm
        let ratio = spm / bpm
        return asymmetricGaussian(ratio)
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

struct ArtistTopSongsView: View {
                                
    let artist: Artist
    @Binding var currentArtistName: String?
    
    @EnvironmentObject var spmManager: SPMManager
    @EnvironmentObject var songHistoryManager: SongHistoryManager

    @State private var fetchedSongs: [FetchedSong] = []
    @State private var isLoading: Bool = true

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading top songs...")
                    .padding()
            } else {
                List {
                    ForEach(fetchedSongs) { item in
                        SongInfoView(songItem: item.song, currentArtistName: $currentArtistName)
                    }
                    Section(footer: SpacerView()) {
                        EmptyView() // セクションの中身がないことを明示
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle(artist.name)
        .task {
            await loadTopSongs()
        }
    }

    func loadTopSongs() async {
        do {
            var request = MusicCatalogSearchRequest(term: artist.name, types: [Song.self])
            request.limit = 25
            let response = try await request.response()
            let songs = response.songs.filter { $0.artistName == artist.name }.prefix(25)

            var tempFetchedSongs: [FetchedSong] = []
            let group = DispatchGroup()

            for song in songs {
                group.enter()
                let bpmFetcher = BPMFetcher(historyManager: songHistoryManager)
                bpmFetcher.fetchBPM(song: song.title, artist: song.artistName, id: song.id.rawValue) { bpm in
                    tempFetchedSongs.append(FetchedSong(song: song, bpm: bpm))
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.fetchedSongs = tempFetchedSongs.sorted {
                    evaluateFunction(for: $0) > evaluateFunction(for: $1)
                }
                self.isLoading = false
            }
        } catch {
            print("🚨 Failed to fetch top songs: \(error.localizedDescription)")
            self.isLoading = false
        }
    }

    private func evaluateFunction(for song: FetchedSong) -> Double {
        guard let bpm = song.bpm else { return 0 }
        let spm = spmManager.spm
        let ratio = spm / bpm
        return asymmetricGaussian(ratio)
    }

    private func asymmetricGaussian(_ x: Double) -> Double {
        let x0 = 1.0
        let sigmaLeft = 0.042
        let sigmaRight = 0.127
        let sigma = x < x0 ? sigmaLeft : sigmaRight
        return exp(-((x - x0) * (x - x0)) / (2 * sigma * sigma))
    }
}

struct FetchedSong: Identifiable {
    let song: Song
    let bpm: Double?

    var id: MusicItemID {
        song.id
    }
}

struct SpacerView: View {
    var body: some View {
        Color.clear
            .frame(height: 200) // 🎯 `MusicPlayerView` の高さに合わせて余白を確保
    }
}
