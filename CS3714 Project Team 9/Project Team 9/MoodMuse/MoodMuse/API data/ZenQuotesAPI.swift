//
//  ZenQuotesAPI.swift
//  MoodMuse
//
//  Created by Soham KN on 4/28/25.
//  Copyright © 2025 Soham Nawthale. All rights reserved.
//

import Foundation

/*
 The API requires the full complete name of a national park to search for.
 Therefore, only one park can be found for the given full name.
 */
// Global variable to contain the API search results
var quote = QuoteStruct(q: "", a: "")
 

/*
 ================================================
 |   Fetch and Process JSON Data from the API   |
 |   for a National Park with its name given    |
 ================================================
*/
public func getQuote() {
   
    // Avoid executing this function if already done for the same park nam
   
    // Initialize the global variable to contain the API search results
    quote = QuoteStruct(q: "", a: "")
    
    let apiUrlString = "https://zenquotes.io/api/random"
    /*
    ***************************************************
    *   Fetch JSON Data from the API Asynchronously   *
    ***************************************************
    */
    print("test 1")
    var jsonDataFromApi: Data
    
    let jsonDataFetchedFromApi = getJsonDataFromApiNoHeaders(apiUrl: apiUrlString, timeout: 20.0)
    
    if let jsonData = jsonDataFetchedFromApi {
        jsonDataFromApi = jsonData
    } else {
        return
    }
    print("test 2")
    /*
    **************************************************
    *   Process the JSON Data Fetched from the API   *
    **************************************************
    */
    do {
        let jsonResponse = try JSONSerialization.jsonObject(with: jsonDataFromApi,
                          options: JSONSerialization.ReadingOptions.mutableContainers)
        //-----------------------------
        // Obtain Top Level JSON Object
        //-----------------------------
        var topLevel = [Any]()
        
        if let jArray = jsonResponse as? [Any] {
            topLevel = jArray
        } else {
            // nationalParkFound will have empty values
            return
        }
        
        var jsonDataDictionary = [String: Any]()
        
        if let jsonObject = topLevel[0] as? [String: Any] {
            jsonDataDictionary = jsonObject
        } else {
            // nationalParkFound will have empty values
            return
        }
        var quo = ""
        
        if let jObject = jsonDataDictionary["q"] as? String {
            quo = jObject
        }
        var author = ""
        
        if let jObject = jsonDataDictionary["a"] as? String {
            author = jObject
        }
        print("test 4")
        quote = QuoteStruct(q: quo, a: author)
        print("test 5")
    } catch {
        // nationalParkFound will have empty values
        return
    }
       
}
 
 

