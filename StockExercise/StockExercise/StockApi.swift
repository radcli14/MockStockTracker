//
//  StockApi.swift
//  StockExercise
//
//  Created by Eliott Radcliffe on 8/7/24.
//

import Foundation


/// The status of the API can be idle, if it has not been called, waiting if it has been called and still waiting for a response, success or failure
enum StockApiStatus {
    case idle
    case waiting(since: Date)
    case success(wait: Double, stocks: [String])
    case failure(error: String)
}

/// The protocol for the `StockApi` is that it has a status message, and a method to get a list of stocks
protocol StockApi {
    var status: StockApiStatus { get set }
    mutating func getStocks(for user: User) async -> [Stock]?
}

/// A mock implementation of the `StockApi` protocol, where the `getStocks` method call with either randomly fail, or succeed after a random time delay, in which case it returns a list of random stocks.
struct MockStockApi: StockApi {
    var status: StockApiStatus = .idle
    
    @MainActor
    mutating func getStocks(for user: User) async -> [Stock]? {
        // Random error, one out of three API calls
        if Int.random(in: 1...3) == 3 {
            status = .failure(error:"Failed to get stocks")
            return nil
        }
        
        // Good result, but after a delay
        let start: Date = .now
        let delay = Double(Float.random(in: 0.0...10.0))
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        let stocks: [Stock] = randomStocks
        
        // Update the status to indicate success
        status = .success(
            wait: Date.now.timeIntervalSince(start),
            stocks: stocks.map { stock in stock.symbol }
        )
        return stocks
    }
    
    /// Provides a random number of stocks with random symbol and price
    private var randomStocks: [Stock] {
        let nStocks = Int.random(in: 1...10)
        let stocks: [Stock] = (1...nStocks).map { _ in
            generateRandomStock()
        }
        return stocks
    }
    
    private func generateRandomStock() -> Stock {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let randomLength = Int.random(in: 1...4)
        let randomSymbol = (1...randomLength).map { _ in
            String(letters.randomElement() ?? "A")
        }.joined()
        let history = [Price(time: .now, dollars: Double.random(in: 1...500))]
        return Stock(symbol: String(randomSymbol), history: history)
    }
}
