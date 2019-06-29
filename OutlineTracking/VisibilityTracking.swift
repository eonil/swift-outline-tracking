//
//  VisibilityTracking.swift
//  OutlineVisibilityTracking
//
//  Created by Henry on 2019/06/29.
//

import PD
import Tree

/// Tracks visibility information of outline-tree.
///
/// - Complexity:
///     Any update at leaf node requires update of whole ancestor nodes to root.
///     Therefore insert/update/remove all becomes O(depth).
///     Look-up for key at visible row index takes O(depth * order).
/// - Note:
///     This is currently based on persistent version of `KVLT`.
///     As persistence is not required, performance can be improved
///     by replacing it with ephemeral variant.
public struct VisibilityTracking<K> where K:Comparable & Hashable {
    /// `NSOutlineView` always shows root items.
    /// Therefore, treats this virtual root as always expanded.
    private(set) var rootValue = State(isExpanded: true, totalDescendantsCount: 0, totalVisibleDescendantsCount: 0)
    private(set) var tree = KVLTStorage<K,State>()
    private(set) var ptt = ParentChildTracking<K>()
    public init() {}
}
extension VisibilityTracking {
    struct State {
        var isExpanded = false
        var totalDescendantsCount = 0
        var totalVisibleDescendantsCount = 0
        var totalCount: Int {
            return 1 + totalDescendantsCount
        }
        var totalVisibleCount: Int {
            return isExpanded ? 1 + totalVisibleDescendantsCount : 1
        }
    }
    /// Get all keys from root to target including target key.
    func keys(to k:K) -> [K?] {
        var aks = ptt.ancestors(to: k)
        aks.append(k)
        return aks
    }
    func state(for k:K?) -> State {
        guard let k = k else { return rootValue }
        return tree[k]
    }
    func states(for ks:[K?]) -> [State] {
        return ks.map({ state(for: $0) })
    }
    mutating func setState(_ v:State, for k:K?) {
        if let k = k { tree[k] = v }
        else { rootValue = v }
    }
    mutating func setStates(_ vs:[State], for ks:[K?]) {
        precondition(vs.count == ks.count)
        for (k,v) in zip(ks,vs) {
            setState(v, for: k)
        }
    }
}
extension VisibilityTracking {
    func findPosition(atVisibleOffset d: Int) -> (at:Int, in:K?) {
        assert(d < rootValue.totalVisibleCount)
        return findPosition(atVisibleOffset: d, in: nil)
    }
    func findPosition(atVisibleOffset d: Int, in pk:K?) -> (at:Int, in:K?) {
        assert((0..<state(for: pk).totalVisibleCount).contains(d))
        var d1 = d
        let s = tree.collection(of: pk)
        for (i,t) in s.enumerated() {
            let k = t.key
            guard d1 > 0 else { return (i,pk) }
            let v = t.value
            if d1 < v.totalVisibleCount {
                return findPosition(atVisibleOffset: d1-1, in: k)
            }
            d1 -= v.totalVisibleCount
        }
        assert(d1 == 0)
        fatalError("A bug in algorithm.")
    }
}
public extension VisibilityTracking {
    mutating func setExpansionState(_ b:Bool, of k:K) {
        let ks = keys(to: k)
        var vs = states(for: ks)
        guard vs.last!.isExpanded != b else { return }
        for i in vs.indices.dropLast() {
            vs[i].totalVisibleDescendantsCount -= vs[i+1].totalVisibleCount
        }
        vs[vs.count-1].isExpanded = b
        for i in vs.indices.lazy.dropLast().reversed() {
            vs[i].totalVisibleDescendantsCount += vs[i+1].totalVisibleCount
        }
        setStates(vs, for: ks)
    }
    /// - Complexity:
    ///     O(`count(t)` * depth).
    mutating func insertSubtree<T>(_ t:T, at i:Int, in pk:K?) where
    T:KVLTProtocol,
    T.Key == K {
        // Insert element.
        let k = t.key
        let v = State(isExpanded: false, totalDescendantsCount: 0, totalVisibleDescendantsCount: 0)
        tree.insert((k,v), at: i, in: pk)
        ptt.insertLeaf(k, in: pk)

        // Update stats over ancestor line to root.
        let ks = keys(to: k)
        var xs = states(for: ks)
        for i in xs.indices.dropLast(2) {
            xs[i].totalDescendantsCount -= xs[i+1].totalCount
            xs[i].totalVisibleDescendantsCount -= xs[i+1].totalVisibleCount
        }
        for i in xs.indices.dropLast(1).reversed() {
            xs[i].totalDescendantsCount += xs[i+1].totalCount
            xs[i].totalVisibleDescendantsCount += xs[i+1].totalVisibleCount
        }
        setStates(xs, for: ks)

        // Insert descendants.
        for (i1,t1) in t.collection.enumerated() {
            insertSubtree(t1, at: i1, in: k)
        }
    }
    /// - Complexity:
    ///     O(`count(t)` * depth).
    mutating func removeSubtree(at i:Int, in pk:K?) {
        // Remove descendants.
        let t = tree.collection(of: pk)[i]
        let k = t.key
        for i1 in 0..<t.collection.count {
            removeSubtree(at: i1, in: k)
        }

        // Update stats over ancestor line to root.
        let ks = keys(to: k)
        var xs = states(for: ks)
        for i in xs.indices.dropLast(1) {
            xs[i].totalDescendantsCount -= xs[i+1].totalCount
            xs[i].totalVisibleDescendantsCount -= xs[i+1].totalVisibleCount
        }
        for i in xs.indices.dropLast(2).reversed() {
            xs[i].totalDescendantsCount += xs[i+1].totalCount
            xs[i].totalVisibleDescendantsCount += xs[i+1].totalVisibleCount
        }
        setStates(xs, for: ks)

        // Remove element.
        assert(tree.collection(of: pk)[i].collection.count == 0)
        tree.remove(at: i, in: pk)
        ptt.removeLeaf(k)
    }
}
public extension VisibilityTracking {
    /// Initializes visibility tracker with copying tree structures of
    /// supplied repository `s`.
    init<V>(_ s:KVLTStorage<K,V>) {
        for (i,t) in s.collection.enumerated() {
            insertSubtree(t, at: i, in: nil)
        }
    }
    /// Replays topological changes in supplied stepping `x`.
    mutating func replay<V>(_ x:PDKVLTRepository<K,V>.Step) where K:Comparable {
        // Update PTT.
        ptt.replay(x)

        // Replay VTT.
        switch x {
        case .values(_):
            // Nothing to do at this point...
            // Maybe later if `V` contains expansion state...
            break
        case let .subtrees(a,b,pk):
            // Apply removals.
            do {
                for i in a.range.lazy.reversed() {
                    removeSubtree(at: i, in: pk)
                }
            }
            // Apply insertions.
            do {
                let ts = b.snapshot.collection(of: pk)[b.range]
                for (i,t) in ts.enumerated() {
                    insertSubtree(t, at: i, in: pk)
                }
            }
        }
    }
}
public extension VisibilityTracking {
    func find(atVisibleOffset d:Int) -> K {
        let p = findPosition(atVisibleOffset: d)
        return tree.collection(of: p.in)[p.at].key
    }
}
