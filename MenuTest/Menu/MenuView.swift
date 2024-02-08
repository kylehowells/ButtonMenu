//
//  MenuView.swift
//  Menus
//
//  Created by Simeon on 2/6/18.
//  Copyright © 2018 Two Lives Left. All rights reserved.
//

import UIKit


// MARK: - MenuView

public class MenuView: UIView, MenuThemeable, UIGestureRecognizerDelegate {
	
	public static let menuWillPresent = Notification.Name("CodeaMenuWillPresent")
	
	private let titleLabel = UILabel()
	private let gestureBarView = UIView()
	private let tintView = UIView()
	private let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
	private let feedback = UISelectionFeedbackGenerator()
	
	public var title: String {
		didSet {
			self.titleLabel.text = self.title
			self.contents?.title = self.title
		}
	}
	
	private var menuPresentationObserver: Any!
	
	private var contents: MenuContents?
	private var theme: MenuTheme
	private var longPress: UILongPressGestureRecognizer!
	private var tapGesture: UITapGestureRecognizer!
	
	private let itemsSource: () -> [MenuItem]
	
	public enum Alignment {
		case left
		case center
		case right
	}
	
	public var contentAlignment = Alignment.right {
		didSet {
			if self.contentAlignment == .center {
				self.titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
			}
			else {
				self.titleLabel.setContentHuggingPriority(.required, for: .horizontal)
			}
		}
	}
	
	public init(title: String, theme: MenuTheme, itemsSource: @escaping () -> [MenuItem]) {
		self.itemsSource = itemsSource
		self.title = title
		self.theme = theme
		
		super.init(frame: .zero)
		
		self.titleLabel.text = title
		self.titleLabel.textColor = theme.darkTintColor
		self.titleLabel.textAlignment = .center
		self.titleLabel.setContentHuggingPriority(.required, for: .horizontal)
		self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
		
		let clippingView = UIView()
		clippingView.clipsToBounds = true
		self.addSubview(clippingView)
		
		clippingView.edgesEqualToSuperview()
		
		clippingView.layer.cornerRadius = 8.0
		
		clippingView.addSubview(self.effectView)
		
		self.effectView.edgesEqualToSuperview()
		
		self.effectView.contentView.addSubview(self.tintView)
		self.effectView.contentView.addSubview(self.titleLabel)
		self.effectView.contentView.addSubview(self.gestureBarView)
		
		self.tintView.edgesEqualToSuperview()
		
		if let titleLabelSuperview = self.titleLabel.superview {
			self.titleLabel.leftAnchor.constraint(equalTo: titleLabelSuperview.leftAnchor, constant: 12).isActive = true
			self.titleLabel.rightAnchor.constraint(equalTo: titleLabelSuperview.rightAnchor, constant: -12).isActive = true
			
			self.titleLabel.centerYAnchor.constraint(equalTo: titleLabelSuperview.centerYAnchor).isActive = true
		}
		
		self.gestureBarView.layer.cornerRadius = 1.0
		self.gestureBarView.translatesAutoresizingMaskIntoConstraints = false
		
		if let gestureBarViewSuperview = self.gestureBarView.superview {
			self.gestureBarView.centerXAnchor.constraint(equalTo: gestureBarViewSuperview.centerXAnchor).isActive = true
			
			self.gestureBarView.heightAnchor.constraint(equalToConstant: 2).isActive = true
			self.gestureBarView.widthAnchor.constraint(equalToConstant: 20).isActive = true
			
			self.gestureBarView.bottomAnchor.constraint(equalTo: gestureBarViewSuperview.bottomAnchor, constant: -3).isActive = true
		}
		
		self.longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressGesture(_:)))
		self.longPress.minimumPressDuration = 0.0
		self.longPress.delegate = self
		self.addGestureRecognizer(self.longPress)
		
		self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
		self.tapGesture.delegate = self
		self.addGestureRecognizer(self.tapGesture)
		
		self.applyTheme(theme)
		
		self.menuPresentationObserver = NotificationCenter.default.addObserver(forName: MenuView.menuWillPresent, object: nil, queue: nil, using: { [weak self] notification in
			
			if let poster = notification.object as? MenuView,
			   let this = self,
			   poster !== this
			{
				self?.hideContents(animated: false)
			}
		})
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self.menuPresentationObserver)
	}
	
	// MARK: - Required Init
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: - Gesture Handling
	
	private var gestureStart: Date = .distantPast
	
	@objc private func longPressGesture(_ sender: UILongPressGestureRecognizer) {
		
		// Highlight whatever we can
		if let contents = self.contents {
			let localPoint = sender.location(in: self)
			let contentsPoint = self.convert(localPoint, to: contents)
			
			if contents.pointInsideMenuShape(contentsPoint) {
				contents.highlightedPosition = CGPoint(x: contentsPoint.x, y: localPoint.y)
			}
		}
		
		switch sender.state {
			case .began:
				if !self.isShowingContents {
					self.gestureStart = Date()
					self.showContents()
				}
				else {
					self.gestureStart = .distantPast
				}
				
				self.contents?.isInteractiveDragActive = true
				
			case .cancelled:
				fallthrough
			case .ended:
				let gestureEnd = Date()
				
				self.contents?.isInteractiveDragActive = false
				
				if gestureEnd.timeIntervalSince(self.gestureStart) > 0.3 {
					self.selectPositionAndHideContents(sender)
				}
				
			default:
				()
		}
	}
	
	@objc private func tapped(_ sender: UITapGestureRecognizer) {
		self.selectPositionAndHideContents(sender)
	}
	
	private func selectPositionAndHideContents(_ gesture: UIGestureRecognizer) {
		if let contents = self.contents {
			let point = self.convert(gesture.location(in: self), to: contents)
			
			if contents.point(inside: point, with: nil) {
				contents.selectPosition(point, completion: { [weak self] menuItem in
					self?.hideContents(animated: true)
					
					menuItem.performAction()
				})
			}
			else {
				self.hideContents(animated: true)
			}
		}
	}
	
	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		if gestureRecognizer == self.longPress && otherGestureRecognizer == self.tapGesture {
			return true
		}
		
		return false
	}
	
	public func showContents() {
		NotificationCenter.default.post(name: MenuView.menuWillPresent, object: self)
		
		let contents = MenuContents(name: self.title, items: self.itemsSource(), theme: self.theme)
		
		for view in contents.stackView.arrangedSubviews {
			if let view = view as? MenuItemView {
				var updatableView = view
				
				updatableView.updateLayout = { [weak self] in
					self?.relayoutContents()
				}
			}
		}
		
		self.addSubview(contents)
		
		contents.translatesAutoresizingMaskIntoConstraints = false
		
		switch self.contentAlignment {
			case .left:
				contents.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
				contents.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
				
			case .center:
				contents.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
				contents.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
				
			case .right:
				contents.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
				contents.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
		}
		
		self.effectView.isHidden = true
		
		self.longPress?.minimumPressDuration = 0.07
		
		self.contents = contents
		
		self.setNeedsLayout()
		self.layoutIfNeeded()
		
		contents.generateMaskAndShadow(alignment: self.contentAlignment)
		contents.focusInitialViewIfNecessary()
		
		self.feedback.prepare()
		
		contents.highlightChanged = { [weak self] in
			self?.feedback.selectionChanged()
		}
	}
	
	public func hideContents(animated: Bool) {
		let contentsView: MenuContents? = self.contents
		self.contents = nil
		
		self.longPress?.minimumPressDuration = 0.0
		
		self.effectView.isHidden = false
		
		if animated {
			UIView.animate(withDuration: 0.2, animations: {
				contentsView?.alpha = 0.0
			}, completion: { finished in
				contentsView?.removeFromSuperview()
			})
		}
		else {
			contentsView?.removeFromSuperview()
		}
	}
	
	private var isShowingContents: Bool {
		return self.contents != nil
	}
	
	// MARK: - Relayout
	
	private func relayoutContents() {
		if let contents: MenuContents = self.contents {
			self.setNeedsLayout()
			self.layoutIfNeeded()
			
			contents.generateMaskAndShadow(alignment: self.contentAlignment)
		}
	}
	
	// MARK: - Hit Testing
	
	public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		guard let contents = self.contents else {
			return super.point(inside: point, with: event)
		}
		
		let contentsPoint = self.convert(point, to: contents)
		
		if !contents.pointInsideMenuShape(contentsPoint) {
			self.hideContents(animated: true)
		}
		
		return contents.pointInsideMenuShape(contentsPoint)
	}
	
	public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		guard let contents: MenuContents = self.contents else {
			return super.hitTest(point, with: event)
		}
		
		let contentsPoint = self.convert(point, to: contents)
		
		if !contents.pointInsideMenuShape(contentsPoint) {
			self.hideContents(animated: true)
		}
		else {
			return contents.hitTest(contentsPoint, with: event)
		}
		
		return super.hitTest(point, with: event)
	}
	
	// MARK: - Theming
	
	public func applyTheme(_ theme: MenuTheme) {
		self.theme = theme
		
		self.titleLabel.font = theme.font
		self.titleLabel.textColor = theme.darkTintColor
		self.gestureBarView.backgroundColor = theme.gestureBarTint
		self.tintView.backgroundColor = theme.backgroundTint
		self.effectView.effect = theme.blurEffect
		
		self.contents?.applyTheme(theme)
	}
	
	public override func tintColorDidChange() {
		self.titleLabel.textColor = self.tintColor
	}
	
}


// MARK: - Helper

fileprivate extension UIView {
	func edgesEqualToSuperview() {
		guard let superview = self.superview else { return }
		
		self.translatesAutoresizingMaskIntoConstraints = false
		
		self.leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
		self.trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
		self.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
		self.bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
	}
	
	func edgesEqualToSuperview(padding: CGFloat) {
		guard let superview = self.superview else { return }
		
		self.translatesAutoresizingMaskIntoConstraints = false
		
		self.leftAnchor.constraint(equalTo: superview.leftAnchor, constant: padding).isActive = true
		self.rightAnchor.constraint(equalTo: superview.rightAnchor, constant: -padding).isActive = true
		self.topAnchor.constraint(equalTo: superview.topAnchor, constant: padding).isActive = true
		self.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -padding).isActive = true
	}
}


// MARK: - Swift Preview

#if DEBUG

// Not meant to be touched. Updates itself because of the binding
import SwiftUI

struct MenuView_ViewController_Preview: PreviewProvider {
	static var previews: some View {
		return Wrapper(noOp: Binding.constant("no-op"))
			.edgesIgnoringSafeArea(.all)
			.previewInterfaceOrientation(.portrait)
			.previewDisplayName("ViewController")
	}
}

#endif
