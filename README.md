# SwiftRaw

A thin Swift wrapper around [LibRaw](https://libraw.org). Work in progress... 


### How to use


```swift
import SwiftRaw

let raw = try Raw.openFile(path: "my-raw-file.CR2")
try raw.unpack()
try raw.dcrawProcess()
let bitmap = try raw.renderImage()
// do something with bitmap
bitmap.withUnsafeBytes { buf in
    // convert to PNG, render to screen, etc ...
}

```
