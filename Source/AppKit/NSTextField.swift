//
//  NSTextField.swift
//  Rex
//
//  Created by Yury Lapitsky on 7/8/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import Foundation
import AppKit
import ReactiveCocoa

extension NSTextField {
    /// Sends the text field's string value as it changes. Equivalent to the "continuous"
    /// control setting in IB
    public var rex_continuousStringValues: SignalProducer<String, NoError> {
        return NSNotificationCenter.defaultCenter()
            .rac_notifications(NSControlTextDidChangeNotification, object: self)
            .map { notification in
                (notification.object as! NSTextField).stringValue
        }
    }
    
    /// Sends the text field's string value when editing completes. For instance, when the
    /// user tabs out of the control, or hits the return key.
    public var rex_stringValues: SignalProducer<String, NoError> {
        return NSNotificationCenter.defaultCenter()
            .rac_notifications(NSControlTextDidEndEditingNotification, object: self)
            .map { notification in
                (notification.object as! NSTextField).stringValue
        }
    }
    
    /// Wraps a text field's text color value into a bindable property.
    public var rex_textColor: MutableProperty<NSColor?> {
        return associatedProperty(self, key: &textColorKey, initial: { $0.textColor }, setter: { $0.textColor = $1 } )
    }
}

private var textColorKey: UInt8 = 0