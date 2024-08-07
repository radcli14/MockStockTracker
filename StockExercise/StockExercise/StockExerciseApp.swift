//
//  StockExerciseApp.swift
//  StockExercise
//
//  Created by Eliott Radcliffe on 8/7/24.
//

import SwiftUI

@main
struct StockExerciseApp: App {
    @StateObject var tracker = StockTracker()
    
    var body: some Scene {
        WindowGroup {
            StockTrackerView(tracker: tracker)
        }
    }
}
