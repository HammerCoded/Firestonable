//
//  File.swift
//  
//
//  Created by Antonio Martelli on 09/03/24.
//

import OSLog
import FirebaseFirestore
import FirebaseStorage
import PINCache

//private struct FBTypeCheck {
//	enum TypeError: Error {
//		case invalidFirestoreType
//	}
//	
//	static func isSupportedType(_ value: Any) ->  Bool {
//		// Verifica se il valore è di uno dei tipi di dati supportati da Firestore
//		return value is String ||
//		value is Int || value is Int8 || value is Int16 || value is Int32 || value is Int64 ||
//		value is UInt || value is UInt8 || value is UInt16 || value is UInt32 || value is UInt64 ||
//		value is Float || value is Double ||
//		value is Bool ||
//		value is Date ||
//		value is [Any] ||
//		value is [String: Any] ||
//		value is GeoPoint ||
//		value is DocumentReference ||
//		value is NSNull
//	}
//}


public protocol Firestonable: Codable, Identifiable, Hashable, CustomStringConvertible {

	private let logger = Logger(subsystem: "Package", category: "Firestonable")
	
	init()
	var id: String { get }
	var createdAt: TimeInterval { get }
	var updatedAt: TimeInterval { get set }
	var isPublic: Bool { get set }
	
	
	// MARK: - func
	func create() async throws
	func delete() async throws
	static func getAll() async throws -> [Self]?
	
	
	/**
	 - Parsare enumeratori e restituire valori compatibili con firebase
	 es:
	 
	 func getDifferences(with compare: Self) -> [String: Any] {
		var dic = _getDifferences(with: compare)
		if let type = dic["type"] as? CustomType {
			dic["type"] = type.rawValue
		}
		return dic
	 }
	*/
	func getDifferences(with other: Self) -> [String: Any]
}

extension Firestonable {
	
	var description: String {
		describe(self)
	}
	
	mutating func updatedAtDateToNow() {
		updatedAt = Date().timeIntervalSince1970
	}
	
	
	// Mark: - Static func Firestore -
	
	static var reference: CollectionReference {
		Firestore.firestore().collection(String(describing: type(of: Self())))
	}
	
	static func get(withQuery query: Query) async throws -> [Self]? {
		let result = try await query.getDocuments()
		return result.documents.decode(as: Self.self)
	}
	
	static func getAll() async throws -> [Self]? {
		try await get(withQuery: reference)
	}
	
	static func get(withIds ids: [String]) async throws -> [Self]? {
		guard !ids.isEmpty else { return [] }
		let query = reference.whereField(FieldPath.documentID(), in: ids)
		return try await get(withQuery: query)
	}
	
	static func getAllPublic(flag: Bool = true) async throws -> [Self]? {
		try await get(withQuery: Self.reference.whereField("isPublic", isEqualTo: flag))
	}
	
	static func fetchData(ids: [String], orderByField: String, descending: Bool = true) async throws -> [Self]? {
		let query = reference
			.whereField("id", in: ids)
			.order(by: orderByField, descending: descending)
		
		return try await get(withQuery: query)
	}
	
	
	// MARK: - No static func Firestore -
	
	func get(withQuery query: Query) async throws -> [Self]? {
		try await Self.get(withQuery: query)
	}
	
	func create() async throws {
		guard let data = self.dictionary else { return }
		return try await Self.reference.document(self.id).setData(data)
	}
	
	func delete() async throws {
		try await Self.reference.document(id).delete()
	}
	
	// MARK: - Storage Metadata -
	func getFileMetadata(fromKey key: String) async throws -> StorageMetadata {
		try await Storage
			.storage()
			.reference()
			.child(baseChild(append: key))
			.getMetadata()
	}
	
	
	// Mark: - Storage func -
	
	func baseChild(append key: String) -> String {
		"\(type(of: self))/\(self.id)/\(key)"
	}
	
	func getStorage(fromKey key: String) async throws -> URL? {
		try await Storage
			.storage()
			.reference()
			.child(baseChild(append: key))
			.downloadURL()
	}
	
	func getStorageUrls(fromIds ids: [String]) async throws -> [URL] {
		var urls: [URL] = []
		for id in ids {
			do {
				let url = try await Storage
					.storage()
					.reference()
					.child(baseChild(append: id))
					.downloadURL()
				urls.append(url)
				
			} catch {
				logger.error("getStorageUrls error: \(error)")
			}
		}
		return urls
	}
	
	func uploadStorage(data: Data, key: String) async throws -> Bool {
		try await Storage
			.storage()
			.reference()
			.child(baseChild(append: key))
			.putDataAsync(data).isFile
	}
	
	func deleteStorage(key: String) async throws {
		try await Storage
			.storage()
			.reference()
			.child(baseChild(append: key))
			.delete()
	}
	
	func deleteStorageFolder() async throws {
		let folder = Storage
			.storage()
			.reference()
			.child(baseChild(append: ""))
		
		// List the files and subfolders in the folder
		let files = try await folder.listAll()
		
		// Delete all the files and subfolders in the folder
		for file in files.items {
			print("file.name: \(file.name)")
			try await file.delete()
		}
	}
	
	func upload(media: Media, onProgress: ((Progress?) -> Void)? = nil) async throws -> StorageMetadata {
		try await Storage
			.storage()
			.reference()
			.child(baseChild(append: media.id))
			.putFileAsync(from: media.url, metadata: nil) { progress in
				onProgress?(progress)
			}
	}
	
	func upload(data: Data, id: String, onProgress: ((Progress?) -> Void)? = nil) async throws -> StorageMetadata {
		try await Storage
			.storage()
			.reference()
			.child(baseChild(append: id))
			.putDataAsync(data, metadata: nil) { progress in
				onProgress?(progress)
			}
	}
	
	
	// MARK: - Updater func -
	
	func _getDifferences(with other: Self) -> [String: Any] {
		
		func processOptionalValues(in dictionary: [String: Any]) -> [String: Any] {
			
			// Funzione di supporto per svolgere gli opzionali
			func unwrap(_ value: Any) -> Any? {
				let mirror = Mirror(reflecting: value)
				
				if mirror.displayStyle == .optional {
					if mirror.children.count == 0 {
						// Il caso in cui l'opzionale è nil
						return nil
					} else {
						// Estrai il valore dall'opzionale
						return mirror.children.first?.value
					}
				}
				
				return value
			}
			
			var processedDictionary: [String: Any] = [:]

			for (key, value) in dictionary {
				// Verifica se il valore è un opzionale
				if let unwrappedValue = unwrap(value) {
					processedDictionary[key] = unwrappedValue
				} else {
					processedDictionary[key] = value
				}
			}

			return processedDictionary
		}
		
		var differences: [String: Any] = [:]

		let mirror = Mirror(reflecting: other)

		for (label, value) in mirror.children {
			if let label = label {
				let originalMirror = Mirror(reflecting: self)
				if let originalChild = originalMirror.children.first(where: { $0.label == label }) {
					let originalValue = originalChild.value as AnyObject
					let updatedValue = value as AnyObject

					// Check if either value is nil or both are nil
					if (originalValue.isEqual(nil) && updatedValue.isEqual(nil)) {
						continue
					}

					// Check if values are different when both are non-nil
					if originalValue.isEqual(nil) == false && updatedValue.isEqual(nil) == false && !originalValue.isEqual(updatedValue) {
						differences[label] = value
					} else if originalValue.isEqual(nil) != updatedValue.isEqual(nil) {
						// Check if one value is nil while the other is not
						differences[label] = value
					}
				}
			}
		}
		
		return processOptionalValues(in: differences)
	}
	
	func update(from other: Self) async throws {
		var other = other
		let differenceCheck = getDifferences(with: other)
		guard !differenceCheck.isEmpty else { return }
		other.updatedAt = Date().timeIntervalSince1970
		let differences = getDifferences(with: other)
		logger.info("differences: \(differences.description) update")
		try await Self.reference.document(self.id).updateData(differences)
	}
}


// MARK: - Thumbnail handler -

enum MediaUpload: Error {
	case noImageFromDate, resizedError
}

extension Firestonable {
	func uploadThumb(media: Media, longestLenghtOf lenght: CGFloat = 300, onProgress: ((Progress?) -> Void)? = nil) async throws -> StorageMetadata {
		do {
			let data = try Data(contentsOf: media.url)
			if let image = NSImage(data: data) {

				let thumbSize = image.getNewSize(withLongestLenghtOf: lenght)
				guard let jpgData = image.resize(to: thumbSize) else {
					throw MediaUpload.resizedError
				}

				do {
					return try await self.upload(data: jpgData.getJpgData(), id: media.thumbId) { progress in
						onProgress?(progress)
					}
				} catch {
					throw error
				}
			} else {
				throw MediaUpload.noImageFromDate
			}
		} catch {
			throw error
		}
	}
	
	func uploadThumb(image: NSImage, id: String, longestLenghtOf lenght: CGFloat = 300, onProgress: ((Progress?) -> Void)? = nil) async throws -> StorageMetadata {
		do {
			let thumbSize = image.getNewSize(withLongestLenghtOf: lenght)
			guard let jpgData = image.resize(to: thumbSize) else {
				throw MediaUpload.resizedError
			}

			do {
				return try await self.upload(data: jpgData.getJpgData(), id: id) { progress in
					onProgress?(progress)
				}
			} catch {
				throw error
			}
		} catch {
			throw error
		}
	}
}


// MARK: - Thumbnail handler -

enum ThumbType {
	case png, jpg
}

extension Firestonable {
	func uploadThumb(media: Media, type: ThumbType, longestLenghtOf lenght: CGFloat = 640, onProgress: ((Progress?) -> Void)? = nil) async throws -> StorageMetadata {
		do {
			let data = try Data(contentsOf: media.url)
			if let image = NSImage(data: data) {
				let thumbSize = image.getNewSize(withLongestLenghtOf: lenght)
				let thumbnailImage = image.resize(to: thumbSize)!
				var data: Data

				switch type {
				case .jpg:
					data = thumbnailImage.getJpgData(compression: 0.8)
				case .png:
					data = thumbnailImage.getPNGData()
				}

				do {
					return try await self.upload(data: data, id: media.thumbId) { progress in
						onProgress?(progress)
					}
				} catch {
					throw error
				}
			} else {
				throw MediaUpload.noImageFromDate
			}
		} catch {
			throw error
		}
	}
}

// MARK: - Utils
extension Firestonable {
	static func sort<T: Firestonable>(_ firestonables: [T], withIds ids: [String]) -> [T] {
		// Create a dictionary to map IDs to indices in arrayB
		let indexMap = Dictionary(uniqueKeysWithValues: ids.enumerated().map { ($1, $0) })

		// Sort wallpapers using the order defined by ids
		let result = firestonables.sorted { obj1, obj2 in
			if let index1 = indexMap[obj1.id], let index2 = indexMap[obj2.id] {
				return index1 < index2
			}
			// Handle the case where an ID is not present in arrayB
			return false
		}

		return result
	}
}


//MARK: -
extension Firestonable {
	func imageAt(_ url: URL) async throws -> NSImage {
		let (data, _) = try await URLSession.shared.data(from: url)
		guard let image = NSImage(data: data) else {
			throw NSError(domain: "InvalidImageData", code: 0, userInfo: nil)
		}
		return image
	}
	
	func getImage(with key: String) async throws -> NSImage? {
		guard !key.isEmpty else {
			return nil
		}

		if let result = await PINCache.shared.object(forKeyAsync: key).2 {
			return NSImage(data: (result as? Data) ?? Data())
		}

		guard let url = try await getStorage(fromKey: key) else {
			return nil
		}

		let image = try await imageAt(url)
		let data = image.getPNGData()
		await PINCache.shared.setObjectAsync(data, forKey: key)
		return image
	}
}
