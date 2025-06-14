//
//  DatabaseManager.swift
//  PasswordManager
//
//  Created by Hitesh Madaan on 14/06/25.
//

import SQLite
import Foundation

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: Connection?
    
    private let accounts = Table("accounts")
    private let nameColumn = Expression<String>("name")
    private let emailColumn = Expression<String>("email")
    private let passwordColumn = Expression<String>("password")
    
    private init() {
        do {
            db = try Connection(getDatabasePath())
            try createTable()
        } catch {
            print("Database initialization error: \(error)")
        }
    }
    
    private func getDatabasePath() -> String {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0]
        return documentDirectory.appendingPathComponent("db.sqlite3").path
    }
    
    private func createTable() throws {
        try db?.run(accounts.create(ifNotExists: true) { t in
            t.column(nameColumn)
            t.column(emailColumn)
            t.column(passwordColumn)
        })
    }
    
    func saveRecord(name: String, email: String, password: String) throws {
        try db?.run(accounts.insert(
            nameColumn <- name,
            emailColumn <- email,
            passwordColumn <- password
        ))
    }
    
    func fetchRecords() -> [Account] {
        do {
            guard let db = db else { return [] }
            var result: [Account] = []
            for record in try db.prepare(accounts) {
                result.append(Account(
                    name: record[nameColumn],
                    email: record[emailColumn],
                    password: record[passwordColumn]
                ))
            }
            return result
        } catch {
            print("Failed to fetch records: \(error)")
            return []
        }
    }
    
    func updateRecord(name: String, email: String, password: String) throws {
        let filteredRecord = accounts.filter(nameColumn == name)
        try db?.run(filteredRecord.update(
            emailColumn <- email,
            passwordColumn <- password
        ))
    }
    
    func deleteRecord(name: String) throws {
        let recordToDelete = accounts.filter(nameColumn == name)
        try db?.run(recordToDelete.delete())
    }
}
