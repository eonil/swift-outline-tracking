//
//  VisibilityTrackingTest.swift
//  VisibilityTrackingTest
//
//  Created by Henry on 2019/06/29.
//

import XCTest
import Tree
import PD
@testable import OutlineTracking

class VisibilityTrackingTest: XCTestCase {
    func testTwoDepths() {
        var s = KVLTStorage<Int,String>()
        s.insert((111,"aaa"), at: 0, in: nil)
        s.insert((222,"bbb"), at: 0, in: 111)

        var x = VisibilityTracking<Int>()
        x.insertSubtree(s.collection[0], at: 0, in: nil)

        XCTAssertEqual(x.state(for: 111).totalCount, 2)
        XCTAssertEqual(x.state(for: 111).totalVisibleCount, 1)
        XCTAssertEqual(x.state(for: 111).totalVisibleDescendantsCount, 1)
        XCTAssertEqual(x.state(for: 222).totalCount, 1)
        XCTAssertEqual(x.state(for: 222).totalVisibleCount, 1)
        XCTAssertEqual(x.state(for: 222).totalVisibleDescendantsCount, 0)

        x.setExpansionState(true, of: 111)
        XCTAssertEqual(x.state(for: 111).totalVisibleCount, 2)
        XCTAssertEqual(x.state(for: 222).totalVisibleCount, 1)

        x.setExpansionState(true, of: 222)
        XCTAssertEqual(x.state(for: 111).totalVisibleCount, 2)
        XCTAssertEqual(x.state(for: 222).totalVisibleCount, 1)
    }
    func testThreeDepths() {
        var s = KVLTStorage<Int,String>()
        s.insert((111,"aaa"), at: 0, in: nil)
        s.insert((222,"bbb"), at: 0, in: 111)
        s.insert((333,"ccc"), at: 0, in: 222)

        var x = VisibilityTracking<Int>()
        x.insertSubtree(s.collection[0], at: 0, in: nil)

        XCTAssertEqual(x.state(for: 111).totalCount, 3)
        XCTAssertEqual(x.state(for: 111).totalVisibleCount, 1)
        XCTAssertEqual(x.state(for: 111).totalVisibleDescendantsCount, 1)
        XCTAssertEqual(x.state(for: 222).totalCount, 2)
        XCTAssertEqual(x.state(for: 222).totalVisibleCount, 1)
        XCTAssertEqual(x.state(for: 222).totalVisibleDescendantsCount, 1)
        XCTAssertEqual(x.state(for: 333).totalCount, 1)
        XCTAssertEqual(x.state(for: 333).totalVisibleCount, 1)
        XCTAssertEqual(x.state(for: 333).totalVisibleDescendantsCount, 0)

        x.setExpansionState(true, of: 111)
        XCTAssertEqual(x.state(for: 111).totalVisibleCount, 2)
        XCTAssertEqual(x.state(for: 111).totalVisibleDescendantsCount, 1)
        XCTAssertEqual(x.state(for: 222).totalVisibleCount, 1)
        XCTAssertEqual(x.state(for: 333).totalVisibleCount, 1)

        x.setExpansionState(true, of: 222)
        XCTAssertEqual(x.state(for: 111).totalVisibleCount, 3)
        XCTAssertEqual(x.state(for: 222).totalVisibleCount, 2)
        XCTAssertEqual(x.state(for: 333).totalVisibleCount, 1)

        x.setExpansionState(true, of: 333)
        XCTAssertEqual(x.state(for: 111).totalVisibleCount, 3)
        XCTAssertEqual(x.state(for: 222).totalVisibleCount, 2)
        XCTAssertEqual(x.state(for: 333).totalVisibleCount, 1)
    }
    func testThreeDepthsWithMultipleElements() {
        var s = KVLTStorage<Int,String>()
        s.insert((11,"a"), at: 0, in: nil)
        s.insert((11_11,"aa"), at: 0, in: 11)
        s.insert((11_11_11,"aaa"), at: 0, in: 11_11)
        s.insert((11_11_22,"aab"), at: 1, in: 11_11)

        var x = VisibilityTracking<Int>()
        x.insertSubtree(s.collection[0], at: 0, in: nil)

        XCTAssertEqual(x.state(for: 11).totalCount, 4)
        XCTAssertEqual(x.state(for: 11).totalVisibleCount, 1)
        XCTAssertEqual(x.state(for: 11).totalVisibleDescendantsCount, 1)
        XCTAssertEqual(x.state(for: 11_11).totalCount, 3)
        XCTAssertEqual(x.state(for: 11_11).totalVisibleCount, 1)
        XCTAssertEqual(x.state(for: 11_11).totalVisibleDescendantsCount, 2)
        XCTAssertEqual(x.state(for: 11_11_11).totalCount, 1)
        XCTAssertEqual(x.state(for: 11_11_11).totalVisibleCount, 1)
        XCTAssertEqual(x.state(for: 11_11_11).totalVisibleDescendantsCount, 0)
        XCTAssertEqual(x.state(for: 11_11_22).totalCount, 1)
        XCTAssertEqual(x.state(for: 11_11_22).totalVisibleCount, 1)
        XCTAssertEqual(x.state(for: 11_11_22).totalVisibleDescendantsCount, 0)

        x.setExpansionState(true, of: 11)
        XCTAssertEqual(x.state(for: 11).isExpanded, true)
        XCTAssertEqual(x.state(for: 11).totalVisibleCount, 2)
        XCTAssertEqual(x.state(for: 11).totalVisibleDescendantsCount, 1)
        XCTAssertEqual(x.state(for: 11_11).isExpanded, false)
        XCTAssertEqual(x.state(for: 11_11).totalVisibleCount, 1)
        XCTAssertEqual(x.state(for: 11_11_11).isExpanded, false)
        XCTAssertEqual(x.state(for: 11_11_11).totalVisibleCount, 1)
        XCTAssertEqual(x.state(for: 11_11_22).isExpanded, false)
        XCTAssertEqual(x.state(for: 11_11_22).totalVisibleCount, 1)

        x.setExpansionState(true, of: 11_11)
        XCTAssertEqual(x.state(for: 11).isExpanded, true)
        XCTAssertEqual(x.state(for: 11).totalVisibleCount, 4)
        XCTAssertEqual(x.state(for: 11_11).isExpanded, true)
        XCTAssertEqual(x.state(for: 11_11).totalVisibleCount, 3)
        XCTAssertEqual(x.state(for: 11_11_11).isExpanded, false)
        XCTAssertEqual(x.state(for: 11_11_11).totalVisibleCount, 1)
        XCTAssertEqual(x.state(for: 11_11_22).isExpanded, false)
        XCTAssertEqual(x.state(for: 11_11_22).totalVisibleCount, 1)

        x.setExpansionState(true, of: 11_11_11)
        XCTAssertEqual(x.state(for: 11).isExpanded, true)
        XCTAssertEqual(x.state(for: 11).totalVisibleCount, 4)
        XCTAssertEqual(x.state(for: 11_11).isExpanded, true)
        XCTAssertEqual(x.state(for: 11_11).totalVisibleCount, 3)
        XCTAssertEqual(x.state(for: 11_11_11).isExpanded, true)
        XCTAssertEqual(x.state(for: 11_11_11).totalVisibleCount, 1)
        XCTAssertEqual(x.state(for: 11_11_22).isExpanded, false)
        XCTAssertEqual(x.state(for: 11_11_22).totalVisibleCount, 1)
        XCTAssertEqual(x.find(atVisibleOffset: 0), 11)
        XCTAssertEqual(x.find(atVisibleOffset: 1), 11_11)
        XCTAssertEqual(x.find(atVisibleOffset: 2), 11_11_11)
        XCTAssertEqual(x.find(atVisibleOffset: 3), 11_11_22)
    }
    func testOneStepReplay() {
        var r = PDKVLTRepository<Int,String>()
        var x = VisibilityTracking<Int>()
        r.insert((11,"a"), at: 0, in: nil)
        x.replay(r.timeline.steps[0])
        XCTAssertEqual(x.tree.collection[0].key, 11)
    }
    func testTwoStepReplay() {
        var r = PDKVLTRepository<Int,String>()
        var x = VisibilityTracking<Int>()
        r.insert((11,"a"), at: 0, in: nil)
        r.insert((22,"b"), at: 1, in: nil)
        x.replay(r.timeline.steps[0])
        x.replay(r.timeline.steps[1])
        XCTAssertEqual(x.tree.collection[0].key, 11)
        XCTAssertEqual(x.tree.collection[1].key, 22)
    }
    func testThreeStepReplay() {
        var r = PDKVLTRepository<Int,String>()
        var x = VisibilityTracking<Int>()
        r.insert((11,"a"), at: 0, in: nil)
        r.insert((22,"b"), at: 1, in: nil)
        r.remove(at: 0, in: nil)
        for s in r.timeline.steps {
            x.replay(s)
        }
        XCTAssertEqual(x.tree.collection[0].key, 22)
    }
}

