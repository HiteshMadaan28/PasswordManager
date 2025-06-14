import SwiftUI

struct HomeContentView: View {
    @StateObject private var viewModel = HomeContentViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor(red: 0.9529, green: 0.9608, blue: 0.9804, alpha: 1.0))
                    .ignoresSafeArea()
                
                if viewModel.unlocked {
                    unlockedView
                } else {
                    Text("Locked")
                }
                
                if viewModel.showAddingSheet || viewModel.showDetailSheet {
                    Color(red: 0, green: 0, blue: 0, opacity: 0.6)
                        .ignoresSafeArea()
                }
            }
            .onAppear {
                viewModel.authenticate()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    VStack {
                        Text("Password Manager")
                            .padding(.top, 57.52)
                            .font(.custom("SFProDisplay-Semibold", size: 18))
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 1))
                    }
                    .padding(.bottom, 50)
                }
            }
        }
    }
    
    private var unlockedView: some View {
        VStack {
            ScrollView {
                Divider()
                    .frame(width: 375)
                    .position(x: -230, y: -81.16)
                    .foregroundColor(Color(red: 0.9098, green: 0.9098, blue: 0.9098, opacity: 1.0))
                
                VStack(spacing: 18) {
                    ForEach(viewModel.accounts, id: \.name) { account in
                        AccountRow(account: account) {
                            viewModel.selectedAccount = account
                            viewModel.showDetailSheet = true
                        }
                    }
                }
                .padding(.top, 18)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button(action: {
                    viewModel.showAddingSheet = true
                }) {
                    Image("Plus button")
                        .cornerRadius(10)
                        .padding(.leading, 284.21)
                        .padding([.trailing, .bottom], 20)
                        .shadow(color: Color(UIColor(red: 0, green: 0, blue: 0, alpha: 0.15)), radius: 15, x: 5, y: 5)
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddingSheet) {
            AddRecordContentView { name, email, password in
                viewModel.saveAccount(name: name, email: email, password: password)
            }
            .presentationDetents([.height(333)])
            .presentationCornerRadius(17)
        }
        .sheet(isPresented: $viewModel.showDetailSheet) {
            if let selectedAccount = viewModel.selectedAccount {
                AccountDetailContentView(
                    name: selectedAccount.name,
                    email: selectedAccount.email,
                    encryptedPassword: selectedAccount.password,
                    onSaveChanges: { name, email, password in
                        viewModel.updateAccount(Account(name: name, email: email, password: password))
                    },
                    onDelete: {
                        viewModel.deleteAccount(name: selectedAccount.name)
                    },
                    isSheetPresented: $viewModel.showDetailSheet
                )
            }
        }
        .presentationDetents([.height(380)])
        .presentationCornerRadius(17)
    }
}

private struct AccountRow: View {
    let account: Account
    let action: () -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            Text(account.name)
                .font(.custom("SFProDisplay-Semibold", size: 20))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 1.0))
                .padding(.leading, 25)
            
            VStack {
                Text("*******")
                    .frame(width: 69, height: 24)
                    .font(.custom("SFProDisplay-Semibold", size: 20))
                    .foregroundColor(Color(red: 0.7765, green: 0.7765, blue: 0.7765, opacity: 1.0))
            }
            .padding(.top, 10)
            .padding(.leading, 4)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .frame(width: 13.71, height: 6.86)
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 1.0))
                .padding(.trailing, 20)
        }
        .frame(width: 360, height: 66.19)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 40.0).strokeBorder(Color(red: 0.9294, green: 0.9294, blue: 0.9294, opacity: 1.0), style: StrokeStyle(lineWidth: 1.0)))
        .cornerRadius(50)
        .onTapGesture(perform: action)
    }
}
