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
	
	var menu: MenuView? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.addSubview(self.mapView)
		
		let menu = MenuView(title: "Menu", theme: LightMenuTheme(), itemsSource: { [weak self] () -> [MenuItem] in
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
		})
		
		self.menu = menu
		
		self.view.addSubview(menu)
		
		menu.tintColor = UIColor.black
		
		menu.layer.borderColor = UIColor.red.cgColor
		
		menu.layer.borderWidth = 1
		
		menu.translatesAutoresizingMaskIntoConstraints = false
		menu.heightAnchor.constraint(equalToConstant: 40).isActive = true
		menu.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
		menu.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
	}
	
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		let size = self.view.bounds.size
		
		self.mapView.frame = self.view.bounds
		/*
		if let menu = self.menu {
			menu.frame = {
				var frame = CGRect()
				frame.size.width = menu.intrinsicContentSize.width
				frame.size.height = 40
				frame.origin.x = (size.width - frame.width) * 0.5
				frame.origin.y = (size.height - frame.height) * 0.5
				return frame
			}()
		}*/
	}
	
}
