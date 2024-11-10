import SwiftSDL

extension SDL.Test {
  final class Controller: Game {
    private enum CodingKeys: String, CodingKey {
      case options
      case useVirtual
    }
    
    static let configuration = CommandConfiguration(
      abstract: "Simple program to test the SDL controller routines"
    )
    
    @OptionGroup var options: Options
    
    @Flag(name: [.customLong("virtual")], help: "Simulate a virtual gamepad.")
    var useVirtual: Bool = false

    static let name: String = "SDL Test: Controller"
    
    private var renderer: (any Renderer)!
    private var state: State!
    
    func onInit() throws(SDL_Error) -> any Window {
      print("Applying SDL Hints...")
      _applyHints()
      
      print("Initializing SDL (v\(SDL_Version()))...")
      try SDL_Init(.video, .gamepad)
      
      let display = try Displays.primary.get()
      let contentScale = (try? display.contentScale.get()) ?? 1
      let screenSize = Layout
        .screenSize(scaledBy: contentScale)
        .to(Sint64.self)

      let window = try SDL_CreateWindow(
        with: .windowTitle(Self.name),
        .width(screenSize.x), .height(screenSize.y)
      )
      
      return window
    }
    
    func onReady(window: any Window) throws(SDL_Error) {
      renderer = try window.createRenderer(with: (SDL_PROP_RENDERER_VSYNC_NUMBER, 1))
      state = try State(renderer: renderer)
    }

    func onUpdate(window: any Window, _ delta: Uint64) throws(SDL_Error) {
      SDL_Delay(16)
      try renderer
        .clear(color: .white)
        .debug(text: state.gamepadDisplay.joystickIDText, position: state.gamepadDisplay.joystickIDTextPosition, color: .black)
        .debug(text: state.gamepadDisplay.title, position: state.gamepadDisplay.titleTextPosition, color: .black)
        .debug(text: state.gamepadDisplay.subtitle, position: state.gamepadDisplay.subtitleTextPosition, color: .black)
        .debug(text: state.gamepadDisplay.miscIDText, position: state.gamepadDisplay.miscTextPosition, color: .black)
        .debug(text: state.gamepadDisplay.serialText, position: state.gamepadDisplay.serialTextPosition, color: .black)
        .draw(into: { renderer in
          for i in 0..<10 {
            try renderer.fill(rects: [Float(i * 10), 400, 100, 100], color: i % 2 == 0 ? .green : .red)
          }
        })
        .draw(texture: state.gamepadDisplay.gamepadTexture, position: Layout.gamepadImagePosition)
        .present()
    }
    
    func onEvent(window: any Window, _ event: SDL_Event) throws(SDL_Error) {
      var event = event
      try renderer(SDL_ConvertEventToRenderCoordinates, .some(&event))
      
      switch event.eventType {
        case .joystickAdded: ()
          print("Joystick Added:", event.jdevice.which)
        case .joystickRemoved: ()
          print("Joystick Removed:", event.jdevice.which)
        case .joystickAxisMotion: ()
        case .joystickButtonDown: ()
        case .joystickButtonUp: ()
        case .joystickHatMotion: ()
          
        case .gamepadAdded: ()
          print("Gamepad Added:", event.gdevice.which)
        case .gamepadRemoved: ()
          print("Gamepad Removed:", event.gdevice.which)
        case .gamepadRemapped: ()
        case .gamepadSteamHandleUpdated: ()
        case .gamepadButtonDown: fallthrough
        case .gamepadButtonUp: ()
          
        case .mouseButtonDown: ()
        case .mouseButtonUp: ()
        case .mouseMotion: ()

        case .keyDown:
          guard case(.open) = state.joystick else {
            if event.key.key == SDLK_A {
              try state.joystick = Joysticks
                .attachVirtual(
                  type: .gamepad,
                  touchpads: [.init(nfingers: 1, padding: (0, 0, 0))],
                  sensors: [.init(type: .accelerometer, rate: 0)]
                )
                .open()
              
              print("Is Gamepad:", SDL_IsGamepad(state.joystick.id))
            }

            /*
            if event.key.key == SDLK_ESCAPE {
              state.display = .detached
            } else {
              state.display = event.key.down ? .back(state.gamepadRear) : .front(state.gamepadFront)
            }
             */
            break;
          }
          
          if event.key.key >= SDLK_0 && event.key.key <= SDLK_9 {
            let playerIndex = (event.key.key - SDLK_0)
            try state.joystick.set(playerIndex: playerIndex)
          }
          else if event.key.key == SDLK_D {
            if state.joystick.isVirtual {
              print("Closing virtual joystick...")
              try state.joystick.close()
            }
          }
          else if event.key.key == SDLK_R && ((UInt32(event.key.mod) & SDL_KMOD_CTRL) != 0) {
          }
        case .keyUp: ()

        case .textInput: ()
          
        default: ()
      }
    }
    
    func onShutdown(window: any Window) throws(SDL_Error) {
      state = nil
      renderer = nil
    }
    
    private func _applyHints() {
      #if os(macOS)
      // Wired 360 controller wasn't reported...related?
      // See this issue: https://github.com/libsdl-org/SDL/issues/11002
      SDL_SetHint(SDL_HINT_JOYSTICK_MFI, "0")
      #endif
      SDL_SetHint(SDL_HINT_JOYSTICK_HIDAPI, "1");
      SDL_SetHint(SDL_HINT_JOYSTICK_HIDAPI_PS4_RUMBLE, "1");
      SDL_SetHint(SDL_HINT_JOYSTICK_HIDAPI_PS5_RUMBLE, "1");
      SDL_SetHint(SDL_HINT_JOYSTICK_HIDAPI_STEAM, "1");
      SDL_SetHint(SDL_HINT_JOYSTICK_ROG_CHAKRAM, "1");
      SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1");
      SDL_SetHint(SDL_HINT_JOYSTICK_LINUX_DEADZONES, "1");
      SDL_SetHint(SDL_HINT_RENDER_VSYNC, "1")
    }
  }
}

extension SDL.Test.Controller {
  struct State {
    @MainActor init(renderer: any Renderer) throws(SDL_Error) {
      let surfaceFront = try Load(bitmap: "gamepad_front.bmp")
      gamepadFront = try renderer.texture(from: surfaceFront)
      
      let surfaceRear = try Load(bitmap: "gamepad_back.bmp")
      gamepadRear = try renderer.texture(from: surfaceRear)
    }
    
    private(set) var gamepadDisplay: GamepadDisplay = .detached
    private(set) var showRear: Bool = false
    
    private var gamepadFront: (any Texture)!
    private var gamepadRear: (any Texture)!
    
    var joystick: Joystick = .invalid {
      willSet {
        print(newValue.guid)
      }
      didSet {
        guard case(.open) = joystick else {
          gamepadDisplay = .detached
          return
        }
        
        gamepadDisplay = showRear ? .back(joystick, gamepadRear) : .front(joystick, gamepadFront)
      }
    }
  }
  
  enum GamepadDisplay {
    case detached
    case front(Joystick, (any Texture)!)
    case back(Joystick, (any Texture)!)
    
    var gamepadTexture: (any Texture)! {
      switch self {
        case .detached: return nil
        case .front(_, let texture): return texture
        case .back(_, let texture): return texture
      }
    }
    
    private var joystick: Joystick? {
      switch self {
        case .detached: return nil
        case .front(let joystick, _): return joystick
        case .back(let joystick, _): return joystick
      }
    }

    @MainActor
    var title: String {
      switch self {
        case .back(let joystick, _): return (try? joystick.name.get()) ?? "Back"
        case .front(let joystick, _): return (try? joystick.name.get()) ?? "Front"
        case .detached: return "Waiting for gamepad, press A to add a virtual controller"
      }
    }
    
    @MainActor
    var subtitle: String {
      guard joystick != nil else {
        return ""
      }
      return "Click on the gamepad image below to generate input"
    }
    
    @MainActor
    var joystickIDText: String {
      guard let joystick = joystick else {
        return ""
      }
      return "(\(joystick.id))"
    }
    
    @MainActor
    var miscIDText: String {
      guard let joystick = joystick else {
        return ""
      }

      let vID = String(joystick.vendorID, radix: 16)
      let pID = String(joystick.productID, radix: 16)
      return "VID: 0x\(vID), PID: 0x\(pID)"
    }
    
    @MainActor
    var serialText: String {
      guard let joystick = joystick, !joystick.isVirtual else {
        return ""
      }
      
      return "Serial: \(joystick.serial)"
    }

    @MainActor
    var joystickIDTextPosition: Point<Float> {
      let width: Float = Layout.sceneWidth - (Layout.fontCharacterSize * Float(SDL_strlen(joystickIDText))) - 8
      let height: Float = 8
      return [width, height]
    }
    
    @MainActor
    var titleTextPosition: Point<Float> {
      let width = (Layout.sceneWidth / 2) - (Layout.fontCharacterSize * Float(SDL_strlen(title)) / 2)
      let height = (Layout.titleHeight / 2) - (Layout.fontCharacterSize / 2)
      return [width, height]
    }
    
    @MainActor
    var subtitleTextPosition: Point<Float> {
      let width = (Layout.sceneWidth / 2) - (Layout.fontCharacterSize * Float(SDL_strlen(subtitle)) / 2)
      let height = (Layout.titleHeight / 2) - (Layout.fontCharacterSize / 2) + (Layout.fontCharacterSize + 2.0) + 2.0
      return [width, height]
    }
    
    @MainActor
    var miscTextPosition: Point<Float> {
      let width = Layout.sceneWidth - 8.0 - (Layout.fontCharacterSize * Float(SDL_strlen(miscIDText)))
      let height = Layout.sceneHeight - 8.0 - Layout.fontCharacterSize
      return [width, height]
    }
    @MainActor
    var serialTextPosition: Point<Float> {
      let width = (Layout.sceneWidth / 2) - (Layout.fontCharacterSize * Float(SDL_strlen(miscIDText)) / 2)
      let height = Layout.sceneHeight - 8.0 - Layout.fontCharacterSize
      return [width, height]
    }
  }
  
  struct Layout {
    static let titleHeight: Float = 48.0
    static let panelSpacing: Float = 25.0
    static let panelWidth: Float = 250.0
    static let minimumButtonWidth: Float = 96.0
    static let buttonMargin: Float = 16.0
    static let buttonPadding: Float = 12.0
    static let gamepadWidth: Float = 512.0
    static let gamepadHeight: Float = 560.0
    static let fontCharacterSize: Float = Float(SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE)
    
    static var gamepadImagePosition: Point<Float> {
      [Self.panelWidth + Self.panelSpacing, Self.titleHeight]
    }
    
    static var titleFrame: Rect<Float> {
      var width = gamepadWidth
      var height = Self.fontCharacterSize + 2.0 * Self.buttonMargin
      var xPos = Self.panelWidth + Self.panelSpacing
      var yPos = Self.titleHeight / 2 - height / 2
      
      width = Self.panelWidth - 2 * Self.buttonMargin
      height = Self.fontCharacterSize + 2 * Self.buttonMargin
      xPos = Self.buttonMargin
      yPos = Self.titleHeight / 2 - height / 2
      
      return Rect(lowHalf: [xPos, yPos], highHalf: [width, height])
    }
    
    static var gamepadDisplayArea: Rect<Float> {
      [
        0, Self.titleHeight,
        Self.panelWidth, Self.gamepadHeight
      ]
    }
    
    static var gamepadTypeDisplayArea: Rect<Float> {
      [
        0, Self.titleHeight,
        Self.panelWidth, Self.gamepadHeight
      ]
    }
    
    @MainActor
    static let sceneWidth = panelWidth
    + panelSpacing
    + gamepadWidth
    + panelSpacing
    + panelWidth
    
    @MainActor
    static let sceneHeight = titleHeight
    + gamepadHeight
    
    @MainActor
    static func screenSize(scaledBy scale: Float = 1.0) -> Size<Sint64> {
      let scaledSize = Size(x: sceneWidth, y: sceneHeight).to(Float.self) * scale
      let size: Size<Float> = [SDL_ceilf(scaledSize.x), SDL_ceilf(scaledSize.y)]
      return size.to(Sint64.self)
    }
  }
}

extension SDL.Test.Controller {
  final class Button: SpriteNode<any Renderer> {
    enum State: Equatable {
      case highlighted
      case pressed
    }
  }
}
