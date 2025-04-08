//
//  UserSettingView.swift
//  Beatim6Swift
//
//  Created by heilab on 2025-04-08.
//

import Foundation
import SwiftUI
import UIKit

struct UserSettingView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var userID: String
    var onUserIdUpdate: (String) -> Void
    
    init(userID: String, onUserIdUpdate: @escaping (String) -> Void) {
        _userID = State(initialValue: userID)
        self.onUserIdUpdate = onUserIdUpdate
    }
    
    var body: some View {
        Form {
            HStack {
                Image(systemName: "person.fill")
                Text("User ID")
                Spacer()
                TextField("User ID", text: $userID, onCommit: saveUserID)
                    .onChange(of: userID) { _, newValue in
                        userID = newValue
                    }
            }
        }
    }
    
    private func saveUserID() {
        onUserIdUpdate(userID)
        presentationMode.wrappedValue.dismiss()
    }
}
