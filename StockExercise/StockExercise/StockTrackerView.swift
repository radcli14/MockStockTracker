//
//  StockTrackerView.swift
//  StockExercise
//
//  Created by Eliott Radcliffe on 8/7/24.
//

import SwiftUI

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
