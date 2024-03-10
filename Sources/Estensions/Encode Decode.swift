//
//  Encode.Decode.swift
//  Firestonable
//
//  Created by Martelli Antonio on 09/03/24.
//

import OSLog
import FirebaseFirestore

private let logger = Logger(subsystem: "Package", category: "Firestonable")

public extension Encodable {
	public var dictionary: [String: Any]? {
		do {
			let encoder = JSONEncoder()
			let data = try encoder.encode(self)
			if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
				return dict
			}
		} catch {
			logger.error("Error creating the dictionary • error: \(error)")
		}
		return nil
	}
}

extension DocumentSnapshot {
	func decode<T: Decodable>(as type: T.Type ) -> T? {
		do {
			guard let data = data() else { return nil }
			let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
			let item = try JSONDecoder().decode(T.self, from: jsonData)
			return item
		} catch {
			logger.error("Error decoding object • error: \(error)")
			return nil
		}
	}
}

public extension Array where Element: QueryDocumentSnapshot  {
	public func decode<T: Decodable>(as type: T.Type) -> [T]? {
		do {
			var items: [T] = []
			for document in self {
				let jsonData = try JSONSerialization.data(withJSONObject: document.data(), options: [])
				let item = try JSONDecoder().decode(T.self, from: jsonData)
				items.append(item)
			}
			return items
		} catch {
			logger.error("Error decoding object • error: \(error)")
			return nil
		}
	}
}
