//
//  PlaylistStruct.swift
//  MoodMuse
//
//  Created by Soham KN on 5/6/25.
//  Copyright © 2025 Soham Nawthale. All rights reserved.
//

import SwiftUI
import Foundation

struct PlaylistStruct: Decodable, Encodable, Identifiable {
    var id: String
    var name: String
    var owner: String
    var visiblity: Bool // public vs private, true = prublic, false = private
    var imageUrl: String
}
