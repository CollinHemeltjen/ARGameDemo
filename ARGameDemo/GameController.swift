//
//  GameController.swift
//  ARGameDemo
//
//  Created by Collin Hemeltjen on 08/01/2020.
//  Copyright © 2020 Collin Hemeltjen. All rights reserved.
//

import Foundation
import ARKit
import SceneKit
import MultipeerConnectivity

class GameController {
    var gameWindowStore = GameWindowStore()
	var gameState = GameState()

	var currentGameWindows: [GameWindow]!

	init(){
//        var peers = multipeerSession?.connectedPeers
		loadLevel()
//        do{
//            print("ok")
//            if peers == nil{
//                return
//            }else{
//                let item = try NSKeyedArchiver.archivedData(withRootObject: gameState, requiringSecureCoding: true)
//                multipeerSession.sendToPeers(item, reliably: true, peers: peers!)
//            }
//        }catch let error{
//            print(error)
//        }
	}

	func loadLevel(){
		let currentLevel = gameState.currentLevel
		currentGameWindows = [GameWindow]()
		currentGameWindows.append(contentsOf: gameWindowStore.gameWindows[currentLevel])
	}

	func loadWindow(for image: ARReferenceImage) -> SCNNode? {
		guard let window = currentGameWindows.first(where: {$0.referenceImage == image}) else {
			return nil
		}

		let node = window.sceneNode
		populateSpawns(on: node, window: window.window)
		node.deleteSpawnLocations()
		return node
	}

	func nextLevel(){

	}

	func populateSpawns(on node: SCNNode, window: Int){
		guard let fuelCells = node.fuelCells else { return }
		let locations = gameState.occupatedSpawnLocations[window]
		for index in 0..<fuelCells.count {
			let fuelCell = fuelCells[index]
			let location = locations[index]
			node.insert(node: fuelCell, on: location)
		}
	}

    func fuelCellTapped(node: SCNNode, peers: [MCPeerID], multipeerSession: MultipeerSession){
		var fuelCellIndex: Int?
		var windowIndex: Int?
		for index in 0..<currentGameWindows.count {
			let gameWindow = currentGameWindows[index]
			if gameWindow.sceneNode.childNodes(withName: NODE.FUELCELL)?.contains(node) ?? false{
				windowIndex = index
				fuelCellIndex = (gameWindow.sceneNode.fuelCells?.firstIndex(of: node))!
			}
		}

		guard fuelCellIndex != nil && windowIndex != nil else {
			return
		}
        print("WindowIndex: \(windowIndex!)")
		print("fuelCellIndex: \(fuelCellIndex!)")
		gameState.occupatedSpawnLocations[windowIndex!].remove(at: fuelCellIndex!)
        
		gameState.score += 1
		gameState.fuelCellsRemaining -= 1
		print("score: \(gameState.score)")
		print("fuelCellsRemaining: \(gameState.fuelCellsRemaining)")

		if gameState.fuelCellsRemaining == 0 {
			print("all cells found!")
		}
        do{
            let encoder = JSONEncoder()
            let item = try encoder.encode(gameState)
            
            multipeerSession.sendToPeers(item, reliably: true, peers: peers)
        }catch let error{
            print(error)
        }
	}
}
