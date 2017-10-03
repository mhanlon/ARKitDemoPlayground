//: A UIKit based Playground to present an ARSKScene so you can play with ARKit in a playground

import UIKit
import ARKit
import PlaygroundSupport
import SpriteKit


class QIARViewController : UIViewController, ARSKViewDelegate, ARSessionDelegate {
    var sceneView: ARSKView!
    
    override func loadView() {
        sceneView = ARSKView(frame:CGRect(x: 0.0, y: 0.0, width: 500.0, height: 600.0))
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and node count
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
        
        // Load the SKScene from 'Scene.sks'
        if let scene = SKScene(fileNamed: "Scene") {
            sceneView.presentScene(scene)
        }

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        // Playground note: You can't use the audio capture capabilities
        // of an ARSession with a Swift Playground.
        // config.providesAudioData = true
        
        // Now we'll get messages when planes were detected...
        sceneView.session.delegate = self
        
        self.view = sceneView
        sceneView.session.run(config)
    }

    // MARK: - ARSKViewDelegate
    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
        // Create and configure a node for the anchor added to the view's session.
        let image = #imageLiteral(resourceName: "PearLogo.png")
        let spriteTexture = SKTexture(cgImage: image.cgImage!)
        let spriteNode = SKSpriteNode(texture: spriteTexture)
        // Or you can use this to create a sprite from an emoji,
        // like an alien monster (👾), a cat (🐱), or more (🥛, 🍩, 📦)
//        let spriteNode = SKLabelNode(text: "👾")
//        spriteNode.horizontalAlignmentMode = .center
//        spriteNode.verticalAlignmentMode = .center
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

PlaygroundPage.current.liveView = QIARViewController()
PlaygroundPage.current.needsIndefiniteExecution = true


//: This is our Scene, which doesn't do a heck of a lot.
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
    
}

