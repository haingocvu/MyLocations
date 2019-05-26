//
//  LocationDetailViewController.swift
//  MyLocations
//
//  Created by Hai Vu on 5/25/19.
//  Copyright © 2019 Hai Vu. All rights reserved.
//

import UIKit
import CoreLocation

class LocationDetailViewController: UITableViewController {
	//MARK:- Outlets
	@IBOutlet weak var descriptionTextView: UITextView!
	@IBOutlet weak var categoryLabel: UILabel!
	@IBOutlet weak var latitudeLabel: UILabel!
	@IBOutlet weak var longitudeLabel: UILabel!
	@IBOutlet weak var addressLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	
	//MARK:- Properties
	var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
	var placemark: CLPlacemark?
	lazy private var dateFormater: DateFormatter = {
		let dateFormater = DateFormatter()
		dateFormater.dateStyle = .medium
		dateFormater.timeStyle = .short
		print("created a day formater!")
		return dateFormater
	}()
	var categoryName = "No Category"
	
	//MARK:- Actions
	@IBAction func done() {
		//do later
		navigationController?.popViewController(animated: true)
	}
	
	@IBAction func cancel() {
		//do later
		navigationController?.popViewController(animated: true)
	}
	
	@IBAction func categoryPickerDidPickCategory(_ segue: UIStoryboardSegue) {
		let source = segue.source as! CategoryPickerViewController
		categoryName = source.selectedCategoryName
		categoryLabel.text = categoryName
	}
	
	//MARK:- Life Cycles
	override func viewDidLoad() {
		super.viewDidLoad()
		categoryLabel.text = categoryName
		descriptionTextView.text = ""
		latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
		longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
		if let placeMark = placemark {
			//update address label
			addressLabel.text = string(from: placeMark)
		} else {
			addressLabel.text = "No Address Found"
		}
		dateLabel.text = format(date: Date())
	}
	
	//MARK:- Helper methods
	func string(from placemark: CLPlacemark) -> String {
		var text = ""
		if let s = placemark.subThoroughfare {
			text += s + " "
		}
		if let s = placemark.thoroughfare {
			text += s + ", "
		}
		if let s = placemark.locality {
			text += s + ", "
		}
		if let s = placemark.administrativeArea {
			text += s + " "
		}
		if let s = placemark.postalCode {
			text += s + ", "
		}
		if let s = placemark.country {
			text += s
		}
		return text
	}
	
	func format(date: Date) -> String {
		return dateFormater.string(from: date)
	}
	
	//Prepare for segue
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "PickCategory" {
			let controller = segue.destination as! CategoryPickerViewController
			controller.selectedCategoryName = categoryName
		}
	}
}
