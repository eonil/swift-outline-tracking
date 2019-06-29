//
//  ParentTrackingTest.swift
//  OutlineVisibilityTrackingTest
//
//  Created by Henry on 2019/06/29.
//

import XCTest
import Tree
@testable import OutlineTracking

class ParentTrackingTest: XCTestCase {
    func test1() {
        var x = ParentChildTracking<Int>()
        x.insertLeaf(111, in: nil)
        x.insertLeaf(222, in: nil)
        x.insertLeaf(333, in: nil)
        XCTAssertEqual(x.parent(for: 111), nil)
        XCTAssertEqual(x.parent(for: 222), nil)
        XCTAssertEqual(x.parent(for: 333), nil)

        x.insertLeaf(111_111, in: 111)
        x.insertLeaf(222_111, in: 222)
        XCTAssertEqual(x.parent(for: 111_111), 111)
        XCTAssertEqual(x.parent(for: 222_111), 222)

        x.insertLeaf(111_111_111, in: 111_111)
        XCTAssertEqual(x.parent(for: 111_111_111), 111_111)

        x.removeSubtree(111)
        XCTAssertEqual(x.parentMap[111], Optional<Optional<Int>>.none)
        XCTAssertEqual(x.parentMap[111_111], Optional<Optional<Int>>.none)
        XCTAssertEqual(x.parentMap[111_111_111], Optional<Optional<Int>>.none)
        XCTAssertEqual(x.parent(for: 222_111), 222)
    }
}
