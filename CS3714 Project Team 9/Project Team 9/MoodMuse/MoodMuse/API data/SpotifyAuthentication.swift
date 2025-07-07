//
//  SpotifyAuthentication.swift
//  MoodMuse
//
//  Created by Soham KN on 5/6/25.
//  Copyright © 2025 Soham Nawthale. All rights reserved.
//

import Foundation
import CryptoKit
import AuthenticationServices
import SwiftUI

// logs into spotify API
func login() {
    let userDefaults = UserDefaults.standard

    // Check if access token, refresh token, and expiration date exist
    if let accessToken = userDefaults.string(forKey: "spotify_access_token"),
       let refreshToken = userDefaults.string(forKey: "spotify_refresh_token"),
       let expiration = userDefaults.object(forKey: "spotify_token_expiration") as? Date {
        
        // Check if the access token is still valid
        if expiration > Date() {
            print("Access token is still valid.")
            return
        } else {
            // Access token expired — try to refresh
            print("Access token expired. Attempting refresh...")
            refreshSpotifyAccessToken()

            // Give time for the refresh to complete before checking again
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let newAccessToken = userDefaults.string(forKey: "spotify_access_token"),
                   let newExpiration = userDefaults.object(forKey: "spotify_token_expiration") as? Date,
                   newExpiration > Date() {
                    print("Token refreshed successfully.")
                } else {
                    print("Failed to refresh token. Need to reauthenticate.")
                    authenticateWithSpotify()
                }
            }
            return
        }
    }

    // 4. No access or refresh token available — start login flow
    print("🚪 No tokens found. Starting authentication.")
    authenticateWithSpotify()
}



// generates a random string of defined lenth
// will be used to generate Code Challenge
// Usage : let codeVerifier = generateRandomString(length: 64)
func generateRandomString(length: Int) -> String {
    let characters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
    var randomString = ""
    for _ in 0..<length {
        if let randomChar = characters.randomElement() {
            randomString.append(randomChar)
        }
    }
    return randomString
}

// encode the a string in SHA256
// converts it to utf8 first, then hashes it to SHA256
// usage : let hashed = sha256(codeVerifier)
func sha256(_ input: String) -> Data {
    let inputData = Data(input.utf8)
    let hashed = SHA256.hash(data: inputData)
    return Data(hashed)
}
// converts data to a base 64 string
// usage : let codeChallenge = base64URLEncode(hashed)
func base64URLEncode(_ data: Data) -> String {
    let base64 = data.base64EncodedString()
    let base64Url = base64
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
    return base64Url
}


// Example function to generate auth URL and open Spotify login
func authenticateWithSpotify() {
    print("test a")
    let clientId = spotifyClientID
    let redirectUri = "moodmuse://callback" // Important: Must match what you registered with Spotify

    let scope = "user-read-private user-read-email playlist-read-private playlist-read-collaborative playlist-modify-private playlist-modify-public"
    let authBaseUrl = "https://accounts.spotify.com/authorize"
    
    // Assume you already have the codeVerifier and codeChallenge ready
    let codeVerifier = generateRandomString(length: 64)
    let hashed = sha256(codeVerifier)
    let codeChallenge = base64URLEncode(hashed)
    
    // Save code verifier locally (equivalent to window.localStorage)
    UserDefaults.standard.set(codeVerifier, forKey: "spotify_code_verifier")
    
    // Build the authorization URL
    var components = URLComponents(string: authBaseUrl)!
    components.queryItems = [
        URLQueryItem(name: "response_type", value: "code"),
        URLQueryItem(name: "client_id", value: clientId),
        URLQueryItem(name: "scope", value: scope),
        URLQueryItem(name: "redirect_uri", value: redirectUri),
        URLQueryItem(name: "code_challenge_method", value: "S256"),
        URLQueryItem(name: "code_challenge", value: codeChallenge)
    ]
    print("test b")
    guard let authUrl = components.url else {
        print("Failed to construct Spotify auth URL.")
        return
    }
    print("test c")
    // Open the URL to start OAuth flow
    UIApplication.shared.open(authUrl, options: [:], completionHandler: nil)
    print("test d")
}


func exchangeCodeForTokens(code: String) {
    let tokenUrl = URL(string: "https://accounts.spotify.com/api/token")!
    
    let clientId = spotifyClientID
    let redirectUri = "moodmuse://callback"
    
    // Retrieve the previously saved code_verifier
    guard let codeVerifier = UserDefaults.standard.string(forKey: "spotify_code_verifier") else {
        print("Missing code verifier.")
        return
    }
    
    let bodyParams = [
        "grant_type": "authorization_code",
        "code": code,
        "redirect_uri": redirectUri,
        "client_id": clientId,
        "code_verifier": codeVerifier
    ]
    
    let bodyString = bodyParams
        .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
        .joined(separator: "&")
    
    var request = URLRequest(url: tokenUrl)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.httpBody = bodyString.data(using: .utf8)
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error exchanging code for tokens: \(error)")
            return
        }
        
        guard let data = data else {
            print("No data received from Spotify token exchange.")
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Token exchange response: \(json)")
                
                if let accessToken = json["access_token"] as? String,
                   let refreshToken = json["refresh_token"] as? String {
                    
                    // Save access and refresh tokens
                    UserDefaults.standard.set(accessToken, forKey: "spotify_access_token")
                    UserDefaults.standard.set(refreshToken, forKey: "spotify_refresh_token")
                    
                    // Handle token expiration
                    if let expiresIn = json["expires_in"] as? Int {
                        let expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
                        UserDefaults.standard.set(expirationDate, forKey: "spotify_token_expiration")
                        print("Access token expires in \(expiresIn) seconds at \(expirationDate)")
                    } else {
                        print("Warning: No expires_in found.")
                    }
                    
                } else {
                    print("Failed to parse access or refresh token.")
                }
            }
        } catch {
            print("Failed to decode token response: \(error)")
        }
    }
    
    task.resume()
}

// Refreshs spotify access token
func refreshSpotifyAccessToken() {
    let tokenUrl = URL(string: "https://accounts.spotify.com/api/token")!
    
    // Retrieve stored refresh token and client ID
    guard let refreshToken = UserDefaults.standard.string(forKey: "spotify_refresh_token") else {
        print("No refresh token available.")
        return
    }
    
    let clientId = spotifyClientID  // Replace with your actual Client ID
    
    // Build URL-encoded body
    let bodyParams = [
        "grant_type": "refresh_token",
        "refresh_token": refreshToken,
        "client_id": clientId
    ]
    
    let bodyString = bodyParams
        .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
        .joined(separator: "&")
    
    var request = URLRequest(url: tokenUrl)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.httpBody = bodyString.data(using: .utf8)
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error refreshing token: \(error)")
            return
        }
        
        guard let data = data else {
            print("No data received from token refresh.")
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Token refresh response: \(json)")
                
                if let accessToken = json["access_token"] as? String {
                    UserDefaults.standard.set(accessToken, forKey: "spotify_access_token")
                    print("Access Token (refreshed): \(accessToken)")
                    
                    // If a new refresh token is returned, update it
                    if let newRefreshToken = json["refresh_token"] as? String {
                        UserDefaults.standard.set(newRefreshToken, forKey: "spotify_refresh_token")
                        print("Refresh Token (updated): \(newRefreshToken)")
                    }

                    // Store expiration time if provided
                    if let expiresIn = json["expires_in"] as? Int {
                        let expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
                        UserDefaults.standard.set(expirationDate, forKey: "spotify_token_expiration")
                        print("New token expires in \(expiresIn) seconds")
                    }
                } else {
                    print("Access token not found in refresh response.")
                }
            }
        } catch {
            print("Error decoding token refresh response: \(error)")
        }
    }
    
    task.resume()
}


// checks to see if there is time remaining to make an api call
func checkSpotifyAccessToken() {
    let userDefaults = UserDefaults.standard

    // Get stored expiration date
    guard let expirationDate = userDefaults.object(forKey: "spotify_token_expiration") as? Date else {
        print("❌ No token expiration date found. Triggering login or refresh.")
        login()
        return
    }

    // Add a 5-minute buffer (300 seconds)
    let bufferDate = Date().addingTimeInterval(300)

    if expirationDate > bufferDate {
        print("✅ Access token is valid (more than 5 min remaining).")
        return
    } else {
        print("⚠️ Access token is close to expiring or already expired. Refreshing...")
        refreshSpotifyAccessToken()
    }
}

// checks if user ID exists, if not it creates one

func checkUserID() {
    if let userID = UserDefaults.standard.string(forKey: "spotify_user_id") {
        print("Spotify user ID already exists: \(userID)")
        return
    }

    print("Spotify user ID not found. Fetching from Spotify...")

    // Ensure access token is valid
    checkSpotifyAccessToken()
    
    let apiUrl = "https://api.spotify.com/v1/me"
    let accessToken = UserDefaults.standard.string(forKey: "spotify_access_token") ?? ""
    let spotifyApiHeaders = [
        "Authorization": "Bearer \(accessToken)",
        "Accept": "application/json"
    ]
    
    if let jsonData = getJsonDataFromApi(apiHeaders: spotifyApiHeaders, apiUrl: apiUrl, timeout: 20.0) {
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let userId = jsonObject["id"] as? String {
                UserDefaults.standard.set(userId, forKey: "spotify_user_id")
                print("Saved new Spotify user ID: \(userId)")
            } else {
                print("Failed to parse user ID from response.")
            }
        } catch {
            print("JSON parsing error while fetching user ID: \(error)")
        }
    } else {
        print("Failed to fetch user ID from Spotify API.")
    }
}

