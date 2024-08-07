//
//  StockTracker.swift
//  StockExercise
//
//  Created by Eliott Radcliffe on 8/7/24.
//

import Foundation

/// The `StockTracker` functions as our view model, providing wrappers and intents for the `User` and `StockApi` models. The latter are each `@Published`, so that the user interface will react to all changes.
class StockTracker: ObservableObject {
    @Published private var user: User = User()
    @Published private var api: StockApi = MockStockApi()
    
    /// Initialize the app by loading the `stocks` data from the local storage
    init() {
        loadFromLocal()
    }
    
    /// Wraps the `stocks` of the `user` variable
    var stocks: [Stock] {
        user.stocks
    }
    
    // MARK: - API Calls
    
    /// Refreshes the `stocks` of the `user` variable by calling the `getStocks(for: user)` method of the `api`
    @MainActor
    func refresh() async {
        api.status = .waiting(since: Date.now)
        if let result = await api.getStocks(for: user) {
            user.stocks = result
            user.lastUpdate = .now
            saveToLocal()
        }
        print(api.status)
    }
    
    /// Wraps the `StockApiStatus` of the `api` variable
    var apiStatus: StockApiStatus {
        api.status
    }
    
    /// Provide a `String` indicating the last time the `stocks` data was updated
    var lastUpdate: String {
        guard let lastUpdate = user.lastUpdate else {
            return "never"
        }
        return shortDateString(lastUpdate)
    }
    
    // MARK: - Local Storage
    
    /// Define a file path for storing the JSON data
    private var fileURL: URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentsDirectory?.appendingPathComponent("user.json")
    }

    /// Save the `User` data to local storage
    func saveToLocal() {
        if let encodedData = try? user.json(), let fileURL {
            try? encodedData.write(to: fileURL)
        }
    }

    /// Load the `User` data from local storage
    func loadFromLocal() {
        if let fileURL = fileURL,
            let data = try? Data(contentsOf: fileURL),
            let loadedUser = try? User(json: data) {
            user = loadedUser
        } else {
            print("Failed to load user from local storage")
        }
    }
    
    // MARK: - Utilities
    
    /// Formatter for generating nice string formatted dates
    var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    /// Function for generating nice string formatted dates
    func shortDateString(_ date: Date) -> String {
        return shortDateFormatter.string(from: date)
    }
}
