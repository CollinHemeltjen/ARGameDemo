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
	var loadNewWorld: (() -> Void)?

	init(){
		loadLevel()
	}
    
    func updateGameState(newGameState: GameState){
        if gameState.currentLevel != newGameState.currentLevel {
            gameState = newGameState
            loadLevel()
            loadNewWorld?()
            return
        }else if gameState.fuelCellsRemaining != newGameState.fuelCellsRemaining{
            updateFuelCells(gameState: gameState, newGameState: newGameState)
            gameState = newGameState
            
        }else if gameState.occupatedSpawnLocations[0] != newGameState.occupatedSpawnLocations[0] || gameState.occupatedSpawnLocations[1] != newGameState.occupatedSpawnLocations[1]{
            gameState = newGameState
        }
    }

	func loadLevel(){
		let currentLevel = gameState.currentLevel
		if currentGameWindows != nil {
			for gameWindow in currentGameWindows {
				gameWindow.sceneNode.cleanup()
				gameWindow.sceneNode.removeFromParentNode()
			}
		}
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
		print("all cells found!")
		if gameWindowStore.gameWindows[gameState.currentLevel].count > 0{
			gameWindowStore.gameWindows[gameState.currentLevel] = [GameWindow]()
		}
		gameState.currentLevel += 1
		gameState.determineSpawnLocatins()
		gameState.score = 0
		gameState.fuelCellsRemaining = 6
		guard !(gameState.currentLevel >= gameState.levels.count) else {
			return
		}
		loadLevel()
		loadNewWorld?()
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

		gameState.occupatedSpawnLocations[windowIndex!].remove(at: fuelCellIndex!)
        
		gameState.score += 1
		gameState.fuelCellsRemaining -= 1
		print("score: \(gameState.score)")
		print("fuelCellsRemaining: \(gameState.fuelCellsRemaining)")

		if gameState.fuelCellsRemaining == 0 {
			nextLevel()
		}
        do{
            let encoder = JSONEncoder()
            let item = try encoder.encode(gameState)

            multipeerSession.sendToPeers(item, reliably: true, peers: peers)
        }catch let error{
            print(error)
        }
	}

	// checks if a fuelcell is found by a peer, removes said cell if true
    func updateFuelCells(gameState: GameState, newGameState: GameState){
        for i in 0..<gameState.occupatedSpawnLocations.count {
            let array = gameState.occupatedSpawnLocations[i]
            for fuelCellIndex in 0..<array.count{
                let spawnLocation = array[fuelCellIndex]
                if !newGameState.occupatedSpawnLocations[i].contains(spawnLocation) && gameState.occupatedSpawnLocations[i].contains(spawnLocation){
                    if let fuelCell = currentGameWindows[i].sceneNode.childNodes(withName: NODE.FUELCELL)?[fuelCellIndex]{
                        fuelCell.removeFromParentNode()
                    }
                    gameState.occupatedSpawnLocations[i].remove(at: fuelCellIndex)
                }
            }
        }
    }
}
