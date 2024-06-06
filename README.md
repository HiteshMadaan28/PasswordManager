PasswordManager 
Practical Number: MOBILEIIP02504.md

Overview
PasswordManager is a secure and user-friendly iOS application for managing your passwords. It uses biometrics for authentication and encryption to keep your data safe. This document provides clear instructions on how to build, run, and use the PasswordManager application.

Prerequisites
macOS with Xcode installed (version 12.0 or higher).
A valid Apple Developer account for signing the application.
An iOS device or simulator for testing.

Setup Instructions

1. Clone the Repository
First, clone the repository from GitHub:
git clone https://github.com/yourusername/PasswordManager.git
cd PasswordManager

2. Open the Project in Xcode
Open `PasswordManager.xcodeproj` in Xcode:
open PasswordManager.xcodeproj

3. Install Dependencies
Ensure all dependencies are installed. PasswordManager uses `SQLite` and `KeychainAccess` libraries, which should be added via Swift Package Manager.

1. Open the project in Xcode.
2. Go to `File` > `Add Packages`.
3. Search for `https://github.com/stephencelis/SQLite.swift` and add the package.
4. Search for `https://github.com/kishikawakatsumi/KeychainAccess` and add the package.

4. Configure the App
Make sure to set up the App ID and provisioning profiles in Xcode:
1. Go to the `Signing & Capabilities` tab.
2. Select your team.
3. Ensure the bundle identifier is unique (e.g., `com.yourusername.PasswordManager`).

5. Build and Run the App
Select your target device or simulator and click the `Run` button (or press `Cmd+R`). Xcode will build the app and install it on the selected device or simulator.

Usage Instructions

Adding a New Account
1. Launch the PasswordManager app.
2. Tap the `+` button to add a new account.
3. Fill in the account name, email/username, and password.
4. Tap the `Add New Account` button to save the account. The password is encrypted before saving.

Fig.1 (Adding Account)
Viewing Account Details
1. From the main screen, tap on any account to view its details.
2. The account name, email/username, and password (masked) will be displayed.
3. Tap the `eye` icon to toggle password visibility.

Fig2. View Account Details
Editing an Account
1. From the account details screen, edit the email/username or password fields.
2. Tap the `Edit` button to save the changes. The password is re-encrypted before saving.
3. Changes will be reflected in the main list.

   Fig3. Before Password Edit             

 Fig4. After Password Edit
Deleting an Account
1. From the account details screen, tap the `Delete` button.
2. Confirm the deletion. The account will be removed from the list.

Fig5.List of Password 

Fig6. After Deleting 
Technical Details
Encryption
Passwords are encrypted using AES-GCM with a symmetric key stored in the iOS Keychain. This ensures that your passwords are secure both in transit and at rest.

Biometric Authentication
The app uses Local Authentication (Face ID) to unlock access to the password manager, providing an additional layer of security.

Database
SQLite is used as the local database to store account information. The database schema includes three fields: name, email, and password.

By following these instructions, you should be able to successfully build, run, and use the PasswordManager application.


