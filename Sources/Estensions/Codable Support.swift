//
//  Codable Support.swift
//  Firestonable
//
//  Created by Antonio Martelli on 28/11/23.
//

import Foundation

// MARK: - Json Format

private let logger = Logger(subsystem: "Codable Support", category: "Firestonable")

func describe(_ obj: Codable) -> String {
	
	enum DescribeError: Error {
		case encodingFaillure
	}
	
	do {
		let encoder = JSONEncoder()
		#if DEBUG
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
		#else
		encoder.outputFormatting = .sortedKeys
		#endif
		let data = try encoder.encode(obj)
		if let jsonString = String(data: data, encoding: .utf8) {
			return jsonString
		} else {
			logger.error("Error describe codable \(#function) object: \(obj)")
			return ""
		}
	} catch {
		logger.error("Error describe codable \(#function) object: \(obj) error: \(error)")
		return ""
	}
}
