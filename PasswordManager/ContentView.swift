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

//Generating key and store it
func generateAndStoreEncryptionKey() throws {
    
    //Check if a key exists or not
    if keychain[data: "encryptionKey"] == nil {
        
        let key = SymmetricKey(size: .bits256)
        try keychain.set(key.withUnsafeBytes { Data($0) }, key: "encryptionKey")
    }
}


struct ContentView: SwiftUI.View {
    @State private var accounts: [(String, String, String)] = []
    @State private var unlocked: Bool = false
    @State private var showAddingSheet: Bool = false
    @State private var showDetailSheet: Bool = false
    @State private var selectedAccount: (String, String, String)? = nil
    
    var body: some SwiftUI.View {
        NavigationView {
            ZStack{
                if unlocked {
                    ScrollView{
                        VStack(alignment:.leading,spacing: 20){
                            ForEach(accounts, id: \.0) { account in
                                HStack{
                                    Spacer()
                                    Text("\(account.0)")
                                        .bold()
                                        .font(.title)
                                    
                                    Text("********")
                                        .foregroundColor(.gray)
                                        .font(.title2)
                                    
                                    Spacer()
                                    Spacer()
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                    Spacer()
                                    
                                }
                                .frame(width: 350,height: 70)
                                .background(Color.white)
                                .cornerRadius(40)
                                .onTapGesture {
                                    selectedAccount = account
                                    showDetailSheet = true
                                }
                            }
                            Spacer()
                        }
                    }
                    
                    VStack
                    {
                        Spacer()
                        
                        HStack{
                            Spacer()
                            Button(action: {
                                showAddingSheet.toggle()
                            }) {
                                Image(systemName: "plus")
                                    .bold()
                                    .font(.system(.largeTitle))
                                    .frame(width: 77, height: 70)
                                    .foregroundColor(Color.white)
                                    .padding(.bottom, 5)
                                    .background(Color.blue)
                                    .cornerRadius(9)
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
                            .sheet(isPresented: self.$showDetailSheet) {
                                if let selectedAccount = selectedAccount {
                                    AccountDetailView(name: selectedAccount.0, email: selectedAccount.1, encryptedPassword: selectedAccount.2,onSaveChanges: {name, email, password in
                                        // Update the record in the database
                                        updateRecord(name: name, email: email, password: password)
                                        // Reload accounts from the database
                                        accounts = fetchRecords()
                                    },onDelete:{ deleteRecord(name:selectedAccount.0)},isSheetPresented: self.$showDetailSheet)
                                }
                                
                            }
                        }
                    }
                } else {
                    Text("Locked")
                }
            }
            .onAppear(){
                do {
                    selectedAccount = accounts.first
                    authenticate()
                    try generateAndStoreEncryptionKey()
                    print("Encryption key generated and stored successfully.")
                } catch {
                    print("Error generating and storing encryption key: \(error)")
                }
            }
            .navigationTitle("Password Manager")
            .background(.ultraThinMaterial)
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
    
    //updateRecord
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
    
    //deleteRecord() - Deleting record based on name(like, google,twiter)
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
    
    //authenticate() - for authenticate using biometric (eg. FaceID)
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


//Struc AddRecordView - for Adding Values to our Variable name,email,password
struct AddRecordView: SwiftUI.View{
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    
    //Variables for alert
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    //onSave will Insert the Data in SQLite database
    var onSave: (String, String, String) -> Void
    
    //For Password Visibility
    @State private var isPasswordVisible = true
    
    var body: some SwiftUI.View {
        VStack {
            
            VStack{
                
                TextField("Account Name", text: $name)
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1.0)))
                    .background(.white)
                    .padding(10)
                
                
                TextField("UserName/Email", text: $email)
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1.0)))
                    .background(Color.white)
                    .padding(10)
                
                
                HStack {
                    if isPasswordVisible {
                        SecureField("Password", text: $password)
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1.0)))
                            .background(Color.white)
                            .padding(10)
                    } else {
                        TextField("Password", text: $password)
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1.0)))
                            .background(Color.white)
                            .padding(10)
                    }
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                }
                
            }.padding()
            
            VStack{
                
                Button("Add New Account") {
                    if name.isEmpty {
                        alertMessage = "Name is required."
                        showAlert = true
                    } else if email.isEmpty {
                        alertMessage = "Email is required."
                        showAlert = true
                    } else if !isValidEmail(email) {
                        alertMessage = "Invalid email format."
                        showAlert = true
                    }else if password.isEmpty {
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
                .frame(width: 350,height:60)
                .foregroundColor(Color.white)
                .font(.system(size: 20, weight: Font.Weight.bold))
                .background(Color.black)
                .cornerRadius(20)
                .presentationDetents([.medium,.large])
                .presentationDragIndicator(.visible)
                .padding()
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Validation Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
                
            }
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity)
        .background(.thinMaterial)
    }
    
    // Email validation function using regular expression
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
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
    
    @SwiftUI.Binding var isSheetPresented: Bool
    
    @State private var isPasswordVisible = false
    
    var onDelete: () -> Void
    
    init(name: String, email: String, encryptedPassword: String, onSaveChanges: @escaping (String, String, String) -> Void, onDelete: @escaping () -> Void,isSheetPresented: SwiftUI.Binding<Bool>) {
        self.name = name
        self.email = email
        self.encryptedPassword = encryptedPassword
        self.onSaveChanges = onSaveChanges
        self.onDelete = onDelete
        self._isSheetPresented = isSheetPresented
        
        // Initialize the edited email with the current email value
        self._editedEmail = State(initialValue: email)
        // Initialize the edited password as an empty string
        self._editedPassword = State(initialValue: "")
        
    }
    
    var body: some SwiftUI.View {
        VStack{
            
            VStack(alignment: .leading,spacing: 15) {
                
                Text("Account Details")
                    .bold()
                    .foregroundColor(.blue)
                    .padding()
                    .font(.title)
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Account Type")
                        .foregroundStyle(Color.gray.opacity(0.5))
                    Text(name)
                        .bold()
                        .font(.title2)
                }
                
                VStack(alignment: .leading) {
                    Text("Username/ Email")
                        .foregroundStyle(Color.gray.opacity(0.5))
                    TextField("\(email)", text: $editedEmail)
                        .bold()
                        .font(.title2)
                }
                
                
                VStack(alignment: .leading) {
                    Text("Password")
                        .foregroundStyle(Color.gray.opacity(0.5))
                    HStack {
                        if isPasswordVisible {
                            TextField("\(decryptedPassword)", text: $editedPassword)
                                .font(.title2)
                                .disableAutocorrection(true)
                        } else {
                            TextField("********", text: $editedPassword)
                                .font(.title2)
                                .disableAutocorrection(true)
                        }
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                HStack {
                    Button("Edit") {
                        do {
                            let updatedEmail = editedEmail.isEmpty ? email : editedEmail
                            let updatedPassword = editedPassword.isEmpty ? encryptedPassword : try encryptPassword(editedPassword)
                            
                            onSaveChanges(name, updatedEmail, updatedPassword)
                            
                        } catch {
                            showAlert(message: "Failed to encrypt editpassword.")
                        }
                    }
                    .font(.system(size: 20, weight: Font.Weight.bold))
                    .foregroundColor(.white)
                    .frame(width: 170,height:55)
                    .background(Color.black)
                    .cornerRadius(20)
                    
                    Spacer()
                    
                    Button("Delete") {
                        onDelete()
                        isSheetPresented = false
                    }
                    .frame(width: 170,height:55)
                    .foregroundColor(Color.white)
                    .font(.system(size: 20, weight: Font.Weight.bold))
                    .background(Color.red)
                    .cornerRadius(20)
                }
            }
            .cornerRadius(10)
            .presentationDetents([.fraction(0.6)])
            .presentationDragIndicator(.visible)
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
        .frame(maxWidth: .infinity,maxHeight: .infinity)
        .background(.ultraThinMaterial)
        
        
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




#Preview {
    ContentView()
}
