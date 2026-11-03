//
//  PublicAPICompat.swift
//  Example
//
//  Compile-time check that SDK types ported to Swift keep the public API they had in Objective-C.
//  Never called. `make ci-build-example` builds this against the public RadarSDK interface only
//  (no `@testable`), so an `internal` init breaks the build.
//

import RadarSDK

private func checkPublicInitializers() {
    // The old RadarAddress.h declared no init, so `RadarAddress()` and `[RadarAddress new]` were public.
    _ = RadarAddress()
}
