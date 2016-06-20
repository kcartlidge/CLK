//
//  ElectronDocument.swift
//  Clock Signal
//
//  Created by Thomas Harte on 03/01/2016.
//  Copyright © 2016 Thomas Harte. All rights reserved.
//

import Foundation
import AudioToolbox

class ElectronDocument: MachineDocument {

	private lazy var electron = CSElectron()
	override func machine() -> CSMachine! {
		return electron
	}

	override func aspectRatio() -> NSSize {
		return NSSize(width: 11.0, height: 10.0)
	}

	private func rom(name: String) -> NSData? {
		return dataForResource(name, ofType: "rom", inDirectory: "ROMImages/Electron")
	}

	override func windowControllerDidLoadNib(aController: NSWindowController) {
		super.windowControllerDidLoadNib(aController)

		if let os = rom("os"), basic = rom("basic") {
			self.electron.setOSROM(os)
			self.electron.setBASICROM(basic)
		}

		establishStoredOptions()
	}

	override var windowNibName: String? {
		return "ElectronDocument"
	}

	override func readFromURL(url: NSURL, ofType typeName: String) throws {
		print(url)
		print(typeName)

		if let pathExtension = url.pathExtension {
			switch pathExtension.lowercaseString {
				case "uef":
					electron.openUEFAtURL(url)
					return
				default: break;
			}
		}

		let fileWrapper = try NSFileWrapper(URL: url, options: NSFileWrapperReadingOptions(rawValue: 0))
		try self.readFromFileWrapper(fileWrapper, ofType: typeName)
	}

	override func readFromData(data: NSData, ofType typeName: String) throws {
		if let plus1ROM = rom("plus1") {
			electron.setROM(plus1ROM, slot: 12)
		}
		electron.setROM(data, slot: 15)
	}

	// MARK: IBActions
	@IBOutlet var displayTypeButton: NSPopUpButton!
	@IBAction func setDisplayType(sender: NSPopUpButton!) {
		electron.useTelevisionOutput = (sender.indexOfSelectedItem == 1)
		NSUserDefaults.standardUserDefaults().setInteger(sender.indexOfSelectedItem, forKey: self.displayTypeUserDefaultsKey)
	}

	@IBOutlet var fastLoadingButton: NSButton!
	@IBAction func setFastLoading(sender: NSButton!) {
		electron.useFastLoadingHack = sender.state == NSOnState
		NSUserDefaults.standardUserDefaults().setBool(electron.useFastLoadingHack, forKey: self.fastLoadingUserDefaultsKey)
	}

	private let displayTypeUserDefaultsKey = "electron.displayType"
	private let fastLoadingUserDefaultsKey = "electron.fastLoading"
	private func establishStoredOptions() {
		let standardUserDefaults = NSUserDefaults.standardUserDefaults()
		standardUserDefaults.registerDefaults([
			displayTypeUserDefaultsKey: 0,
			fastLoadingUserDefaultsKey: true
		])

		let useFastLoadingHack = standardUserDefaults.boolForKey(self.fastLoadingUserDefaultsKey)
		electron.useFastLoadingHack = useFastLoadingHack
		self.fastLoadingButton.state = useFastLoadingHack ? NSOnState : NSOffState

		let displayType = standardUserDefaults.integerForKey(self.displayTypeUserDefaultsKey)
		electron.useTelevisionOutput = (displayType == 1)
		self.displayTypeButton.selectItemAtIndex(displayType)
	}
}