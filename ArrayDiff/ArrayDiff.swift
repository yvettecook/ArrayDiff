
import Foundation

public struct ArrayDiff {
	static var debugLogging = false
	
	/// The indexes in the old array of the items that were kept
	public let commonIndexes: IndexSet
	/// The indexes in the old array of the items that were removed
	public let removedIndexes: IndexSet
	/// The indexes in the new array of the items that were inserted
	public let insertedIndexes: IndexSet
	
	/// Returns nil if the item was inserted
	public func oldIndexForNewIndex(_ index: Int) -> Int? {
		if insertedIndexes.contains(index) { return nil }
		
		var result = index
		result -= insertedIndexes.count(in: NSMakeRange(0, index).toRange()!)
		result += removedIndexes.count(in: NSMakeRange(0, result + 1).toRange()!)
		return result
	}
	
	/// Returns nil if the item was deleted
	public func newIndexForOldIndex(_ index: Int) -> Int? {
		if removedIndexes.contains(index) { return nil }
		
		var result = index
		let deletedBefore = removedIndexes.count(in: NSMakeRange(0, index).toRange()!)
		result -= deletedBefore
		var insertedAtOrBefore = 0
		for i in insertedIndexes {
			if i <= result  {
				insertedAtOrBefore += 1
				result += 1
			} else {
				break
			}
		}
		if ArrayDiff.debugLogging {
			print("***Old -> New\n Removed \(removedIndexes)\n Inserted \(insertedIndexes)\n \(index) - \(deletedBefore) + \(insertedAtOrBefore) = \(result)\n")
		}
		
		return result
	}
    
    /**
     Returns true iff there are no changes to the items in this diff
     */
    public var isEmpty: Bool {
        return removedIndexes.count == 0 && insertedIndexes.count == 0
    }
}

public extension Array {
	
	public func diff(_ other: Array<Element>, elementsAreEqual: ((Element, Element) -> Bool)) -> ArrayDiff {
		var lengths: [[Int]] = Array<Array<Int>>(
			repeating: Array<Int>(
				repeating: 0,
				count: other.count + 1),
			count: count + 1
		)
		
		for i in (0...count).reversed() {
			for j in (0...other.count).reversed() {
				if i == count || j == other.count {
					lengths[i][j] = 0
				} else if elementsAreEqual(self[i], other[j]) {
					lengths[i][j] = 1 + lengths[i+1][j+1]
				} else {
					lengths[i][j] = Swift.max(lengths[i+1][j], lengths[i][j+1])
				}
			}
		}
		var commonIndexes = IndexSet()
		var i = 0, j = 0

		while i < count && j < other.count {
			if elementsAreEqual(self[i], other[j]) {
				commonIndexes.insert(i)
				i += 1
				j += 1
			} else if lengths[i+1][j] >= lengths[i][j+1] {
				i += 1
			} else {
				j += 1
			}
		}
    
    var removedIndexes = IndexSet(integersIn: 0..<count)
    commonIndexes.forEach {
      removedIndexes.remove($0)
    }
		
		let commonObjects = self[commonIndexes]
		var addedIndexes = IndexSet()
		i = 0
		j = 0
		
		while i < commonObjects.count || j < other.count {
			if i < commonObjects.count && j < other.count && elementsAreEqual (commonObjects[i], other[j]) {
				i += 1
				j += 1
			} else {
				addedIndexes.insert(j)
				j += 1
			}
		}
		
		return ArrayDiff(commonIndexes: commonIndexes, removedIndexes: removedIndexes, insertedIndexes: addedIndexes)
	}
}

public extension Array where Element: Equatable {
	public func diff(_ other: Array<Element>) -> ArrayDiff {
		return self.diff(other, elementsAreEqual: { $0 == $1 })
	}
}
