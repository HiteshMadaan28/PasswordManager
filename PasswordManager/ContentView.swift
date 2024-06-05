//
//  ContentView.swift
//  PasswordManager
//
//  Created by Hitesh Madaan on 05/06/24.
//

import SwiftUI
import LocalAuthentication


struct AddNewAccount:View {
    var body: some View {
        VStack(spacing:20){
            Text("Account Name")
            Image(systemName: "star")
                .padding()
        }
    }
}

struct ContentView: View {
    @State private var accounts:[String]=[]
    @State private var unlocked:Bool=false
    @State private var text="LOCKED"
    @State private var accountName=""
    @State private var userName=""
    @State private var password=""
    @State private var showAddingSheet: Bool = false
    var body: some View {
        NavigationStack{
            VStack {
                if unlocked {
                    Text("Unlocked")
                    List{
                        ForEach(accounts,id:\.self){
                            Text("\($0)")
                        }
                        
                        Text(text)
                            .bold()
                            .padding()
                        
                    }
                    
                    Button("Click"){
                        showAddingSheet.toggle()
                    }
                    .foregroundColor(.red)
                    .sheet(isPresented:$showAddingSheet){
                        AddNewAccount()
                            .presentationDetents([.fraction(0.4),.large])
                            .presentationDragIndicator(.visible)
                    }
                } else {
                    Text("Locked")
                }
            }
            .onAppear(perform: authenticate)
                
            .navigationTitle("Password Manager")
            
            
        }
        
    }
    func authenticate() {
        let context = LAContext()
        var error: NSError?

        // check whether biometric authentication is possible
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // it's possible, so go ahead and use it
            let reason = "We need to unlock your data."

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                // authentication has now completed
                if success {
                    // authenticated successfully
                    unlocked=true
                } else {
                    // there was a problem
                }
            }
        } else {
            // no biometrics
        }
    }

}

#Preview {
    ContentView()
}
