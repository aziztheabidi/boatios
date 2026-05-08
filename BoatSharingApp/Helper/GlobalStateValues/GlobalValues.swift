//
//  GlobalStateValues.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 16/04/2025.
//

import Foundation

enum GlobalValues {
    // NOTE:
    // This global is kept for backward compatibility with legacy call sites.
    // Prefer scoped state (e.g. UIFlowState) for new code to reduce hidden coupling.
    // Access is synchronized to avoid data races when touched across threads.
    private static let lock = NSLock()
    private static var _isFindingBoat: Bool = false

    static var isFindingBoat: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _isFindingBoat
        }
        set {
            lock.lock()
            _isFindingBoat = newValue
            lock.unlock()
        }
    }
}
