/* *     Copyright 2016, 2017, 2018 IBM Corp.
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */

import Foundation

public enum SecAttrAccessible: RawRepresentable {

    case accessibleAlways                           // kSecAttrAccessibleAlways
    case accessibleAlwaysThisDeviceOnly             // kSecAttrAccessibleAlwaysThisDeviceOnly
    case accessibleAfterFirstUnlock                 // kSecAttrAccessibleAfterFirstUnlock
    case accessibleAfterFirstUnlockThisDeviceOnly   // kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    case accessibleWhenUnlocked                     // kSecAttrAccessibleWhenUnlocked
    case accessibleWhenUnlockedThisDeviceOnly       // kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    case accessibleWhenPasscodeSetThisDeviceOnly    // kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly

    public init?(rawValue: CFString) {
        switch rawValue {
        case kSecAttrAccessibleAlways: self = .accessibleAlways
        case kSecAttrAccessibleAlwaysThisDeviceOnly: self = .accessibleAlwaysThisDeviceOnly
        case kSecAttrAccessibleAfterFirstUnlock: self = .accessibleAfterFirstUnlock
        case kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly: self = .accessibleAfterFirstUnlockThisDeviceOnly
        case kSecAttrAccessibleWhenUnlocked: self = .accessibleWhenUnlocked
        case kSecAttrAccessibleWhenUnlockedThisDeviceOnly: self = .accessibleWhenUnlockedThisDeviceOnly
        case kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly: self = .accessibleWhenPasscodeSetThisDeviceOnly
        default: self = .accessibleAfterFirstUnlock
        }
    }

    public var rawValue: CFString {
        switch self {
        case .accessibleAlways: return kSecAttrAccessibleAlways
        case .accessibleAlwaysThisDeviceOnly: return kSecAttrAccessibleAlwaysThisDeviceOnly
        case .accessibleAfterFirstUnlock: return kSecAttrAccessibleAfterFirstUnlock
        case .accessibleAfterFirstUnlockThisDeviceOnly: return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .accessibleWhenUnlocked: return kSecAttrAccessibleWhenUnlocked
        case .accessibleWhenUnlockedThisDeviceOnly: return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .accessibleWhenPasscodeSetThisDeviceOnly: return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        }
    }
}
