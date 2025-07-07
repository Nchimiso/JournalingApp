//
//  SpotifyPlaylist.swift
//  MoodMuse
//
//  Created by Soham KN on 5/6/25.
//  Copyright © 2025 Soham Nawthale. All rights reserved.
//

import AuthenticationServices
import CryptoKit
import Foundation
import SwiftUI

var playlists = [PlaylistStruct]() // list of all playlists in spotify
var playlistTracks = [SongStruct]() // list of tracks in playlist selected

// get information on the playlists
func fetchUserPlaylists() {

    // check if the access token needs to be refreshed
    checkSpotifyAccessToken()
    playlists = [PlaylistStruct]()
    // make the api URL
    let url = "https://api.spotify.com/v1/me/playlists"
    print("Api URL being used for search: \(url)")

    // make the apiHeader
    let accessToken =
        UserDefaults.standard.string(forKey: "spotify_access_token") ?? ""
    print("Using access token:", accessToken)

    let spotifyApiHeaders = [
        "Authorization": "Bearer \(accessToken)",
        "Accept": "application/json",
    ]

    // call GET api request
    if let jsonData = getJsonDataFromApi(
        apiHeaders: spotifyApiHeaders, apiUrl: url, timeout: 20.0)
    {
        do {
            let jsonObject = try JSONSerialization.jsonObject(
                with: jsonData, options: [])
            print("playlist api response:", jsonObject)
            if let root = jsonObject as? [String: Any],
                let items = root["items"] as? [[String: Any]]
            {

                for playlist in items {
                    let playlistName =
                        playlist["name"] as? String ?? "Unknown Playlist"
                    let isPublic = playlist["public"] as? Bool ?? false
                    let playlistId = playlist["id"] as? String ?? "N/A"
                    let playlistUri = playlist["uri"] as? String ?? "N/A"

                    var imageUrl = ""
                    if let images = playlist["images"] as? [[String: Any]],
                        let firstImage = images.first,
                        let url = firstImage["url"] as? String
                    {
                        imageUrl = url
                    }

                    var ownerName = "Unknown"
                    if let owner = playlist["owner"] as? [String: Any],
                        let displayName = owner["display_name"] as? String
                    {
                        ownerName = displayName
                    }

                    let newPlaylist = PlaylistStruct(
                        id: playlistId,
                        name: playlistName,
                        owner: ownerName,
                        visiblity: isPublic,
                        imageUrl: imageUrl
                    )

                    playlists.append(newPlaylist)

                    print(
                        """
                        Playlist: \(playlistName)
                        Owner: \(ownerName)
                        Public: \(isPublic ? "Yes" : "No")
                        Image URL: \(imageUrl)
                        URI: \(playlistUri)
                        ID: \(playlistId)
                        -------------------------------
                        """)
                }

            } else {
                print("Could not parse JSON Object.")
            }

        } catch {
            print("Failed to decode playlist response: \(error)")
        }
    }

}

// checks if a playlist (name) exists, if not it creates one
public func checkPlaylistExist(name: String) {
    for playlist in playlists {
        if playlist.name == name {
            print("Found a play list called \(name)")
            return
        }
    }
    print("\(name) is not in your current playlists")
    // check if user ID exist, creates one if not there
    // also checks if access token is valid
    checkUserID()

    let userID = UserDefaults.standard.string(forKey: "spotify_user_id") ?? ""
    print("User ID:", userID)

    // make the apiHeader
    let accessToken =
        UserDefaults.standard.string(forKey: "spotify_access_token") ?? ""
    print("Using access token:", accessToken)

    let apiUrl = "https://api.spotify.com/v1/users/\(userID)/playlists"

    guard let url = URL(string: apiUrl) else {
        print("Invalid URL.")
        return
    }

    let headers = [
        "Authorization": "Bearer \(accessToken)",
        "Content-Type": "application/json",
    ]

    let requestBody: [String: Any] = [
        "name": name,
        "description": "Created with MoodMuse",
        "public": false,  // 👈 This sets the playlist to private
    ]

    do {
        let jsonData = try JSONSerialization.data(
            withJSONObject: requestBody, options: [])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            if let error = error {
                print("Error creating playlist: \(error)")
                return
            }

            guard let data = data else {
                print("No response data received.")
                return
            }

            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data)
                    as? [String: Any]
                {
                    print(
                        "Playlist created: \(jsonObject["name"] ?? "Unnamed")"
                    )
                    print("URI: \(jsonObject["uri"] ?? "No URI")")
                }
            } catch {
                print("Failed to parse response JSON: \(error)")
            }
        }
        task.resume()
    } catch {
        print("Failed to serialize JSON: \(error)")
    }
    
    // refresh the playlist within app
    fetchUserPlaylists()
}

// add track to playlist based on playlist ID and Track ID
func addTrackToPlaylist(trackID: String, playlistID: String) {
    checkSpotifyAccessToken()

    let apiUrl = "https://api.spotify.com/v1/playlists/\(playlistID)/tracks"
    let accessToken = UserDefaults.standard.string(forKey: "spotify_access_token") ?? ""

    let spotifyApiHeaders = [
        "Authorization": "Bearer \(accessToken)",
        "Content-Type": "application/json"
    ]

    let trackURI = "spotify:track:\(trackID)"

    let requestBody: [String: Any] = [
        "uris": [trackURI]
    ]

    do {
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])

        if let response = postJsonDataToApi(apiHeaders: spotifyApiHeaders, apiUrl: apiUrl, jsonData: jsonData, timeout: 20.0) {
            print("successfully added track to playlist.")
            print(String(data: response, encoding: .utf8) ?? "No response string")
        } else {
            print("failed to add track to playlist.")
        }
    } catch {
        print("JSON encoding error: \(error)")
    }
}

// populate playlistTracks with a list of song structs 
func getTracksFromPlaylist(playlistID: String) {
    
    playlistTracks = [SongStruct]()

    checkSpotifyAccessToken()
    
    let accessToken = UserDefaults.standard.string(forKey: "spotify_access_token") ?? ""
    let apiUrl = "https://api.spotify.com/v1/playlists/\(playlistID)/tracks"
    let spotifyApiHeaders = [
        "Authorization": "Bearer \(accessToken)",
        "Accept": "application/json"
    ]

    if let jsonData = getJsonDataFromApi(apiHeaders: spotifyApiHeaders, apiUrl: apiUrl, timeout: 20.0) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]

            if let items = jsonObject?["items"] as? [[String: Any]] {
                for item in items {
                    if let track = item["track"] as? [String: Any] {
                        // get track info
                        let id = track["id"] as? String ?? ""
                        let name = track["name"] as? String ?? "Unknown"
                        let durationMs = track["duration_ms"] as? Int ?? 0
                        let popularity = track["popularity"] as? Int ?? 0

                        // Get album name and image URL
                        var albumName = "Unknown Album"
                        var imageUrl = ""
                        if let album = track["album"] as? [String: Any] {
                            
                            albumName = album["name"] as? String ?? "Unknown Album"
                            
                            if let images = album["images"] as? [[String: Any]],
                               let firstImage = images.first,
                               let url = firstImage["url"] as? String {
                                imageUrl = url
                            }
                        }

                        // Get artist name
                        var artistName = "Unknown Artist"
                        if let artists = track["artists"] as? [[String: Any]],
                           let firstArtist = artists.first,
                           let name = firstArtist["name"] as? String {
                            artistName = name
                        }

                        let newSong = SongStruct(
                            id: id,
                            name: name,
                            albumName: albumName,
                            imageURL: imageUrl,
                            duration: durationMs / 1000,
                            popularity: popularity,
                            artist: artistName,
                            mood: "" // Optional if needed
                        )

                        playlistTracks.append(newSong)
                    }
                }
            }
        } catch {
            print("failed to parse playlist tracks JSON: \(error)")
        }
    }
}

func getPlaylistIDFromName(name: String) -> String{
    for playlist in playlists {
        if playlist.name == name {
            print("playlist: \(name) found!")
            return playlist.id
        }
     }
    print("playlist: \(name) NOT FOUND")
    return ""
}
