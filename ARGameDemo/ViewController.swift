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
    var multipeerSession: MultipeerSession!
    var peerSessionIDs = [MCPeerID: String]()
    var gameController = GameController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        configureOnClick()
        gameController.loadNewWorld = self.loadingNewWorld
        
        loadingNewWorld()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        multipeerSession = MultipeerSession(receivedDataHandler: receivedData, peerJoinedHandler:
            peerJoined, peerLeftHandler: peerLeft, peerDiscoveredHandler: peerDiscovered)
        
        createSessionConfig()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        
    }
    
    func createSessionConfig(){
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical //needs to be vertical, but for testing purposes
        configuration.isLightEstimationEnabled = true
        configuration.detectionImages = gameController.gameWindowStore.getReferenceImages()
        configuration.isCollaborationEnabled = true
        anchorNodes = [SCNNode]()
        sceneNodes = [SCNNode]()

        configureLight()
        
        // Run the view's session
        sceneView.session.run(configuration, options: [.removeExistingAnchors])
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

	func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//		DispatchQueue.main.async {
//			if self.anchorNodes.contains(node){
//				print("update")
//				let index = self.anchorNodes.firstIndex(of: node)
//				let sceneNode = self.sceneNodes[index!]
//
//				sceneNode.removeAllActions()
//				node.eulerAngles = SCNVector3Make(node.eulerAngles.x - (Float.pi / 2), node.eulerAngles.y, node.eulerAngles.z)
//				let action = SCNAction.group([SCNAction.move(to: node.position, duration: 0.5),
//											 SCNAction.rotate(toAxisAngle: node.rotation, duration: 0.5)])
//				sceneNode.runAction(action)
//			}
//		}
	}



	var anchorNodes = [SCNNode]()
	var sceneNodes = [SCNNode]()
    func addSceneNode(_ sceneNode: SCNNode, to anchor: ARImageAnchor) -> SCNNode {
        let node = SCNNode()

        sceneNode.position = SCNVector3Zero

        sceneNode.configureOcclusionPlanes()
        sceneNode.transform = SCNMatrix4(anchor.transform)
        sceneNode.eulerAngles = SCNVector3Make(sceneNode.eulerAngles.x - (Float.pi / 2), sceneNode.eulerAngles.y, sceneNode.eulerAngles.z)

		sceneView.scene.rootNode.addChildNode(sceneNode)

		sceneNodes.append(sceneNode)
		anchorNodes.append(node)
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
        
        gameController.fuelCellTapped(node: hitTestResult.node, peers: multipeerSession.connectedPeers, multipeerSession: multipeerSession)
        hitTestResult.node.removeFromParentNode()
        if gameController.gameState.fuelCellsRemaining == 0 {
            //			label.text = "Je hebt alle energie cellen gevonden!"
        }
    }
    
    
    func loadingNewWorld(){
        if let loadingOverlay = SKScene(fileNamed: "LoadingOverlay") {
            sceneView.overlaySKScene = loadingOverlay
        }
        sceneView.scene.rootNode.cleanup()
        createSessionConfig()
        
        sceneView.prepare(gameController.currentGameWindows.compactMap({$0.sceneNode}), completionHandler: { success in
            DispatchQueue.main.async {
                self.sceneView.overlaySKScene = nil
            }
        })
    }
    
    let ambientLight = SCNLight()
	var previousUpdate = TimeInterval()
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if let lightEstimate = sceneView.session.currentFrame?.lightEstimate {
            changeLightConditions(to: lightEstimate)
        }
		guard (time - previousUpdate) > 0.2 else { return }
		previousUpdate = time
		DispatchQueue.main.async {
			for index in 0..<self.anchorNodes.count {
				print("update \(time)")
				let node = self.anchorNodes[index]
				let sceneNode = self.sceneNodes[index]

				sceneNode.removeAllActions()
				node.eulerAngles = SCNVector3Make(node.eulerAngles.x - (Float.pi / 2), node.eulerAngles.y, node.eulerAngles.z)
				let action = SCNAction.group([SCNAction.move(to: node.position, duration: 1)])
				sceneNode.runAction(action)
			}
		}

    }
    
    func receivedData(_ data: Data, from peer: MCPeerID) {
		let decoder = JSONDecoder()
		if let newGameState = try? decoder.decode(GameState.self, from: data) {
			gameController.updateGameState(newGameState: newGameState)
		}
    }
    
    func peerDiscovered(_ peer: MCPeerID) -> Bool {
        guard let multipeerSession = multipeerSession else { return false }

        if multipeerSession.connectedPeers.count > 4 {
            // Do not accept more than four users in the experience.
            print("A fifth peer wants to join the experience.\nThis app is limited to four users.")
            return false
        } else {
            return true
        }
    }

    /// - Tag: PeerJoined
    func peerJoined(_ peer: MCPeerID) {
        print(" A peer wants to join the experience.")

        // Provide your session ID to the new user so they can keep track of your anchors.
        sendARSessionIDTo(peers: [peer])
    }
    
    func peerLeft(_ peer: MCPeerID) {
        print("A peer has left the shared experience")

        // Remove peer from session list
        if peerSessionIDs[peer] != nil {
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
        
        if let commandData = command.data(using: .utf8) {
            multipeerSession.sendToPeers(commandData, reliably: true, peers: peers)
        }
    }
}

