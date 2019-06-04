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
import BMSCore

internal class Config {
    
    private static var oauthEndpoint = "/oauth/v4/"
    private static var attributesEndpoint = "/api/v1/"
    private static var serverUrlPrefix = "https://appid-oauth"
    private static var attributesUrlPrefix = "https://appid-profiles"
    private static var publicKeysEndpoint = "/publickeys"
    private static var urlProtocol = "https"
    
    
    private static var REGION_US_SOUTH_OLD = ".ng.bluemix.net";
    private static var REGION_US_EAST_OLD = ".us-east.bluemix.net";
    private static var REGION_UK_OLD = ".eu-gb.bluemix.net";
    private static var REGION_SYDNEY_OLD = ".au-syd.bluemix.net";
    private static var REGION_GERMANY_OLD = ".eu-de.bluemix.net";
    private static var REGION_TOKYO_OLD = ".jp-tok.bluemix.net";
    
    internal static let logger =  Logger.logger(name: AppIDConstants.ConfigLoggerName)
    
    internal static func getServerUrl(appId: AppID) -> String {
        
        guard var serverUrl = convertOldRegionToNewURL(region: appId.region), let tenant = appId.tenantId else {
            logger.error(message: "Could not set server url properly, no tenantId or no region set")
            return serverUrlPrefix
        }
        
        serverUrl = serverUrl + oauthEndpoint
        if let overrideServerHost = AppID.overrideServerHost {
            serverUrl = overrideServerHost + "/"
        }
        
        return serverUrl + tenant
    }
    
    internal static func getAttributesUrl(appId: AppID) -> String {
        
        guard var attributesUrl = convertOldRegionToNewURL(region: appId.region) else {
            logger.error(message: "Could not set server url properly, no region set")
            return attributesUrlPrefix
        }
        
        if let overrideHost = AppID.overrideAttributesHost {
            attributesUrl = overrideHost
        }
        
        return attributesUrl + attributesEndpoint
    }
    
    internal static func getPublicKeyEndpoint(appId: AppID) -> String {
        return getServerUrl(appId: appId) + publicKeysEndpoint
    }

    internal static func getIssuer(appId: AppID) -> String? {
        return getServerUrl(appId: appId)

    }
    
    internal static func convertOldRegionToNewURL(region: String?) -> String? {
        switch region {
        case REGION_US_SOUTH_OLD: return AppID.REGION_US_SOUTH
        case REGION_US_EAST_OLD: return AppID.REGION_US_EAST
        case REGION_UK_OLD: return AppID.REGION_UK
        case REGION_SYDNEY_OLD: return AppID.REGION_SYDNEY
        case REGION_GERMANY_OLD: return AppID.REGION_GERMANY
        case REGION_TOKYO_OLD: return AppID.REGION_TOKYO
        case AppID.REGION_US_SOUTH: return AppID.REGION_US_SOUTH
        case AppID.REGION_US_EAST: return AppID.REGION_US_EAST
        case AppID.REGION_UK: return AppID.REGION_UK
        case AppID.REGION_UK_STAGE1: return AppID.REGION_UK_STAGE1
        case AppID.REGION_US_SOUTH_STAGE1: return AppID.REGION_US_SOUTH_STAGE1
        case AppID.REGION_SYDNEY: return AppID.REGION_SYDNEY
        case AppID.REGION_GERMANY: return AppID.REGION_GERMANY
        case AppID.REGION_TOKYO: return AppID.REGION_TOKYO
        default: return nil;
        }
    }
    
}
