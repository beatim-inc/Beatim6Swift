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
        case artist = "Artist"
        case song = "Song"
    }
    
    @State private var searchTerm: String = ""
    @State private var selectedCategory: SearchCategory = .artist
    @State private var searchResultSongs: MusicItemCollection<Song> = []
    @State private var searchResultArtists: MusicItemCollection<Artist> = []
    @State private var uniqueArtists: MusicItemCollection<Artist> = []
    @State private var fetchedTopSongs: [FetchedSong] = []
    @State private var isPerformingSearch: Bool = false
    @State private var musicSubscription: MusicSubscription?
    @State private var showDeleteAlert = false
    @Binding var currentArtistName: String?
    @Binding var musicDefaultBpm: Double
    @Binding var bpmErrorMessage: String
    @Binding var tempoRatioEvaluationEnabled: Bool
    @Binding var autoPause: Bool
    @EnvironmentObject var stepSoundManager: StepSoundManager
    @EnvironmentObject var spmManager: SPMManager
    @EnvironmentObject var songHistoryManager: SongHistoryManager
    @EnvironmentObject var authManager: AuthManager

    @FocusState private var isSearchFieldFocused: Bool // 🎯 フォーカス状態を管理
    @State private var showCancelButton: Bool = false
    
    init(musicDefaultBpm: Binding<Double>, currentArtistName: Binding<String?>, bpmErrorMessage: Binding<String>, tempoRatioEvaluationEnabled: Binding<Bool>, autoPause: Binding<Bool>){
        self._musicDefaultBpm = musicDefaultBpm
        self._currentArtistName = currentArtistName
        self._bpmErrorMessage = bpmErrorMessage
        self._tempoRatioEvaluationEnabled = tempoRatioEvaluationEnabled
        self._autoPause = autoPause
    }
    
    var body: some View {
        VStack {
            // 🔍 検索バー
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField(
                        selectedCategory == .artist ? "アーティスト名を検索" :
                            selectedCategory == .song ? "曲名を検索" : "Search",
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
                            SongInfoView(
                                songItem: song,
                                currentArtistName: $currentArtistName,
                                musicDefaultBpm: $musicDefaultBpm,
                                bpmErrorMessage: $bpmErrorMessage,
                                autoPause: $autoPause
                            )
                                .environmentObject(songHistoryManager)
                                .environmentObject(spmManager)
                                .environmentObject(authManager)
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
                                currentArtistName: $currentArtistName,
                                musicDefaultBpm: $musicDefaultBpm,
                                bpmErrorMessage: $bpmErrorMessage,
                                tempoRatioEvaluationEnabled: $tempoRatioEvaluationEnabled,
                                autoPause: $autoPause
                            )
                            .environmentObject(spmManager)
                            .environmentObject(songHistoryManager)
                            .environmentObject(authManager)
                        ) {
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
            } else if selectedCategory == .artist && !uniqueArtists.isEmpty {
                List {
                    Section(header: Text("人気のアーティスト")) {
                        ForEach(uniqueArtists, id: \.id) { artist in
                            NavigationLink(
                                destination: ArtistTopSongsView(
                                    artist: artist,
                                    currentArtistName: $currentArtistName,
                                    musicDefaultBpm: $musicDefaultBpm,
                                    bpmErrorMessage: $bpmErrorMessage,
                                    tempoRatioEvaluationEnabled: $tempoRatioEvaluationEnabled,
                                    autoPause: $autoPause
                                )
                                .environmentObject(spmManager)
                                .environmentObject(songHistoryManager)
                                .environmentObject(authManager)
                            ) {
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
                    }
                    Section(footer: SpacerView()) {}
                }
                .listStyle(PlainListStyle())
            } else {
                List {
                    Section(
                        header: HStack {
                            Text("再生された曲")
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
                                    title: Text("Clear History"),
                                    message: Text("Do you really want to delete all history?"),
                                    primaryButton: .destructive(Text("delete")) {
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
                            SongHistoryRowView(
                                songID: song.id,
                                currentArtistName: $currentArtistName,
                                musicDefaultBpm: $musicDefaultBpm,
                                bpmErrorMessage: $bpmErrorMessage,
                                autoPause: $autoPause
                            )
                                .environmentObject(songHistoryManager)
                                .environmentObject(spmManager)
                                .environmentObject(authManager)
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
        .task {
            await loadArtistsFromTop100()
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
    
    func fetchTop100JapanPlaylist() async -> Playlist? {
        do {
            // Top 100: Japan の識別子（固定値）
            let playlistID = MusicItemID("pl.043a2c9876114d95a4659988497567be") // 公式Top 100: Japan
            
            let request = MusicCatalogResourceRequest<Playlist>(matching: \.id, equalTo: playlistID)
            let response = try await request.response()
            print(response)
            return response.items.first
        } catch {
            print("🚨 プレイリスト取得失敗: \(error)")
            return nil
        }
    }

    func loadArtistsFromTop100() async {
        print("🟡 Top100アーティスト読み込み開始")

        // キャッシュがあればそれを使う
        if let cachedArtists = loadArtistsFromDisk() {
            print("📦 キャッシュからアーティスト読み込み")
            await MainActor.run {
                uniqueArtists = MusicItemCollection(cachedArtists)
            }
            return
        }

        // なければAPIから取得
        guard let playlist = await fetchTop100JapanPlaylist() else { return }

        do {
            let songs = try await playlist.with(.tracks).tracks ?? []
            var artistSet = Set<MusicItemID>()
            var artists: [Artist] = []

            for song in songs {
                let artistName = song.artistName
                let searchRequest = MusicCatalogSearchRequest(term: artistName, types: [Artist.self])
                let response = try await searchRequest.response()
                if let artist = response.artists.first(where: { $0.name == artistName }),
                   !artistSet.contains(artist.id) {
                    artistSet.insert(artist.id)
                    artists.append(artist)
                }
                try? await Task.sleep(nanoseconds: 150_000_000)
            }

            // キャッシュ保存
            saveArtistsToDisk(artists)

            await MainActor.run {
                uniqueArtists = MusicItemCollection(artists)
            }
        } catch {
            print("🚨 アーティスト取得エラー: \(error)")
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
        let sigmaLeft = 0.04246609001440099
        let sigmaRight = 0.21233045007200477
        let sigma = x < x0 ? sigmaLeft : sigmaRight
        return exp(-((x - x0) * (x - x0)) / (2 * sigma * sigma))
    }
    
    private func saveArtistsToDisk(_ artists: [Artist]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(artists)
            let url = getArtistsCacheURL()
            try data.write(to: url)
            print("✅ アーティストキャッシュ保存済み")
        } catch {
            print("🚨 アーティストキャッシュ保存エラー: \(error)")
        }
    }
    
    private func loadArtistsFromDisk() -> [Artist]? {
        do {
            let url = getArtistsCacheURL()
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let artists = try decoder.decode([Artist].self, from: data)
            return artists
        } catch {
            print("🚨 アーティストキャッシュ読み込みエラー: \(error)")
            return nil
        }
    }
    
    func getArtistsCacheURL() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("top100_artists.json")
    }

}

struct ArtistTopSongsView: View {
                                
    let artist: Artist
     
    @Binding var currentArtistName: String?
    @Binding var musicDefaultBpm: Double
    @Binding var bpmErrorMessage: String
    @Binding var tempoRatioEvaluationEnabled: Bool
    @Binding var autoPause: Bool
    
    @EnvironmentObject var spmManager: SPMManager
    @EnvironmentObject var songHistoryManager: SongHistoryManager
    @EnvironmentObject var authManager: AuthManager

    @State private var fetchedSongs: [FetchedSong] = []
    @State private var isLoading: Bool = true

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading top songs...")
                    .padding()
            } else {
                List {
                    Section(header: tempoRatioEvaluationEnabled ? Text("おすすめ順") : Text("おすすめ順")) {
                        let displaySongs: [FetchedSong] = {
                            if tempoRatioEvaluationEnabled {
                                return fetchedSongs.sorted {
                                    evaluateFunction(for: $0) > evaluateFunction(for: $1)
                                }
                            } else {
                                return fetchedSongs // 並び替えしない
                            }
                        }()

                        ForEach(displaySongs) { item in
                            SongInfoView(
                                songItem: item.song,
                                currentArtistName: $currentArtistName,
                                musicDefaultBpm: $musicDefaultBpm,
                                bpmErrorMessage: $bpmErrorMessage,
                                autoPause: $autoPause
                            )
                            .environmentObject(songHistoryManager)
                            .environmentObject(spmManager)
                            .environmentObject(authManager)
                            .opacity(
                                tempoRatioEvaluationEnabled
                                ? ( evaluateFunction(for: item) >= 0.5 ? evaluateFunction(for: item) : 0) // スコアに応じて不透明度を調整
                                : 1.0 // 並び替えスキップ時はすべて不透明
                            )
                        }
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
        self.isLoading = true
        self.fetchedSongs = []
        
        // キャッシュがあれば使う
        if tempoRatioEvaluationEnabled, let cached = loadTopSongsFromDisk(artistID: artist.id) {
            var tempFetchedSongs: [FetchedSong] = []
            let group = DispatchGroup()

            for cachedSong in cached {
                group.enter()
                let bpmFetcher = BPMFetcher(historyManager: songHistoryManager)
                bpmFetcher.fetchBPM(song: cachedSong.song.title, artist: cachedSong.song.artistName, id: cachedSong.song.id.rawValue) { bpm in
                    tempFetchedSongs.append(FetchedSong(song: cachedSong.song, bpm: bpm))
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.fetchedSongs = tempFetchedSongs
                self.isLoading = false
                print("📦 Top songs (with BPM) loaded from cache for \(artist.name)")
            }

            return
        }

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
                self.fetchedSongs = tempFetchedSongs
                self.isLoading = false
                removeTopSongsCache(artistID: artist.id)
                saveTopSongsToDisk(artistID: artist.id, songs: self.fetchedSongs)
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
        let sigmaLeft = 0.04246609001440099
        let sigmaRight = 0.21233045007200477
        let sigma = x < x0 ? sigmaLeft : sigmaRight
        return exp(-((x - x0) * (x - x0)) / (2 * sigma * sigma))
    }
    
    func removeTopSongsCache(artistID: MusicItemID) {
        let filename = "top_songs_\(artistID.rawValue).json"
        let url = getCacheDirectory().appendingPathComponent(filename)
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
                print("🗑️ 既存キャッシュ削除済み for \(artistID)")
            }
        } catch {
            print("⚠️ キャッシュ削除失敗: \(error)")
        }
    }
    
    func saveTopSongsToDisk(artistID: MusicItemID, songs: [FetchedSong]) {
        let filename = "top_songs_\(artistID.rawValue).json"
        let url = getCacheDirectory().appendingPathComponent(filename)
        do {
            let data = try JSONEncoder().encode(songs)
            try data.write(to: url)
            print("✅ Top songs cached for \(artistID)")
        } catch {
            print("🚨 Failed to cache top songs: \(error)")
        }
    }

    func loadTopSongsFromDisk(artistID: MusicItemID) -> [FetchedSong]? {
        let filename = "top_songs_\(artistID.rawValue).json"
        let url = getCacheDirectory().appendingPathComponent(filename)
        do {
            let data = try Data(contentsOf: url)
            let songs = try JSONDecoder().decode([FetchedSong].self, from: data)
            return songs
        } catch {
            print("🚨 Failed to load cached top songs: \(error)")
            return nil
        }
    }

    func getCacheDirectory() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

}

struct FetchedSong: Identifiable, Codable {
    let song: Song
    let bpm: Double?

    var id: MusicItemID { song.id }

    enum CodingKeys: CodingKey {
        case song, bpm
    }

    init(song: Song, bpm: Double?) {
        self.song = song
        self.bpm = bpm
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.song = try container.decode(Song.self, forKey: .song)
        self.bpm = try container.decodeIfPresent(Double.self, forKey: .bpm)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(song, forKey: .song)
        try container.encodeIfPresent(bpm, forKey: .bpm)
    }
}


struct SpacerView: View {
    var body: some View {
        Color.clear
            .frame(height: 200) // 🎯 `MusicPlayerView` の高さに合わせて余白を確保
    }
}
