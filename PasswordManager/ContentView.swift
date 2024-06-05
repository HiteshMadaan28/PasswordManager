//
//  ContentView.swift
//  PasswordManager
//
//  Created by Hitesh Madaan on 05/06/24.
//

import SwiftUI

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
    @State private var accountName=""
    @State private var userName=""
    @State private var password=""
    @State private var showAddingSheet: Bool = false
    var body: some View {
        NavigationStack{
            List{
                ForEach(accounts,id:\.self){
                    Text("\($0)")
                }
            }
            
            Button("Click"){
                showAddingSheet.toggle()
            }
            .sheet(isPresented:$showAddingSheet){
                AddNewAccount()
                    .presentationDetents([.fraction(0.4),.large])
                    .presentationDragIndicator(.visible)
            }
                
            .navigationTitle("Password Manager")
            
            
        }
        
    }
}

#Preview {
    ContentView()
}
