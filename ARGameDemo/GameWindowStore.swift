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

struct GameWindow {
	let referenceImage: ARReferenceImage
	let sceneNode: SCNNode
	let window: Int
}

struct GameWindowStore {
	var gameWindows = [[GameWindow]()]

	init() {
		gameWindows[0].append(
			GameWindow(referenceImage: GameWindowStore.getReferenceImage(withName: "Brazil"),
					   sceneNode: GameWindowStore.getSceneNode(withName: "Brazil1"),
					   window: WINDOW.ONE)
		)
		gameWindows[0].append(
			GameWindow(referenceImage: GameWindowStore.getReferenceImage(withName: "China"),
					   sceneNode: GameWindowStore.getSceneNode(withName: "Brazil1"),
					   window: WINDOW.TWO)
		)
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
		for image in gameWindows[0].compactMap({$0.referenceImage}) {
			set.insert(image)
		}
		return set
	}
}
