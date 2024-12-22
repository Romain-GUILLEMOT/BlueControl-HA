import Cocoa
import IOKit.pwr_mgt  // Importer IOKit pour la gestion de l'énergie

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var mqttManager: MQTTManager?
    var preventSleepAssertion: IOPMAssertionID = 0 // Variable pour stocker l'assertion

    func showErrorPopup(message: String) {
        let alert = NSAlert()
        alert.messageText = "Erreur MQTT"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
   
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Créer une power assertion pour empêcher le Mac de se mettre en veille
        let reasonForActivity = "Prevent sleep while app is running"
        
        // Convertir la constante kIOPMAssertionTypePreventUserIdleSystemSleep en CFString
        let assertionType = kIOPMAssertionTypePreventUserIdleSystemSleep as CFString
        
        // Convertir reasonForActivity en CFString
        let activityReason = reasonForActivity as CFString
        
        // Créer l'assertion pour empêcher la mise en veille
        let success = IOPMAssertionCreateWithName(
            assertionType,               // CFString pour le type d'assertion
            IOPMAssertionLevel(kIOPMAssertionLevelOn), // Niveau de l'assertion
            activityReason,               // CFString pour la raison
            &preventSleepAssertion       // ID de l'assertion
        )
        
        if success == kIOReturnSuccess {
            print("Empêcher la mise en veille avec succès.")
        } else {
            print("Échec de l'empêchement de la mise en veille.")
        }

        mqttManager = MQTTManager()

        mqttManager?.connect().whenComplete { [weak self] result in
            switch result {
            case .success:
                print("Connecté au broker MQTT avec succès")
                self?.mqttManager?.subscribe(to: "homeassistant/bluecontrol")
                self?.mqttManager?.listenForMessages()
                self?.mqttManager?.publish(message: "online", to: "homeassistant/bluecontrol")
                self?.mqttManager?.publish(message: "on", to: "homeassistant/bluecontrol")

            case .failure(let error):
                print("Erreur lors de la connexion au broker MQTT : \(error.localizedDescription)")
                self?.showErrorPopup(message: "Impossible de se connecter au broker MQTT.\n\(error.localizedDescription)")
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Libérer la power assertion lorsque l'application se termine
        IOPMAssertionRelease(preventSleepAssertion)
        print("Application se termine, la gestion de la mise en veille a été relâchée.")

        mqttManager?.connect().whenComplete { [weak self] result in
            switch result {
            case .success:
                self?.mqttManager?.publish(message: "offline", to: "homeassistant/bluecontrol")
            case .failure(let error):
                print("Erreur lors de la connexion au broker MQTT : \(error.localizedDescription)")
                self?.showErrorPopup(message: "Impossible de se connecter au broker MQTT.\n\(error.localizedDescription)")
            }
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
