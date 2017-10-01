//: I used to live in an apartment in Brooklyn, and now you, too, can have the same experience.

import PlaygroundSupport
import ARKit
import SpriteKit

class QIBrooklynViewController: UIViewController, ARSKViewDelegate, ARSessionDelegate {
    var sceneView: ARSKView!
    var lightIntensityLabel: SKLabelNode!
    
    override func loadView() {
        lightIntensityLabel = SKLabelNode(text: "Light intensity: <>")
        lightIntensityLabel.horizontalAlignmentMode = .center
        lightIntensityLabel.verticalAlignmentMode = .center
        lightIntensityLabel.fontSize = 10
        lightIntensityLabel.position = CGPoint(x: 250, y: 300) // centered in the scene... see measurements below for my advanced math
        sceneView = ARSKView(frame:CGRect(x: 0.0, y: 0.0, width: 500.0, height: 600.0))
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and node count
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
        
        let scene = SKScene(size: sceneView.frame.size)
        scene.scaleMode = .aspectFill
        sceneView.presentScene(scene)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal

        // Now we'll get messages when planes were detected...
        sceneView.session.delegate = self
        
        sceneView.scene?.addChild(lightIntensityLabel)
        self.view = sceneView
        sceneView.session.run(config)
    }
    
    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
        // Create and configure a node for the anchor added to the view's session.
        let spriteNode = SKLabelNode(text: "👾")
        spriteNode.horizontalAlignmentMode = .center
        spriteNode.verticalAlignmentMode = .center
        
//        let action = SKAction.repeatForever(SKAction.applyAngularImpulse(2.0, duration: 30))
//        let moveAction = SKAction.repeatForever(SKAction.applyForce(CGVector(dx:5, dy: 5), duration: 50))

        // Add some baby bugs, too...
        for num in 1...4 {
            let babySprite = SKLabelNode(text: "👾")
            babySprite.fontSize = 10
            babySprite.physicsBody?.isDynamic = true
            
            switch num {
            case 1:
                babySprite.position.x = 25
            case 2:
                babySprite.position.x = -25
            case 3:
                babySprite.position.y = 25
            case 4:
                babySprite.position.y = -25
            default:
                babySprite.position.x = 0
                babySprite.position.y = 0
            }
//            babySprite.run(action)
//            babySprite.run(moveAction)
            spriteNode.addChild(babySprite)
        }
//        spriteNode.run(moveAction)
        return spriteNode;
    }


    // You, and by you I mean me, might want to dump this in a SKScene subclasss.
    func view(_ view: SKView, shouldRenderAtTime time: TimeInterval) -> Bool {
        guard let currentFrame = sceneView.session.currentFrame,
            let lightEstimate = currentFrame.lightEstimate else {
                return true // Return, if we don't have a currentFrame and light estimate to work with.
        }
        
        let neutralIntensity: CGFloat = 1000 // 1,000 is a well lit environment... less is darker, up to 2,000 is super bright
        let ambientIntensity = min(lightEstimate.ambientIntensity, neutralIntensity)
        let alpha = ( ambientIntensity / neutralIntensity )
        self.lightIntensityLabel.text = "Light intensity: \(ambientIntensity) Blend factor: \(alpha)"
        // If there is light, we should show the bugs...
        for node in sceneView.scene!.children {
            if let bug = node as? SKLabelNode, bug.text == "👾" {
                if ( ambientIntensity < 500 ) {
                    bug.alpha = 0
                } else if ( ambientIntensity < 900 ) {
                    // Amplify the alpha effect a bit to make them more dim outside of direct light...
                    bug.alpha = alpha * 0.5
                } else {
                    bug.alpha = alpha
                }
                
            }
        }
        return true
    }
}

PlaygroundPage.current.liveView = QIBrooklynViewController()
PlaygroundPage.current.needsIndefiniteExecution = true
