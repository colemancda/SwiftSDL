extension SDL.Test {
  final class Camera: Game {
    private enum CodingKeys: String, CodingKey {
      case options
      case useAcceleration
      case cameraName
    }
    
    static let configuration = CommandConfiguration(
      abstract: "Simple program to test the SDL camera routines"
    )
    
    @OptionGroup var options: Options

    @Option(
      name: .customLong("camera"),
      help: "Name of the camera to use."
    ) var cameraName: String?
    
    @Flag(name: [
      .customLong("accelerated"),
      .customShort("a")
    ], help: "Use hardware accelerated rendering.")
    var useAcceleration: Bool = false
    
    static let name: String = "SDL Test: Camera"
    
    private var renderer: (any Renderer)!
    private var camera: CameraID? = nil
    private var texture: (any Texture)?
    
    func onReady(window: any Window) throws(SDL_Error) {
      try SDL_Init(.camera)
      
      try self._printCameraInfoMatchingOriginalTestBench()
      
      self.camera = try Cameras.matching { camera, specs, _ in
        switch self.cameraName {
          case let cameraName? where !cameraName.isEmpty:
            let shouldMatchTo = camera.name.contains(cameraName)
            if shouldMatchTo  {
              _printCameraSpecsMatchingOriginalTestBench(specs)
            }
            return shouldMatchTo
          default:
            return true
        }
      }
      
      if let cameraName = self.cameraName, self.camera == nil {
        throw .custom("Could not find camera \"\(cameraName)\"")
      }
    }
    
    func onUpdate(window: any Window, _ delta: Uint64) throws(SDL_Error) {
      guard useAcceleration else {
        try _surfaceDrawing(window)
        return
      }
      
      try _renderDrawing(window)
    }
    
    func onEvent(window: any Window, _ event: SDL_Event) throws(SDL_Error) {
      switch event.eventType {
        case .cameraDeviceApproved:
          print("Camera approved!")
        case .cameraDeviceDenied:
          print("Camera denied")
        default: break
      }
    }
    
    func onShutdown(window: (any Window)?) throws(SDL_Error) {
      texture = nil
      camera?.close()
    }
    
    private func _surfaceDrawing(_ window: any Window) throws(SDL_Error) {
      let surface = try window.surface.get()
      try surface.clear(color: .gray)
      try camera?.draw(to: surface)
      try window.updateSurface()
    }
    
    private func _renderDrawing(_ window: any Window) throws(SDL_Error) {
      if self.renderer == nil {
        do { self.renderer = try window.renderer.get() }
        catch { print(error) }
      }
      
      if self.renderer == nil {
        do { self.renderer = try window.createRenderer() }
        catch { print(error) }
      }
      
      let outputSize = try renderer.outputSize(as: Float.self)
      try camera?.stream(to: &texture, renderer: renderer)
      var dstRect: SDL_FRect = [0, 0, outputSize.x, outputSize.y]
      try renderer(SDL_RenderTexture, texture?.pointer, nil, .some(&dstRect))
      try renderer.present()
    }
    
    private func _printCameraInfoMatchingOriginalTestBench() throws(SDL_Error) {
      let cameras = try Cameras.connected.get()
      let pluralText = cameras.count == 1 ? "" : "s"
      print("Saw \(cameras.count) camera device\(pluralText).")
      for (idx, camera) in cameras.enumerated() {
        var posText = ""
        switch camera.position {
          case .backFacing: posText = "[back-facing]"
          case .frontFacing: posText = "[front-facing]"
          default: break
        }
        let camName = try camera.name.get()
        print("  - Camera #\(idx): \(posText) \(camName)")
      }
    }
    
    private func _printCameraSpecsMatchingOriginalTestBench(_ specs: [SDL_CameraSpec]) {
      print("Available formats:")
      for spec in specs {
        let pixelFormat = SDL_GetPixelFormatName(spec.format)!
        let pixelFormatName = String(cString: pixelFormat)
        print("    \(spec.width)x\(spec.height) \(spec.framesPerSecond) FPS \(pixelFormatName)")
      }
    }
  }
}
