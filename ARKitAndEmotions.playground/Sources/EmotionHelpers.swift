import Foundation
import UIKit
import SpriteKit

public class EmotionHelpers : NSObject {
    /**
     Method for putting an emoji with a matching emotion over each detected face in a photo.
     
     - parameters:
       - photo: The photo on which faces and it's emotion shall be detected
       - withFaceRect: If TRUE then the face rectangle is drawn into the photo
     - completion: An array of SKLabelNodes of emojis for the detected emotion over each face. TODO: Add some positioning information to anchor the nodes to the ARSession.
     */
    public func makeEmojisFromEmotionOnPhoto (photo : UIImage!, includeFaceRect: Bool, completion: @escaping ([SKLabelNode]) -> (Void)) {
        
        let manager = CognitiveServices()
        
        manager.retrievePlausibleEmotionsForImage(photo) { (result, error) -> (Void) in
            DispatchQueue.main.async(execute: {
                if let _ = error {
                    print("omg something bad happened")
                } else {
                    print("seems like all went well: \(String(describing: result))")
                }
                
                if (result?.count)! > 0 {
                    print("1..2.. Emoji!\n\((result?.count)!) emotions detected")
                } else {
                    print("Seems like no emotions were detected :(")
                }
                
                let emojiNodesForPhoto = self.emojiNodesForPhoto(emotions: result, includeFaceRect: includeFaceRect, image: photo!)
                completion(emojiNodesForPhoto)
                //let photoWithEmojis = self.drawEmojisFor(emotions: result, withFaceRect: withFaceRect, image: photo!)
                //completion(photoWithEmojis)
            })
        }
        
    }
    
    public func emojisFor(emotion: CognitiveServicesEmotionResult) -> [String] {
        var availableEmojis = [String]()
        
        switch emotion.emotion {
        case .Anger:
            availableEmojis.append("😡")
            availableEmojis.append("😠")
        case .Contempt:
            availableEmojis.append("😤")
        case .Disgust:
            availableEmojis.append("😷")
            availableEmojis.append("🤐")
        case .Fear:
            availableEmojis.append("😱")
        case .Happiness:
            availableEmojis.append("😝")
            availableEmojis.append("😀")
            availableEmojis.append("😃")
            availableEmojis.append("😄")
            availableEmojis.append("😆")
            availableEmojis.append("😊")
            availableEmojis.append("🙂")
            availableEmojis.append("☺️")
        case .Neutral:
            availableEmojis.append("😶")
            availableEmojis.append("😐")
            availableEmojis.append("😑")
        case .Sadness:
            availableEmojis.append("🙁")
            availableEmojis.append("😞")
            availableEmojis.append("😟")
            availableEmojis.append("😔")
            availableEmojis.append("😢")
            availableEmojis.append("😭")
        case .Surprise:
            availableEmojis.append("😳")
            availableEmojis.append("😮")
            availableEmojis.append("😲")
        }
        
        return availableEmojis

    }

    public func emojiNodesForPhoto(emotions: [CognitiveServicesEmotionResult]?, includeFaceRect: Bool, image: UIImage) -> [SKLabelNode] {
        
        var emojiNodes: [SKLabelNode] = []
        
        if let results = emotions {
            
            for result in results {
                let availableEmojis = emojisFor(emotion: result)
                
                let emoji = availableEmojis.randomElement()
                
                let emojiNode = SKLabelNode(text: emoji)
                emojiNode.horizontalAlignmentMode = .center
                emojiNode.verticalAlignmentMode = .center
                
                emojiNodes.append(emojiNode)
                if includeFaceRect {
//                    let context = UIGraphicsGetCurrentContext()
//                    let frame = result.frame
//                    context!.setLineWidth(5)
//                    context!.addRect(frame)
//                    context!.drawPath(using: .stroke)
                }
                
            }
        }
        
        return emojiNodes
    }

}

