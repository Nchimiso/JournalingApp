//
//  MoodMuseApp.swift
//  MoodMuse
//
//  Created by CS3714 on 4/27/25.
//  Copyright © 2025 Nchimi Mvula. All rights reserved.
//  Copyright © 2025 Yejin Moon. All rights reserved.
//  Copyright © 2025 Soham Nawthale. All rights reserved.
//

/*
**********************************************************
*   Statement of Compliance with the Stated Honor Code   *
**********************************************************
I hereby declare on my honor and I affirm that
 
 (1) I have not given or received any unauthorized help on this project, and
 (2) All work is my own in this project.
 
I am hereby writing my name as my signature to declare that the above statements are true:
   
    Nchimi Mvula Yejin Moon Soham Nawthale
 
**********************************************************
 */

import SwiftUI
import SwiftData

@main
struct MoodMuseApp: App {
    init() {
        /*
         ------------------------------------------------------------
         |   Create National Park Visits Database upon App Launch   |
         |   IF the app is being launched for the first time.       |
         ------------------------------------------------------------
         */
        createJournalDatabase()      // Given in DatabaseCreation.swift
        
    }

    @AppStorage("darkMode") private var darkMode = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Change the color mode of the entire app to Dark or Light
                .preferredColorScheme(darkMode ? .dark : .light)
            
                /*
                 Inject the Model Container into the environment so that you can access its Model Context
                 in a SwiftUI file by using @Environment(\.modelContext) private var modelContext
                 */
                .modelContainer(for: [JournalEntry.self, JournalAudio.self, JournalPhoto.self,
                                      Song.self], isUndoEnabled: true)
        }
    }
}


