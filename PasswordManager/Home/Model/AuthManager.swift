//
//  AuthManager.swift
//  PasswordManager
//
//  Created by Hitesh Madaan on 14/06/25.
//

import Foundation
import LocalAuthentication

class AuthManager {
    static let shared = AuthManager()
    private let context = LAContext()
    
    func authenticate(reason: String = "We need to unlock your data.", completion: @escaping (Bool, Error?) -> Void) {
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason, reply: completion)
        } else {
            completion(false, error)
        }
    }
}
