//
//  SwiftRawTests.swift
//  
//
//  Created by Tobias Haeberle on 27.05.22.
//

import XCTest
import SwiftRaw

class SwiftRawTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSimpleDCRawProcess() throws {
        let url = Bundle.module.resourceURL!
            .appendingPathComponent("data")
            .appendingPathComponent("raw_example.CR2")
        
        let raw = try Raw.openFile(path: url.path)
        try raw.unpack()
        
        XCTAssertEqual(raw.sizes.width, 5202)
        XCTAssertEqual(raw.sizes.height, 3464)
        
        let make : String = withUnsafeBytes(of: raw.imageInfo.make) { (p)  in
            String(cString: p.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
        XCTAssertEqual(make, "Canon")
        
        try raw.dcrawProcess()
        let bitmap = try raw.renderImage()
        
    
        // do something with bitmap
        XCTAssertEqual(3464, bitmap.height)
        XCTAssertEqual(5202, bitmap.width)
        XCTAssertEqual(bitmap.bits, 8)
        XCTAssertEqual(bitmap.colors, 3)
        bitmap.withUnsafeBytes { buf in
            XCTAssertEqual(buf.count, bitmap.height * bitmap.width * Int(bitmap.colors) * Int(bitmap.bits) / 8)
        }
        
    }

    func testCR3WithHeif() throws {
        let url = Bundle.module.resourceURL!
            .appendingPathComponent("data")
            .appendingPathComponent("heif_thumb.cr3")

        let raw = try Raw.openFile(path: url.path)
        try raw.unpack()
        try raw.unpackThumbnail()

        let thumbnail = try raw.renderThumbnail()
        switch thumbnail {
            case .heif(let bytes):
                XCTAssertEqual(bytes.count, 739784)
            default:
                XCTFail("Expected heif thumbnail, got \(thumbnail) instead")
        }
    }

}
