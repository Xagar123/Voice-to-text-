//
//  ViewController.swift
//  Voice to Text
//
//  Created by Sagar on 16/01/24.
//

import UIKit
import Speech
import AVFoundation


class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    @IBOutlet weak var textLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //check if recognization is available
        SFSpeechRecognizer.requestAuthorization { authState in
            if authState == SFSpeechRecognizerAuthorizationStatus.authorized {
                //Speech recognization is authorised
                print("authorized success")
            }
        }
    }
    
    func startSpeechRecognition() {
        do {
            try startRecording()
        } catch {
            print("Error starting recording: \(error)")
        }
    }
    
    func startRecording() throws {
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup error: \(error)")
        }

        let inputNode: AVAudioInputNode? = audioEngine.inputNode

        guard let inputNode = inputNode else {
            print("Audio engine has no input node")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
        }

        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            // Handle recognition results here
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                print("Transcription: \(transcription)")
                self.textLabel.text = transcription
            } else if let error = error {
                print("Recognition error: \(error)")
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start error: \(error)")
        }
    }

    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
    
    func resetAudioEngine() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest = nil
        recognitionTask = nil
        self.textLabel.text = ""
    }
    
    @IBAction func startButtonPressed(_ sender: UIButton) {
        startSpeechRecognition()
        
    }
    
    @IBAction func stopButtonPressed(_ sender: UIButton) {
        resetAudioEngine()
        stopRecording()
    }
}
