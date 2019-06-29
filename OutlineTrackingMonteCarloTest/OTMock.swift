//
//  OTMock.swift
//  OutlineTrackingMonteCarloTest
//
//  Created by Henry on 2019/06/29.
//

import XCTest
import Tree
import PD
import TestUtil
@testable import OutlineTracking

struct OT5Mock {
    typealias K = Int
    typealias V = String
    typealias Source = PDKVLTRepository<K,V>
    typealias Snapshot = Source.Snapshot
    //    typealias Element = Snapshot.Element

    private(set) var prng = ReproduciblePRNG(1_000_000)
    private(set) var source = Source()
    private(set) var target = VisibilityTracking<K>()
}
extension OT5Mock {
    var latestSourceSnapshot: Source.Snapshot {
        return source.timeline.points.last?.snapshot ?? Snapshot()
    }
    /// Returns a new key that is not contained in latest source snapshot.
    mutating func makeNewRandomKey() -> K {
        let s = latestSourceSnapshot
        var k = prng.nextWithRotation()
        while s.keys.contains(k) {
            k = prng.nextWithRotation()
        }
        return k
    }
    mutating func randomKeyInLatestSnapshot() -> K {
        let s = latestSourceSnapshot
        let c = s.count
        let n = prng.nextWithRotation(in: 0..<c)
        let i = s.keys.index(s.keys.startIndex, offsetBy: n)
        let k = s.keys[i]
        return k
    }
    /// Selects `nil` in 0.001% or snapshot is empty.
    mutating func selectRandomParentKey() -> K? {
        if latestSourceSnapshot.count == 0 { return nil }
        if prng.nextWithRotation(in: 0..<1000) == 0 { return nil }
        return randomKeyInLatestSnapshot()
    }
    mutating func selectRandomInsertionIndexInKey(in k:K?) -> Int {
        let c = latestSourceSnapshot.collection(of: k)
        let i = prng.nextWithRotation(in: 0..<c.count+1)
        return i
    }
    mutating func selectRandomUpdateOrRemoveIndexInKey(in k:K?) -> Int? {
        let c = latestSourceSnapshot.collection(of: k)
        guard c.count > 0 else { return nil }
        let i = prng.nextWithRotation(in: 0..<c.count)
        return i
    }

    mutating func stepRandom(_ n: Int = 1) {
        for _ in 0..<n {
            switch prng.nextWithRotation(in: 0..<3) {
            case 0:     insertRandom()
            case 1:     updateRandomValue()
            case 2:     removeRandom()
            default:    fatalError()
            }
        }
    }
    mutating func insertRandom() {
        let pk = selectRandomParentKey()
        let i = selectRandomInsertionIndexInKey(in: pk)
        let k = makeNewRandomKey()
        let v = "\(k)"
        insert(k, v, at: i, in: pk)
    }
    mutating func insert(_ k:K, _ v:V, at i:Int, in pk:K?) {
        source.insert((k,v), at: i, in: pk)
        target.replayUnconditionally(source.timeline)
        target.setExpansionState(true, of: k)
        source = source.latestOnly
    }
    mutating func updateRandomValue() {
        guard latestSourceSnapshot.count > 0 else { return }
        let s = latestSourceSnapshot
        let pk = selectRandomParentKey()
        guard let i = selectRandomUpdateOrRemoveIndexInKey(in: pk) else { return }
        let t = s.collection(of: pk)[i]
        let k = t.key
        let v = t.value
        let v1 = "\(v)."
        source[k] = v1
        target.replayUnconditionally(source.timeline)
        source = source.latestOnly
    }
    mutating func removeRandom() {
        guard latestSourceSnapshot.count > 0 else { return }
        let pk = selectRandomParentKey()
        guard let i = selectRandomUpdateOrRemoveIndexInKey(in: pk) else { return }
        source.remove(at: i, in: pk)
        target.replayUnconditionally(source.timeline)
        source = source.latestOnly
    }
}

extension OT5Mock {
    func validate() {
        XCTAssertEqual(latestSourceSnapshot.count, target.tree.count)
        // Visible tracking.
        do {
            let ks = source.collection.map({ $0.dfs.map({ $0.key }) }).flatMap({ $0 })
            for k in ks {
                let b = target.expansionState(of: k)
                XCTAssertTrue(b)
            }
//            for i in 0..<c {
//                let ref = target.outlineView.item(atRow: i) as! Ref
//                let k = ref.identity
//                let k1 = target.visibilityTracking.find(atVisibleOffset: i)
//                XCTAssertEqual(k, k1)
//            }
        }
    }
}
