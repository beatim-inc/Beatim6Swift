//
//  TabSelectionManager.swift
//  Beatim6Swift
//
//  Created by heilab on 2025-03-20.
//

import SwiftUI

class TabSelectionManager: ObservableObject {
    @Published var selectedTab: String = "Instruments" // 初期タブ
    @Published var lastSelectedTab: String? // 直前のタブを記録
}
