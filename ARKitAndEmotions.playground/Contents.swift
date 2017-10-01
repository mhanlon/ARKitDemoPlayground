//: Playground - noun: a place where people can play

import UIKit
import ARKit
import PlaygroundSupport
var str = "Hello, playground"

class QIAREmotionsViewController : UIViewController, ARSKViewDelegate, ARSessionDelegate {
    var sceneView: ARSKView!
    
    override func loadView() {
        sceneView = ARSKView(frame:CGRect(x: 0.0, y: 0.0, width: 500.0, height: 600.0))
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and node count
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
        
        let scene = SKScene(size: sceneView.frame.size)
        sceneView.presentScene(scene)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal

        // Now we'll get messages when planes were detected...
        sceneView.session.delegate = self
        
        self.view = sceneView
        sceneView.session.run(config)
    }
    
    // MARK: - ARSKViewDelegate
    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
        // Create and configure a node for the anchor added to the view's session.
        // Or you can use this to create a sprite from another emoji,
        // like a cat (🐱) or seomthing else (🥛, 🍩, 📦)
        let spriteNode = SKLabelNode(text: "👾")
        spriteNode.horizontalAlignmentMode = .center
        spriteNode.verticalAlignmentMode = .center
        return spriteNode;
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal:
            //: We'd probably want some other way of capturing images for emotional states than just when the tracking starts
            let helper = EmotionHelpers()
            
//            guard let pixelBuffer = session.currentFrame?.capturedImage else {
//                return
//            }
//            guard let cgImage = createCGImageFromCVPixelBuffer(pixelBuffer: pixelBuffer)
//                else {
//                    return
//            }
            guard let image = self.view.toUIImage()
                else {
                    let message = "We failed to get an image from the view."
                    print(message)
                return
            }

            helper.makeEmojisFromEmotionOnPhoto(photo: image, includeFaceRect: false) { emojiNodes in
                for node in emojiNodes {
                    self.sceneView.scene?.addChild(node)
                }
            }
        default:
            // do nothing...
            print("Not ready yet...")
        }
    }
    
    func createCGImageFromCVPixelBuffer(pixelBuffer: CVPixelBuffer) -> CGImage? {
        let bitmapInfo: CGBitmapInfo
        let sourcePixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        if kCVPixelFormatType_32ARGB == sourcePixelFormat {
            bitmapInfo = [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)]
        } else
            if kCVPixelFormatType_32BGRA == sourcePixelFormat {
                bitmapInfo = [.byteOrder32Little, CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)]
            } else {
                return nil
        }
        
        // only uncompressed pixel formats
        let sourceRowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        print("Buffer image size \(width) height \(height)")
        
        let val: CVReturn = CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        if  val == kCVReturnSuccess,
            let sourceBaseAddr = CVPixelBufferGetBaseAddress(pixelBuffer),
            let provider = CGDataProvider(dataInfo: nil, data: sourceBaseAddr, size: sourceRowBytes * height, releaseData: {_,_,_ in })
        {
            let colorspace = CGColorSpaceCreateDeviceRGB()
            let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: sourceRowBytes,
                                space: colorspace, bitmapInfo: bitmapInfo, provider: provider, decode: nil,
                                shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            return image
        } else {
            return nil
        }
    }
}


PlaygroundPage.current.liveView = QIAREmotionsViewController()
PlaygroundPage.current.needsIndefiniteExecution = true
