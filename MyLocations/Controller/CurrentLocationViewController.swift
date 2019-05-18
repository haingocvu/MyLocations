//
//  FirstViewController.swift
//  MyLocations
//
//  Created by Hai Vu on 5/12/19.
//  Copyright © 2019 Hai Vu. All rights reserved.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
	
	let locationManager = CLLocationManager()
	var location: CLLocation?
	var updatingLocation = false
	var lastLocationError: Error?
	
	public var currentLocationView: CurrentLocationView! {
		guard isViewLoaded else {
			return nil
		}
		return (view as! CurrentLocationView)
	}
	
	//MARK:- Actions
	@IBAction func getLocation() {
		//do something here
		let authStatus = CLLocationManager.authorizationStatus()
		if authStatus == .notDetermined {
			locationManager.requestWhenInUseAuthorization()
			return
		}
		if authStatus == .denied || authStatus == .restricted {
			showLocationServicesDeniedAlert()
			return
		}
		//if uodating then stop
		//if not then start
		if updatingLocation {
			stoplocationManager()
		} else {
			lastLocationError = nil
			location = nil
			startLocationManager()
		}
		//first will be searching message, right?
		updateLabels()
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		updateLabels()
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("didFailWithError: \(error.localizedDescription)")
		//location unknown is a minor error, just waiting for location to update new location
		if (error as NSError).code == CLError.locationUnknown.rawValue {
			return
		}
		//handle fatal
		lastLocationError = error
		stoplocationManager()
		updateLabels()
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		let newLocation = locations.last!
		print("didUpdateLocation: \(newLocation)")
		//ignore cached location. (from 5s ago)
		if newLocation.timestamp.timeIntervalSinceNow < -5 {
			return
		}
		//ignore the location that whose horizontal accuracy is less than 5
		if newLocation.horizontalAccuracy < 0 {
			return
		}
		//location == nil means this is a very first location you're receiving
		//NOTE: the larger accuracy value means less accurate
		if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
			//receiving a valid location
			location = newLocation
			lastLocationError = nil
			//check accuracy
			if location!.horizontalAccuracy <= locationManager.desiredAccuracy {
				print("we've done!")
				stoplocationManager()
			}
			updateLabels()
		}
	}
	
	func showLocationServicesDeniedAlert() {
		let alert = UIAlertController(
			title: "Location services disabled",
			message: "Please enable location services for this app in settings.",
			preferredStyle: .alert)
		let okAction = UIAlertAction(
			title: "OK",
			style: .default,
			handler: nil)
		alert.addAction(okAction)
		present(alert, animated: true, completion: nil)
	}
	
	func updateLabels() {
		//get location successfully
		if let location = location {
			currentLocationView.latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
			currentLocationView.longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
			currentLocationView.messageLabel.text = ""
			currentLocationView.tagButton.isHidden = false
		} else {
			//can not get location
			currentLocationView.latitudeLabel.text = ""
			currentLocationView.longitudeLabel.text = ""
			var statusMessage: String
			if let error = lastLocationError as NSError? {
				if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
					statusMessage = "Location Services Disabled"
				} else {
					statusMessage = "Error getting Location"
				}
			} else if !CLLocationManager.locationServicesEnabled() {
				statusMessage = "Location Services Disabled"
			} else if updatingLocation {
				statusMessage = "Searching"
			} else {
				statusMessage = "Tap 'Get My Location' to Start"
			}
			currentLocationView.messageLabel.text = statusMessage
			currentLocationView.tagButton.isHidden = true
		}
		//change the title of getButton to show the user what's happen
		configureGetButton()
	}
	
	func startLocationManager() {
		if CLLocationManager.locationServicesEnabled() {
			locationManager.delegate = self
			locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
			locationManager.startUpdatingLocation()
			updatingLocation = true
		}
	}
	
	func stoplocationManager() {
		if updatingLocation {
			locationManager.stopUpdatingLocation()
			locationManager.delegate = nil
			updatingLocation = false
		}
	}
	
	func configureGetButton() {
		if updatingLocation {
			currentLocationView.getButton.setTitle("Stop", for: .normal)
		} else {
			currentLocationView.getButton.setTitle("Get My Location", for: .normal)
		}
	}
}

