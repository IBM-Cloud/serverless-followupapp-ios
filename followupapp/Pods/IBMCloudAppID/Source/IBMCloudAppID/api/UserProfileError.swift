/* *     Copyright 2016, 2017 IBM Corp.
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

public enum UserProfileError: Error {

    case notFound
    case unauthorized
    case missingAccessToken
    case missingOrMalformedIdToken
    case responseValidationError
    case invalidUserInfoResponse
    case bodyParsingError
    case general(String)

    public var description: String {
        switch self {
        case .general(let msg) : return msg
        case .notFound: return "Not Found"
        case .unauthorized: return "Unauthorized"
        case .missingAccessToken: return "Access token not found. Please login."
        case .missingOrMalformedIdToken: return "Identity token not found or is missing subject field. Please login again."
        case .responseValidationError: return "Potential token substitution attack. Rejecting: response.sub != identityToken.sub"
        case .bodyParsingError: return "Failed to parse server body"
        case .invalidUserInfoResponse: return "Invalid user info response"
        }
    }
}
