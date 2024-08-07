# Mock Stock Tracker
 A potential client has an investment app, which provides education and has a goal of making stock trading more enjoyable. As a coding exercise, they have asked to provide a solution to a remote API that is unreliable and occasionally returns errors or takes a long time t respond. 
 
 The code here contains and example application implementing three aspects that are important to this situation:
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
