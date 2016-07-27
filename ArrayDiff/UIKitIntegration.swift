//
//  UIKitIntegration.swift
//  ArrayDiff
//
//  Created by Adlai Holler on 10/3/15.
//  Copyright © 2015 Adlai Holler. All rights reserved.
//

import UIKit

public extension ArrayDiff {
	/**
	Apply this diff to items in the given section of the collection view.

	This should be called on the main thread inside collectionView.performBatchUpdates
	*/
	public func applyToItemsInCollectionView(_ collectionView: UICollectionView, section: Int) {
		assert(Thread.isMainThread)
		// Apply updates in safe order for good measure.
		// Deletes, descending
		// Inserts, ascending
		collectionView.deleteItems(at: removedIndexes.indexPathsInSection(section, ascending: false))
		collectionView.insertItems(at: insertedIndexes.indexPathsInSection(section))
	}

	/**
	Apply this diff to rows in the given section of the table view.

	This should be called on the main thread between tableView.beginUpdates and tableView.endUpdates
	*/
	public func applyToRowsInTableView(_ tableView: UITableView, section: Int, rowAnimation: UITableViewRowAnimation) {
		assert(Thread.isMainThread)
		// Apply updates in safe order for good measure.
		// Deletes, descending
		// Inserts, ascending
		tableView.deleteRows(at: removedIndexes.indexPathsInSection(section, ascending: false), with: rowAnimation)
		tableView.insertRows(at: insertedIndexes.indexPathsInSection(section), with: rowAnimation)
	}

	/**
	Apply this diff to the sections of the table view.

	This should be called on the main thread between tableView.beginUpdates and tableView.endUpdates
	*/
	public func applyToSectionsInTableView(_ tableView: UITableView, rowAnimation: UITableViewRowAnimation) {
		assert(Thread.isMainThread)
		// Apply updates in safe order for good measure.
		// Deletes, descending
		// Inserts, ascending
		if removedIndexes.count > 0 {
			tableView.deleteSections(removedIndexes as IndexSet, with: rowAnimation)
		}
		if insertedIndexes.count > 0 {
			tableView.insertSections(insertedIndexes as IndexSet, with: rowAnimation)
		}
	}

	/**
	Apply this diff to the sections of the collection view.

	This should be called on the main thread inside collectionView.performBatchUpdates
	*/
	public func applyToSectionsInCollectionView(_ collectionView: UICollectionView) {
		assert(Thread.isMainThread)
		// Apply updates in safe order for good measure.
		// Deletes, descending
		// Inserts, ascending
		if removedIndexes.count > 0 {
			collectionView.deleteSections(removedIndexes as IndexSet)
		}
		if insertedIndexes.count > 0 {
			collectionView.insertSections(insertedIndexes as IndexSet)
		}
	}
}

public extension NestedDiff {
	/**
	Apply this nested diff to the given table view.
	
	This should be called on the main thread between tableView.beginUpdates and tableView.endUpdates
	*/
	public func applyToTableView(_ tableView: UITableView, rowAnimation: UITableViewRowAnimation) {
		assert(Thread.isMainThread)
		// Apply updates in safe order for good measure.
		// Item deletes, descending
		// Section deletes
		// Section inserts
		// Item inserts, ascending
		for (oldSection, diffOrNil) in itemDiffs.enumerated() {
			if let diff = diffOrNil {
				tableView.deleteRows(at: diff.removedIndexes.indexPathsInSection(oldSection, ascending: false), with: rowAnimation)
			}
		}
		sectionsDiff.applyToSectionsInTableView(tableView, rowAnimation: rowAnimation)
		for (oldSection, diffOrNil) in itemDiffs.enumerated() {
			if let diff = diffOrNil {
				if let newSection = sectionsDiff.newIndexForOldIndex(oldSection) {
					tableView.insertRows(at: diff.insertedIndexes.indexPathsInSection(newSection), with: rowAnimation)
				} else {
					assertionFailure("Found an item diff for a section that was removed. Wat.")
				}
			}
		}
	}
	
	/**
	Apply this nested diff to the given collection view.
	
	This should be called on the main thread inside collectionView.performBatchUpdates
	*/
	public func applyToCollectionView(_ collectionView: UICollectionView) {
		assert(Thread.isMainThread)
		// Apply updates in safe order for good measure. 
		// Item deletes, descending
		// Section deletes
		// Section inserts
		// Item inserts, ascending
		for (oldSection, diffOrNil) in itemDiffs.enumerated() {
			if let diff = diffOrNil {
				collectionView.deleteItems(at: diff.removedIndexes.indexPathsInSection(oldSection, ascending: false))
			}
		}
		sectionsDiff.applyToSectionsInCollectionView(collectionView)
		for (oldSection, diffOrNil) in itemDiffs.enumerated() {
			if let diff = diffOrNil {
				if let newSection = sectionsDiff.newIndexForOldIndex(oldSection) {
					collectionView.insertItems(at: diff.insertedIndexes.indexPathsInSection(newSection))
				} else {
					assertionFailure("Found an item diff for a section that was removed. Wat.")
				}
			}
		}
	}
}
