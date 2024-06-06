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
import KeychainAccess

let keychain = Keychain(service: "com.example.PasswordManager")

func generateAndStoreEncryptionKey() throws {
    // Generate a random encryption key
    let key = SymmetricKey(size: .bits256)

    // Store the key in the Keychain
    try keychain.set(key.withUnsafeBytes { Data($0) }, key: "encryptionKey")
}

struct AddRecordView: SwiftUI.View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    var onSave: (String, String, String) -> Void
    
    var body: some SwiftUI.View {
        VStack {
            VStack {
                Section {
                    TextField("Name", text: $name)
                        .foregroundStyle(.primary)
                }
                .frame(width: 300,height: 60)
                
                Section {
                    TextField("UserName/Email", text: $email)
                }
                .frame(width: 300,height: 60)
                
                
                Section {
                    SecureField("Password", text: $password)
                }
                .frame(width: 300,height: 60)
                
            }
            Button("Save") {
                if name.isEmpty {
                    alertMessage = "Name is required."
                    showAlert = true
                } else if email.isEmpty {
                    alertMessage = "Email is required."
                    showAlert = true
                } else if password.isEmpty {
                    alertMessage = "Password is required."
                    showAlert = true
                } else {
                    do {
                        let encryptedPassword = try encryptPassword(password)
                        onSave(name, email, encryptedPassword)
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        showAlert(message: "Failed to encrypt password.")
                    }
                }
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Validation Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // Encrypt password using the encryption key stored in the Keychain
    func encryptPassword(_ password: String) throws -> String {
        guard let encryptionKey = try keychain.getData("encryptionKey") else {
            throw EncryptionError.keyNotFound
        }
        
        let passwordData = password.data(using: .utf8)!
        let sealedBox = try AES.GCM.seal(passwordData, using: SymmetricKey(data: encryptionKey))
        return sealedBox.combined!.base64EncodedString()
    }
    
    // Show alert message
    func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

enum EncryptionError: Error {
    case keyNotFound
    case invalidData
}


struct AccountDetailView: SwiftUI.View {
    var name: String
    var email: String
    var encryptedPassword: String
    
    @State private var decryptedPassword: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    var onSaveChanges: (String, String, String) -> Void
    @State private var editedEmail: String
    @State private var editedPassword: String
    
    var onDelete: () -> Void
    
    init(name: String, email: String, encryptedPassword: String, onSaveChanges: @escaping (String, String, String) -> Void, onDelete: @escaping () -> Void) {
            self.name = name
            self.email = email
            self.encryptedPassword = encryptedPassword
            self.onSaveChanges = onSaveChanges
            self.onDelete = onDelete
            
            // Initialize the edited email with the current email value
            self._editedEmail = State(initialValue: email)
            // Initialize the edited password as an empty string
            self._editedPassword = State(initialValue: "")
        }
    
    var body: some SwiftUI.View {
        VStack(alignment: .leading) {
        
            Text("Account Details")
                .bold()
                .foregroundColor(.blue)
                .font(.largeTitle)
                .padding()
            
            VStack(alignment: .leading) {
                Text("Account Type")
                    .font(.subheadline)
                Text(name)
                    .bold()
                    .font(.title)
            }
            .padding()
            
            VStack(alignment: .leading) {
                Text("Username/ Email")
                    .font(.subheadline)
                TextField("\(email)", text: $editedEmail)
                    .bold()
                    .font(.title)
            }
            .padding()
            
            VStack(alignment: .leading) {
                Text("Password")
                    .font(.subheadline)
                SecureField("\(decryptedPassword)", text: $editedPassword)
                    .bold()
                    .font(.title)
            }
            .padding()
            
            HStack {
                Button("Edit") {
                    do {
                        let encryptedPassword = try encryptPassword(editedPassword)
                        onSaveChanges(name, email, encryptedPassword)
                        
                    } catch {
                        showAlert(message: "Failed to encrypt editpassword.")
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.trailing)
                
                Button("Delete") {
                    onDelete()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .padding()
        .onAppear {
            do {
                decryptedPassword = try decryptPassword(encryptedPassword)
            } catch {
                showAlert(message: "Failed to decrypt password.")
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Decryption Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    func encryptPassword(_ password: String) throws -> String {
        guard let encryptionKey = try keychain.getData("encryptionKey") else {
            throw EncryptionError.keyNotFound
        }
        
        let passwordData = password.data(using: .utf8)!
        let sealedBox = try AES.GCM.seal(passwordData, using: SymmetricKey(data: encryptionKey))
        return sealedBox.combined!.base64EncodedString()
    }
    // Decrypt password using the encryption key stored in the Keychain
    func decryptPassword(_ encryptedPassword: String) throws -> String {
        guard let encryptionKey = try keychain.getData("encryptionKey") else {
            throw DecryptionError.keyNotFound
        }
        
        guard let combinedData = Data(base64Encoded: encryptedPassword) else {
            throw DecryptionError.invalidData
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: SymmetricKey(data: encryptionKey))
        
        guard let decryptedPassword = String(data: decryptedData, encoding: .utf8) else {
            throw DecryptionError.invalidPassword
        }
        
        return decryptedPassword
    }
    
    // Show alert message
    func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}


enum DecryptionError: Error {
    case keyNotFound
    case invalidData
    case invalidPassword
}



struct ContentView: SwiftUI.View {
    @State private var accounts: [(String, String, String)] = []
    @State private var unlocked: Bool = false
    @State private var showAddingSheet: Bool = false
    @State private var showDetailSheet: Bool = false
    @State private var selectedAccount: (String, String, String)? = nil
    
    var body: some SwiftUI.View {
        NavigationView {
            VStack {
                if unlocked {
                    List(accounts, id: \.0) { account in
                        HStack{
                            Text("\(account.0)")
                                .font(.title)
                            Spacer()
                            Text("********")
                                .font(.title2)
                        }
                        .onTapGesture {
                            selectedAccount = account
                            showDetailSheet = true
                        }
                    }
                    Button(action: {
                        showAddingSheet.toggle()
                    }) {
                        Image(systemName: "plus")
                            .font(.largeTitle)
                            .padding()
                    }
                    .sheet(isPresented: $showAddingSheet) {
                        AddRecordView { name, email, password in
                            saveRecord(name: name, email: email, password: password)
                            accounts = fetchRecords()
                        }
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                    }
                    .sheet(isPresented: $showDetailSheet) {
                        if let selectedAccount = selectedAccount {
                            AccountDetailView(name: selectedAccount.0, email: selectedAccount.1, encryptedPassword: selectedAccount.2,onSaveChanges: {name, email, password in
                                // Update the record in the database
                                updateRecord(name: name, email: email, password: password)
                                // Reload accounts from the database
                                accounts = fetchRecords()
                            },onDelete:{ deleteRecord(name:selectedAccount.0)})
                        }
                            
                    }
                } else {
                    Text("Locked")
                }
            }
            .onAppear(){
                do {
                    try authenticate()
                    try generateAndStoreEncryptionKey()
                    print("Encryption key generated and stored successfully.")
                } catch {
                    print("Error generating and storing encryption key: \(error)")
                }
            }
            .navigationTitle("Password Manager")
        }
    }
    
    func getKey() throws -> SymmetricKey {
        // Check if key exists in the keychain
        if let storedKeyData = try? keychain.getData("encryptionKey"),
           let key = try? SymmetricKey(data: storedKeyData) {
            return key
        } else {
            // Generate a new key
            let key = SymmetricKey(size: .bits256)
            // Store the key in the keychain
            try? keychain.set(key.withUnsafeBytes { Data($0) }, key: "encryptionKey")
            return key
        }
    }
    
    
    
    func saveRecord(name: String, email: String, password: String) {
        do {
            // Save record to database
            let db = try Connection(getDatabasePath())
            let records = Table("accounts")
            let nameColumn = Expression<String>("name")
            let emailColumn = Expression<String>("email")
            let passwordColumn = Expression<String>("password")
            try db.run(records.create(ifNotExists: true) { t in
                t.column(nameColumn)
                t.column(emailColumn)
                t.column(passwordColumn)
            })
            try db.run(records.insert(nameColumn <- name, emailColumn <- email, passwordColumn <- password))
        } catch {
            print("Failed to save record: \(error)")
        }
    }
    
    func fetchRecords() -> [(String, String, String)] {
        do {
            let db = try Connection(getDatabasePath())
            let records = Table("accounts")
            let nameColumn = Expression<String>("name")
            let emailColumn = Expression<String>("email")
            let passwordColumn = Expression<String>("password")
            var result: [(String, String, String)] = []
            for record in try db.prepare(records) {
                let name = record[nameColumn]
                let email = record[emailColumn]
                let password = record[passwordColumn]
                result.append((name, email, password))
            }
            return result
        } catch {
            print("Failed to fetch records: \(error)")
            return []
        }
    }
    
    func updateRecord(name: String, email: String, password: String) {
        do {
            let db = try Connection(getDatabasePath())
            let accounts = Table("accounts")
            let nameColumn = Expression<String>("name")
            let emailColumn = Expression<String>("email")
            let passwordColumn = Expression<String>("password")
            let filteredRecord = accounts.filter(nameColumn == name)
            try db.run(filteredRecord.update(emailColumn <- email, passwordColumn <- password))
        } catch {
            print("Failed to update record: \(error)")
        }
    }
    
    func deleteRecord(name: String) {
        do {
            let db = try Connection(getDatabasePath())
            let records = Table("accounts")
            let nameColumn = Expression<String>("name")
            
            // Delete record from the database
            let recordToDelete = records.filter(nameColumn == name)
            try db.run(recordToDelete.delete())
            
            // Refresh the accounts array after deletion
            accounts = fetchRecords()
        } catch {
            print("Failed to delete record: \(error)")
        }
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "We need to unlock your data."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                if success {
                    DispatchQueue.main.async {
                        self.unlocked = true
                        self.accounts = fetchRecords()
                    }
                } else {
                    print("Authentication failed: \(String(describing: authenticationError))")
                }
            }
        } else {
            print("No biometrics available: \(String(describing: error))")
        }
    }
    
    func getDatabasePath() -> String {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0]
        return documentDirectory.appendingPathComponent("db.sqlite3").path
    }
}

#Preview {
    ContentView()
}
