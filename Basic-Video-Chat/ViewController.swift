//
//  ViewController.swift
//  Hello-World
//
//  Created by Roberto Perez Cubero on 11/08/16.
//  Copyright © 2016 tokbox. All rights reserved.
//

import UIKit
import OpenTok

// *** Fill the following variables using your own Project info  ***
// ***            https://tokbox.com/account/#/                  ***
// Replace with your OpenTok API key
let kApiKey = ""
// Replace with your generated session ID
#warning("You need to make 2 calls so prepare 2 session ids and 2 tokens")
let kSessionId1 = ""
// Replace with your generated token
let kToken1 = ""

let kSessionId2 = ""
// Replace with your generated token
let kToken2 = ""

let kWidgetHeight = 240
let kWidgetWidth = 320

class ViewController: UIViewController {
    var session: OTSession?

    var publisher: OTPublisher?
    
    var subscriber: OTSubscriber?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    @IBAction func connect1ButtonPressed(_ sender: Any) {
        
        doConnect(sessionId: kSessionId1, token: kToken1)
        
    }

    @IBAction func connect2ButtonPressed(_ sender: Any) {
        
        doConnect(sessionId: kSessionId2, token: kToken2)
        
    }
    
    @IBAction func disconnectButtonPressed(_ sender: Any) {
        
        disconnect()
        
    }
    
    /**
     * Asynchronously begins the session connect process. Some time later, we will
     * expect a delegate method to call us back with the results of this action.
     */
    fileprivate func doConnect(sessionId :String, token:String) {
        var error: OTError?
        defer {
            processError(error)
        }
        
        
        
        self.session = OTSession(apiKey: kApiKey, sessionId: sessionId, delegate: self)
        
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        
        #warning("Publisher is not a lazy var but is reinitialized each call")
        self.publisher = OTPublisher(delegate: self, settings: settings)!
        
        self.session!.connect(withToken: token, error: &error)
        
        
    }
    
    fileprivate func disconnect() {
        
        var error: OTError?
        
        defer {
            processError(error)
        }
     
        if let subscriber = self.subscriber {
            
            self.session!.unsubscribe(subscriber, error: &error)
            
            self.cleanupSubscriber()
            
        }

        self.session!.unpublish(publisher!, error: &error)
        
        self.cleanupPublisher()

        
        session!.disconnect(&error)

    }
    
    /**
     * Sets up an instance of OTPublisher to use with this session. OTPubilsher
     * binds to the device camera and microphone, and will provide A/V streams
     * to the OpenTok session.
     */
    fileprivate func doPublish() {
        var error: OTError?
        defer {
            processError(error)
        }
        
        session!.publish(publisher!, error: &error)
        
        if let pubView = publisher!.view {
            pubView.frame = CGRect(x: 0, y: 0, width: kWidgetWidth, height: kWidgetHeight)
            view.addSubview(pubView)
        }
    }
    
    /**
     * Instantiates a subscriber for the given stream and asynchronously begins the
     * process to begin receiving A/V content for this stream. Unlike doPublish,
     * this method does not add the subscriber to the view hierarchy. Instead, we
     * add the subscriber only after it has connected and begins receiving data.
     */
    fileprivate func doSubscribe(_ stream: OTStream) {
        var error: OTError?
        defer {
            processError(error)
        }
        subscriber = OTSubscriber(stream: stream, delegate: self)
        
        session!.subscribe(subscriber!, error: &error)
        
        subscriber?.audioLevelDelegate = self
        
    }
    
    fileprivate func cleanupSubscriber() {
        subscriber?.view?.removeFromSuperview()
        subscriber = nil
    }
    
    fileprivate func cleanupPublisher() {
        publisher!.view?.removeFromSuperview()
        
        #warning("If the publisher is released after the call, the second call will be without audio")
        publisher = nil//comment this line to get the audio working
        
    }
    
    fileprivate func processError(_ error: OTError?) {
        if let err = error {
            DispatchQueue.main.async {
                let controller = UIAlertController(title: "Error", message: err.localizedDescription, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(controller, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - OTSession delegate callbacks
extension ViewController: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        print("Session connected")
        doPublish()
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        print("Session disconnected")
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("Session streamCreated: \(stream.streamId)")
        if subscriber == nil {
            doSubscribe(stream)
        }
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("Session streamDestroyed: \(stream.streamId)")
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("session Failed to connect: \(error.localizedDescription)")
    }
    
}

// MARK: - OTPublisher delegate callbacks
extension ViewController: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        print("Publishing")
    }
    
    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        cleanupPublisher()
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
    }
    
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("Publisher failed: \(error.localizedDescription)")
    }
}

// MARK: - OTSubscriber delegate callbacks
extension ViewController: OTSubscriberDelegate {
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        #warning("When the second call takes place, the current audio device is NOT rendering")
        print("Subscriber connected. Current audio device is rendering \(OTAudioDeviceManager.currentAudioDevice()?.isRendering())")
        
        if let subsView = subscriber?.view {
            subsView.frame = CGRect(x: 0, y: kWidgetHeight, width: kWidgetWidth, height: kWidgetHeight)
            view.addSubview(subsView)
        }
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("Subscriber failed: \(error.localizedDescription)")
    }
}


extension ViewController:OTSubscriberKitAudioLevelDelegate {
    func subscriber(_ subscriber: OTSubscriberKit, audioLevelUpdated audioLevel: Float) {
        #warning("During the second call, subscriber's audio level is 0")
        print("Audio level is \(audioLevel)")
        
    }
    
    
    
    
}
