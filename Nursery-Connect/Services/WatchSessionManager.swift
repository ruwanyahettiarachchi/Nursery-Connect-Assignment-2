import Foundation
import WatchConnectivity
import OSLog

class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    
    private let logger = Logger(subsystem: "com.ruwanya.Nursery-Connect", category: "WatchSessionManager")
    private var session: WCSession = .default
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
            logger.info("WCSession activation initiated on iOS.")
        } else {
            logger.warning("WCSession is not supported on this iOS device.")
        }
    }
    
    func activate() {
        // Triggers the lazy initialization of the shared instance and session activation
        logger.info("WatchSessionManager shared instance activated.")
    }
    
    func sendSummary(_ summary: WatchTodaySummary) {
        guard WCSession.isSupported() else { return }
        
        do {
            let data = try JSONEncoder().encode(summary)
            let context = ["summaryData": data]
            
            if session.activationState == .activated {
                // 1. Send via Application Context for offline relaunch storage consistency
                try session.updateApplicationContext(context)
                logger.info("Successfully updated watch application context.")
                
                // 2. If watch is running in foreground, send via sendMessage for instant sync
                if session.isReachable {
                    session.sendMessage(context, replyHandler: nil) { error in
                        self.logger.warning("Live sendMessage failed: \(error.localizedDescription)")
                    }
                    logger.info("Sent real-time message to watch.")
                }
            } else {
                logger.warning("WCSession not activated yet. State: \(self.session.activationState.rawValue). Cannot send context.")
            }
        } catch {
            logger.error("Failed to encode or send summary to watch: \(error.localizedDescription)")
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            logger.error("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            logger.info("WCSession activation completed on iOS. State: \(activationState.rawValue)")
            if activationState == .activated {
                // If a summary was already saved during startup, send it now that the session is active
                if let saved = WatchSummaryStore.load() {
                    sendSummary(saved)
                }
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        logger.info("WCSession became inactive.")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        logger.info("WCSession deactivated. Reactivating...")
        // Reactivate session as required for iOS multi-device support
        self.session.activate()
    }
}
