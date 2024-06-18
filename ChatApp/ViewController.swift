import UIKit
import Starscream

class ViewController: UIViewController, WebSocketDelegate{
    @IBOutlet weak var input: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var content: UILabel!
    @IBOutlet weak var status: UILabel!
    
    var myName = false
    var socket: WebSocket!
    var isConnected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var request = URLRequest(url: URL(string: "ws://localhost:1337/")!)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.delegate = self
        
        self.content.text = "Not connected to Websocket 😞"
        
        socket.connect()
    }
    
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocketClient) {
        switch event {
        case .connected(let headers):
            isConnected = true
            print("websocket is connected: \(headers)")
            self.content.text = "Connected to Websocket 😊"
        case .disconnected(let reason, let code):
            isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
            self.content.text = "Disconnected from Websocket 😞"
        case .text(let string):
            guard let data = string.data(using: .utf8) else {
                return
            }
            guard var receivedMesage = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return
            }
            print(receivedMesage)
            var type = receivedMesage["type"] as! String
            
            switch type{
            case "history":
                var data = receivedMesage["data"]
                self.content.text = ""
                var history = ""
                if let dataArray = data as? [[String: Any]] {
                    for item in dataArray {
                        if let author = item["author"] as? String, let text = item["text"] as? String {
                            history += "[\(author)]: \(text)\n"
                        }
                    }
                }
                self.content.text = history
                break
            case "message":
                var data = receivedMesage["data"]
                
                if let dataDict = data as? [String: Any] {
                    if let author = dataDict["author"] as? String, let text = dataDict["text"] as? String {
                        self.content.text! += "[\(author)]: \(text)\n"
                    }
                }
                break
            default:
                self.content.text = ""
                break
            }
            
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            isConnected = false
        case .error(let error):
            isConnected = false
            print(error)
        case .peerClosed:
               break
        }
    }
    
    @IBAction func sendButtonPressed(_ sender: Any) {
        if self.myName == false {
            socket.write(string: self.input.text!)
            self.status.text = self.input.text!
            self.input.text = ""
            self.myName = true
            return
        }
        socket.write(string: self.input.text!)
        self.input.text = ""
        return
    }
    
    deinit {
        socket.disconnect()
        socket.delegate = nil
    }
    
}
