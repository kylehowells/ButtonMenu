//
//  ViewController.swift
//  MenuTest
//
//  Created by Simeon Saint-Saens on 3/1/19.
//  Copyright © 2019 Two Lives Left. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {
	
	let mapView: MKMapView = MKMapView()
	
	var menuView: MenuView? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// - Map view
		self.view.insertSubview(self.mapView, at: 0)
		
		// - Menu
		let menu = MenuView(title: "Menu", theme: LightMenuTheme()) { [weak self] () -> [MenuItem] in
			return [
				ShortcutMenuItem(name: "Undo", shortcut: (.command, "Z"), action: { [weak self] in
					let alert = UIAlertController(title: "Undo Action", message: "You selected undo", preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
					
					self?.present(alert, animated: true, completion: nil)
				}),
				
				ShortcutMenuItem(name: "Redo", shortcut: ([.command, .shift], "Z"), action: {}),
				
				SeparatorMenuItem(),
				
				ShortcutMenuItem(name: "Insert Image…", shortcut: ([.command, .alternate], "I"), action: {}),
				ShortcutMenuItem(name: "Insert Link…", shortcut: ([.command, .alternate], "L"), action: {}),
				
				SeparatorMenuItem(),
				
				ShortcutMenuItem(name: "Help", shortcut: (.command, "?"), action: {}),
			]
		}
		self.menuView = menu
		
		self.view.addSubview(menu)
		
		menu.tintColor = UIColor.black
		
		/*
		// AutoLayout Example
		menu.translatesAutoresizingMaskIntoConstraints = false
		
		menu.heightAnchor.constraint(equalToConstant: 40).isActive = true
		
		menu.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
		menu.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
		*/
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		let safeArea = self.view.safeAreaInsets
		let size = self.view.bounds.size
		
		self.mapView.frame = self.view.bounds
		
		if let menuView = self.menuView {
			// - Manual Layout Example
			
			menuView.frame = {
				let menuButtonSize = menuView.systemLayoutSizeFitting(CGSize(
					width: size.width,
					height: 60
				))
				print("menuButtonSize: \(menuButtonSize)")
				
				var frame = CGRect()
				frame.size.width = menuButtonSize.width
				frame.size.height = 40
				frame.origin.x = safeArea.left + 20
				frame.origin.y = safeArea.top + 10
				return frame
			}()
		}
	}
	
}


// MARK: - Swift Preview

#if DEBUG

// Not meant to be touched. Updates itself because of the binding
import SwiftUI

struct ViewController_Preview: PreviewProvider {
	static var previews: some View {
		return Wrapper(noOp: Binding.constant("no-op"))
			.edgesIgnoringSafeArea(.all)
			.previewDisplayName("ViewController")
	}
}

// Could probably use a generic, for easier reuse
struct Wrapper: UIViewControllerRepresentable {
	
	@Binding var noOp: String // no-op -> binding just to trigger updateUIView
	
	func makeUIViewController(context: Context) -> UIViewController {
		let vc = ViewController()
		let v = vc.view
		v?.layoutIfNeeded()
		vc.menuView?.showContents()
		return vc
	}
	
	func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
		uiViewController.view.layoutSubviews()
	}
}

#endif
