//
//  BindingValue.swift
//  FuzzMeasure
//
//  Created by Christopher Liscio on 2015-12-12.
//  Copyright © 2015 SuperMegaUltraGroovy, Inc. All rights reserved.
//

import Foundation

/// Represents a value to be bound to a UI control, including common placeholders for empty or multiple selections.
public enum BindingValue<ValueType> {
    /// A placeholder to represent the "No Selection" case
    case NoSelection
    
    /// A placeholder to represent the "Multiple Values" case
    case MultipleValues
    
    /// The value to be displayed by the control
    case Value(ValueType)
    
    /// Map the value to another (possibly differently typed) value using the supplied closure
    public func map<U>(transform: ((ValueType)->U)) -> BindingValue<U> {
        switch self {
        case let .Value(v):
            return .Value(transform(v))
        case .NoSelection:
            return .NoSelection
        case .MultipleValues:
            return .MultipleValues
        }
    }
    
    /// Format the value's string using the specified formatter. (Note that you can also use `map` to achieve the same thing.)
    public func formatString(formatter: (ValueType) -> String) -> String {
        switch self {
        case .Value(let v):
            return formatter(v)
        default:
            return description
        }
    }
    
    /// Returns whether this `BindingValue` instance represents a placeholder
    public var isPlaceholder: Bool {
        switch self {
            case .Value:
                return false
            default:
                return true
        }
    }
}

extension BindingValue : CustomStringConvertible {
    public var description: String {
        switch self {
        case .Value(let v):
            if let printableValue = v as? CustomStringConvertible {
                return String.localizedStringWithFormat(NSLocalizedString("Value(%@)", comment: "Debug value display"), printableValue.description)
            }
            else {
                return NSLocalizedString("Value(no description)", comment: "Debug value display for non-CustomStringConvertible type")
            }
        case .NoSelection:
            return NSLocalizedString("No Selection", comment: "No selection placeholder")
        case .MultipleValues:
            return NSLocalizedString("Multiple Values", comment: "Multiple values placeholder")
        }
    }
}

public extension BindingValue where ValueType : Equatable {
    /// Initializes a binding value with the default behavior for arrays of values. That is, an empty array becomes .NoSelection, an array with more than one non-matching element is .MultipleValues, and the .Value itself otherwise.
    public init(values: [ValueType]) {
        if values.isEmpty {
            self = BindingValue.NoSelection
        }
        else if values.count == 1 {
            self = BindingValue.Value(values.first!)
        }
        else {
            let firstValue = values.first!
            let allEqual = values.suffixFrom(1).reduce(true) { $0 && ($1 == firstValue) }
            if allEqual {
                self = BindingValue.Value(firstValue)
            }
            else {
                self = BindingValue.MultipleValues
            }
        }
    }
}