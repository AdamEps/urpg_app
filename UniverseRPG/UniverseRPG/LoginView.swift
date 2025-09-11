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
    @ObservedObject var gameStateManager: GameStateManager
    
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUp = false
    @State private var errorMessage = ""
    @State private var showingDevTool = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Dev tool button (top right)
            HStack {
                Spacer()
                Button(action: {
                    showingDevTool = true
                }) {
                    Image(systemName: "wrench.and.screwdriver")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
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
        .sheet(isPresented: $showingDevTool) {
            AccountDevToolView(gameStateManager: gameStateManager) { username, password in
                // Auto-fill the login form
                self.username = username
                self.password = password
                self.errorMessage = ""
                
                // Automatically trigger sign in after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.attemptSignIn()
                }
            }
        }
    }
    
    private func setupTestAccount() {
        let userDefaults = UserDefaults.standard
        userDefaults.set("test", forKey: "test_password")
        
        // Set up creation and last login times for test account if they don't exist
        if userDefaults.object(forKey: "test_created_at") == nil {
            userDefaults.set(Date(), forKey: "test_created_at")
        }
        if userDefaults.object(forKey: "test_last_login") == nil {
            userDefaults.set(Date(), forKey: "test_last_login")
        }
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
        
        // Create new account using GameStateManager
        gameStateManager.createUser(username: username, password: password)
        loginUser()
    }
    
    private func loginUser() {
        // Use GameStateManager's login system
        gameStateManager.login(username: username)
        
        // Update ContentView's state
        currentUsername = username
        isLoggedIn = true
        
        print("✅ Logged in as: \(username)")
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
