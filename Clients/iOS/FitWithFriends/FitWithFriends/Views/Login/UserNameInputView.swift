//
//  UserNameInputView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 7/29/25.
//

import SwiftUI

struct UserNameInputView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @Environment(\.dismiss) private var dismiss
    
    let completion: (String, String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Complete Your Profile")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Please enter your name to complete your account setup")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("First Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("Enter your first name", text: $firstName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("Enter your last name", text: $lastName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                    }
                }
                .padding(.horizontal)
                
                Button("Continue") {
                    let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
                    completion(trimmedFirstName, trimmedLastName)
                    dismiss()
                }
                .disabled(firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                          lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 24)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct UserNameInputView_Previews: PreviewProvider {
    static var previews: some View {
        UserNameInputView { firstName, lastName in
            print("Name entered: \(firstName) \(lastName)")
        }
    }
}
