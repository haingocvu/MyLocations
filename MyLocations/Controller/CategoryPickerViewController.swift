//
//  CategoryPickerViewController.swift
//  MyLocations
//
//  Created by Hai Vu on 5/26/19.
//  Copyright © 2019 Hai Vu. All rights reserved.
//

import UIKit

class CategoryPickerViewController: UITableViewController {
	
	//properties
	var selectedCategoryName = ""
	let categories = [
		"No Category",
		"Apple Store",
		"Bar",
		"BookStore",
		"Club",
		"Grocery Store",
		"Historic Building",
		"House",
		"Icecream Vendor",
		"Landmark",
		"Park"
	]
	var selectedIndexPath = IndexPath()
	
	//Life cycles
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.tableFooterView = UIView()
		for (index, category) in categories.enumerated() {
			if category == selectedCategoryName {
				selectedIndexPath = IndexPath(row: index, section: 0)
				break
			}
		}
	}
	
	//MARK:- table view datasource
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return categories.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		let category = categories[indexPath.row]
		cell.textLabel?.text = category
		if category == selectedCategoryName {
			cell.accessoryType = .checkmark
		} else {
			cell.accessoryType = .none
		}
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if selectedIndexPath.row != indexPath.row {
			if let newCell = tableView.cellForRow(at: indexPath) {
				newCell.accessoryType = .checkmark
			}
			if let oldCell = tableView.cellForRow(at: selectedIndexPath) {
				oldCell.accessoryType = .none
			}
			selectedIndexPath = indexPath
		}
	}
	
	//preapre for segue
	//in this case: unwind segue
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "PickedCategory" {
			let cell = sender as! UITableViewCell
			if let indexPath = tableView.indexPath(for: cell) {
				selectedCategoryName = categories[indexPath.row]
			}
		}
	}
}
