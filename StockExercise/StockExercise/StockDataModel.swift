//
//  StockDataModel.swift
//  StockExercise
//
//  Created by Eliott Radcliffe on 8/7/24.
//

import Foundation


/// Holds the price in dollars, and the time at which that price was obtained
struct Price: Codable {
    let time: Date
    let dollars: Double
}

/// Holds the symbol of a stock, and its price history with times and dollar amounts as in the `Price` model. Since we can assume stock symbols are always unique, we use the stock symbol as its identifier, which is used by the `List` in SwiftUI.
struct Stock: Codable, Identifiable {
    let symbol: String
    let history: [Price]
    var id: String {
        symbol
    }
}

/// Holds a user with a name, list of stocks they are tracking, and date in which the user data was last updated. We assume the remote API will require a unique identifier for the user.
struct User: Codable, Identifiable {
    var name: String
    var stocks: [Stock] = [Stock]()
    var lastUpdate: Date?
    var id: UUID = UUID()
    
    init() {
        name = "TestUser"
    }
    
    // MARK: - Local Storage
    
    /// Decode the user from JSON
    init(json: Data) throws {
        self = try JSONDecoder().decode(User.self, from: json)
    }
    
    /// Encode the user as JSON for saving to local storage
    func json() throws -> Data {
        let encoded = try JSONEncoder().encode(self)
        return encoded
    }
}
