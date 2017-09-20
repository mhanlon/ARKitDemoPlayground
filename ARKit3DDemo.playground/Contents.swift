//: A SceneKit and ARKit based Playground

import PlaygroundSupport
import SceneKit
import ARKit

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

//        sceneView.scene.enableEnvironmentMapWithIntensity(25, queue: serialQueue)
        
        // Now we'll get messages when planes were detected...
        sceneView.session.delegate = self

        // default lighting
        sceneView.autoenablesDefaultLighting = true
        
        // a camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
        scene.rootNode.addChildNode(cameraNode)
        
        let pyramid = SCNPyramid(width: 0.1, height: 0.15, length: 0.1)
        let pyramidNode = SCNNode(geometry: pyramid)
        scene.rootNode.addChildNode(pyramidNode)
        pyramid.firstMaterial?.diffuse.contents = UIColor.blue
        pyramid.firstMaterial?.specular.contents = UIColor.white
        
        // animate the rotation of the torus
        let spin = CABasicAnimation(keyPath: "rotation.w") // only animate the angle
        spin.toValue = 2.0*Double.pi
        spin.duration = 3
        spin.repeatCount = HUGE // for infinity
        pyramid.addAnimation(spin, forKey: "spin around")
        
        self.view = sceneView
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
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
