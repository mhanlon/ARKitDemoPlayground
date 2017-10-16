# ARKitDemoPlayground and Friends

A demo of the ARKit Demo project from Xcode 9 as a Swift Playground. This is the demo that was given at the 404 conference in Dublin on October 7th, 2017.

`ARKitDemo.playground` is the sample project that comes with Xcode 9 for checking out ARKit with SpriteKit with a few minor tweaks to get it into a playground.

The second project, `ARKit3DDemo.playground` uses some of the assets from the [Fox2 SceneKit sample code from Apple](https://developer.apple.com/library/content/samplecode/scenekit-2017/Introduction/Intro.html). It'll place Max and his friends around the flat surfaces in your environment. Assets all copyright Apple and includes the LICENSE.txt that accompanies the sample code.

The *third* project, `BrooklynApartment.playground`, simulates my old apartment in Brooklyn. When the light is strong enough (using the `lightEstimate` from the current `ARFrame`) you'll see a number of bugs... when it gets darker you can no longer see the bugs... but they're likely still there. *This project will not be (was not, if you're reading this in the future and I didn't, in fact, demo it -- also, I like your hoverboard and day-glo sunglasses) demoed at 404 because I don't think I'll have sufficient control over the lighting in the venue.*

The *fourth* project is not quite there... it uses, well, nearly uses, the MS APIs to derive emotions on faces in a picture. The idea was to take a snapshot of the ARSKScene, send the frame capture to the MS services and let it determine emotions on the faces in the scene. With the result, an emotion emmoji would be drawn on the scene at the point at which a person was having that emotion. You could track a person or people's emotions depending where they were in a room, I suppose? *Hint: It's also on the [`emotionsAPI`](https://github.com/mhanlon/ARKitDemoPlayground/tree/emotionsAPI) branch.* 

What's far more cool is the new Augmented Reality Challenge in Swift Playgrounds, so go grab that from the Challenges tab in Swift Playgrounds, when you hit the big + sign to add a new playground.

More info on ARKit:
* [ARKit - Apple Developer](https://developer.apple.com/arkit/) - the landing page for ARKit at Apple
* [Swift Playgrounds](https://www.apple.com/swift/playgrounds/) - You need Swift Playgrounds 2 and iOS 11
* [ARKit Documentation](https://developer.apple.com/documentation/arkit) - the ARKit developer docs



`A messy kitchen and a virtual pear in the midst of it all`
![](http://www.wickedpearprogramming.com/w/wp-content/uploads/2017/09/pear-arkit-1.png)
