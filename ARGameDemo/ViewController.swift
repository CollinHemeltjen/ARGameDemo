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
import MultipeerConnectivity

class ViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet var sceneView: ARSCNView!
    let gameWindowStore = GameWindowStore()
	var gameController = GameController()
	var fuelCellNode: SCNNode!
    
    var multipeerSession: MultipeerSession!
    var peerSessionIDs = [MCPeerID: String]()

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
        
        configuration.isCollaborationEnabled = true
        
        multipeerSession = MultipeerSession(receivedDataHandler: receivedData, peerJoinedHandler:
        peerJoined, peerLeftHandler: peerLeft, peerDiscoveredHandler: peerDiscovered)

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
        let peers = multipeerSession.connectedPeers

		let tapLocation = recognizer.location(in: sceneView)
		let hitTestResults = sceneView.hitTest(tapLocation)
		
		guard let hitTestResult = hitTestResults.first(where: {$0.node.name == NODE.FUELCELL}) else {
			// no node tapped
			return
		}
        
        let command = "Tap"
        if let commandData = command.data(using: .utf8) {
            multipeerSession.sendToPeers(commandData, reliably: true, peers: peers)
        }

        gameController.fuelCellTapped(node: hitTestResult.node, peers: multipeerSession.connectedPeers, multipeerSession: multipeerSession)
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
    
    func receivedData(_ data: Data, from peer: MCPeerID) {
//        let message: String
//        message = String(data: data, encoding: .utf8)!
//            DispatchQueue.main.async {
//                self.sessionInfoLabel.text = message
//        }
        do {
            print("received")
            let decoder = JSONDecoder()
            if let collaborationData = try? decoder.decode(GameState.self, from: data) {
                print("\(collaborationData.fuelCellsRemaining)")
                gameController.gameState = collaborationData
                print(gameController.gameState)
            }
        }catch let error {
            print(error.localizedDescription)
        }
    }
    
        func peerDiscovered(_ peer: MCPeerID) -> Bool {
            guard let multipeerSession = multipeerSession else { return false }
            let message: String
            
            if multipeerSession.connectedPeers.count > 4 {
                // Do not accept more than four users in the experience.
                message = "A fifth peer wants to join the experience.\nThis app is limited to four users."
                DispatchQueue.main.async {
                    self.label.text = message
                }
                return false
            } else {
                return true
            }
        }
        /// - Tag: PeerJoined
        func peerJoined(_ peer: MCPeerID) {
            let message: String
            
            message = " A peer wants to join the experience. Hold the phones next to each other."
            DispatchQueue.main.async {
                self.label.text = message
            }
            // Provide your session ID to the new user so they can keep track of your anchors.
            sendARSessionIDTo(peers: [peer])
        }
            
        func peerLeft(_ peer: MCPeerID) {
            let message: String
            
            message = "A peer has left the shared experience"
            DispatchQueue.main.async {
                self.label.text = message
            }
            // Remove all ARAnchors associated with the peer that just left the experience.
            if peerSessionIDs[peer] != nil {
    //            removeAllAnchorsOriginatingFromARSessionWithID(sessionID)
                peerSessionIDs.removeValue(forKey: peer)
            }
        }
    
    private func sendARSessionIDTo(peers: [MCPeerID]) {
        guard let multipeerSession = multipeerSession else { return }
        let message: String
        let idString = sceneView.session.identifier.uuidString
        let command = "SessionID:" + idString
        let peerNames = multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
        message = "Connected with \(peerNames)."
        print(message)
//        DispatchQueue.main.async {
//            self.sessionInfoLabel.text = message
//        }
        if let commandData = command.data(using: .utf8) {
            multipeerSession.sendToPeers(commandData, reliably: true, peers: peers)
        }
    }
}
