# basic-video-chat-bug
example project to show that OpenTok iOS library 2.16.0+ contains a bug that stops OTAudioDevice from rendering audio after first successful video call. 

How to replicate:
1. Add 2 session ids and 2 tokens at the top of ViewController.swift
2. A and B join the call by clicking "Connect1"
3. A and B can hear each other
4. A and B disconnect from the call by clicking "Disconnect"
5. A and B join the other call by clicking "Connect2"
6. A and B cannot hear (but can see) each other. Subscriber audio level is 0.0. OTAudioDeviceManager.currentAudioDevice()?.isRendering() is false

See the code (especially around #warning()) to know more.
