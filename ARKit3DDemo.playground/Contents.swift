//: A SceneKit and ARKit based Playground

import PlaygroundSupport
import SceneKit
import ARKit

class QISceneKitViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    let session = ARSession()
    var sceneView: ARSCNView!
    var pear: SCNNode?

    override func loadView() {
        sceneView = ARSCNView(frame: CGRect(x: 0.0, y: 0.0, width: 500.0, height: 600.0))
        
        let scene = SCNScene()
        //let pearScene = SCNScene(named: "3DWickedPear.scn")!
        let pearScene = SCNScene(named: "WickedPear2.scn")!
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
        
        let pyramid = SCNPyramid(width: 0.1, height: 0.15, length: 0.1)
        let pyramidNode = SCNNode(geometry: pyramid)
        scene.rootNode.addChildNode(pyramidNode)
        pyramid.firstMaterial?.diffuse.contents = UIColor.blue
        pyramid.firstMaterial?.specular.contents = UIColor.white
        
        // Add our 3d pear...
        pear = pearScene.rootNode.childNode(withName: "pear", recursively: true)!
        
        pear?.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        pear?.geometry?.firstMaterial?.specular.contents = UIColor.green

        // Resize and rotate our pear from our *amazing* Blender rendering
        // of a pear
        pear?.scale = SCNVector3(0.15, 0.15, 0.05)
        pear?.rotation = SCNVector4(180, 180, 180, 0)
        scene.rootNode.addChildNode(pear!)
        
        // Now let's spin our pear around a little bit, spin it
        // right round baby, right round. Spin it right round.
        pear?.runAction(SCNAction.rotateBy(x: 5, y: 10, z: 90, duration: 30))
        
        self.view = sceneView
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // When we detect a new anchor for the session we'll add a pear to that anchor
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            var pearCopy = self.pear?.copy() as! SCNNode?
            pearCopy?.position = SCNVector3(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z)
            sceneView.scene.rootNode.addChildNode(pearCopy!)
        }
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
