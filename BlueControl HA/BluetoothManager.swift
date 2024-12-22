import Foundation

class BluetoothManager {
    private let mqttManager = MQTTManager()

    // Fonction pour exécuter une commande shell
    private func runCommand(_ command: String) {
        print("Exécution de la commande : \(command)")

        let process = Process()
        process.launchPath = "/bin/zsh"
        process.arguments = ["-c", command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        process.launch()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            print("Résultat de la commande : \(output)")
        } else {
            print("Aucun résultat de la commande.")
        }

        print("Code de sortie : \(process.terminationStatus)")
    }

    // Fonction pour activer ou désactiver le Bluetooth
    func toggle(_ state: Bool) {
        print(state)
        let command = state ? "/opt/homebrew/bin/blueutil --power 1" : "/opt/homebrew/bin/blueutil --power 0"
        runCommand(command)
    
    }

}
