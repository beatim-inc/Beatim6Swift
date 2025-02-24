//
//  SearchPlaylistViewModel.swift
//  Beatim6Swift
//
//  Created by heilab on 2025-02-24.
//

import SwiftUI
import MusicKit

class SearchPlaylistViewModel: ObservableObject {
    @Published var searchTerm: String = ""
    @Published var searchResultPlaylists: MusicItemCollection<Playlist> = []
    @Published var isPerformingSearch: Bool = false
    
    /// ライブラリ内のプレイリスト検索を実行
    func performSearch() async {
        do {
            let request = MusicLibrarySearchRequest(term: searchTerm, types: [Playlist.self])
            await MainActor.run {
                self.isPerformingSearch = true
            }
            let response = try await request.response()
            await MainActor.run {
                self.searchResultPlaylists = response.playlists
                self.isPerformingSearch = false
            }
        } catch {
            print("Search error: \(error.localizedDescription)")
            await MainActor.run {
                self.isPerformingSearch = false
            }
        }
    }
}
