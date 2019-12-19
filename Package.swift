// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "SwiftSDL",
    products: [
      .library( name: "SwiftSDL2", targets: ["SwiftSDL2"] ),
      .executable( name: "DemoSDL2", targets: ["DemoSDL2"]),
    ],
    targets: [
      .target( name: "DemoSDL2", dependencies: ["SwiftSDL2"]), 
      .target( name: "CreateWindowDemo", dependencies: ["SwiftSDL2"]), 
      .target( name: "SwiftSDL2", dependencies: ["CSDL2", "CSDL2_Image", "CSDL2_Mixer", "CSDL2_TTF"]),
      .systemLibrary( name: "CSDL2", pkgConfig: "sdl2"
        , providers: [
            .brew(["sdl2"]),
            .apt(["libsdl2-dev"]) ]
      ),
      .systemLibrary( name: "CSDL2_Image", pkgConfig: "sdl2_image"
        , providers: [
            .brew(["sdl2_image"]),
            .apt(["libsdl2_image-dev"]) ]
      ),
      .systemLibrary( name: "CSDL2_Mixer", pkgConfig: "sdl2_mixer"
        , providers: [
            .brew(["sdl2_mixer"]),
            .apt(["libsdl2_mixer-dev"]) ]
      ),
      .systemLibrary( name: "CSDL2_TTF", pkgConfig: "sdl2_ttf"
        , providers: [
            .brew(["sdl2_ttf"]),
            .apt(["libsdl2_ttf-dev"]) ]
      ),
      //.testTarget( name: "SDLTests", dependencies: ["SDL"]),
    ],
    swiftLanguageVersions: [.v5]
)
