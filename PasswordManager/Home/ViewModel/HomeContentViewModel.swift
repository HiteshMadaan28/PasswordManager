//
//  HomeContentViewModel.swift
//  PasswordManager
//
//  Created by Hitesh Madaan on 14/06/25.
//

import SwiftUI
import Combine

class HomeContentViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var unlocked: Bool = false
    @Published var showAddingSheet: Bool = false
    @Published var showDetailSheet: Bool = false
    var selectedAccount: Account?
    
    private let databaseManager = DatabaseManager.shared
    private let authManager = AuthManager.shared
    
    func authenticate() {
        authManager.authenticate { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.unlocked = true
                    self?.loadAccounts()
                } else {
                    print("Authentication failed: \(String(describing: error))")
                }
            }
        }
    }
    
    func loadAccounts() {
        accounts = databaseManager.fetchRecords()
    }
    
    func saveAccount(name: String, email: String, password: String) {
        do {
            try databaseManager.saveRecord(name: name, email: email, password: password)
            loadAccounts()
        } catch {
            print("Failed to save record: \(error)")
        }
    }
    
    func updateAccount(_ account: Account) {
        do {
            try databaseManager.updateRecord(
                name: account.name,
                email: account.email,
                password: account.password
            )
            loadAccounts()
        } catch {
            print("Failed to update record: \(error)")
        }
    }
    
    func deleteAccount(name: String) {
        do {
            try databaseManager.deleteRecord(name: name)
            loadAccounts()
        } catch {
            print("Failed to delete record: \(error)")
        }
    }
}
