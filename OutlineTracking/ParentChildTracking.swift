//
//  ParentChildTracking.swift
//  OutlineVisibilityTracking
//
//  Created by Henry on 2019/06/29.
//

import Tree
import PD

/// Tracks parent-child relations of a KVLT storage.
public struct ParentChildTracking<K> where K:Comparable & Hashable {
    /// Child id to parent id map.
    private(set) var parentMap = [K:K?]()
    private var childrenMap = [K?:Set<K>]()

    public init() {}
}
public extension ParentChildTracking {
    /// Returns `nil` if target k is a root, therefore, no parent.
    /// This function crashes if there's no parent key stored
    /// for supplied key `k`.
    func parent(for k:K) -> K? {
        return parentMap[k]!
    }
    /// Keys to root collection.
    /// - Returns:
    ///     Returning array is sorted root to leaf
    ///     including root key `nil` and excluding leaf key `k`.
    func ancestors(to k:K?) -> [K?] {
        guard let k = k else { return [] }
        let pk = parent(for: k)
        var a = ancestors(to: pk)
        a.append(pk)
        return a
    }
    mutating func insertLeaf(_ k:K, in pk:K?) {
        precondition(!childrenMap[pk, default: []].contains(k))
        precondition(childrenMap[k] == nil)
        childrenMap[k] = []
        childrenMap[pk, default: []].insert(k)
        parentMap[k] = pk
    }
    /// Removes leaf entry.
    /// This method fails if target key is not leaf.
    mutating func removeLeaf(_ k:K) {
        precondition(childrenMap[k]!.count == 0)
        let pk = parentMap[k]!
        parentMap[k] = nil
        childrenMap[pk, default: []].remove(k)
        childrenMap[k] = nil
    }
    /// Removes branch key with all of its descesdant keys.
    /// You cannot supply root key because you cannot remove root key.
    mutating func removeSubtree(_ k:K) {
        precondition(childrenMap[k] != nil)
        let pk = parentMap[k]!
        let cks = childrenMap[k]!
        for ck in cks {
            removeSubtree(ck)
        }
        childrenMap[pk, default: []].remove(k)
        parentMap[k] = nil
        childrenMap[k] = nil
    }
}

public extension ParentChildTracking {
    init<V>(_ s: KVLTStorage<K,V>) {
        for k in s.collection.keys {
            parentMap[k] = nil as K?
            childrenMap[nil, default: []].insert(k)
        }
        for k in s.keys {
            let cc = s.collection(of: k)
            for ck in cc.keys {
                parentMap[ck] = k
                childrenMap[k, default: []].insert(ck)
            }
        }
    }

    mutating func insertSubtree<T>(_ t: T, in pk:K?) where
    T: KeyValueCollectionTreeProtocol,
    T.Key == K {
        let k = t.key
        insertLeaf(k, in: pk)
        for t1 in t.collection {
            insertSubtree(t1, in: k)
        }
    }
    mutating func removeSubtree<T>(_ t: T, in pk:K?) where
    T: KeyValueCollectionTreeProtocol,
    T.Key == K {
        let k = t.key
        removeLeaf(k)
        for t1 in t.collection {
            removeSubtree(t1, in:k)
        }
    }
    mutating func replay<V>(_ x: PDKVLTRepository<K,V>.Step) {
        switch x {
        case .values(_): break
        case let .subtrees(a,b,pk):
            let os = a.snapshot.collection(of: pk)
            let ns = b.snapshot.collection(of: pk)
            for t in os[a.range] {
                removeSubtree(t, in: pk)
            }
            for t in ns[b.range] {
                insertSubtree(t, in: pk)
            }
        }
    }
}
