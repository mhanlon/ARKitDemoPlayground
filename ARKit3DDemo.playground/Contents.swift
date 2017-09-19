//: A SceneKit and ARKit based Playground

import PlaygroundSupport
import SceneKit
import ARKit
// MARK: - Scene extensions

extension SCNScene {
    func enableEnvironmentMapWithIntensity(_ intensity: CGFloat, queue: DispatchQueue) {
        queue.async {
            if self.lightingEnvironment.contents == nil {
                if let environmentMap = UIImage(named: "Models.scnassets/sharedImages/environment_blur.exr") {
                    self.lightingEnvironment.contents = environmentMap
                }
            }
            self.lightingEnvironment.intensity = intensity
        }
    }
}

class FocusSquare: SCNNode {
    
    // MARK: - Focus Square Configuration Properties
    
    // Original size of the focus square in m.
    private let focusSquareSize: Float = 0.17
    
    // Thickness of the focus square lines in m.
    private let focusSquareThickness: Float = 0.018
    
    // Scale factor for the focus square when it is closed, w.r.t. the original size.
    private let scaleForClosedSquare: Float = 0.97
    
    // Side length of the focus square segments when it is open (w.r.t. to a 1x1 square).
    private let sideLengthForOpenSquareSegments: CGFloat = 0.2
    
    // Duration of the open/close animation
    private let animationDuration = 0.7
    
    // Color of the focus square
    static let primaryColor = #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1) // base yellow
    static let primaryColorLight = #colorLiteral(red: 1, green: 0.9254901961, blue: 0.4117647059, alpha: 1) // light yellow
    
    // For scale adapdation based on the camera distance, see the `scaleBasedOnDistance(camera:)` method.
    
    // MARK: - Position Properties
    
    var lastPositionOnPlane: float3?
    var lastPosition: float3?
    
    // MARK: - Other Properties
    
    private var isOpen = false
    private var isAnimating = false
    
    // use average of recent positions to avoid jitter
    private var recentFocusSquarePositions: [float3] = []
    private var anchorsOfVisitedPlanes: Set<ARAnchor> = []
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        self.opacity = 0.0
        self.addChildNode(focusSquareNode)
        open()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Appearence
    
    func update(for position: float3, planeAnchor: ARPlaneAnchor?, camera: ARCamera?) {
        lastPosition = position
        if let anchor = planeAnchor {
            close(flash: !anchorsOfVisitedPlanes.contains(anchor))
            lastPositionOnPlane = position
            anchorsOfVisitedPlanes.insert(anchor)
        } else {
            open()
        }
        updateTransform(for: position, camera: camera)
    }
    
    func hide() {
        if self.opacity == 1.0 {
            self.renderOnTop(false)
            self.runAction(.fadeOut(duration: 0.5))
        }
    }
    
    func unhide() {
        if self.opacity == 0.0 {
            self.renderOnTop(true)
            self.runAction(.fadeIn(duration: 0.5))
        }
    }
    
    // MARK: - Private
    
    private func updateTransform(for position: float3, camera: ARCamera?) {
        // add to list of recent positions
        recentFocusSquarePositions.append(position)
        
        // remove anything older than the last 8
        recentFocusSquarePositions.keepLast(8)
        
        // move to average of recent positions to avoid jitter
        if let average = recentFocusSquarePositions.average {
            self.simdPosition = average
            self.setUniformScale(scaleBasedOnDistance(camera: camera))
        }
        
        // Correct y rotation of camera square
        if let camera = camera {
            let tilt = abs(camera.eulerAngles.x)
            let threshold1: Float = .pi / 2 * 0.65
            let threshold2: Float = .pi / 2 * 0.75
            let yaw = atan2f(camera.transform.columns.0.x, camera.transform.columns.1.x)
            var angle: Float = 0
            
            switch tilt {
            case 0..<threshold1:
                angle = camera.eulerAngles.y
            case threshold1..<threshold2:
                let relativeInRange = abs((tilt - threshold1) / (threshold2 - threshold1))
                let normalizedY = normalize(camera.eulerAngles.y, forMinimalRotationTo: yaw)
                angle = normalizedY * (1 - relativeInRange) + yaw * relativeInRange
            default:
                angle = yaw
            }
            self.rotation = SCNVector4(0, 1, 0, angle)
        }
    }
    
    private func normalize(_ angle: Float, forMinimalRotationTo ref: Float) -> Float {
        // Normalize angle in steps of 90 degrees such that the rotation to the other angle is minimal
        var normalized = angle
        while abs(normalized - ref) > .pi / 4 {
            if angle > ref {
                normalized -= .pi / 2
            } else {
                normalized += .pi / 2
            }
        }
        return normalized
    }
    
    /// Reduce visual size change with distance by scaling up when close and down when far away.
    ///
    /// These adjustments result in a scale of 1.0x for a distance of 0.7 m or less
    /// (estimated distance when looking at a table), and a scale of 1.2x
    /// for a distance 1.5 m distance (estimated distance when looking at the floor).
    private func scaleBasedOnDistance(camera: ARCamera?) -> Float {
        guard let camera = camera else { return 1.0 }
        
        let distanceFromCamera = simd_length(self.simdWorldPosition - camera.transform.translation)
        if distanceFromCamera < 0.7 {
            return distanceFromCamera / 0.7
        } else {
            return 0.25 * distanceFromCamera + 0.825
        }
    }
    
    private func pulseAction() -> SCNAction {
        let pulseOutAction = SCNAction.fadeOpacity(to: 0.4, duration: 0.5)
        let pulseInAction = SCNAction.fadeOpacity(to: 1.0, duration: 0.5)
        pulseOutAction.timingMode = .easeInEaseOut
        pulseInAction.timingMode = .easeInEaseOut
        
        return SCNAction.repeatForever(SCNAction.sequence([pulseOutAction, pulseInAction]))
    }
    
    private func stopPulsing(for node: SCNNode?) {
        node?.removeAction(forKey: "pulse")
        node?.opacity = 1.0
    }
    
    private func open() {
        if isOpen || isAnimating {
            return
        }
        
        // Open animation
        SCNTransaction.begin()
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        SCNTransaction.animationDuration = animationDuration / 4
        focusSquareNode.opacity = 1.0
        for segment in self.segments {
            segment.open()
        }
//        self.segments.forEach { segment in segment.open() }
        SCNTransaction.completionBlock = { self.focusSquareNode.runAction(self.pulseAction(), forKey: "pulse") }
        SCNTransaction.commit()
        
        // Scale/bounce animation
        SCNTransaction.begin()
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        SCNTransaction.animationDuration = animationDuration / 4
        focusSquareNode.setUniformScale(focusSquareSize)
        SCNTransaction.commit()
        
        isOpen = true
    }
    
    private func close(flash: Bool = false) {
        if !isOpen || isAnimating {
            return
        }
        
        isAnimating = true
        
        stopPulsing(for: focusSquareNode)
        
        // Close animation
        SCNTransaction.begin()
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        SCNTransaction.animationDuration = self.animationDuration / 2
        focusSquareNode.opacity = 0.99
        SCNTransaction.completionBlock = {
            SCNTransaction.begin()
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            SCNTransaction.animationDuration = self.animationDuration / 4
            self.segments.forEach { segment in segment.close() }
            SCNTransaction.completionBlock = { self.isAnimating = false }
            SCNTransaction.commit()
        }
        SCNTransaction.commit()
        
        // Scale/bounce animation
        focusSquareNode.addAnimation(scaleAnimation(for: "transform.scale.x"), forKey: "transform.scale.x")
        focusSquareNode.addAnimation(scaleAnimation(for: "transform.scale.y"), forKey: "transform.scale.y")
        focusSquareNode.addAnimation(scaleAnimation(for: "transform.scale.z"), forKey: "transform.scale.z")
        
        // Flash
        if flash {
            let waitAction = SCNAction.wait(duration: animationDuration * 0.75)
            let fadeInAction = SCNAction.fadeOpacity(to: 0.25, duration: animationDuration * 0.125)
            let fadeOutAction = SCNAction.fadeOpacity(to: 0.0, duration: animationDuration * 0.125)
            fillPlane.runAction(SCNAction.sequence([waitAction, fadeInAction, fadeOutAction]))
            
            let flashSquareAction = flashAnimation(duration: animationDuration * 0.25)
            segments.forEach { segment in
                segment.runAction(SCNAction.sequence([waitAction, flashSquareAction]))
            }
        }
        
        isOpen = false
    }
    
    private func flashAnimation(duration: TimeInterval) -> SCNAction {
        let action = SCNAction.customAction(duration: duration) { (node, elapsedTime) -> Void in
            // animate color from HSB 48/100/100 to 48/30/100 and back
            let elapsedTimePercentage = elapsedTime / CGFloat(duration)
            let saturation = 2.8 * (elapsedTimePercentage - 0.5) * (elapsedTimePercentage - 0.5) + 0.3
            if let material = node.geometry?.firstMaterial {
                material.diffuse.contents = UIColor(hue: 0.1333, saturation: saturation, brightness: 1.0, alpha: 1.0)
            }
        }
        return action
    }
    
    private func scaleAnimation(for keyPath: String) -> CAKeyframeAnimation {
        let scaleAnimation = CAKeyframeAnimation(keyPath: keyPath)
        
        let easeOut = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        let easeInOut = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        let linear = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        
        let fs = focusSquareSize
        let ts = focusSquareSize * scaleForClosedSquare
        let values = [fs, fs * 1.15, fs * 1.15, ts * 0.97, ts]
        let keyTimes: [NSNumber] = [0.00, 0.25, 0.50, 0.75, 1.00]
        let timingFunctions = [easeOut, linear, easeOut, easeInOut]
        
        scaleAnimation.values = values
        scaleAnimation.keyTimes = keyTimes
        scaleAnimation.timingFunctions = timingFunctions
        scaleAnimation.duration = animationDuration
        
        return scaleAnimation
    }
    
    private var segments: [FocusSquare.Segment] = []
    
    private lazy var fillPlane: SCNNode = {
        let c = focusSquareThickness / 2 // correction to align lines perfectly
        let plane = SCNPlane(width: CGFloat(1.0 - focusSquareThickness * 2 + c),
                             height: CGFloat(1.0 - focusSquareThickness * 2 + c))
        let node = SCNNode(geometry: plane)
        node.name = "fillPlane"
        node.opacity = 0.0
        
        let material = plane.firstMaterial
        material?.diffuse.contents = FocusSquare.primaryColorLight
        material?.isDoubleSided = true
        material?.ambient.contents = UIColor.black
        material?.lightingModel = .constant
        material?.emission.contents = FocusSquare.primaryColorLight
        
        return node
    }()
    
    private lazy var focusSquareNode: SCNNode = {
        /*
         The focus square consists of eight segments as follows, which can be individually animated.
         
         s1  s2
         _   _
         s3 |     | s4
         
         s5 |     | s6
         -   -
         s7  s8
         */
        let s1 = Segment(name: "s1", corner: .topLeft, alignment: .horizontal)
        let s2 = Segment(name: "s2", corner: .topRight, alignment: .horizontal)
        let s3 = Segment(name: "s3", corner: .topLeft, alignment: .vertical)
        let s4 = Segment(name: "s4", corner: .topRight, alignment: .vertical)
        let s5 = Segment(name: "s5", corner: .bottomLeft, alignment: .vertical)
        let s6 = Segment(name: "s6", corner: .bottomRight, alignment: .vertical)
        let s7 = Segment(name: "s7", corner: .bottomLeft, alignment: .horizontal)
        let s8 = Segment(name: "s8", corner: .bottomRight, alignment: .horizontal)
        
        let sl: Float = 0.5  // segment length
        let c: Float = focusSquareThickness / 2 // correction to align lines perfectly
        s1.simdPosition += float3(-(sl / 2 - c), -(sl - c), 0)
        s2.simdPosition += float3(sl / 2 - c, -(sl - c), 0)
        s3.simdPosition += float3(-sl, -sl / 2, 0)
        s4.simdPosition += float3(sl, -sl / 2, 0)
        s5.simdPosition += float3(-sl, sl / 2, 0)
        s6.simdPosition += float3(sl, sl / 2, 0)
        s7.simdPosition += float3(-(sl / 2 - c), sl - c, 0)
        s8.simdPosition += float3(sl / 2 - c, sl - c, 0)
        
        let planeNode = SCNNode()
        planeNode.eulerAngles.x = .pi / 2 // Horizontal
        planeNode.setUniformScale(focusSquareSize * scaleForClosedSquare)
        planeNode.addChildNode(s1)
        planeNode.addChildNode(s2)
        planeNode.addChildNode(s3)
        planeNode.addChildNode(s4)
        planeNode.addChildNode(s5)
        planeNode.addChildNode(s6)
        planeNode.addChildNode(s7)
        planeNode.addChildNode(s8)
        planeNode.addChildNode(fillPlane)
        segments = [s1, s2, s3, s4, s5, s6, s7, s8]
        isOpen = false
        
        // Always render focus square on top
        planeNode.renderOnTop(true)
        
        return planeNode
    }()
}


extension FocusSquare {
    
    /*
     The focus square consists of eight segments as follows, which can be individually animated.
     
     s1  s2
     _   _
     s3 |     | s4
     
     s5 |     | s6
     -   -
     s7  s8
     */
    enum Corner {
        case topLeft // s1, s3
        case topRight // s2, s4
        case bottomRight // s6, s8
        case bottomLeft // s5, s7
    }
    enum Alignment {
        case horizontal // s1, s2, s7, s8
        case vertical // s3, s4, s5, s6
    }
    enum Direction {
        case up, down, left, right
        
        var reversed: Direction {
            switch self {
            case .up:   return .down
            case .down: return .up
            case .left:  return .right
            case .right: return .left
            }
        }
    }
    
    class Segment: SCNNode {
        
        // MARK: - Configuration & Initialization
        
        /// Thickness of the focus square lines in m.
        static let thickness: Float = 0.018
        
        /// Length of the focus square lines in m.
        static let length: Float = 0.5  // segment length
        
        /// Side length of the focus square segments when it is open (w.r.t. to a 1x1 square).
        static let openLength: Float = 0.2
        
        let corner: Corner
        let alignment: Alignment
        
        init(name: String, corner: Corner, alignment: Alignment) {
            self.corner = corner
            self.alignment = alignment
            super.init()
            self.name = name
            
            switch alignment {
            case .vertical:
                geometry = SCNPlane(width: CGFloat(FocusSquare.Segment.thickness),
                                    height: CGFloat(FocusSquare.Segment.length))
            case .horizontal:
                geometry = SCNPlane(width: CGFloat(FocusSquare.Segment.length),
                                    height: CGFloat(FocusSquare.Segment.thickness))
            }
            
            let material = geometry?.firstMaterial
            material?.diffuse.contents = FocusSquare.primaryColor
            material?.isDoubleSided = true
            material?.ambient.contents = UIColor.black
//            material.lightingModel = .constant
            material?.emission.contents = FocusSquare.primaryColor
        }
        
        required override init() {
            self.corner = .topRight
            self.alignment = .horizontal
            super.init()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Animating Open/Closed
        
        var openDirection: Direction {
            switch (corner, alignment) {
            case (.topLeft,     .horizontal):   return .left
            case (.topLeft,     .vertical):     return .up
            case (.topRight,    .horizontal):   return .right
            case (.topRight,    .vertical):     return .up
            case (.bottomLeft,  .horizontal):   return .left
            case (.bottomLeft,  .vertical):     return .down
            case (.bottomRight, .horizontal):   return .right
            case (.bottomRight, .vertical):     return .down
            }
        }
        
        func open() {
            guard let plane = self.geometry as? SCNPlane else { return }
            let direction = openDirection
            
            if alignment == .horizontal {
                plane.width = CGFloat(FocusSquare.Segment.openLength)
            } else {
                plane.height = CGFloat(FocusSquare.Segment.openLength)
            }
            
            let offset = FocusSquare.Segment.length / 2 - FocusSquare.Segment.openLength / 2
            switch direction {
            case .left:     self.position.x -= offset
            case .right:    self.position.x += offset
            case .up:       self.position.y -= offset
            case .down:     self.position.y += offset
            }
        }
        
        func close() {
            guard let plane = self.geometry as? SCNPlane else { return }
            let direction = openDirection.reversed
            
            let oldLength: Float
            if alignment == .horizontal {
                oldLength = Float(plane.width)
                plane.width = CGFloat(FocusSquare.Segment.length)
            } else {
                oldLength = Float(plane.height)
                plane.height = CGFloat(FocusSquare.Segment.length)
            }
            
            let offset = FocusSquare.Segment.length / 2 - oldLength / 2
            switch direction {
            case .left:     self.position.x -= offset
            case .right:    self.position.x += offset
            case .up:       self.position.y -= offset
            case .down:     self.position.y += offset
            }
        }
        
    }
}

extension ARSCNView {
    
    // MARK: - Types
    
    struct HitTestRay {
        let origin: float3
        let direction: float3
    }
    
    struct FeatureHitTestResult {
        let position: float3
        let distanceToRayOrigin: Float
        let featureHit: float3
        let featureDistanceToHitResult: Float
    }
    
    func unprojectPoint(_ point: float3) -> float3 {
        return float3(self.unprojectPoint(SCNVector3(point)))
    }
    
    // MARK: - Hit Tests
    
    func hitTestRayFromScreenPos(_ point: CGPoint) -> HitTestRay? {
        
        guard let frame = self.session.currentFrame else {
            return nil
        }
        
        let cameraPos = frame.camera.transform.translation
        
        // Note: z: 1.0 will unproject() the screen position to the far clipping plane.
        let positionVec = float3(x: Float(point.x), y: Float(point.y), z: 1.0)
        let screenPosOnFarClippingPlane = self.unprojectPoint(positionVec)
        
        let rayDirection = simd_normalize(screenPosOnFarClippingPlane - cameraPos)
        return HitTestRay(origin: cameraPos, direction: rayDirection)
    }
    
    func hitTestWithInfiniteHorizontalPlane(_ point: CGPoint, _ pointOnPlane: float3) -> float3? {
        
        guard let ray = hitTestRayFromScreenPos(point) else {
            return nil
        }
        
        // Do not intersect with planes above the camera or if the ray is almost parallel to the plane.
        if ray.direction.y > -0.03 {
            return nil
        }
        
        // Return the intersection of a ray from the camera through the screen position with a horizontal plane
        // at height (Y axis).
        return rayIntersectionWithHorizontalPlane(rayOrigin: ray.origin, direction: ray.direction, planeY: pointOnPlane.y)
    }
    
    func hitTestWithFeatures(_ point: CGPoint, coneOpeningAngleInDegrees: Float,
                             minDistance: Float = 0,
                             maxDistance: Float = Float.greatestFiniteMagnitude,
                             maxResults: Int = 1) -> [FeatureHitTestResult] {
        
        var results = [FeatureHitTestResult]()
        
        guard let features = self.session.currentFrame?.rawFeaturePoints else {
            return results
        }
        
        guard let ray = hitTestRayFromScreenPos(point) else {
            return results
        }
        
        let maxAngleInDeg = min(coneOpeningAngleInDegrees, 360) / 2
        let maxAngle = (maxAngleInDeg / 180) * .pi
        
        let points = features.__points
        
        for i in 0...features.__count {
            
            let feature = points.advanced(by: Int(i))
            let featurePos = feature.pointee
            
            let originToFeature = featurePos - ray.origin
            
            let crossProduct = simd_cross(originToFeature, ray.direction)
            let featureDistanceFromResult = simd_length(crossProduct)
            
            let hitTestResult = ray.origin + (ray.direction * simd_dot(ray.direction, originToFeature))
            let hitTestResultDistance = simd_length(hitTestResult - ray.origin)
            
            if hitTestResultDistance < minDistance || hitTestResultDistance > maxDistance {
                // Skip this feature - it is too close or too far away.
                continue
            }
            
            let originToFeatureNormalized = simd_normalize(originToFeature)
            let angleBetweenRayAndFeature = acos(simd_dot(ray.direction, originToFeatureNormalized))
            
            if angleBetweenRayAndFeature > maxAngle {
                // Skip this feature - is is outside of the hit test cone.
                continue
            }
            
            // All tests passed: Add the hit against this feature to the results.
            results.append(FeatureHitTestResult(position: hitTestResult,
                                                distanceToRayOrigin: hitTestResultDistance,
                                                featureHit: featurePos,
                                                featureDistanceToHitResult: featureDistanceFromResult))
        }
        
        // Sort the results by feature distance to the ray.
        results = results.sorted(by: { (first, second) -> Bool in
            return first.distanceToRayOrigin < second.distanceToRayOrigin
        })
        
        // Cap the list to maxResults.
        var cappedResults = [FeatureHitTestResult]()
        var i = 0
        while i < maxResults && i < results.count {
            cappedResults.append(results[i])
            i += 1
        }
        
        return cappedResults
    }
    
    func hitTestWithFeatures(_ point: CGPoint) -> [FeatureHitTestResult] {
        
        var results = [FeatureHitTestResult]()
        
        guard let ray = hitTestRayFromScreenPos(point) else {
            return results
        }
        
        if let result = self.hitTestFromOrigin(origin: ray.origin, direction: ray.direction) {
            results.append(result)
        }
        
        return results
    }
    
    func hitTestFromOrigin(origin: float3, direction: float3) -> FeatureHitTestResult? {
        
        guard let features = self.session.currentFrame?.rawFeaturePoints else {
            return nil
        }
        
        let points = features.__points
        
        // Determine the point from the whole point cloud which is closest to the hit test ray.
        var closestFeaturePoint = origin
        var minDistance = Float.greatestFiniteMagnitude
        
        for i in 0...features.__count {
            let feature = points.advanced(by: Int(i))
            let featurePos = feature.pointee
            
            let originVector = origin - featurePos
            let crossProduct = simd_cross(originVector, direction)
            let featureDistanceFromResult = simd_length(crossProduct)
            
            if featureDistanceFromResult < minDistance {
                closestFeaturePoint = featurePos
                minDistance = featureDistanceFromResult
            }
        }
        
        // Compute the point along the ray that is closest to the selected feature.
        let originToFeature = closestFeaturePoint - origin
        let hitTestResult = origin + (direction * simd_dot(direction, originToFeature))
        let hitTestResultDistance = simd_length(hitTestResult - origin)
        
        return FeatureHitTestResult(position: hitTestResult,
                                    distanceToRayOrigin: hitTestResultDistance,
                                    featureHit: closestFeaturePoint,
                                    featureDistanceToHitResult: minDistance)
    }
    
}

// MARK: - Collection extensions
extension Array where Iterator.Element == Float {
    var average: Float? {
        guard !self.isEmpty else {
            return nil
        }
        
        let sum = self.reduce(Float(0)) { current, next in
            return current + next
        }
        return sum / Float(self.count)
    }
}

extension Array where Iterator.Element == float3 {
    var average: float3? {
        guard !self.isEmpty else {
            return nil
        }
        
        let sum = self.reduce(float3(0)) { current, next in
            return current + next
        }
        return sum / Float(self.count)
    }
}

extension RangeReplaceableCollection where IndexDistance == Int {
    mutating func keepLast(_ elementsToKeep: Int) {
        if count > elementsToKeep {
            self.removeFirst(count - elementsToKeep)
        }
    }
}

// MARK: - SCNNode extension

extension SCNNode {
    
    func setUniformScale(_ scale: Float) {
        self.simdScale = float3(scale, scale, scale)
    }
    
    func renderOnTop(_ enable: Bool) {
        self.renderingOrder = enable ? 2 : 0
        if let geom = self.geometry {
            for material in geom.materials {
                material.readsFromDepthBuffer = enable ? false : true
            }
        }
        for child in self.childNodes {
            child.renderOnTop(enable)
        }
    }
}

// MARK: - float4x4 extensions

extension float4x4 {
    /// Treats matrix as a (right-hand column-major convention) transform matrix
    /// and factors out the translation component of the transform.
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

// MARK: - CGPoint extensions

extension CGPoint {
    
    init(_ size: CGSize) {
        self.x = size.width
        self.y = size.height
    }
    
    init(_ vector: SCNVector3) {
        self.x = CGFloat(vector.x)
        self.y = CGFloat(vector.y)
    }
    
    func distanceTo(_ point: CGPoint) -> CGFloat {
        return (self - point).length()
    }
    
    func length() -> CGFloat {
        return sqrt(self.x * self.x + self.y * self.y)
    }
    
    func midpoint(_ point: CGPoint) -> CGPoint {
        return (self + point) / 2
    }
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
    
    static func - (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }
    
    static func += (left: inout CGPoint, right: CGPoint) {
        left = left + right
    }
    
    static func -= (left: inout CGPoint, right: CGPoint) {
        left = left - right
    }
    
    static func / (left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: left.x / right, y: left.y / right)
    }
    
    static func * (left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: left.x * right, y: left.y * right)
    }
    
    static func /= (left: inout CGPoint, right: CGFloat) {
        left = left / right
    }
    
    static func *= (left: inout CGPoint, right: CGFloat) {
        left = left * right
    }
}

// MARK: - CGSize extensions

extension CGSize {
    init(_ point: CGPoint) {
        self.width = point.x
        self.height = point.y
    }
    
    static func + (left: CGSize, right: CGSize) -> CGSize {
        return CGSize(width: left.width + right.width, height: left.height + right.height)
    }
    
    static func - (left: CGSize, right: CGSize) -> CGSize {
        return CGSize(width: left.width - right.width, height: left.height - right.height)
    }
    
    static func += (left: inout CGSize, right: CGSize) {
        left = left + right
    }
    
    static func -= (left: inout CGSize, right: CGSize) {
        left = left - right
    }
    
    static func / (left: CGSize, right: CGFloat) -> CGSize {
        return CGSize(width: left.width / right, height: left.height / right)
    }
    
    static func * (left: CGSize, right: CGFloat) -> CGSize {
        return CGSize(width: left.width * right, height: left.height * right)
    }
    
    static func /= (left: inout CGSize, right: CGFloat) {
        left = left / right
    }
    
    static func *= (left: inout CGSize, right: CGFloat) {
        left = left * right
    }
}

// MARK: - CGRect extensions

extension CGRect {
    var mid: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

func rayIntersectionWithHorizontalPlane(rayOrigin: float3, direction: float3, planeY: Float) -> float3? {
    
    let direction = simd_normalize(direction)
    
    // Special case handling: Check if the ray is horizontal as well.
    if direction.y == 0 {
        if rayOrigin.y == planeY {
            // The ray is horizontal and on the plane, thus all points on the ray intersect with the plane.
            // Therefore we simply return the ray origin.
            return rayOrigin
        } else {
            // The ray is parallel to the plane and never intersects.
            return nil
        }
    }
    
    // The distance from the ray's origin to the intersection point on the plane is:
    //   (pointOnPlane - rayOrigin) dot planeNormal
    //  --------------------------------------------
    //          direction dot planeNormal
    
    // Since we know that horizontal planes have normal (0, 1, 0), we can simplify this to:
    let dist = (planeY - rayOrigin.y) / direction.y
    
    // Do not return intersections behind the ray's origin.
    if dist < 0 {
        return nil
    }
    
    // Return the intersection point.
    return rayOrigin + (direction * dist)
}

class QISceneKitViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    let serialQueue = DispatchQueue(label: "com.qisoftware.arkitdemo.serialSpriteKitQueue")
    var screenCenter: CGPoint? // For the Focus Square from the ARKitExample
    let session = ARSession()
    var sceneView: ARSCNView!

    override func loadView() {
        sceneView = ARSCNView(frame: CGRect(x: 0.0, y: 0.0, width: 500.0, height: 600.0))
        
        let scene = SCNScene()
//        let scene = SCNScene(named: "Scene")
        sceneView.scene = scene
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal

        // set up scene view
        sceneView.setup()
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session = session
        sceneView.showsStatistics = true

        sceneView.scene.enableEnvironmentMapWithIntensity(25, queue: serialQueue)
        
        // Now we'll get messages when planes were detected...
        sceneView.session.delegate = self

        // This will show our cool square overlaid the environment
        setupFocusSquare()
        
        DispatchQueue.main.async {
            self.screenCenter = self.sceneView.bounds.mid
        }

        self.view = sceneView
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
    
    
    // MARK: - Focus Square
    
    var focusSquare: FocusSquare?
    
    func setupFocusSquare() {
        serialQueue.async {
            self.focusSquare?.isHidden = true
            self.focusSquare?.removeFromParentNode()
            self.focusSquare = FocusSquare()
            self.sceneView.scene.rootNode.addChildNode(self.focusSquare!)
        }
    }
    
    func updateFocusSquare() {
        guard let screenCenter = screenCenter else { return }
        
        DispatchQueue.main.async {
//            var objectVisible = false
//            for object in self.virtualObjectManager.virtualObjects {
//                if self.sceneView.isNode(object, insideFrustumOf: self.sceneView.pointOfView!) {
//                    objectVisible = true
//                    break
//                }
//            }
            // TODO: Needed?
            self.focusSquare?.unhide()
            
            let (worldPos, planeAnchor, _) = self.worldPositionFromScreenPosition(screenCenter,
                                                                                                       in: self.sceneView,
                                                                                                       objectPos: self.focusSquare?.simdPosition)
            if let worldPos = worldPos {
                self.serialQueue.async {
                    self.focusSquare?.update(for: worldPos, planeAnchor: planeAnchor, camera: self.session.currentFrame?.camera)
                }
            }
        }
    }
    func worldPositionFromScreenPosition(_ position: CGPoint,
                                         in sceneView: ARSCNView,
                                         objectPos: float3?,
                                         infinitePlane: Bool = false) -> (position: float3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
        
        let dragOnInfinitePlanesEnabled = false
        // -------------------------------------------------------------------------------
        // 1. Always do a hit test against exisiting plane anchors first.
        //    (If any such anchors exist & only within their extents.)
        
        let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {
            
            let planeHitTestPosition = result.worldTransform.translation
            let planeAnchor = result.anchor
            
            // Return immediately - this is the best possible outcome.
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
        }
        
        // -------------------------------------------------------------------------------
        // 2. Collect more information about the environment by hit testing against
        //    the feature point cloud, but do not return the result yet.
        
        var featureHitTestPosition: float3?
        var highQualityFeatureHitTestResult = false
        
        let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)
        
        if !highQualityfeatureHitTestResults.isEmpty {
            let result = highQualityfeatureHitTestResults[0]
            featureHitTestPosition = result.position
            highQualityFeatureHitTestResult = true
        }
        
        // -------------------------------------------------------------------------------
        // 3. If desired or necessary (no good feature hit test result): Hit test
        //    against an infinite, horizontal plane (ignoring the real world).
        
        if (infinitePlane && dragOnInfinitePlanesEnabled) || !highQualityFeatureHitTestResult {
            
            if let pointOnPlane = objectPos {
                let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
                if pointOnInfinitePlane != nil {
                    return (pointOnInfinitePlane, nil, true)
                }
            }
        }
        
        // -------------------------------------------------------------------------------
        // 4. If available, return the result of the hit test against high quality
        //    features if the hit tests against infinite planes were skipped or no
        //    infinite plane was hit.
        
        if highQualityFeatureHitTestResult {
            return (featureHitTestPosition, nil, false)
        }
        
        // -------------------------------------------------------------------------------
        // 5. As a last resort, perform a second, unfiltered hit test against features.
        //    If there are no features in the scene, the result returned here will be nil.
        
        let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
        if !unfilteredFeatureHitTestResults.isEmpty {
            let result = unfilteredFeatureHitTestResults[0]
            return (result.position, nil, false)
        }
        
        return (nil, nil, false)
    }
}


extension ARSCNView {
    
    func setup() {
        antialiasingMode = .multisampling4X
        automaticallyUpdatesLighting = false
        
        preferredFramesPerSecond = 60
        contentScaleFactor = 1.3
        
        if let camera = pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
            camera.exposureOffset = -1
            camera.minimumExposure = -1
            camera.maximumExposure = 3
        }
    }
}


PlaygroundPage.current.liveView = QISceneKitViewController()
PlaygroundPage.current.needsIndefiniteExecution = true
