
import UIKit

extension IndexSet {
	// Get a random index set in a range
	static func randomIndexesInRange(_ range: Range<Int>, probability: Float) -> IndexSet {
		var result = IndexSet()
		for i in range.lowerBound ..< range.upperBound {
			if Bool.random(probability) {
				result.insert(i)
			}
		}
		return result as IndexSet
	}
}

extension Bool {
	static var trueCount = 0
	static var totalCount = 0
	static func random(_ probability: Float) -> Bool {
		let result = arc4random_uniform(100) < UInt32(probability * 100)
		if result {
			trueCount += 1
		}
		totalCount += 1
		return result
	}
}

extension String {
	static func random() -> String {
		return UUID().uuidString
	}
}
