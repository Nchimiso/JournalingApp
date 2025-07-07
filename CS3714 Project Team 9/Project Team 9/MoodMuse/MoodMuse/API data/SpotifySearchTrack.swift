//
//  SpotifySearchTrack.swift
//  MoodMuse
//
//  Created by Soham KN on 5/6/25.
//  Copyright © 2025 Soham Nawthale. All rights reserved.
//

import Foundation
import CryptoKit
import AuthenticationServices
import SwiftUI

var foundSongs = [SongStruct]()
var songToAdd = SongStruct(id: "", name: "", albumName: "", imageURL: "", duration: 0, popularity: 0, artist: "", mood: "")

// gets songs based on relavance of the search, if focused on tracks names
func getSongs(query: String) {
    
    foundSongs = [SongStruct]()
    songToAdd = SongStruct(id: "", name: "", albumName: "", imageURL: "", duration: 0, popularity: 0, artist: "", mood: "")
    
    // check if the access token needs to be refreshed
    checkSpotifyAccessToken()
    
    // make the api URL
    let apiUrl = "https://api.spotify.com/v1/search?q=\(query)&type=track&limit=5"
    print("Api URL being used for search: \(apiUrl)")
    
    // make the apiHeader
    let accessToken = UserDefaults.standard.string(forKey: "spotify_access_token") ?? ""
    print("Using access token:", accessToken)
    let spotifyApiHeaders = [
        "Authorization": "Bearer \(accessToken)",
        "Accept": "application/json"
    ]
    
    // call GET api request
    if let jsonData = getJsonDataFromApi(apiHeaders: spotifyApiHeaders, apiUrl: apiUrl, timeout: 20.0) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])

            if let root = jsonObject as? [String: Any],
               let tracksDict = root["tracks"] as? [String: Any],
               let items = tracksDict["items"] as? [[String: Any]] {

                for item in items {
                    // get track info  
                    let trackName = item["name"] as? String ?? "Unknown Track"
                    let durationMs = item["duration_ms"] as? Int ?? 0
                    let popularity = item["popularity"] as? Int ?? 0
                    let trackId = item["id"] as? String ?? "N/A"
                    let trackUri = item["uri"] as? String ?? "N/A"
                    let isPlayable = item["is_playable"] as? Bool ?? false

                    // get artist name
                    var artistList = [String]()
                    var artistName = "Unknown Artist"
                    if let artists = item["artists"] as? [[String: Any]],
                       let firstArtist = artists.first,
                       let name = firstArtist["name"] as? String {
                        artistName = name
                        for artist in artists {
                            if let temp = artist["name"] as? String {
                                artistList.append(temp)
                            }
                        }
                    }

                    // Get album name and image URL
                    var albumName = "Unknown Album"
                    var imageUrl = ""
                    if let album = item["album"] as? [String: Any] {
                        albumName = album["name"] as? String ?? "Unknown Album"
                        if let images = album["images"] as? [[String: Any]],
                           let firstImage = images.first,
                           let url = firstImage["url"] as? String {
                            imageUrl = url
                        }
                    }
                    
                    let newSong = SongStruct(
                        id: trackId,
                        name: trackName,
                        albumName: albumName,
                        imageURL: imageUrl,
                        duration: durationMs / 1000,
                        popularity: popularity,
                        artist: artistName,
                        mood: ""
                    )
                    
                    foundSongs.append(newSong)
                    
                    print("""
                    number of artists: \(artistList.count)
                    \(trackName) by \(artistName)
                    Album: \(albumName)
                    Duration: \(durationMs / 1000) sec
                    Popularity: \(popularity)
                    URI: \(trackUri)
                    Image URL: \(imageUrl)
                    Playable: \(isPlayable)
                    -------------------------------
                    """)
                }
            } else {
                print("Could not parse JSON object.")
            }
        } catch {
            print("Failed to decode search response: \(error)")
        }
    }


    
}
