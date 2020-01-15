//
//  Hud.swift
//  ARGameDemo
//
//  Created by Collin Hemeltjen on 15/01/2020.
//  Copyright © 2020 Collin Hemeltjen. All rights reserved.
//

import SpriteKit

class Hud: SKScene {
	var gameController: GameController?

	var scoreLabel = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
	var scoreTextLabel = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")

	var fuelLabel = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
	var fuelTextLabel = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")

	override init() {
		super.init()
		fullInit()
	}
	override init(size: CGSize) {
		super.init(size: size)
		fullInit()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func fullInit(){
		let frameW = self.frame.size.width
        let frameH = self.frame.size.height

		scoreTextLabel.position = CGPoint(x: 50, y: frameH - 50)
		scoreTextLabel.text = "Score"
		scoreTextLabel.fontSize = 30
		self.addChild(scoreTextLabel)

		scoreLabel.position = CGPoint(x: 50, y: frameH - 90)
		scoreLabel.text = "0"
		scoreLabel.fontSize = 30
		self.addChild(scoreLabel)

		fuelTextLabel.position = CGPoint(x: frameW - 5, y: frameH - 50)
		fuelTextLabel.text = "Energie cellen"
		fuelTextLabel.horizontalAlignmentMode = .right
		fuelTextLabel.fontSize = 30

		self.addChild(fuelTextLabel)

		fuelLabel.position = CGPoint(x: frameW - 50, y: frameH - 90)
		fuelLabel.text = "0"
		fuelLabel.fontSize = 30
		self.addChild(fuelLabel)
	}

	override func update(_ currentTime: TimeInterval) {
		scoreLabel.text = "\(gameController?.gameState.score ?? 0)"
		fuelLabel.text = "\(gameController?.gameState.fuelCellsRemaining ?? 0)"
	}
}
