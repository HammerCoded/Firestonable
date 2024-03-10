//
//  Media.swift
//  trace table manager
//
//  Created by Antonio Martelli on 28/11/23.
//

import Foundation

struct Media: Identifiable, Hashable {
	
	let id: String
	let url: URL
	
	var thumbId: String {
		"thumb-" + id
	}
	
	internal init(url: URL) {
		self.url = url
		let uuid = UUID().uuidString
		self.id = uuid
	}
}
