import Foundation

/**
 A protocol defining the interface for handling shake gestures.
 */
protocol IShakeGestureHandler: AnyObject {
    /// Handles a detected shake gesture.
    func handleShakeGesture()
}
