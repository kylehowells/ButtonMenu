//
//  MenuItem.swift
//  Menus
//
//  Created by Simeon on 6/6/18.
//  Copyright © 2018 Two Lives Left. All rights reserved.
//

import UIKit

public protocol MenuItem {
	typealias MenuViewType = (UIView & MenuThemeable & MenuItemView)
	
	var view: MenuViewType { get }
	
	func performAction()
}


// MARK: - SeparatorMenuItem

public struct SeparatorMenuItem: Equatable, MenuItem {
	
	public var view: MenuItem.MenuViewType {
		return SeparatorMenuItemView()
	}
	
	public init() { }
	
	public static func == (lhs: SeparatorMenuItem, rhs: SeparatorMenuItem) -> Bool {
		return true
	}
	
	public func performAction() {}
}


// MARK: - UIKeyModifierFlags

public extension UIKeyModifierFlags {
	var symbols: [String] {
		var result: [String] = []
		
		if self.contains(.alternate) {
			result.append("⌥")
		}
		
		if self.contains(.control) {
			result.append("⌃")
		}
		
		if self.contains(.shift) {
			result.append("⇧")
		}
		
		if self.contains(.command) {
			result.append("⌘")
		}
		
		return result
	}
}


// MARK: - ShortcutMenuItem

public struct ShortcutMenuItem: Equatable, MenuItem {
	
	public static var displayShortcuts: Bool = true
	
	public struct Shortcut: Equatable {
		public let modifiers: UIKeyModifierFlags
		public let key: String
		public let title: String
	}
	
	public var action: () -> Void = {}
	
	public let name: String
	public let shortcut: Shortcut?
	
	public init(name: String, shortcut: (UIKeyModifierFlags, String)? = nil, action: @escaping () -> Void) {
		self.name = name
		self.action = action
		
		if let (modifiers, key) = shortcut {
			self.shortcut = Shortcut(modifiers: modifiers, key: key, title: name)
		} else {
			self.shortcut = nil
		}
	}
	
	public var view: MenuItem.MenuViewType {
		return ShortcutMenuItemView(item: self)
	}
	
	public static func == (lhs: ShortcutMenuItem, rhs: ShortcutMenuItem) -> Bool {
		return lhs.name == rhs.name && lhs.shortcut == rhs.shortcut
	}
	
	public func performAction() {
		self.action()
	}
	
}

public extension ShortcutMenuItem {
	var keyCommand: UIKeyCommand? {
// TODO: Needs updating
//        if let shortcut = shortcut {
//            return UIKeyCommand(input: shortcut.key, modifierFlags: shortcut.modifiers, action: action, discoverabilityTitle: shortcut.title)
//        }
		
		return nil
	}
}


// MARK: - Swift Preview
//#if DEBUG
//import SwiftUI
//struct MenuContents_ViewController_Preview: PreviewProvider {
//	static var previews: some View {
//		return Wrapper(noOp: Binding.constant("no-op")).edgesIgnoringSafeArea(.all)
//	}
//}
//#endif
