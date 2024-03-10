//
//  Rankable.swift
//  AestheticManager
//
//  Created by Antonio Martelli on 23/11/23.
//

import Foundation

protocol Rankable: Firestonable {
	var ranking: [String: Int] { get set }
}

extension Rankable {
	mutating func updateRanking(forKey key: String, value: Int) {
		ranking[key] = value
	}
	
	static func sortByRanking(data: [any Rankable], id: String) -> [Any] {
		data.sorted { (struct1, struct2) -> Bool in
			if let int1 = struct1.ranking[id], let int2 = struct2.ranking[id] {
				return int1 < int2
			}
			return false
		}
	}
}
