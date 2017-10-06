//: A SceneKit and ARKit based Playground

import PlaygroundSupport
import SceneKit
import ARKit

class QISceneKitViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    let session = ARSession()
    var sceneView: ARSCNView!
    var hasPlacedMax = false
    var max: SCNNode?
    var characterNode: SCNNode?
    var characterOrientation: SCNNode?

    override func loadView() {
        sceneView = ARSCNView(frame: CGRect(x: 0.0, y: 0.0, width: 500.0, height: 600.0))
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal

        // set up scene view
        sceneView.setup()
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session = session
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,
                                  ARSCNDebugOptions.showWorldOrigin/*,
                                  .showBoundingBoxes,
                                  .showWireframe,
                                  .showSkeletons,
                                  .showPhysicsShapes,
                                  .showCameras*/
                                ]
        
        sceneView.showsStatistics = true
        
        // Now we'll get messages when planes were detected...
        sceneView.session.delegate = self

        // default lighting
        sceneView.autoenablesDefaultLighting = true
        
        // a camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
        scene.rootNode.addChildNode(cameraNode)
        
        max = maxNode()
        characterNode = SCNNode()
        characterNode!.name = "character"
        characterNode!.simdPosition = float3(0.1, -0.2, 0)
        
        characterOrientation = SCNNode()
        characterNode!.addChildNode(characterOrientation!)
        characterOrientation!.addChildNode(max!)

        self.loadAnimations(forNode:max!)
        
        self.view = sceneView
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // When we detect a new anchor for the session we'll add max at that anchor
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if ( !hasPlacedMax ) {
                max?.position = SCNVector3(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z)
                sceneView.scene.rootNode.addChildNode(max!)
                DispatchQueue.main.async {
                    self.hasPlacedMax = true
                }
                max?.animationPlayer(forKey: "idle")?.play()
            } else {
                let friend = maxNode()
                friend.position = SCNVector3(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z)
                guard let geometryNode = friend.childNode(withName: "Max", recursively: true) else { return }
                
                geometryNode.geometry!.firstMaterial?.diffuse.intensity = 0.5
                
                geometryNode.geometry?.firstMaterial?.diffuse.contents = randomMaxTexture()
                loadAnimations(forNode: friend)
                sceneView.scene.rootNode.addChildNode(friend)
                friend.animationPlayer(forKey: randomMaxAnimation())?.play()
            }
        }
    }
    // An exercise for the reader: make the characters respond to the orientation of the camera and turn accordingly.
//    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
//        DispatchQueue.main.async {
//            // Rotate Max to face the camera?
//            self.characterOrientation?.runAction(
//                SCNAction.rotateTo(x: 0.0, y: 3.0, z: 0.0, duration: 0.1, usesShortestUnitArc:true))
//        }
//    }
    
    func loadAnimation(fromSceneNamed sceneName: String) -> SCNAnimationPlayer {
        let scene = SCNScene( named: sceneName )!
        // find top level animation
        var animationPlayer: SCNAnimationPlayer! = nil
        scene.rootNode.enumerateChildNodes { (child, stop) in
            if !child.animationKeys.isEmpty {
                animationPlayer = child.animationPlayer(forKey: child.animationKeys[0])
                stop.pointee = true
            }
        }
        return animationPlayer
    }

    func loadAnimations(forNode node: SCNNode) {
        let idleAnimation = self.loadAnimation(fromSceneNamed: "Art.scnassets/character/max_idle.scn")
        node.addAnimationPlayer(idleAnimation, forKey: "idle")
        idleAnimation.play()
        
        let walkAnimation = self.loadAnimation(fromSceneNamed: "Art.scnassets/character/max_walk.scn")
        walkAnimation.speed = 1.0
        walkAnimation.stop()
        
        node.addAnimationPlayer(walkAnimation, forKey: "walk")
        
        let jumpAnimation = self.loadAnimation(fromSceneNamed: "Art.scnassets/character/max_jump.scn")
        jumpAnimation.animation.isRemovedOnCompletion = false
        jumpAnimation.stop()
        node.addAnimationPlayer(jumpAnimation, forKey: "jump")
        
        let spinAnimation = self.loadAnimation(fromSceneNamed: "Art.scnassets/character/max_spin.scn")
        spinAnimation.animation.isRemovedOnCompletion = false
        spinAnimation.speed = 1.5
        spinAnimation.stop()
        node.addAnimationPlayer(spinAnimation, forKey: "spin")
    }

    func maxNode() -> SCNNode {
        let maxScene = SCNScene(named: "Art.scnassets/character/max.scn")!
        let max = maxScene.rootNode.childNode(withName: "Max_rootNode", recursively: true)!
        return max
    }
    
    func randomMaxTexture() -> String {
        let randomNumber = arc4random_uniform(2)
        var texture = "Art.scnassets/character/max_diffuseB.png"
        switch randomNumber {
        case 0:
            texture = "Art.scnassets/character/max_diffuseC.png"
        case 1:
            texture = "Art.scnassets/character/max_diffuseD.png"
        default:
            texture = "Art.scnassets/character/max_diffuseB.png"
        }
        return texture
    }
    
    func randomMaxAnimation() -> String {
        let randomNumber = arc4random_uniform(3)
        var animation = "walk"
        switch randomNumber {
        case 0:
            animation = "spin"
        case 1:
            animation = "spin"
        case 1:
            animation = "jump"
        default:
            animation = "walk"
        }
        return animation
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
