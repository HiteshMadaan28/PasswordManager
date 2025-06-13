//
//  HomeContentView.swift
//  PasswordManager
//
//  Created by Hitesh Madaan on 13/06/25.
//

import SwiftUI
import SQLite
import LocalAuthentication

struct HomeContentView: SwiftUI.View {
    @State private var accounts: [(String, String, String)] = []
    @State private var unlocked: Bool = false
    @State private var showAddingSheet: Bool = false
    @State private var showDetailSheet: Bool = false
    @State private var selectedAccount: (String, String, String)? = nil
    
    var body: some SwiftUI.View{
         
        NavigationStack {
            
           
            ZStack{

                Color(UIColor(red: 0.9529, green: 0.9608, blue: 0.9804, alpha: 1.0))
                    .ignoresSafeArea()
                if unlocked {
                    
                    ScrollView{
                        
                        Divider()
                            .frame(width: 375)
                            .position(x:-230,y:-81.16)
                            .foregroundColor(Color(red: 0.9098, green: 0.9098, blue: 0.9098,opacity: 1.0))
                        
                        VStack{
                            
                            VStack(spacing: 18){
                                
                                    
                                
                                ForEach(accounts, id: \.0) { account in
                                    HStack(alignment: .center){
                                        
                                        Text("\(account.0)")
                                            .font(.custom("SFProDisplay-Semibold", size: 20))
                                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2,opacity: 1.0))
                                            .padding(.leading,25)
                                        
                                        
                                        
                                        VStack(){
                                            Text("*******")
                                                .frame(width: 69, height: 24)
                                                .font(.custom("SFProDisplay-Semibold", size: 20))
                                                .foregroundColor(Color(red: 0.7765, green: 0.7765, blue: 0.7765,opacity: 1.0))
                                        }.padding(.top,10)
                                            .padding(.leading,4)
                                        
                                        Spacer()
                                        
                                        
                                        Image(systemName: "chevron.right")
                                            .frame(width: 13.71,height: 6.86)
                                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2,opacity: 1.0))
                                            .padding(.trailing,20)
                                        
                                    }
                                    .frame(width: 360,height: 66.19)
                                    .background(Color.white)
                                    .overlay(RoundedRectangle(cornerRadius: 40.0).strokeBorder(Color(red: 0.9294, green: 0.9294, blue: 0.9294,opacity: 1.0), style: StrokeStyle(lineWidth: 1.0)))
                                    .cornerRadius(50)
                                    .onTapGesture {
                                        selectedAccount = account
                                        showDetailSheet.toggle()
                                    }
                                    .sheet(isPresented: self.$showDetailSheet) {
                                        if let selectedAccount = selectedAccount {
                                            AccountDetailContentView(name: selectedAccount.0, email: selectedAccount.1, encryptedPassword: selectedAccount.2, onSaveChanges: { name, email, password in
                                                // Update the record in the database
                                                updateRecord(name: name, email: email, password: password)
                                                // Reload accounts from the database
                                                accounts = fetchRecords()
                                            }, onDelete: { deleteRecord(name: selectedAccount.0) }, isSheetPresented: self.$showDetailSheet)
                                        }
                                    }.presentationDetents([.height(380)])
                                }
                                
                            }
                        }
                        .padding(.top,18)
                    }
                    
                    VStack
                    {
                        Spacer()
                        
                        HStack{
                            Spacer()
                            Button(action: {
                                showAddingSheet.toggle()
                            }) {
                                Image("Plus button")
//                                    .frame(width: 60,height:60)
//                                    .font(.system(size:26.13))
//                                    .bold()
//                                    .background(Color(UIColor(red: 0.2471, green: 0.4902, blue: 0.8902, alpha: 1.0)))
                                    .cornerRadius(10)
                                    .padding(.leading,284.21)
                                    .padding([.trailing,.bottom],20)
                                    .shadow(color:Color(UIColor(red: 0, green: 0, blue: 0, alpha: 0.15)),radius: 15,x: 5,y:5)
                                
                                
                            }
                            .sheet(isPresented: $showAddingSheet) {
                                AddRecordContentView{ name, email, password in
                                    saveRecord(name: name, email: email, password: password)
                                    accounts = fetchRecords()
                                }
                                .presentationDetents([.height(333)])
                                .presentationCornerRadius(17)
                                
                            }
                            
                        }
                    }
                } else {
                    
                    Text("Locked")
                }
                
                if showAddingSheet || showDetailSheet {
                    withAnimation{
                        Color(red:0,green: 0,blue: 0,opacity:0.6)
                            .ignoresSafeArea()
                    }
                }
            }
            .onAppear(){
                do {
                    authenticate()
                    try generateAndStoreEncryptionKey()
                    print("Encryption key generated and stored successfully.")
                } catch {
                    print("Error generating and storing encryption key: \(error)")
                }
            }
            //            .navigationTitle("Password Manager")
            .toolbar{
                ToolbarItem(placement: .topBarLeading){
                    ZStack{
                        
                        
                        VStack{
                            
                            Text("Password Manager")
                                .padding(.top,57.52)
                                .font(.custom("SFProDisplay-Semibold", size: 18))
                                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2,opacity: 1))
                            
                        }
//                        .frame(width: 152,height: 21)
                        
                         
                    }.padding(.bottom,50)
                    
                }
                
            }
            
            
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

#Preview {
    HomeContentView()
}
