//
//  Query.swift
//  Rex
//
//  Created by Neil Pankey on 10/20/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import ReactiveCocoa

public enum CollectionEvent<Collection: CollectionType> {
    case Insert(Collection.Generator.Element, Collection.Index)
    case Remove(Collection.Generator.Element, Collection.Index)
    case Composite([CollectionEvent])
}

public protocol ObservableCollectionType {
    typealias Collection: CollectionType

    /// Read-only access to the underlying collection. These _should_ be copy-on-write
    /// to avoid a copy on each access while still allowing the callee to update the
    /// returned collection.
    ///
    /// N.B. Investigate clojure vector because CoW is still expensive.
    var collection: Collection { get }

    /// Safely subscribe to changes on `collection`.
    func observe() -> SignalProducer<(Collection, SignalProducer<CollectionEvent<Collection>, NoError>), NoError>
}

public final class ObservableArray<Element>: ObservableCollectionType, MutableCollectionType, MutableSliceable, RangeReplaceableCollectionType {
    private var elements: [Element] = []
    private var sinks: Bag<Signal<CollectionEvent<[Element]>, NoError>.Observer> = Bag()

    public typealias Collection = [Element]
    public typealias Generator = Array<Element>.Generator
    
    public init() {
    }
    
    // Indexable, MutableIndexable

    public var startIndex: Int {
        return elements.startIndex
    }
    
    public var endIndex: Int {
        return elements.endIndex
    }

    public subscript(index: Int) -> Element {
        get {
            return elements[index]
        }
        set(newValue) {
            replaceRange(index..<index, with: [newValue])
        }
    }
    
    // SequenceType
    
    public func generate() -> Generator {
        return elements.generate()
    }
    
    // RangeReplaceableCollectionType

    public func replaceRange<C : CollectionType where C.Generator.Element == Generator.Element>(subRange: Range<Int>, with newElements: C) {
        let removes: [CollectionEvent<Collection>] = subRange.map { .Remove(self.elements[$0], subRange.startIndex) }
        let inserts: [CollectionEvent<Collection>] = newElements.enumerate().map { .Insert($1, $0 + subRange.startIndex) }
        
        let change: CollectionEvent<Collection>
        switch (removes.count, inserts.count) {
        case (0, 1):
            change = inserts[0]
        case (1, 0):
            change = removes[0]
        default:
            change = .Composite(removes + inserts)
        }

        // TODO this should be more effecient than copy-on-write
        elements.replaceRange(subRange, with: newElements)
        sinks.forEach { $0.sendNext(change) }
    }

    // ObservableCollectionType

    public var collection: [Element] {
        return elements
    }

    public func observe() -> SignalProducer<(Collection, SignalProducer<CollectionEvent<Collection>, NoError>), NoError> {
        return SignalProducer { observer, disposable in
            let (producer, sink) = SignalProducer<CollectionEvent<Collection>, NoError>.buffer()
            
            observer.sendNext((self.elements, producer))
            let token = self.sinks.insert(sink)
            disposable.addDisposable {
                self.sinks.removeValueForToken(token)
            }
        }
    }
}
