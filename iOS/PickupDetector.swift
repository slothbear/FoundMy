import CoreMotion

/// Notices when the phone is picked up, so the chirp can stop by itself.
final class PickupDetector {
    private let motion = CMMotionManager()

    /// Movement, in g, that counts as being picked up.
    private let threshold = 0.25

    func start(onPickup: @escaping () -> Void) {
        guard motion.isDeviceMotionAvailable, !motion.isDeviceMotionActive else { return }
        // Ignore the first moment so the phone settling doesn't count.
        let armedAt = Date().addingTimeInterval(1.5)
        motion.deviceMotionUpdateInterval = 0.1
        motion.startDeviceMotionUpdates(to: .main) { [threshold] data, _ in
            guard let a = data?.userAcceleration, Date() > armedAt else { return }
            if (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot() > threshold {
                onPickup()
            }
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
    }
}
