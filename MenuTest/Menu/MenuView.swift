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
		
		self.layer.borderColor = UIColor.red.cgColor
		self.layer.borderWidth = 1
		
		self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
		self.titleLabel.text = title
		self.titleLabel.textColor = theme.darkTintColor
		self.titleLabel.textAlignment = .center
		self.titleLabel.setContentHuggingPriority(.required, for: .horizontal)
		
		let clippingView = UIView()
		clippingView.clipsToBounds = true
		
		self.addSubview(clippingView)
		
		/*clippingView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}*/
		clippingView.translatesAutoresizingMaskIntoConstraints = false
		clippingView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
		clippingView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
		clippingView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
		clippingView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
		
		clippingView.layer.cornerRadius = 8.0
		
		self.effectView.translatesAutoresizingMaskIntoConstraints = false
		clippingView.addSubview(self.effectView)
		
		/*self.effectView.snp.makeConstraints({ make in
			make.edges.equalToSuperview()
		})*/
		self.effectView.topAnchor.constraint(equalTo: clippingView.topAnchor).isActive = true
		self.effectView.bottomAnchor.constraint(equalTo: clippingView.bottomAnchor).isActive = true
		self.effectView.rightAnchor.constraint(equalTo: clippingView.rightAnchor).isActive = true
		self.effectView.leftAnchor.constraint(equalTo: clippingView.leftAnchor).isActive = true
		
		self.effectView.contentView.addSubview(self.tintView)
		self.effectView.contentView.addSubview(self.titleLabel)
		self.effectView.contentView.addSubview(self.gestureBarView)
		
		let effectViewContentView = self.effectView
		//effectViewContentView.translatesAutoresizingMaskIntoConstraints = false
		
		/*self.tintView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}*/
		self.tintView.translatesAutoresizingMaskIntoConstraints = false
		self.tintView.topAnchor.constraint(equalTo: effectViewContentView.topAnchor).isActive = true
		self.tintView.bottomAnchor.constraint(equalTo: effectViewContentView.bottomAnchor).isActive = true
		self.tintView.rightAnchor.constraint(equalTo: effectViewContentView.rightAnchor).isActive = true
		self.tintView.leftAnchor.constraint(equalTo: effectViewContentView.leftAnchor).isActive = true
		
		/*self.titleLabel.snp.makeConstraints { make in
			make.left.right.equalToSuperview().inset(12)
			make.centerY.equalToSuperview()
		}*/
		self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
		self.titleLabel.leftAnchor.constraint(equalTo: effectViewContentView.leftAnchor, constant: 12).isActive = true
		self.titleLabel.rightAnchor.constraint(equalTo: effectViewContentView.rightAnchor, constant: 12).isActive = true
		self.titleLabel.centerYAnchor.constraint(equalTo: effectViewContentView.centerYAnchor).isActive = true
		
		self.gestureBarView.layer.cornerRadius = 1.0
		
		//make.centerX.equalToSuperview()
		//make.height.equalTo(2)
		//make.width.equalTo(20)
		//make.bottom.equalToSuperview().inset(3)
		self.gestureBarView.translatesAutoresizingMaskIntoConstraints = false
		self.gestureBarView.centerXAnchor.constraint(equalTo: effectViewContentView.centerXAnchor).isActive = true
		self.gestureBarView.heightAnchor.constraint(equalToConstant: 2).isActive = true
		self.gestureBarView.widthAnchor.constraint(equalToConstant: 20).isActive = true
		self.gestureBarView.bottomAnchor.constraint(equalTo: effectViewContentView.bottomAnchor, constant: 3).isActive = true
		
		
		self.longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressGesture(_:)))
		self.longPress.minimumPressDuration = 0.0
		self.longPress.delegate = self
		self.addGestureRecognizer(self.longPress)
		
		self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
		self.tapGesture.delegate = self
		self.addGestureRecognizer(self.tapGesture)
		
		self.applyTheme(theme)
		
		self.menuPresentationObserver = NotificationCenter.default.addObserver(forName: MenuView.menuWillPresent, object: nil, queue: nil) { [weak self] notification in
			
			if let poster = notification.object as? MenuView,
			   let this = self,
			   poster !== this
			{
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
		
		// Highlight whatever we can
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
		contents.translatesAutoresizingMaskIntoConstraints = false
		
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
		
		/*contents.snp.makeConstraints({ make in
			switch self.contentAlignment {
				case .left:
					make.top.right.equalToSuperview()
				
				case .right:
					make.top.left.equalToSuperview()
					
				case .center:
					make.top.centerX.equalToSuperview()
			}
		})*/
        
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
		let contentsView = self.contents
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
	
	
	// MARK: - Layout
	
//	public override func layoutSubviews() {
//		super.layoutSubviews()
//	}
	
	
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
