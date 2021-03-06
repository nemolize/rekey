import Cocoa
import RxSwift

private struct ConfigPath {
    let configDirectoryRelativeToHome = ".config/rekey/"
    let configFileName = "config.json"
    var configFilePath: URL {
        configDirectory.appendingPathComponent(configFileName)
    }

    var configDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
            configDirectoryRelativeToHome, isDirectory: true
        )
    }

    static let shared = ConfigPath()
}

class ConfigService: NSObject, NSFilePresenter {
    let presentedItemOperationQueue = OperationQueue()
    private var isPresenting = false

    override init() {
        super.init()
        NSFileCoordinator.addFilePresenter(self)
    }

    deinit { NSFileCoordinator.removeFilePresenter(self) }

    var presentedItemURL: URL? { ConfigPath.shared.configFilePath }

    func loadConfig() -> [String: Any]? {
        if !FileManager.default.fileExists(atPath: ConfigPath.shared.configFilePath.path) {
            debugPrint("config file does not exist at \(ConfigPath.shared.configFilePath)")
            return nil
        }
        do {
            let data = try Data(contentsOf: ConfigPath.shared.configFilePath, options: .mappedIfSafe)
            debugPrint("read from \(ConfigPath.shared.configFilePath.path)")
            guard let json = try JSONSerialization.jsonObject(
                with: data, options: .mutableLeaves
            ) as? [String: Any] else {
                debugPrint("content of config is empty")
                return nil
            }
            return json
        } catch {
            debugPrint(error)
            return nil
        }
    }

    func saveConfig() {
        let dict: [String: Any?] = [
            "windowMove": [
                "up": WindowMoveHotKeyService.shared.getHotKey(.up)?.keyCombo.dictionary,
                "down": WindowMoveHotKeyService.shared.getHotKey(.down)?.keyCombo.dictionary,
                "left": WindowMoveHotKeyService.shared.getHotKey(.left)?.keyCombo.dictionary,
                "right": WindowMoveHotKeyService.shared.getHotKey(.right)?.keyCombo.dictionary,
            ],
        ]

        do {
            try FileManager.default.createDirectory(
                atPath: ConfigPath.shared.configDirectory.path,
                withIntermediateDirectories: true
            )
            let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: ConfigPath.shared.configFilePath)
            debugPrint("wrote to \(ConfigPath.shared.configFilePath.path)")
        } catch {
            debugPrint(error)
        }
    }

    func presentedItemDidChange() {
        // TODO: load config without infinite event loop
    }

    static let shared = ConfigService()
}
