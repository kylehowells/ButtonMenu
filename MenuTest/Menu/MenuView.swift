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
			} else {
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
		
		let clippingView = UIView()
		clippingView.clipsToBounds = true
		
		self.addSubview(clippingView)
		
		clippingView.snp.makeConstraints {
			make in
			
			make.edges.equalToSuperview()
		}
		
		clippingView.layer.cornerRadius = 8.0
		
		clippingView.addSubview(effectView)
		
		self.effectView.snp.makeConstraints {
			make in
			
			make.edges.equalToSuperview()
		}
		
		self.effectView.contentView.addSubview(self.tintView)
		self.effectView.contentView.addSubview(self.titleLabel)
		self.effectView.contentView.addSubview(self.gestureBarView)
		
		self.tintView.snp.makeConstraints {
			make in
			
			make.edges.equalToSuperview()
		}
		
		self.titleLabel.snp.makeConstraints {
			make in
			
			make.left.right.equalToSuperview().inset(12)
			make.centerY.equalToSuperview()
		}
		
		self.gestureBarView.layer.cornerRadius = 1.0
		self.gestureBarView.snp.makeConstraints {
			make in
			
			make.centerX.equalToSuperview()
			make.height.equalTo(2)
			make.width.equalTo(20)
			make.bottom.equalToSuperview().inset(3)
		}
		
		self.longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressGesture(_:)))
		self.longPress.minimumPressDuration = 0.0
		self.longPress.delegate = self
		self.addGestureRecognizer(self.longPress)
		
		self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
		self.tapGesture.delegate = self
		self.addGestureRecognizer(self.tapGesture)
		
		self.applyTheme(theme)
		
		self.menuPresentationObserver = NotificationCenter.default.addObserver(forName: MenuView.menuWillPresent, object: nil, queue: nil) {
			[weak self] notification in
			
			if let poster = notification.object as? MenuView, let this = self, poster !== this {
				self?.hideContents(animated: false)
			}
		}
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
		
		//Highlight whatever we can
		if let contents = self.contents {
			let localPoint = sender.location(in: self)
			let contentsPoint = convert(localPoint, to: contents)
			
			if contents.pointInsideMenuShape(contentsPoint) {
				contents.highlightedPosition = CGPoint(x: contentsPoint.x, y: localPoint.y)
			}
		}
		
		switch sender.state {
			case .began:
				if !self.isShowingContents {
					self.gestureStart = Date()
					self.showContents()
				} else {
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
				break
		}
	}
	
	@objc private func tapped(_ sender: UITapGestureRecognizer) {
		self.selectPositionAndHideContents(sender)
	}
	
	private func selectPositionAndHideContents(_ gesture: UIGestureRecognizer) {
		if let contents = self.contents {
			let point = self.convert(gesture.location(in: self), to: contents)
			
			if contents.point(inside: point, with: nil) {
				contents.selectPosition(point, completion: {
					[weak self] menuItem in
					
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
				updatableView.updateLayout = {
					[weak self] in
					
					self?.relayoutContents()
				}
			}
		}
		
		self.addSubview(contents)
		
		contents.snp.makeConstraints {
			make in
			
			switch contentAlignment {
				case .left:
					make.top.right.equalToSuperview()
				case .right:
					make.top.left.equalToSuperview()
				case .center:
					make.top.centerX.equalToSuperview()
			}
		}
        
		self.effectView.isHidden = true
        
		self.longPress?.minimumPressDuration = 0.07
        
        self.contents = contents
        
		self.setNeedsLayout()
		self.layoutIfNeeded()
        
		contents.generateMaskAndShadow(alignment: self.contentAlignment)
        contents.focusInitialViewIfNecessary()
        
		self.feedback.prepare()
        contents.highlightChanged = {
            [weak self] in
            
            self?.feedback.selectionChanged()
        }
    }
    
    public func hideContents(animated: Bool) {
		let contentsView = self.contents
		self.contents = nil
        
		self.longPress?.minimumPressDuration = 0.0
        
		self.effectView.isHidden = false
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                contentsView?.alpha = 0.0
            }) {
                finished in
                contentsView?.removeFromSuperview()
            }
        } else {
            contentsView?.removeFromSuperview()
        }
    }
    
    private var isShowingContents: Bool {
		return self.contents != nil
    }
    
    // MARK: - Relayout
    
    private func relayoutContents() {
		if let contents = self.contents {
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
		guard let contents = self.contents else {
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
