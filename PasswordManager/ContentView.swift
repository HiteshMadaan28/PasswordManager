//
//  ContentView.swift
//  PasswordManager
//
//  Created by Hitesh Madaan on 05/06/24.
//

import LocalAuthentication
import SwiftUI
import CryptoKit
import SQLite


struct ContentView: SwiftUI.View {

    var body: some SwiftUI.View {
        HomeContentView()
    }
}


enum EncryptionError: Error {
    case keyNotFound
    case invalidData
}

enum DecryptionError: Error {
    case keyNotFound
    case invalidData
    case invalidPassword
}



#Preview {
    ContentView()
}
