import Foundation
import WatchConnectivity
import Combine

class WatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchSessionManager()
    
    @Published var summary: WatchTodaySummary?
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        // Load initial offline cached summary if available
        self.summary = WatchSummaryStore.load()
    }
    
    func activate() {
        // Trigger singleton initialization
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        #if DEBUG
        print("watchOS WCSession activated. State: \(activationState.rawValue)")
        #endif
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        guard let data = applicationContext["summaryData"] as? Data else { return }
        
        do {
            let decoded = try JSONDecoder().decode(WatchTodaySummary.self, from: data)
            DispatchQueue.main.async {
                self.summary = decoded
                WatchSummaryStore.save(decoded)
                
                // Trigger watch haptic/notification logic if attendanceAlert changed
                NotificationCenter.default.post(name: .didReceiveWatchSummaryUpdate, object: decoded)
            }
        } catch {
            #if DEBUG
            print("watchOS failed to decode summary: \(error.localizedDescription)")
            #endif
        }
    }
}

extension Notification.Name {
    static let didReceiveWatchSummaryUpdate = Notification.Name("didReceiveWatchSummaryUpdate")
}
