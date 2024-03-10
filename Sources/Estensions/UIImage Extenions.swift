//
//  File.swift
//  
//
//  Created by Daniel Zanchi on 20/05/22.
//

#if canImport(UIKit)
import SwiftUI

extension UIImage {
    
    public func resize(to newSize: CGSize, scale: CGFloat? = nil, quality: CGInterpolationQuality = .default) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale ?? self.scale
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let image = renderer.image { context in
            context.cgContext.interpolationQuality = quality
            self.draw(in: CGRect.init(origin: CGPoint.zero, size: newSize))
        }
        return image
    }
    
    public func getNewSize(withLongestLenghtOf longest: CGFloat) -> CGSize {
        if longest > self.size.width && longest > self.size.height {
            return self.size
        }
        
        var factor: CGFloat
        if self.size.width > self.size.height {
            factor = longest / self.size.width
        } else {
            factor = longest / self.size.height
        }
        
        let newWidth = factor * self.size.width
        let newHeight = factor * self.size.height
        
        let newSize = CGSize(width: Int(newWidth), height: Int(newHeight))
        return newSize
    }
    
    public func resizedImage(withLongestLenghtOf longest: CGFloat, scale: CGFloat? = nil, quality: CGInterpolationQuality = .default) -> UIImage {
		guard longest < max(self.size.height, self.size.width) else { return self }
        let newSize = getNewSize(withLongestLenghtOf: longest)
        
        return resize(to: newSize, scale: scale, quality: quality)
    }
    
}
#endif


#if canImport(AppKit)
import AppKit

extension NSImage {
	public func resize(to newSize: CGSize, scale: CGFloat? = nil, quality: CGInterpolationQuality = .default) -> NSImage? {
		let newSize = NSSize(width: newSize.width, height: newSize.height)
		
		guard let bitmapRep = NSBitmapImageRep(
			bitmapDataPlanes: nil,
			pixelsWide: Int(newSize.width),
			pixelsHigh: Int(newSize.height),
			bitsPerSample: 8,
			samplesPerPixel: 4,
			hasAlpha: true,
			isPlanar: false,
			colorSpaceName: .calibratedRGB,
			bytesPerRow: 0,
			bitsPerPixel: 0
		) else {
			return nil
		}
		
		bitmapRep.size = newSize
		
		NSGraphicsContext.saveGraphicsState()
		NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
		draw(in: NSRect(origin: .zero, size: newSize), from: .zero, operation: .copy, fraction: 1.0)
		NSGraphicsContext.restoreGraphicsState()
		
		let resizedImage = NSImage(size: newSize)
		
		resizedImage.addRepresentation(bitmapRep)
		return resizedImage
	}
	
	public func getNewSize(withLongestLenghtOf longest: CGFloat) -> CGSize {
		if longest > self.size.width && longest > self.size.height {
			return self.size
		}
		
		var factor: CGFloat
		if self.size.width > self.size.height {
			factor = longest / self.size.width
		} else {
			factor = longest / self.size.height
		}
		
		let newWidth = factor * self.size.width
		let newHeight = factor * self.size.height
		
		let newSize = CGSize(width: Int(newWidth), height: Int(newHeight))
		return newSize
	}
	
	public func getJpgData(compression: Float = 1) -> Data {
		let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil)!
		let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
		let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [.progressive: true, .compressionFactor: compression])!
		return jpegData
	}
	
	public func getPNGData() -> Data {
		let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil)!
		let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
		let pngData = bitmapRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:])!
		return pngData
	}
}
#endif
