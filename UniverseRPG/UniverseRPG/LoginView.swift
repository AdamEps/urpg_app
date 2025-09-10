//
//  SimpleLoginView.swift
//  UniverseRPG
//
//  Created by Adam Epstein on 9/10/25.
//

import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    let gameState: GameState
    
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUp = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Universe RPG")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 15) {
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if isSignUp {
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: {
                    if isSignUp {
                        attemptSignUp()
                    } else {
                        attemptSignIn()
                    }
                }) {
                    Text(isSignUp ? "Create Account" : "Sign In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    isSignUp.toggle()
                    errorMessage = ""
                    password = ""
                    confirmPassword = ""
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Need an account? Sign Up")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .background(Color.black)
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            setupTestAccount()
        }
    }
    
    private func setupTestAccount() {
        let userDefaults = UserDefaults.standard
        userDefaults.set("test", forKey: "test_password")
    }
    
    private func attemptSignIn() {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter username and password"
            return
        }
        
        let userDefaults = UserDefaults.standard
        let storedPassword = userDefaults.string(forKey: "\(username)_password")
        
        if storedPassword == password {
            loginUser()
        } else {
            errorMessage = "Invalid username or password"
        }
    }
    
    private func attemptSignUp() {
        guard !username.isEmpty else {
            errorMessage = "Please enter a username"
            return
        }
        
        guard password.count >= 4 else {
            errorMessage = "Password must be at least 4 characters"
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        let userDefaults = UserDefaults.standard
        let existingPassword = userDefaults.string(forKey: "\(username)_password")
        
        if existingPassword != nil {
            errorMessage = "Username already exists"
            return
        }
        
        // Create new account
        userDefaults.set(password, forKey: "\(username)_password")
        loginUser()
    }
    
    private func loginUser() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(username, forKey: "UniverseRPG_Username")
        userDefaults.set(true, forKey: "UniverseRPG_IsLoggedIn")
        
        currentUsername = username
        isLoggedIn = true
        
        print("✅ Logged in as: \(username)")
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
