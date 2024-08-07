//
//  ContentView.swift
//  StockExercise
//
//  Created by Eliott Radcliffe on 8/7/24.
//

/**
 # Mock Stock Tracker
 A potential client has an investment app, which provides education and has a goal of making stock trading more enjoyable. As a coding exercise, they have asked to provide a solution to a remote API that is unreliable and occasionally returns errors or takes a long time t respond. 
 
 The code below contains and example application implementing three aspects that are important to this situation:
   1. The API requests are asynchronous to not block the user interface,
   2. A local cache is retained so the app is functional if the API is unresponsive,
   3. State is communicated to the user, such as the update is in progress, if an error is returned, and the time of the most recent update.
 
 The example code works well in this situation by leveraging convenient and efficient features of the Swift programming language and SwiftUI. Key aspects include:
   - Defining a protocol for the API, so that multiple implementations can be provided if a single source is unreliable, and it can be easily mocked (in this case with a random stock generator),
   - Using model-view-viewmodel architecture, with the `@ObservableObject` and `@Published` modifiers used to make SwiftUI responsive to changes in the API or data models,
   - Using `Codable` objects to encode and decode data from local storage, on opening the app, and when updates are received from the API,
   - Using `.refreshable` modifier on the `List` of stocks to provide a familiar "swipe-to-refresh" user experience.
 
 The API backend should be designed to be compatible with users who are accessing the data from multiple platforms (iOS and Android). Some basic requirements to aid in this compatibility include:
   - API should provide an equivalent to the `getStocks(for: user)` method, where any user will be provided with a unique user ID,
   - When an API user is created, the user ID should be provided by the API, not generated on the device, to ensure uniqueness and security,
   - The API responses should be encodable/decodable for the same data types as defined here, such as `User`, `Stock`, and `Price`.
 
 Possible improvements that would be included in a production app include:
   - Periodic background refreshes, even if the user did not initiate by a swipe gesture, or, refreshes initiated by the API itself
   - Messages that update chronologically after long wait times, with associated user interface (e.g., "You have waited for 10 seconds, keep trying or cancel?)
   - Improved visualization, such as plotting the stock price history over varying intervals
 */

import SwiftUI

// MARK: - API

/// The status of the API can be idle, if it has not been called, waiting if it has been called and still waiting for a response, success or failure
enum StockApiStatus {
    case idle
    case waiting(since: Date)
    case success(wait: Double, stocks: [String])
    case failure(error: String)
}

/// A protocol for the `StockApi` is that it has a status message, and a method to get a list of stocks
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

// MARK: - Model

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

// MARK: - ViewModel

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

// MARK: - View

struct StockTrackerView: View {
    @ObservedObject var tracker: StockTracker
    
    var body: some View {
        VStack {
            header
            Divider()
            status
            stocks
            Spacer()
        }
        .padding()
    }
    
    // MARK: -
    
    /// The app name and date of last update
    var header: some View {
        VStack(alignment: .leading)  {
            Text("Mock Stock Tracker")
                .font(.title)
            Text("Last Updated: \(tracker.lastUpdate)")
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - API Status
    
    /// An icon and text dsplaying the status of the API call
    @ViewBuilder
    var status: some View {
        switch tracker.apiStatus {
        case .idle: status(text: "Swipe to refresh", icon: "arrow.down.circle")
        case .waiting(let since): status(text: "Waiting since \(tracker.shortDateString(since))", icon: "clock")
        case .success(let wait, _): status(text: "Refreshed stocks after \(String(format: "%.1f", wait)) seconds", icon: "checkmark.circle")
        case .failure(let error): status(text: "Error: \(error)", icon: "exclamationmark.triangle").foregroundColor(.red)
        }
    }
    
    /// Called withing the status view above, takes strings for the text and the icon
    private func status(text: String, icon: String) -> some View {
        VStack {
            Image(systemName: icon)
                .font(.title)
            Text(text)
                .font(.caption)
        }
    }
    
    // MARK: - List of Stocks
    
    /// A list of stocks with their symbol and dollar value
    @ViewBuilder
    private var stocks: some View {
        List(tracker.stocks) { stock in
            HStack {
                Text(stock.symbol)
                Spacer()
                Text("$")
                Text(stock.history.last?.dollars ?? 0.0, format: .number.rounded(increment: 0.01))
            }
        }
        .refreshable {
            await tracker.refresh()
        }
    }
}

#Preview {
    StockTrackerView(tracker: StockTracker())
}
