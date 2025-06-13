//
//  AddRecordContentView.swift
//  PasswordManager
//
//  Created by Hitesh Madaan on 13/06/25.
//

import SwiftUI
import KeychainAccess
import CryptoKit

let keychain = Keychain(service: "com.example.PasswordManager")

//Generating key and store it
func generateAndStoreEncryptionKey() throws {
    
    //Check if a key exists or not
    if keychain[data: "encryptionKey"] == nil {
        
        let key = SymmetricKey(size: .bits256)
        try keychain.set(key.withUnsafeBytes { Data($0) }, key: "encryptionKey")
    }
}

struct AddRecordContentView: SwiftUI.View {
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
        ZStack{
            Color(red: 0.9765, green: 0.9765, blue: 0.9765,opacity: 1).ignoresSafeArea()
            
            
            
            VStack {
                
                
                Capsule()
                    .fill(Color(red: 0.8902, green: 0.8902, blue: 0.8902,opacity: 1))
                    .frame(width: 46, height: 4)
                    .padding(.top,8)
                Spacer()
                
            
                VStack(spacing:20){


                    TextField("Account Name", text: $name)
                        .cornerRadius(6)
                        .font(.custom("Roboto-Regular", size: 13))
                        .padding(.leading,20)
                        .frame(width: 313.45, height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color(UIColor(red: 0.7961, green: 0.7961, blue: 0.7961, alpha: 1.0)), style: StrokeStyle(lineWidth: 0.6)))
                        .background(Color.white)



                    TextField("Username/ Email", text: $email)
                        .cornerRadius(6)
                        .font(.custom("Roboto-Regular", size: 13))
                        .padding(.leading,20)
                        .frame(width: 313.45, height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color(UIColor(red: 0.7961, green: 0.7961, blue: 0.7961, alpha: 1.0)), style: StrokeStyle(lineWidth: 0.6)))
                        .background(Color.white)




                    HStack(alignment: .center){
                        if isPasswordVisible {
                            SecureField("Password", text: $password)

                        } else {
                            TextField("Password", text: $password)

                        }
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            
                            if !isPasswordVisible{
                                Image(systemName: "eye.fill")
                                    .foregroundColor(Color(UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)))
                            }
                            else{
                                Image("eye")
                                    .foregroundColor(Color(UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)))
                            }
//                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
//                                .foregroundColor(.gray)
                        }
                        .padding(.trailing,20)
                    }
                    .cornerRadius(6)
                    .font(.custom("Roboto-Regular", size: 13))
                    .padding(.leading,20)
                    .frame(width: 313.45, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color(UIColor(red: 0.7961, green: 0.7961, blue: 0.7961, alpha: 1.0)), style: StrokeStyle(lineWidth: 0.6)))
                    .background(Color.white)

                }



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
                    .frame(width: 325,height:44)
                    .foregroundColor(Color.white)
                    .font(.custom("Poppins-Bold", size: 16))
                    .background(Color(red: 0.1725, green: 0.1725, blue: 0.1725,opacity: 1))
                    .cornerRadius(20)
                    .shadow(color:Color(red:0,green:0,blue:0,opacity:0.25),radius: 4,x: 0,y:1)
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Validation Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    }

                }.padding(.top,26)
                
                Spacer()
            }
            
        }
        
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
