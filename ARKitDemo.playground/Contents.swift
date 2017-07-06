//: A UIKit based Playground to present an ARSKScene so you can play with ARKit in a playground

import UIKit
import ARKit
import PlaygroundSupport
import SpriteKit

public class Scene: SKScene {
    
    public override required init(size:CGSize) {
        super.init(size:size)
    }
    
    public required init(coder: NSCoder) {
        super.init(coder:coder)!
    }
    public override func didMove(to view: SKView) {
        // Setup your scene here
    }
    
    public override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let sceneView = self.view as? ARSKView else {
            return
        }
        
        // Create anchor using the camera's current position
        if let currentFrame = sceneView.session.currentFrame {
            // Create a transform with a translation of 0.2 meters in front of the camera
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -0.2
            let transform = simd_mul(currentFrame.camera.transform, translation)
            
            // Add a new anchor to the session
            let anchor = ARAnchor(transform: transform)
            sceneView.session.add(anchor: anchor)
        }
    }
}


class arKitViewController : UIViewController, ARSKViewDelegate {
    @IBOutlet var sceneView: ARSKView!
    
    override func loadView() {
        sceneView = ARSKView(frame:CGRect(x: 0.0, y: 0.0, width: 500.0, height: 600.0))
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and node count
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
        
        // Load the SKScene from 'Scene.sks'
        if let scene = SKScene(fileNamed: "Scene") {
            let myScene = scene as! Scene
            sceneView.presentScene(myScene)
        }
        
        let config = ARWorldTrackingSessionConfiguration()
        config.planeDetection = .horizontal
        self.view = sceneView
        sceneView.session.run(config)
    }
    
    
    
    // MARK: - ARSKViewDelegate
    
    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
        // Create and configure a node for the anchor added to the view's session.
        let spriteNode = SKSpriteNode(imageNamed: "PearLogo.png")
        return spriteNode;
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
}

PlaygroundPage.current.liveView = arKitViewController()
PlaygroundPage.current.needsIndefiniteExecution = true
