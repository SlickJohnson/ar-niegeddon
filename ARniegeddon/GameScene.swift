/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import ARKit

class GameScene: SKScene {
  // Return the scene's view as ARSKView
  var sceneView: ARSKView {
    return view as! ARSKView
  }

  // Check if AR nodes are added.
  var isWorldSetUp = false

  // Weapon aiming sight.
  var sight: SKSpriteNode!

  // Size of game world.
  let gameSize = CGSize(width: 2, height: 2)


  /// Set up the scene with the required nodes
  private func setUpWorld() {
    guard let currentFrame = sceneView.session.currentFrame else { return }

    // Load level 1 scene file.
    guard let scene = SKScene(fileNamed: "Level1") else { return }

    for node in scene.children {
      guard let node = node as? SKSpriteNode else { return }

      var translation = matrix_identity_float4x4

      let positionX = node.position.x / scene.size.width
      let positionY = node.position.y / scene.size.height
      translation.columns.3.x = Float(positionX * gameSize.width)
      translation.columns.3.z = -Float(positionY * gameSize.height)
      translation.columns.3.y = Float(drand48() - 0.5)

      let transform = currentFrame.camera.transform * translation

      let anchor = ARAnchor(transform: transform)
      sceneView.session.add(anchor: anchor)
    }

    isWorldSetUp = true
  }

  override func didMove(to view: SKView) {
    sight = SKSpriteNode(imageNamed: "sight")
    addChild(sight)
    srand48(Int(Date.timeIntervalSinceReferenceDate))
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    // Get nodes hit by weapon.
    let location = sight.position
    let hitNodes = nodes(at: location)

    // Check if bug was hit.
    var hitBug: SKNode?
    for node in hitNodes {
      if node.name == "bug" {
        hitBug = node
        break
      }
    }

    run(Sounds.fire)
    // Play hit sound and remove bug when hit.
    if let hitBug = hitBug, let anchor = sceneView.anchor(for: hitBug) {
      let removeAction = SKAction.run {
        self.sceneView.session.remove(anchor: anchor)
      }
      let group = SKAction.group([Sounds.hit, removeAction])
      let sequence = [SKAction.wait(forDuration: 0.3), group]
      hitBug.run(SKAction.sequence(sequence))
    }
  }

  override func update(_ currentTime: TimeInterval) {
    if !isWorldSetUp {
      setUpWorld()
    }

    // Retrieve current frame and light estimate from scene view.
    guard let currentFrame = sceneView.session.currentFrame,
      let lightEstimate = currentFrame.lightEstimate else {
        return
    }

    // Calculate bug tint based on light levels from scene.
    let neutralIntensity: CGFloat = 1000
    let ambientIntensity = min(lightEstimate.ambientIntensity, neutralIntensity)
    let blendFactor = 1 - ambientIntensity / neutralIntensity

    // Tint bug using blend factor
    for node in children {
      if let bug = node as? SKSpriteNode {
        bug.color = .black
        bug.colorBlendFactor = blendFactor
      }
    }
  }
}


