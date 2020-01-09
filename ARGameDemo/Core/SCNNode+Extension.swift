//
//  SCNNode+Extension.swift
//  ARGameDemo
//
//  Created by Collin Hemeltjen on 18/12/2019.
//  Copyright © 2019 Collin Hemeltjen. All rights reserved.
//

import Foundation
import SceneKit

extension SCNNode {
	func childNodes(withName name: String, recursive: Bool = false) -> [SCNNode]?{
		var nodesWithName = [SCNNode]()
		
		for childNode in childNodes {
			if childNode.name == name {
				nodesWithName.append(childNode)
			}

			if recursive {
				if childNode.childNodes.count != 0 {
					if let recursiveChildNodesWithName = childNode.childNodes(withName: name) {
						nodesWithName.append(contentsOf: recursiveChildNodesWithName)
					}
				}
			}
		}
		return nodesWithName
	}

	func configureOcclusionPlanes(){
		guard let occlusionPlanes = childNodes(withName: NODE.OCCLUSION, recursive: true) else {
			return
		}

		for occlusionPlane in occlusionPlanes {
			occlusionPlane.geometry?.materials.first?.writesToDepthBuffer = true
			occlusionPlane.geometry?.materials.first?.colorBufferWriteMask = []
			occlusionPlane.isHidden = false
		}
	}

	var potentialSpawnLocations: [SCNNode]? {
		self.childNodes(withName: NODE.SPAWN, recursive: true)
	}

	var fuelCells: [SCNNode]? {
		self.childNodes(withName: NODE.FUELCELL, recursive: true)
	}

	func insertNodeOnRandomSpawn(node: SCNNode){
		guard let spawn = potentialSpawnLocations?.randomElement() else { return }
		node.position = spawn.position
		self.addChildNode(node)
		deleteSpawnLocations()
	}

	func insert(node: SCNNode, on spawnNumber: Int){
		guard let spawn = potentialSpawnLocations?[spawnNumber] else {
			return
		}
		node.position = spawn.position
		self.addChildNode(node)
	}

	func deleteSpawnLocations(){
		guard let potentialSpawnLocations = potentialSpawnLocations else {
			return
		}

		for node in potentialSpawnLocations {
			node.removeFromParentNode()
		}
	}
}
