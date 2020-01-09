//
//  ViewController.swift
//  ARGameDemo
//
//  Created by Collin Hemeltjen on 16/12/2019.
//  Copyright © 2019 Collin Hemeltjen. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet var sceneView: ARSCNView!
	let gameState = GameState()
    var gameWindowStore = GameWindowStore()
	var gameController = GameController()
	var fuelCellNode: SCNNode!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
		configureOnClick()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
		configuration.planeDetection = .vertical //needs to be vertical, but for testing purposes
		configuration.isLightEstimationEnabled = true
		configuration.detectionImages = gameWindowStore.getReferenceImages()

		configureLight()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate

    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        if let validImageAnchor = anchor as? ARImageAnchor {
			if let node = gameController.loadWindow(for: validImageAnchor.referenceImage) {
				return addSceneNode(node, to: validImageAnchor)
			}
		}
		return nil
    }
	
	func addSceneNode(_ sceneNode: SCNNode, to anchor: ARImageAnchor) -> SCNNode {
		let node = SCNNode()

		sceneNode.position = SCNVector3Zero
        sceneNode.eulerAngles = SCNVector3Make(sceneNode.eulerAngles.x - (Float.pi / 2), sceneNode.eulerAngles.y, sceneNode.eulerAngles.z)

		sceneNode.configureOcclusionPlanes()

		node.addChildNode(sceneNode)
		return node
	}

	func configureOnClick(){
		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTap(withGestureRecognizer:)))
		sceneView.addGestureRecognizer(tapGestureRecognizer)
	}

	@objc func didTap(withGestureRecognizer recognizer: UIGestureRecognizer) {
		let tapLocation = recognizer.location(in: sceneView)
		let hitTestResults = sceneView.hitTest(tapLocation)
		
		guard let hitTestResult = hitTestResults.first(where: {$0.node.name == NODE.FUELCELL}) else {
			// no node tapped
			return
		}

		gameController.fuelCellTapped(node: hitTestResult.node)
		hitTestResult.node.removeFromParentNode()
		if gameController.gameState.fuelCellsRemaining == 0 {
			label.text = "Je hebt alle energie cellen gevonden!"
		}
	}

	@IBOutlet weak var label: UILabel!


	let ambientLight = SCNLight()
	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		if let lightEstimate = sceneView.session.currentFrame?.lightEstimate {
			changeLightConditions(to: lightEstimate)
		}
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
