// HELPERS/AudioDeviceHelper.swift
// This file provides utilities for retrieving audio device information
// Location: Helpers/AudioDeviceHelper.swift
//
// Usage Example:
// 1. Create an instance: @StateObject private var audioHelper = AudioDeviceHelper()
// 2. Display current device: Text(audioHelper.currentOutputDeviceName ?? "No Device")
// 3. List all devices: ForEach(audioHelper.availableDevices) { device in ... }
// 4. Switch devices: audioHelper.setOutputDevice(selectedDevice)

import CoreAudio
import Foundation
import Combine

/// C-style callback function for audio device property changes
private func audioDevicePropertyListener(
    inObjectID: AudioObjectID,
    inNumberAddresses: UInt32,
    inAddresses: UnsafePointer<AudioObjectPropertyAddress>,
    inClientData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let clientData = inClientData else {
        return kAudioHardwareNoError
    }
    
    let helper = Unmanaged<AudioDeviceHelper>.fromOpaque(clientData).takeUnretainedValue()
    
    DispatchQueue.main.async {
        helper.refresh()
    }
    
    return kAudioHardwareNoError
}

/// Represents an audio output device
struct AudioDevice: Identifiable, Hashable {
    let id: AudioDeviceID
    let name: String
}

/// Helper class to retrieve current audio output device information
final class AudioDeviceHelper: ObservableObject {
    @Published private(set) var currentOutputDeviceName: String?
    @Published private(set) var availableDevices: [AudioDevice] = []
    @Published private(set) var currentDeviceID: AudioDeviceID?
    
    private var propertyListenerQueue: DispatchQueue?
    private var listenerCallback: AudioObjectPropertyListenerProc?
    
    init() {
        self.propertyListenerQueue = nil
        self.listenerCallback = nil
        self.currentOutputDeviceName = Self.getCurrentOutputDeviceName()
        self.currentDeviceID = Self.getCurrentOutputDeviceID()
        self.availableDevices = Self.getAllOutputDevices()
        setupDeviceListener()
    }
    
    deinit {
        removeDeviceListener()
    }
    
    /// Get the name of the current default audio output device
    static func getCurrentOutputDeviceName() -> String? {
        guard let deviceID = getCurrentOutputDeviceID() else {
            return nil
        }
        return getDeviceName(for: deviceID)
    }
    
    /// Get the current default output device ID
    static func getCurrentOutputDeviceID() -> AudioDeviceID? {
        var deviceID = AudioDeviceID(0)
        var deviceIDSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &deviceIDSize,
            &deviceID
        )
        
        guard status == kAudioHardwareNoError else {
            return nil
        }
        
        return deviceID
    }
    
    /// Get all available output devices
    static func getAllOutputDevices() -> [AudioDevice] {
        var propertySize: UInt32 = 0
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        // Get the size of the device list
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propertySize
        ) == kAudioHardwareNoError else {
            return []
        }
        
        let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        
        // Get the device list
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propertySize,
            &deviceIDs
        ) == kAudioHardwareNoError else {
            return []
        }
        
        // Filter for output devices only
        return deviceIDs.compactMap { deviceID -> AudioDevice? in
            guard isOutputDevice(deviceID),
                  let name = getDeviceName(for: deviceID) else {
                return nil
            }
            return AudioDevice(id: deviceID, name: name)
        }
    }
    
    /// Check if a device is an output device
    private static func isOutputDevice(_ deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var propertySize: UInt32 = 0
        
        guard AudioObjectGetPropertyDataSize(
            deviceID,
            &address,
            0,
            nil,
            &propertySize
        ) == kAudioHardwareNoError else {
            return false
        }
        
        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
        defer { bufferList.deallocate() }
        
        guard AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &propertySize,
            bufferList
        ) == kAudioHardwareNoError else {
            return false
        }
        
        return bufferList.pointee.mNumberBuffers > 0
    }
    
    /// Set the default output device
    func setOutputDevice(_ device: AudioDevice) -> Bool {
        var deviceID = device.id
        let deviceIDSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            deviceIDSize,
            &deviceID
        )
        
        if status == kAudioHardwareNoError {
            refresh()
            return true
        }
        
        return false
    }
    
    /// Get the device name for a specific audio device ID
    private static func getDeviceName(for deviceID: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var name: Unmanaged<CFString>?
        var nameSize = UInt32(MemoryLayout<Unmanaged<CFString>>.size)
        
        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &nameSize,
            &name
        )
        
        guard status == kAudioHardwareNoError, let name = name else {
            return nil
        }
        
        return name.takeRetainedValue() as String
    }
    
    /// Setup listener for audio device changes
    private func setupDeviceListener() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            audioDevicePropertyListener,
            selfPtr
        )
    }
    
    /// Remove the device change listener
    private func removeDeviceListener() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        AudioObjectRemovePropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            audioDevicePropertyListener,
            selfPtr
        )
    }
    
    /// Manually refresh the current output device
    func refresh() {
        currentOutputDeviceName = Self.getCurrentOutputDeviceName()
        currentDeviceID = Self.getCurrentOutputDeviceID()
        availableDevices = Self.getAllOutputDevices()
    }
}
