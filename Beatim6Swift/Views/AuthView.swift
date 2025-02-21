//
//  Auth.swift
//  MusicKit_Demo
//
//  Created by Shunzhe on 2022/01/22.
//

import SwiftUI
import MusicKit

import SwiftUI
import MusicKit

struct AuthView: View {
    @ObservedObject var authManager: AuthManager

    var body: some View {
        Form {
            switch authManager.currentAuthStatus {
            case .notDetermined:
                Text("Authorization status not yet determined.")
            case .authorized:
                Text("Access granted")
            case .denied:
                Text("Access denied")
            case .restricted:
                Text("User cannot access MusicKit settings.")
            @unknown default:
                Text("Unknown case")
            }

            Button("Request authorization") {
                authManager.requestMusicAuthorization()
            }

            Button("Reload authorization status") {
                authManager.reloadAuthStatus()
            }
        }
    }
}

