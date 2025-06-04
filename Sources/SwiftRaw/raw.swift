//
//  raw.swift
//  
//
//  Created by Tobias Haeberle on 27.07.21.
//

import ClibrawShim
import Clibraw

public struct RawError: Error, CustomStringConvertible {
    public let code: Int
    
    init(_ errorCode: Int32) {
        self.code = Int(errorCode)
    }
    
    public var description: String {
        String(cString: libraw_strerror(Int32(self.code)))
    }
}

public final class Bitmap {
    private var image: UnsafeMutablePointer<libraw_processed_image_t>
    
    init(_ image: UnsafeMutablePointer<libraw_processed_image_t>) {
        precondition(image.pointee.type == LIBRAW_IMAGE_BITMAP, "image must be bitmap")
        self.image = image
    }
    
    public var colors: UInt16 {
        self.image.pointee.colors
    }
    
    public var bits: UInt16 {
        self.image.pointee.bits
    }
    
    public var width: Int {
        Int(self.image.pointee.width)
    }
    
    public var height: Int {
        Int(self.image.pointee.height)
    }
    
    public func withUnsafeBytes<T>(_ work: (UnsafeRawBufferPointer) throws -> T) rethrows -> T {
        
        let memData = shim_libraw_processed_image_get_data(self.image)

        let buffer = UnsafeRawBufferPointer(start: memData, count: Int(self.image.pointee.data_size))
        
        return try work(buffer)
    }
    
    deinit {
        libraw_dcraw_clear_mem(self.image)
    }
}

public enum Image {
    case jpeg([UInt8])
    case bitmap(Bitmap)
    case jpegxl([UInt8])
    case h265([UInt8])
    
    static func wrapping(_ image: UnsafeMutablePointer<libraw_processed_image_t>) -> Image {
        switch image.pointee.type {
        case LIBRAW_IMAGE_BITMAP:
            return bitmap(.init(image))
        case LIBRAW_IMAGE_JPEG:
            let memData = shim_libraw_processed_image_get_data(image)

            let buffer = UnsafeRawBufferPointer(start: memData, count: Int(image.pointee.data_size))
            
            defer { libraw_dcraw_clear_mem(image) }
            
            return .jpeg(Array(buffer))
        case LIBRAW_IMAGE_JPEGXL:
            let memData = shim_libraw_processed_image_get_data(image)

            let buffer = UnsafeRawBufferPointer(start: memData, count: Int(image.pointee.data_size))
            
            defer { libraw_dcraw_clear_mem(image) }
            
            return .jpegxl(Array(buffer))
        case LIBRAW_IMAGE_H265:
            let memData = shim_libraw_processed_image_get_data(image)

            let buffer = UnsafeRawBufferPointer(start: memData, count: Int(image.pointee.data_size))
            
            defer { libraw_dcraw_clear_mem(image) }
            
            return .h265(Array(buffer))
        default:
            fatalError("Unexpected image format: \( image.pointee.type)")
        }
    }
}

public final class Raw {
    public let data: UnsafeMutablePointer<libraw_data_t>!
    
    init(_ data: UnsafeMutablePointer<libraw_data_t>!) {
        self.data = data
    }
    
    convenience init() {
        self.init(libraw_init(0))
    }
    
    public static func openFile(path: String) throws -> Raw {
        let raw = Raw()
        let res = libraw_open_file(raw.data, path)
        guard res == 0 else {
            throw RawError(res)
        }
        
        return raw
    }
    
    public static func withBuffer<T>(_ buffer: UnsafeRawBufferPointer, _ work: (Raw) throws -> T) throws -> T {
        let raw = Raw()
        let res = libraw_open_buffer(raw.data, UnsafeMutableRawPointer(mutating: buffer.baseAddress), buffer.count)
        guard res == 0 else { throw RawError(res) }
        
        return try work(raw)
    }
    
    public var outputParams: libraw_output_params_t {
        get {
            return self.data.pointee.params
        }
        set {
            self.data.pointee.params = newValue
        }
    }
    
    
    public var imageInfo: libraw_iparams_t {
        self.data.pointee.idata
    }
    
    
    public var sizes: libraw_image_sizes_t {
        self.data.pointee.sizes
    }
    
    public static func withBuffer<Buffer: Collection, T>(_ buffer: Buffer, _ work: (Raw) throws -> T) throws -> T where Buffer.Element == UInt8 {
        let maybeResult: T? = try buffer.withContiguousStorageIfAvailable { bytesPtr -> T in
            let rawPtr = UnsafeRawBufferPointer(bytesPtr)
            return try self.withBuffer(rawPtr, work)
        }
        
        if let result = maybeResult {
            return result
        }
        
        var bufferCopy = Array(buffer)
        return try bufferCopy.withUnsafeMutableBufferPointer { rawPtr -> T in
            return try self.withBuffer(UnsafeRawBufferPointer(rawPtr), work)
        }
    }
    
    /**
     Unpacks the RAW files of the image, calculates the black level (not for all formats). The results are placed in imgdata.image.
     */
    public func unpack() throws {
        let res = libraw_unpack(self.data)
        guard res == 0 else { throw RawError(res) }
    }
    
    public func raw2image() throws {
        let res = libraw_raw2image(self.data)
        guard res == 0 else { throw RawError(res) }
    }
    
    public func subtractBlack() {
        libraw_subtract_black(self.data)
    }
    
    public func color(_ row: Int, _ col: Int) -> Int {
        return Int(libraw_COLOR(self.data, Int32(row), Int32(col)))
    }
    
    public func unpackThumbnail() throws {
        let res = libraw_unpack_thumb(self.data)
        guard res == 0 else { throw RawError(res) }
    }
    
    public func dcrawProcess() throws {
        let res = libraw_dcraw_process(self.data)
        guard res == 0 else { throw RawError(res) }
    }
    
    public func renderImage() throws -> Bitmap {
        var errorCode = Int32(0)
        let memImage = libraw_dcraw_make_mem_image(self.data, &errorCode)
        guard errorCode == 0 else { throw RawError(errorCode) }
        return Bitmap(memImage!)
    }
    
    public func renderThumbnail() throws -> Image {
        var errorCode = Int32(0)
        let memImage = libraw_dcraw_make_mem_thumb(self.data, &errorCode)
        guard errorCode == 0 else { throw RawError(errorCode) }
        return Image.wrapping(memImage!)
    }
    
    
    deinit {
        guard let data = data else { return }
        libraw_close(data)
    }
}
