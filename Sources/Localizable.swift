//
//  Localizable.swift
//  trace table manager
//
//  Created by Antonio Martelli on 28/11/23.
//

import Foundation

// MARK: Localization -

enum Localization: String, CaseIterable {
	case it
	case en
	case es
}



// MARK: - Localizable

protocol Localizable: Firestonable {
	var names: [Localization.RawValue : String] { get set }
}


// MARK: - Localizable Extension

extension Localizable {
	var name: String {
		let locale = Locale.current.language.languageCode?.identifier ?? Localization.en.rawValue
		
		let name = names[locale]
		
		if let name {
			return name
		} else if let name = names[Localization.en.rawValue] {
			return name
		} else {
			//			DZError("Couldn't find a localization for the current Wallpaper")
			return ""
		}
	}
	
	mutating func addName(_ localization: Localization, value: String) {
		names[localization.rawValue] = value
	}
	
	mutating func addDefaultName(_ value: String) {
		for item in Localization.allCases {
			names[item.rawValue] = value
		}
	}
	
	mutating func removeAllNames() {
		names = [:]
	}
}
