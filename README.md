# ARKitDemoPlayground

**Make sure you grab the Xcode GM from developer.apple.com, otherwise ARKitDemoPlayground might not work for you on the iOS GM...**

A demo of the ARKit Demo project from Xcode 9 as a Swift Playground

This is nothing special, in fact, `ARKitDemo.playground` is the sample project that comes with Xcode 9 for checking out ARKit with SpriteKit. Only I chucked it into a playground.

The second project, `ARKit3DDemo.playground` is 3 times more amazing, because it will add a virtual pear to your world that spins. Oh, and it also adds a pyramid, which doesn't spin. It just floats in the air. 

What's far more cool is the new Augmented Reality Challenge in Swift Playgrounds, so go grab that from the Challenges tab in Swift Playgrounds, when you hit the big + sign to add a new playground.

More info on ARKit:
* [ARKit - Apple Developer](https://developer.apple.com/arkit/) - the landing page for ARKit at Apple
* [Beta downloads at developer.apple.com](https://developer.apple.com/download/) - You need Swift Playgrounds 2 beta, which you can request here 
* [ARKit Documentation](https://developer.apple.com/documentation/arkit) - the ARKit developer docs


Sorry, I'm an idiot. The touchesBegan code seemed reluctant because that's not what was asking us for nodes to add the the ARSKView. The fact that we're a delegate for the ARSKView is why we get notified when we find an ARAnchor in the scene before us. Any touches would fall on the live view, which is a separate process, and needs to use the `PlaygroundRemoteLiveViewProxy` to communicate back to the code view. *This* is why you see pixelated pears littering the surfaces of your home, office, or school.

`A messy kitchen and a virtual pear in the midst of it all`
![](http://www.wickedpearprogramming.com/w/wp-content/uploads/2017/09/pear-arkit-1.png)

The `master` branch now includes all the code in one file so you can tweak the distance from the sample ARKit code in your Swift Playgrounds app. If you'd like the old behavior, check out the [`original`](https://github.com/mhanlon/ARKitDemoPlayground/tree/original) branch.
