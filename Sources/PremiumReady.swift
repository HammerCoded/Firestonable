//
//  PremiumReady.swift
//  AestheticManager
//
//  Created by Antonio Martelli on 23/11/23.
//

import Foundation

protocol PremiumReady: Firestonable {
	var isPremium: Bool { get set }
}

extension PremiumReady {
	static func getAllPremium() async throws -> [Self]? {
		try await get(withQuery: Self.reference.whereField("isPremium", isEqualTo: true))
	}
}
