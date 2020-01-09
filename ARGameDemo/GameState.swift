//
//  GameState.swift
//  ARGameDemo
//
//  Created by Collin Hemeltjen on 07/01/2020.
//  Copyright © 2020 Collin Hemeltjen. All rights reserved.
//

import Foundation

struct GameState {
	var currentLevel = 0
	var levels = ["Brazil", "China"]
	var occupatedSpawnLocations: [[Int]]!
	var score = 0
	var fuelCellsRemaining = 6

	// each level has 2 windows, each window has 9 possible spawn locations but only 3 locations will contain a fuelCell
	mutating func determineSpawnLocatins(){
		occupatedSpawnLocations = [[Int](), [Int]()]
		for window in 0..<2 {
			for _ in 0..<3 {
				var random: Int
				repeat {
					random = Int.random(in: 0..<9)
				} while (occupatedSpawnLocations[window].contains(random))
				occupatedSpawnLocations[window].append(random)
			}
		}
	}

	init(){
		self.determineSpawnLocatins()
	}
}
