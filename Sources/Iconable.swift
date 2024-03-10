//
//  Iconable.swift
//  AestheticManager
//
//  Created by Antonio Martelli on 21/11/23.
//

import FirebaseFirestore
import FirebaseStorage


protocol Iconable: Firestonable {
	var imageId: String { get set }
}

extension Iconable {
	
	var thumbId: String {
		"thumb-" + imageId
	}
	
	func getImageUrl() async throws -> URL? {
		if !imageId.isEmpty {
			return try await getStorage(fromKey: imageId)
		} else {
			return nil
		}
	}
	
	func getImageMetadata() async throws -> StorageMetadata? {
		if !imageId.isEmpty {
			return try await getFileMetadata(fromKey: imageId)
		} else {
			return nil
		}
	}
	
	func getThumbCached() async throws -> NSImage? {
		try await getImage(with: thumbId)
	}
	
	func getThumbUrl() async throws -> URL? {
		if !thumbId.isEmpty {
			return try await getStorage(fromKey: thumbId)
		} else {
			return nil
		}
	}
	
	func getThumbMetadata() async throws -> StorageMetadata? {
		if !thumbId.isEmpty {
			return try await getFileMetadata(fromKey: thumbId)
		} else {
			return nil
		}
	}
	
	func getMetadata(with key: String) async throws -> StorageMetadata? {
		if !thumbId.isEmpty {
			return try await getFileMetadata(fromKey: key)
		} else {
			return nil
		}
	}
}
