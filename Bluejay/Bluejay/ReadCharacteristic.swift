//
//  ReadCharacteristic.swift
//  Bluejay
//
//  Created by Jeremy Chiang on 2017-01-04.
//  Copyright © 2017 Steamclock Software. All rights reserved.
//

import Foundation
import CoreBluetooth

class ReadCharacteristic<T: Receivable>: Operation {
    
    var state = OperationState.notStarted
    
    private var characteristicIdentifier: CharacteristicIdentifier
    private var callback: (ReadResult<T>) -> Void
    
    init(characteristicIdentifier: CharacteristicIdentifier, callback: @escaping (ReadResult<T>) -> Void) {
        self.characteristicIdentifier = characteristicIdentifier
        self.callback = callback
    }
    
    func start(_ peripheral: CBPeripheral) {
        guard
            let service = peripheral.service(with: characteristicIdentifier.service.uuid),
            let characteristic = service.characteristic(with: characteristicIdentifier.uuid)
        else {
            fail(Error.missingCharacteristicError(characteristicIdentifier))
            return
        }
        
        state = .running
        peripheral.readValue(for: characteristic)
    }
    
    func receivedEvent(_ event: Event, peripheral: CBPeripheral) {
        if case .didReadCharacteristic(let readFrom, let value) = event {
            if readFrom.uuid != characteristicIdentifier.uuid {
                preconditionFailure("Expecting read from charactersitic: \(characteristicIdentifier.uuid), but actually read from: \(readFrom.uuid)")
            }
            
            callback(ReadResult<T>(dataResult: .success(value)))
            state = .completed
        }
        else {
            preconditionFailure("Expecting write to characteristic: \(characteristicIdentifier.uuid), but received event: \(event)")
        }
    }
    
    func fail(_ error: NSError) {
        callback(.failure(error))
        state = .failed(error)
    }
    
}
