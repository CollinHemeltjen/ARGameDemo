//
//  ViewController+Lighting.swift
//  ARGameDemo
//
//  Created by Collin Hemeltjen on 06/01/2020.
//  Copyright © 2020 Collin Hemeltjen. All rights reserved.
//

import ARKit

extension ViewController {

	func configureLight(){

		ambientLight.type = .ambient
		ambientLight.intensity = 40

		sceneView.scene.rootNode.light = ambientLight
		sceneView.autoenablesDefaultLighting = false
	}

	func changeLightConditions(to lightEstimate: ARLightEstimate){
		let ambientLightEstimate = lightEstimate.ambientIntensity
		let ambientColourTemperature = lightEstimate.ambientColorTemperature

//		if ambientLightEstimate < 100 { print("Lighting Is Too Dark") }

		ambientLight.intensity = ambientLightEstimate
		ambientLight.temperature = ambientColourTemperature
	}
}
