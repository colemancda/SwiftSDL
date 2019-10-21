import Foundation

class Action: Hashable, Equatable, Updatable {
    typealias UpdateBlock = (_ deltaTime: TimeInterval) -> ()
    
    init(repeats: Bool, atInterval updateInterval: TimeInterval? = nil, speed: Double = 1.0, _ block: @escaping UpdateBlock) {
        self.block          = block
        self.repeats        = repeats
        self.speed          = speed
        self.updateInterval = updateInterval ?? .zero
        self.id             = UUID()
    }
    
    private var block: UpdateBlock?
    private let id: UUID
    private let repeats: Bool
    private let speed: Double
    private let updateInterval: TimeInterval
    private var isCancelled: Bool = false

    private var  previousUpdateTime: TimeInterval = .infinity
    private var remainingUpdateTime: TimeInterval = .zero

    func update(atTime timeInterval: TimeInterval) {
        guard self.isCancelled == false else {
            return
        }
        
        defer {
            self.previousUpdateTime = timeInterval
        }
        
        if self.previousUpdateTime.isInfinite {
            self.previousUpdateTime = timeInterval
        }
        
        let lastUpdateInterval = timeInterval - self.previousUpdateTime
        self.remainingUpdateTime -= lastUpdateInterval * self.speed
        
        if let block = self.block, self.remainingUpdateTime.isLessThanOrEqualTo(.zero) {
            block(lastUpdateInterval)
            self.remainingUpdateTime = self.updateInterval
        }
        
        if self.repeats == false {
            self.block = nil
        }
    }
    
    func cancel() {
        self.isCancelled.toggle()
    }
    
    func hash(into hasher: inout Hasher) {
        self.id.hash(into: &hasher)
    }

    static func == (lhs: Action, rhs: Action) -> Bool {
        lhs.id == rhs.id
    }
}