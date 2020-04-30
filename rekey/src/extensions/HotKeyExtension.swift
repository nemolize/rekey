import HotKey

extension HotKey {
    func setHandler(_ block: @escaping (Bool) -> Void) -> Self {
        self.keyDownHandler = {
            block(true)
        }

        self.keyUpHandler = {
            block(false)
        }
        return self
    }
}
