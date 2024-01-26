//
//  MenuItem.swift
//  Menus
//
//  Created by Simeon on 6/6/18.
//  Copyright © 2018 Two Lives Left. All rights reserved.
//

import UIKit

public protocol MenuItemView {
	var highlighted: Bool { get set }
	
	var highlightPosition: CGPoint { get set }
	
	var didHighlight: () -> Void { get set }
	
	var initialFocusedRect: CGRect? { get }
	
	var updateLayout: () -> Void { get set }
	
	func startSelectionAnimation(completion: @escaping () -> Void)
}

extension MenuItemView {
	public func startSelectionAnimation(completion: @escaping () -> Void) {}
	
	public var initialFocusedRect: CGRect? { return nil }
}


// MARK: - Separator

class SeparatorMenuItemView: UIView, MenuItemView, MenuThemeable {
	
	private let separatorLine = UIView()
	
	init() {
		super.init(frame: .zero)
		
		self.addSubview(self.separatorLine)
		
		self.separatorLine.snp.makeConstraints {
			make in
			
			make.left.right.equalToSuperview()
			make.height.equalTo(1)
			make.top.bottom.equalToSuperview().inset(2)
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: - Menu Item View
	
	var highlighted: Bool = false
	
	var highlightPosition: CGPoint = .zero
	
	var didHighlight: () -> Void = {}
	
	var updateLayout: () -> Void = {}
	
	//MARK: - Themeable
	
	func applyTheme(_ theme: MenuTheme) {
		self.separatorLine.backgroundColor = theme.separatorColor
	}
	
}

// MARK: - Standard Menu Item

extension String {
	var renderedShortcut: String {
		switch self {
			case " ":
				return "Space"
			case "\u{8}":
				return "⌫"
			default:
				return self
		}
	}
}

extension ShortcutMenuItem.Shortcut {
	var labels: [UILabel] {
		
		let symbols = self.modifiers.symbols + [self.key]
		
		return symbols.map({
			let label = UILabel()
			label.text = $0.renderedShortcut
			label.textAlignment = .right
			
			if $0 == self.key {
				label.textAlignment = .left
				label.snp.makeConstraints {
					make in
					
					make.width.greaterThanOrEqualTo(label.snp.height)
				}
			}
			
			return label
		})
	}
}


// MARK: - ShortcutMenuItemView

public class ShortcutMenuItemView: UIView, MenuItemView, MenuThemeable {
	
	private let nameLabel = UILabel()
	private let shortcutStack = UIView()
	
	private var shortcutLabels: [UILabel] {
		return shortcutStack.subviews.compactMap { $0 as? UILabel }
	}
	
	public init(item: ShortcutMenuItem) {
		super.init(frame: .zero)
		
		self.nameLabel.text = item.name
		
		self.addSubview(self.nameLabel)

		self.nameLabel.textColor = .black
		
		self.nameLabel.snp.makeConstraints {
			make in
			
			make.top.bottom.equalToSuperview().inset(4)
			make.left.equalToSuperview().offset(10)
			make.right.lessThanOrEqualToSuperview().offset(-10)
		}
		
		if let shortcut = item.shortcut, ShortcutMenuItem.displayShortcuts {
			self.addSubview(self.shortcutStack)
			
			self.nameLabel.snp.makeConstraints {
				make in
				
				make.right.lessThanOrEqualTo(shortcutStack.snp.left).offset(-12)
			}
			
			self.shortcutStack.snp.makeConstraints {
				make in
				
				make.top.bottom.equalToSuperview().inset(2)
				make.right.equalToSuperview().inset(6)
			}
			
			self.shortcutStack.setContentHuggingPriority(.required, for: .horizontal)
			
			let labels = shortcut.labels
			
			for (index, label) in labels.enumerated() {
				self.shortcutStack.addSubview(label)
				
				label.snp.makeConstraints {
					make in
					
					make.top.bottom.equalToSuperview()
					
					if index == 0 {
						make.left.equalToSuperview()
					} else if index < labels.count - 1 {
						make.left.equalTo(labels[index - 1].snp.right).offset(1.0 / UIScreen.main.scale)
					}
					
					if index == labels.count - 1 {
						if index > 0 {
							make.left.equalTo(labels[index - 1].snp.right).offset(2)
						}
						make.right.equalToSuperview()
					}
				}
			}
		}
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	public func startSelectionAnimation(completion: @escaping () -> Void) {
		self.updateHighlightState(false)
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			[weak self] in
			self?.updateHighlightState(true)
			
			completion()
		}
	}
	
	//MARK: - Menu Item View
	
	public var highlighted: Bool = false {
		didSet {
			self.updateHighlightState(self.highlighted)
			
			if self.highlighted == true && oldValue == false {
				self.didHighlight()
			}
		}
	}
	
	public var highlightPosition: CGPoint = .zero
	
	public var didHighlight: () -> Void = {}
	
	public var updateLayout: () -> Void = {}
	
	//MARK: - Themeable Helpers
	
	private var highlightedBackgroundColor: UIColor = .clear
	
	private func updateHighlightState(_ highlighted: Bool) {
		self.nameLabel.isHighlighted = highlighted
		self.shortcutLabels.forEach({ $0.isHighlighted = highlighted })
		
		self.backgroundColor = highlighted ? self.highlightedBackgroundColor : .clear
	}
	
	//MARK: - Themeable
	
	public func applyTheme(_ theme: MenuTheme) {
		self.nameLabel.font = theme.font
		self.nameLabel.textColor = theme.textColor
		self.nameLabel.highlightedTextColor = theme.highlightedTextColor
		
		self.highlightedBackgroundColor = theme.highlightedBackgroundColor
		
		self.shortcutLabels.forEach {
			label in
			
			label.font = theme.font
			label.textColor = theme.textColor
			label.highlightedTextColor = theme.highlightedTextColor
		}
		
		self.updateHighlightState(self.highlighted)
	}
}
