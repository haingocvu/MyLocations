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
	
	//for getting geo
	let locationManager = CLLocationManager()
	var location: CLLocation?
	var updatingLocation = false
	var lastLocationError: Error?
	var timer: Timer?
	
	//for reverse geo
	let geocoder = CLGeocoder()
	var placeMark: CLPlacemark?
	var performingReverseGeocoding = false
	var lastGeocodingError: Error?
	
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

	//MARK:- life cycles
	override func viewDidLoad() {
		super.viewDidLoad()
		updateLabels()
	}
	
	//hide the navagation bar when enter current location screen
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(true)
		navigationController?.isNavigationBarHidden = true
	}
	
	//show the navigation controller when exiting current location screen
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(true)
		navigationController?.isNavigationBarHidden = false
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
		//calculating the distance of two locations.
		//we'll use the distance to stop the location manager if we can't get the better location. (in case of ipod)
		//the first time. it'll be greatestFiniteMagnitude
		var distance = CLLocationDistance(Double.greatestFiniteMagnitude)
		//the second times and ...it'll be
		if let location = location {
			distance = location.distance(from: newLocation)
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
				//force reversing geocoding in case we get the final location and
				//and it's different from the previous location.
				if distance > 0 {
					performingReverseGeocoding = false
				}
			}
			updateLabels()
			//reversing geocoding when receiving a valid geo
			if !performingReverseGeocoding {
				print("Going to geocode")
				performingReverseGeocoding = true
				geocoder.reverseGeocodeLocation(location!) { placemarks, error in
					self.lastGeocodingError = error
					//if there's no error and the unwrapped placemarks array is not empty
					if error == nil, let p = placemarks, !p.isEmpty {
						self.placeMark = p.last!
					} else {
						self.placeMark = nil
					}
					self.performingReverseGeocoding = false
					self.updateLabels()
				}
			}
			//If the coordinate from this reading is not significantly different from the previous reading and it
			//has been more than 10 seconds since you’ve received that original reading, then it’s a good point to
			//hang up your hat and stop.
		} else if distance < 1 {
			let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
			if timeInterval > 10 {
				print("***Force done!")
				stoplocationManager()
				updateLabels()
			}
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
			//for reversing geocoding result
			if let placemark = placeMark {
				currentLocationView.addressLabel.text = string(from: placemark)
			} else if performingReverseGeocoding {
				currentLocationView.addressLabel.text = "Searching for address..."
			} else if lastGeocodingError != nil {
				currentLocationView.addressLabel.text = "Error Finding Address"
			} else {
				currentLocationView.addressLabel.text = "No Address Found"
			}
		} else {
			//can not get location
			currentLocationView.latitudeLabel.text = ""
			currentLocationView.longitudeLabel.text = ""
			currentLocationView.addressLabel.text = ""
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
			//schedule timer
			//A selector is the term that Objective-C uses to describe the name of a method,
			//and the #selector() syntax is how you create a selector in Swift.
			timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(didTimeOut), userInfo: nil, repeats: false)
		}
	}
	
	func stoplocationManager() {
		if updatingLocation {
			locationManager.stopUpdatingLocation()
			locationManager.delegate = nil
			updatingLocation = false
			//stop timer
			if let timer = timer {
				timer.invalidate()
			}
		}
	}
	
	func configureGetButton() {
		if updatingLocation {
			currentLocationView.getButton.setTitle("Stop", for: .normal)
		} else {
			currentLocationView.getButton.setTitle("Get My Location", for: .normal)
		}
	}
	
	func string(from placemark: CLPlacemark) -> String {
		//line 1
		var line1 = ""
		//house number.
		if let s = placeMark?.subThoroughfare {
			line1 += s + " "
		}
		//street name
		if let s = placeMark?.thoroughfare {
			line1 += s
		}
		//line 2
		var line2 = ""
		//the city
		if let s = placeMark?.locality {
			line2 += s + " "
		}
		//the state or province
		if let s = placeMark?.administrativeArea {
			line2 += s + " "
		}
		//zip code
		if let s = placeMark?.postalCode {
			line2 += s
		}
		return line1 + "\n" + line2
	}
	
	//So, when you use #selector to identify a method to call,
	//that method has to be accessible not only from Swift, but from Objective-C as well.
	//The @objc attribute allows you to identify a method
	//(or class, or property, or even enumeration) as being accessible from Objective-C.
	@objc func didTimeOut() {
		print("***Time Out")
		if location == nil {
			stoplocationManager()
			lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
			updateLabels()
		}
	}
	
	//Prepare for segue
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "TagLocation" {
			let controller = segue.destination as! LocationDetailViewController
			controller.coordinate = location!.coordinate
			controller.placemark = placeMark
		}
	}
}

