//
//  Categorizable.swift
//  trace table manager
//
//  Created by Antonio Martelli on 29/11/23.
//

import Foundation

protocol Categorizable: Firestonable {
	var categoryIds: [String] { get set }
}

extension Categorizable {
	static func getAll(withCategoryId categoryId: String) async throws -> [Self]? {
		let query = Self.reference.whereField("categoryIds", arrayContains: categoryId)
		return try await get(withQuery: query)
	}
	
	func getCategories<T: Firestonable>() async throws -> [T]? {
		if !categoryIds.isEmpty {
			return try await T.get(withIds: categoryIds)
		} else {
			return []
		}
	}
}
