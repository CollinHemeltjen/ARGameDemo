//
//  GameWindow.swift
//  ARGameDemo
//
//  Created by Collin Hemeltjen on 04/01/2020.
//  Copyright © 2020 Collin Hemeltjen. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

struct GameWindowStore {
	var gameWindows = [ARReferenceImage: SCNNode]()

	init() {
		gameWindows[GameWindowStore.getReferenceImage(withName: "Brazil")] =
			GameWindowStore.getSceneNode(withName: "Brazil")
		gameWindows[GameWindowStore.getReferenceImage(withName: "China")] =
			GameWindowStore.getSceneNode(withName: "Brazil")
	}

	private static func getReferenceImage(withName name: String) -> ARReferenceImage{
		ARReferenceImage.referenceImages(inGroupNamed: "ReferenceImages",
										 bundle: nil)!.first(where: {$0.name == name})!
	}

	private static func getSceneNode(withName name: String) -> SCNNode {
		let arScene = SCNScene(named: "art.scnassets/\(name)/scene.scn")
		return arScene!.rootNode.childNode(withName: "box", recursively: false)!
	}

	func getReferenceImages() -> Set<ARReferenceImage>{
		var set = Set<ARReferenceImage>()
		for key in gameWindows.keys {
			set.insert(key)
		}
		return set
	}
}
