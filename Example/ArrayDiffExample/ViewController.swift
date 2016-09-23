//
//  ViewController.swift
//  ArrayDiffExample
//
//  Created by Adlai Holler on 10/1/15.
//  Copyright © 2015 Adlai Holler. All rights reserved.
//

import UIKit
import ArrayDiff

private let cellID = "cellID"

class ViewController: UITableViewController {
	let dataSource = ThrashingDataSource()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		title = "ArrayDiff Demo"
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "+100", style: .plain, target: self, action: #selector(ViewController.updateTapped))
		dataSource.registerReusableViewsWithTableView(tableView)
		tableView?.dataSource = dataSource
	}
	
	@objc fileprivate func updateTapped() {
		for _ in 0..<100 {
			dataSource.enqueueRandomUpdate(tableView, completion: { dataSource in
				let operationCount = dataSource.updateQueue.operationCount
				self.title = operationCount > 0 ? String(operationCount) : "ArrayDiff Demo"
			})
		}
	}
	
}

private func createRandomSections(_ count: Int) -> [BasicSection<String>] {
	return (0..<count).map { _ in createRandomSection(20) }
}

private func createRandomSection(_ count: Int) -> BasicSection<String> {
	return BasicSection(name: .random(), items: createRandomItems(count))
}

private func createRandomItems(_ count: Int) -> [String] {
	return (0..<count).map { _ in .random() }
}

final class ThrashingDataSource: NSObject, UITableViewDataSource {
	// This is only modified on the update queue
	var data: [BasicSection<String>]

	static var updateLogging = false
	let updateQueue: OperationQueue
	
	// The probability of each incremental update.
	var fickleness: Float = 0.1
	
	override init() {
		updateQueue = OperationQueue()
		updateQueue.maxConcurrentOperationCount = 1
		updateQueue.qualityOfService = .userInitiated
		
		let initialSectionCount = 5
		data = createRandomSections(initialSectionCount)
		super.init()
		updateQueue.name = "\(self).updateQueue"
	}
	
	func enqueueRandomUpdate(_ tableView: UITableView, completion: @escaping ((ThrashingDataSource) -> Void)) {
		updateQueue.addOperation {
			self.executeRandomUpdate(tableView)
			OperationQueue.main.addOperation {
				completion(self)
			}
		}
	}
	
	fileprivate func executeRandomUpdate(_ tableView: UITableView) {
		if ThrashingDataSource.updateLogging {
			print("Data before update: \(data.nestedDescription)")
		}
		
		var newData = data
		
		let minimumSectionCount = 3
		let minimumItemCount = 5
		
		let _deletedItems: [IndexSet] = newData.enumerated().map { sectionIndex, sectionInfo in
			if sectionInfo.items.count >= minimumItemCount {
				let indexSet = IndexSet.randomIndexesInRange(0..<sectionInfo.items.count, probability: fickleness)
				newData[sectionIndex].items.removeAtIndexes(indexSet)
				return indexSet
			} else {
				return NSIndexSet() as IndexSet
			}
		}
		
		let _deletedSections: IndexSet
		if newData.count >= minimumSectionCount {
			_deletedSections = IndexSet.randomIndexesInRange(0..<newData.count, probability: fickleness)
			newData.removeAtIndexes(_deletedSections)
		} else {
			_deletedSections = IndexSet()
		}
		
		let _insertedSections = IndexSet.randomIndexesInRange(0..<newData.count, probability: fickleness)
		let newSections = createRandomSections(_insertedSections.count)
		newData.insertElements(newSections, atIndexes: _insertedSections)
		for (i, index) in _insertedSections.enumerated() {
			assert(newData[index] == newSections[i])
		}
		
		let _insertedItems: [IndexSet] = newData.enumerated().map { sectionIndex, sectionInfo in
			let indexSet = IndexSet.randomIndexesInRange(0..<sectionInfo.items.count, probability: fickleness)
			let newItems = createRandomItems(indexSet.count)
			newData[sectionIndex].items.insertElements(newItems, atIndexes: indexSet)
			assert(newData[sectionIndex].items[indexSet] == newItems)
			return indexSet
		}
		
		if ThrashingDataSource.updateLogging {
			print("Data after update: \(newData.nestedDescription)")
		}
		let nestedDiff = data.diffNested(newData)
		
		// Assert that the diffing worked
		assert(_insertedSections == nestedDiff.sectionsDiff.insertedIndexes)
		assert(_deletedSections == nestedDiff.sectionsDiff.removedIndexes)
		for (oldSection, diffOrNil) in nestedDiff.itemDiffs.enumerated() {
			if let diff = diffOrNil {
				assert(_deletedItems[oldSection] == diff.removedIndexes)
				if let newSection = nestedDiff.sectionsDiff.newIndexForOldIndex(oldSection) {
					assert(_insertedItems[newSection] == diff.insertedIndexes)
				} else {
					assertionFailure("Found an item diff for a section that was removed. Wat.")
				}
			}
		}
		
		DispatchQueue.main.sync {
			tableView.beginUpdates()
			self.data = newData
			nestedDiff.applyToTableView(tableView, rowAnimation: .automatic)
			tableView.endUpdates()
		}
	}
	
	func registerReusableViewsWithTableView(_ tableView: UITableView) {
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return data[section].name
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
		cell.textLabel?.text = data[indexPath.section].items[indexPath.item]
		return cell
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return data[section].items.count
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return data.count
	}
}
