//
//  AccountDetailContentView.swift
//  PasswordManager
//
//  Created by Hitesh Madaan on 13/06/25.
//

import SwiftUI
import CryptoKit

struct AccountDetailContentView : SwiftUI.View {
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
        ZStack{
            Color(red: 0.9765, green: 0.9765, blue: 0.9765,opacity: 1.0).ignoresSafeArea(.all)
            
            VStack{
                
                Capsule()
                    .fill(Color(red: 0.8902, green: 0.8902, blue: 0.8902,opacity: 1))
                    .frame(width: 46, height: 4)
                    .padding(.top,-7)
                    
        
                VStack(alignment: .leading,spacing: 14) {
                    
                    Text("Account Details")
                        .font(.custom("SFProDisplay-Bold", size: 19))
                        .foregroundColor(Color(red: 0.2471, green: 0.4902, blue: 0.8902,opacity: 1))
                        .padding(.top,-10)
                       
                        
                    VStack(alignment: .leading,spacing: 0) {
                        Text("Account Type")
                            .font(.custom("Roboto-Regular", size: 11))
                            .foregroundStyle(Color(red: 0.8, green: 0.8, blue: 0.8,opacity: 1))
                        Text(name)
                            .padding(.top,4)
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2,opacity: 1))
                    }.padding(.top,19)
    //                .padding(.bottom,10)
                    
                    
                    
                    VStack(alignment: .leading,spacing: 0) {
                        Text("Username/ Email")
                            .font(.custom("Roboto-Regular", size: 11))
                            .foregroundStyle(Color(red: 0.8, green: 0.8, blue: 0.8,opacity: 1))
                        
                        TextField("\(email)", text: $editedEmail)
                            .padding(.top,4)
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2,opacity: 1))
                        
                    }.padding(.top,10)
    //                .padding(.bottom,10)
                    
                    
                    
                    
                    VStack(alignment: .leading,spacing: 0) {
                        Text("Password")
                            .font(.custom("Roboto-Regular", size: 11))
                            .foregroundStyle(Color(red: 0.8, green: 0.8, blue: 0.8,opacity: 1))
                        
                        
                        HStack(alignment: .center){
                            if isPasswordVisible {
                                TextField("\(decryptedPassword)", text: $editedPassword)
                                    .padding(.top,4)
                                    .font(.custom("Poppins-SemiBold", size: 16))
                                    .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2,opacity: 1))
                                
                            } else {
                                Text("********")
                                    .padding(.top,4)
                                    .font(.custom("Poppins-SemiBold", size: 16))
                                    .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2,opacity: 1))
                                Spacer()
                                
                            }
                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                if(isPasswordVisible){
                                    Image(systemName: "eye.fill")
                                        .frame(width: 14,height: 13)
                                        .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8,opacity: 1))
                                        .padding(.trailing,20)
                                }
                                else{
                                    Image("eye")
                                        .interpolation(.none)
                                        .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8,opacity: 1))
                                        .background(Color(red: 0.9765, green: 0.9765, blue: 0.9765,opacity: 1.0))
                                        .padding(.trailing,20)
                                }
                            }
                        }
                        
                         
                    }.padding(.top,10)
                    
                    
                    
                        HStack(alignment: .center,spacing: 18){
                            
                            Button("Edit") {
                                do {
                                    let updatedEmail = editedEmail.isEmpty ? email : editedEmail
                                    let updatedPassword = editedPassword.isEmpty ? encryptedPassword : try encryptPassword(editedPassword)
                                    
                                    onSaveChanges(name, updatedEmail, updatedPassword)
                                    
                                } catch {
                                    showAlert(message: "Failed to encrypt editpassword.")
                                }
                            }
                            .frame(width: 154,height: 44)
                            .font(.custom("Poppins-Bold", size: 16))
                            .foregroundColor(.white)
                            .background(Color(red: 0.1725, green: 0.1725, blue: 0.1725,opacity: 1))
                            .shadow(color: Color(red:0,green: 0,blue: 0,opacity: 0.25) ,radius: 4,x: 0,y: 1)
                            .cornerRadius(20)
                            .padding(.leading,4)
                            
                            Button("Delete") {
                                onDelete()
                                isSheetPresented = false
                            }
                            .frame(width: 154,height: 44)
                            .font(.custom("Poppins-Bold", size: 16))
                            .foregroundColor(.white)
                            .background(Color(red: 0.9412, green: 0.2745, blue: 0.2745,opacity: 1))
                            .shadow(color: Color(red:0,green: 0,blue: 0,opacity: 0.25) ,radius: 4,x: 0,y: 1)
                            .cornerRadius(20)
                        }.padding(.top,28)
                    
                        
                    
                }
                .padding(20)
                .presentationCornerRadius(1.0)
                .presentationDetents([.height(380)])
                .presentationCornerRadius(17)
                .presentationDragIndicator(.hidden)
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
