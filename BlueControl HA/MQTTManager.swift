import MQTTNIO
import Foundation
import NIO

class MQTTManager {
    private var mqttClient: MQTTClient?
    
    init() {
        // Configuration du client MQTT
        let configuration = MQTTClient.Configuration(
            keepAliveInterval: .seconds(60), // Intervalle de keep-alive
            connectTimeout: .seconds(10), // Timeout pour la connexion
            userName: "bluecontrol", // Nom d'utilisateur MQTT
            password: "bluecontrol", // Mot de passe MQTT
            useSSL: false // Désactiver SSL
        )
        
        // Création du client MQTT
        mqttClient = MQTTClient(
            host: "192.168.1.161", // Adresse du broker
            port: 1883, // Port par défaut du broker MQTT
            identifier: "BlueControlHA-\(UUID().uuidString)", // Identifiant unique
            eventLoopGroupProvider: .createNew, // Gestion des boucles d'événements
            logger: nil, // Optionnel : Ajouter un logger
            configuration: configuration
        )
    }

    func connect() -> EventLoopFuture<Void> {
        guard let mqttClient = mqttClient else {
            let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
            return eventLoop.makeFailedFuture(
                NSError(domain: "MQTT", code: 1, userInfo: [NSLocalizedDescriptionKey: "Client MQTT introuvable"])
            )
        }

        // Convertir le résultat de connexion (si nécessaire)
        return mqttClient.connect().map { _ in () }
    }
    
    func subscribe(to topic: String) {
         guard let mqttClient = mqttClient else { return }
         
         let subscription = MQTTSubscribeInfo(
             topicFilter: topic,
             qos: .atLeastOnce
         )
         
         mqttClient.subscribe(to: [subscription]).whenComplete { result in
             switch result {
             case .success:
                 print("Abonné au topic : \(topic)")
             case .failure(let error):
                 print("Erreur d'abonnement au topic \(topic) : \(error)")
             }
         }
     }

     func publish(message: String, to topic: String) {
         guard let mqttClient = mqttClient else { return }

         mqttClient.publish(
             to: topic,
             payload: ByteBuffer(string: message),
             qos: .atLeastOnce
         ).whenComplete { result in
             switch result {
             case .success:
                 print("Message publié avec succès sur le topic \(topic)")
             case .failure(let error):
                 print("Erreur lors de la publication : \(error)")
             }
         }
     }
    func listenForMessages() {
        guard let mqttClient = mqttClient else { return }

        mqttClient.addPublishListener(named: "MessageListener") { result in
            switch result {
            case .success(let publishInfo):
                // Convertir le payload reçu en chaîne de caractères
                if let payload = publishInfo.payload.getString(at: 0, length: publishInfo.payload.readableBytes) {
                    print("Message reçu sur le topic '\(publishInfo.topicName)': \(payload)")

                    let bluetoothManager = BluetoothManager()
                    if payload == "off" {
                        bluetoothManager.toggle(false)
                    } else if payload == "on" {
                        bluetoothManager.toggle(true)
                    } else {
                        print("Commande non reconnue : \(payload)")
                    }
                } else {
                    print("Message reçu sur le topic '\(publishInfo.topicName)', mais impossible de lire le payload.")
                }
            case .failure(let error):
                print("Erreur lors de la réception du message : \(error)")
            }
        }
        
    }
    func shutdown() {
        guard let mqttClient = mqttClient else { return }

        // Fermeture propre de la connexion MQTT
        do {
             // Appel de syncShutdownGracefully avec try
             try mqttClient.syncShutdownGracefully()
             print("Client MQTT fermé proprement.")
         } catch {
             // Gestion de l'erreur si le shutdown échoue
             print("Erreur lors de la fermeture du client MQTT : \(error)")
         }
    }
    
    deinit {
        shutdown()
    }
}
