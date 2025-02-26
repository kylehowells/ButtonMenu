//
//  UIScrollView+ScrollToRect.swift
//  ToolKit
//
//  Created by Simeon on 20/9/17.
//  Copyright © 2017 Two Lives Left. All rights reserved.
//

import Foundation
import UIKit

// NOTE: I realise there's a built in method on UIScrollView for this...
// ...but it often just doesn't work and I haven't looked into why.

@objc public extension UIScrollView {
	
	@objc func scrollOffset(for rect: CGRect) -> CGPoint {
		// Compute the visible area of the scroll view
		var visibleArea = self.convert(self.bounds, to: self)
		
		visibleArea.size.height -= (self.contentInset.top + self.contentInset.bottom)
		visibleArea.origin.y += self.contentInset.top
		
		visibleArea.size.width -= (self.contentInset.left + self.contentInset.right)
		visibleArea.origin.x += self.contentInset.left
		
		let intersection = rect.intersection(visibleArea)
		var offset = CGPoint.zero
		
		if intersection.isNull {
			
			if rect.origin.y < visibleArea.minY {
				//Push from top
				offset.y = rect.minY - visibleArea.minY
			}
			else if rect.origin.y > visibleArea.maxY {
				//Push from bottom
				offset.y = rect.maxY - visibleArea.maxY
			}
			
			if rect.origin.x < visibleArea.minX {
				//Push from left
				offset.x = rect.minX - visibleArea.minX
			}
			else if rect.origin.x > visibleArea.maxX {
				//Push from right
				offset.x = rect.maxX - visibleArea.maxX
			}
			
		} else {
			
			if rect.maxY > visibleArea.maxY {
				offset.y = rect.size.height - intersection.size.height
			} else if rect.minY < visibleArea.minY {
				offset.y = intersection.size.height - rect.size.height
			}
			
			if rect.maxX > visibleArea.maxX {
				offset.x = rect.size.width - intersection.size.width
			}
			else if rect.minX < visibleArea.minX {
				offset.x = intersection.size.width - rect.size.width
			}
		}
		
		let newOffset = CGPoint(
			x: self.contentOffset.x + offset.x,
			y: self.contentOffset.y + offset.y
		)
		
		return newOffset
	}
	
	@objc func scroll(toVisible rect: CGRect, animated: Bool) {
		let newOffset = self.scrollOffset(for: rect)
		
		self.setContentOffset(newOffset, animated: animated)
	}
}
