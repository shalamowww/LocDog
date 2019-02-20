typealias JSONDictionary = [String: Any]

/// Indicates that an error occurred in MapboxDirections.
public let MBDirectionsErrorDomain = "com.mapbox.directions.ErrorDomain"

/// The Mapbox access token specified in the main application bundle’s Info.plist.
let defaultAccessToken = Bundle.main.object(forInfoDictionaryKey: "MGLMapboxAccessToken") as? String
let defaultApiEndPointURLString = Bundle.main.object(forInfoDictionaryKey: "MGLMapboxAPIBaseURL") as? String

/// The user agent string for any HTTP requests performed directly within this library.
let userAgent: String = {
    var components: [String] = []
    
    if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        components.append("\(appName)/\(version)")
    }
    
    let libraryBundle: Bundle? = Bundle(for: Directions.self)
    
    if let libraryName = libraryBundle?.infoDictionary?["CFBundleName"] as? String, let version = libraryBundle?.infoDictionary?["CFBundleShortVersionString"] as? String {
        components.append("\(libraryName)/\(version)")
    }
    
    let system: String
    #if os(OSX)
        system = "macOS"
    #elseif os(iOS)
        system = "iOS"
    #elseif os(watchOS)
        system = "watchOS"
    #elseif os(tvOS)
        system = "tvOS"
    #elseif os(Linux)
        system = "Linux"
    #endif
    let systemVersion = ProcessInfo().operatingSystemVersion
    components.append("\(system)/\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)")
    
    let chip: String
    #if arch(x86_64)
        chip = "x86_64"
    #elseif arch(arm)
        chip = "arm"
    #elseif arch(arm64)
        chip = "arm64"
    #elseif arch(i386)
        chip = "i386"
    #endif
    components.append("(\(chip))")
    
    return components.joined(separator: " ")
}()

/**
 A `Directions` object provides you with optimal directions between different locations, or waypoints. The directions object passes your request to the [Mapbox Directions API](https://www.mapbox.com/api-documentation/?language=Swift#directions) and returns the requested information to a closure (block) that you provide. A directions object can handle multiple simultaneous requests. A `RouteOptions` object specifies criteria for the results, such as intermediate waypoints, a mode of transportation, or the level of detail to be returned.
 
 Each result produced by the directions object is stored in a `Route` object. Depending on the `RouteOptions` object you provide, each route may include detailed information suitable for turn-by-turn directions, or it may include only high-level information such as the distance, estimated travel time, and name of each leg of the trip. The waypoints that form the request may be conflated with nearby locations, as appropriate; the resulting waypoints are provided to the closure.
 */
@objc(MBDirections)
open class Directions: NSObject {
    /**
     A closure (block) to be called when a directions request is complete.
     
     - parameter waypoints: An array of `Waypoint` objects. Each waypoint object corresponds to a `Waypoint` object in the original `RouteOptions` object. The locations and names of these waypoints are the result of conflating the original waypoints to known roads. The waypoints may include additional information that was not specified in the original waypoints.
        
        If the request was canceled or there was an error obtaining the routes, this parameter may be `nil`.
     - parameter routes: An array of `Route` objects. The preferred route is first; any alternative routes come next if the `RouteOptions` object’s `includesAlternativeRoutes` property was set to `true`. The preferred route depends on the route options object’s `profileIdentifier` property.
        
        If the request was canceled or there was an error obtaining the routes, this parameter is `nil`. This is not to be confused with the situation in which no results were found, in which case the array is present but empty.
     - parameter error: The error that occurred, or `nil` if the placemarks were obtained successfully.
     */
    public typealias RouteCompletionHandler = (_ waypoints: [Waypoint]?, _ routes: [Route]?, _ error: NSError?) -> Void
    
    /**
     A closure (block) to be called when a map matching request is complete.
     
     If the request was canceled or there was an error obtaining the matches, this parameter is `nil`. This is not to be confused with the situation in which no matches were found, in which case the array is present but empty.
     - parameter error: The error that occurred, or `nil` if the placemarks were obtained successfully.
     */
    public typealias MatchCompletionHandler = (_ matches: [Match]?, _ error: NSError?) -> Void
    
    // MARK: Creating a Directions Object
    
    /**
     The shared directions object.
     
     To use this object, a Mapbox [access token](https://www.mapbox.com/help/define-access-token/) should be specified in the `MGLMapboxAccessToken` key in the main application bundle’s Info.plist.
     */
    @objc(sharedDirections)
    public static let shared = Directions(accessToken: nil)
    
    /**
     The API endpoint to use when requesting directions.
     */
    @objc public private(set) var apiEndpoint: URL
    
    /**
     The Mapbox access token to associate with the request.
     */
    @objc public let accessToken: String
    
    /**
     Initializes a newly created directions object with an optional access token and host.
     
     - parameter accessToken: A Mapbox [access token](https://www.mapbox.com/help/define-access-token/). If an access token is not specified when initializing the directions object, it should be specified in the `MGLMapboxAccessToken` key in the main application bundle’s Info.plist.
     - parameter host: An optional hostname to the server API. The [Mapbox Directions API](https://www.mapbox.com/api-documentation/?language=Swift#directions) endpoint is used by default.
     */
    @objc public init(accessToken: String?, host: String?) {
        let accessToken = accessToken ?? defaultAccessToken
        assert(accessToken != nil && !accessToken!.isEmpty, "A Mapbox access token is required. Go to <https://www.mapbox.com/studio/account/tokens/>. In Info.plist, set the MGLMapboxAccessToken key to your access token, or use the Directions(accessToken:host:) initializer.")
        
        self.accessToken = accessToken!
        
        if let host = host, !host.isEmpty {
            var baseURLComponents = URLComponents()
            baseURLComponents.scheme = "https"
            baseURLComponents.host = host
            apiEndpoint = baseURLComponents.url!
        } else {
            apiEndpoint = URL(string:(defaultApiEndPointURLString ?? "https://api.mapbox.com"))!
        }
        
    }
    
    /**
     Initializes a newly created directions object with an optional access token.
     
     The directions object sends requests to the [Mapbox Directions API](https://www.mapbox.com/api-documentation/?language=Swift#directions) endpoint.
     
     - parameter accessToken: A Mapbox [access token](https://www.mapbox.com/help/define-access-token/). If an access token is not specified when initializing the directions object, it should be specified in the `MGLMapboxAccessToken` key in the main application bundle’s Info.plist.
     */
    @objc public convenience init(accessToken: String?) {
        self.init(accessToken: accessToken, host: nil)
    }
    
    // MARK: Getting Directions
    
    /**
     Begins asynchronously calculating the route or routes using the given options and delivers the results to a closure.
     
     This method retrieves the routes asynchronously over a network connection. If a connection error or server error occurs, details about the error are passed into the given completion handler in lieu of the routes.
     
     Routes may be displayed atop a [Mapbox map](https://www.mapbox.com/maps/). They may be cached but may not be stored permanently. To use the results in other contexts or store them permanently, [upgrade to a Mapbox enterprise plan](https://www.mapbox.com/directions/#pricing).
     
     - parameter options: A `RouteOptions` object specifying the requirements for the resulting routes.
     - parameter completionHandler: The closure (block) to call with the resulting routes. This closure is executed on the application’s main thread.
     - returns: The data task used to perform the HTTP request. If, while waiting for the completion handler to execute, you no longer want the resulting routes, cancel this task.
     */
    @objc(calculateDirectionsWithOptions:completionHandler:)
    @discardableResult open func calculate(_ options: RouteOptions, completionHandler: @escaping RouteCompletionHandler) -> URLSessionDataTask {
        let url = self.url(forCalculating: options)
        let task = dataTask(with: url, completionHandler: { (json) in
            let response = options.response(from: json)
            if let routes = response.1 {
                for route in routes {
                    route.accessToken = self.accessToken
                    route.apiEndpoint = self.apiEndpoint
                    route.routeIdentifier = json["uuid"] as? String
                }
            }
            completionHandler(response.0, response.1, nil)
        }) { (error) in
            completionHandler(nil, nil, error)
        }
        task.resume()
        return task
    }
    
    /**
     Begins asynchronously calculating a match using the given options and delivers the results to a closure.
     
     
     - parameter options: A `MatchOptions` object specifying the requirements for the resulting match.
     - parameter completionHandler: The closure (block) to call with the resulting routes. This closure is executed on the application’s main thread.
     - returns: The data task used to perform the HTTP request. If, while waiting for the completion handler to execute, you no longer want the resulting routes, cancel this task.
     */
    @objc(calculateMatchesWithOptions:completionHandler:)
    @discardableResult open func calculate(_ options: MatchOptions, completionHandler: @escaping MatchCompletionHandler) -> URLSessionDataTask {
        let url = self.url(forCalculating: options)
        let data = options.encodedParam.data(using: .utf8)
        let task = dataTask(with: url, data: data, completionHandler: { (json) in
            let response = options.response(from: json)
            if let matches = response {
                for match in matches {
                    match.accessToken = self.accessToken
                    match.apiEndpoint = self.apiEndpoint
                    match.routeIdentifier = json["uuid"] as? String
                }
            }
            completionHandler(response, nil)
        }) { (error) in
            completionHandler(nil, error)
        }
        task.resume()
        return task
    }
    
    @objc(calculateRoutesMatchingOptions:completionHandler:)
    @discardableResult open func calculateRoutes(matching options: MatchOptions, completionHandler: @escaping RouteCompletionHandler) -> URLSessionDataTask {
        let url = self.url(forCalculating: options)
        let data = options.encodedParam.data(using: .utf8)
        let task = dataTask(with: url, data: data, completionHandler: { (json) in
            let response = options.response(containingRoutesFrom: json)
            if let routes = response.1 {
                for route in routes {
                    route.accessToken = self.accessToken
                    route.apiEndpoint = self.apiEndpoint
                    route.routeIdentifier = json["uuid"] as? String
                }
            }
            completionHandler(response.0, response.1, nil)
        }) { (error) in
            completionHandler(nil, nil, error)
        }
        task.resume()
        return task
    }
    
    /**
     Returns a URL session task for the given URL that will run the given closures on completion or error.
     
     - parameter url: The URL to request.
     - parameter completionHandler: The closure to call with the parsed JSON response dictionary.
     - parameter errorHandler: The closure to call when there is an error.
     - returns: The data task for the URL.
     - postcondition: The caller must resume the returned task.
     */
    fileprivate func dataTask(with url: URL, data: Data? = nil, completionHandler: @escaping (_ json: JSONDictionary) -> Void, errorHandler: @escaping (_ error: NSError) -> Void) -> URLSessionDataTask {
        
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        if let data = data {
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = data
        }
        
        return URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            var json: JSONDictionary = [:]
            if let data = data, response?.mimeType == "application/json" {
                do {
                    json = try JSONSerialization.jsonObject(with: data, options: []) as! JSONDictionary
                } catch {
                    assert(false, "Invalid data")
                }
            }
            
            let apiStatusCode = json["code"] as? String
            let apiMessage = json["message"] as? String
            guard !json.isEmpty, data != nil, error == nil && ((apiStatusCode == nil && apiMessage == nil) || apiStatusCode == "Ok") else {
                let apiError = Directions.informativeError(describing: json, response: response, underlyingError: error as NSError?)
                DispatchQueue.main.async {
                    errorHandler(apiError)
                }
                return
            }
            
            DispatchQueue.main.async {
                completionHandler(json)
            }
        }
    }
    
    /**
     The HTTP URL used to fetch the routes from the API.
     
     After requesting the URL returned by this method, you can parse the JSON data in the response and pass it into the `Route.init(json:waypoints:profileIdentifier:)` initializer.
     */
    @objc(URLForCalculatingDirectionsWithOptions:)
    open func url(forCalculating options: DirectionsOptions) -> URL {
        let params = options.params + [
            URLQueryItem(name: "access_token", value: accessToken),
        ]
        
        let unparameterizedURL = URL(string: options.path, relativeTo: apiEndpoint)!
        var components = URLComponents(url: unparameterizedURL, resolvingAgainstBaseURL: true)!
        components.queryItems = params
        return components.url!
    }
    
    /**
     Returns an error that supplements the given underlying error with additional information from the an HTTP response’s body or headers.
     */
    static func informativeError(describing json: JSONDictionary, response: URLResponse?, underlyingError error: NSError?) -> NSError {
        let apiStatusCode = json["code"] as? String
        var userInfo = error?.userInfo ?? [:]
        if let response = response as? HTTPURLResponse {
            var failureReason: String? = nil
            var recoverySuggestion: String? = nil
            switch (response.statusCode, apiStatusCode ?? "") {
            case (200, "NoRoute"):
                failureReason = "No route could be found between the specified locations."
                recoverySuggestion = "Make sure it is possible to travel between the locations with the mode of transportation implied by the profileIdentifier option. For example, it is impossible to travel by car from one continent to another without either a land bridge or a ferry connection."
            case (200, "NoSegment"):
                failureReason = "A specified location could not be associated with a roadway or pathway."
                recoverySuggestion = "Make sure the locations are close enough to a roadway or pathway. Try setting the coordinateAccuracy property of all the waypoints to a negative value."
            case (404, "ProfileNotFound"):
                failureReason = "Unrecognized profile identifier."
                recoverySuggestion = "Make sure the profileIdentifier option is set to one of the provided constants, such as MBDirectionsProfileIdentifierAutomobile."
                
            case (413, _):
                failureReason = "The request is too large."
                recoverySuggestion = "Try specifying fewer waypoints or giving the waypoints shorter names."
                
            case (429, _):
                if let timeInterval = response.rateLimitInterval, let maximumCountOfRequests = response.rateLimit {
                    let intervalFormatter = DateComponentsFormatter()
                    intervalFormatter.unitsStyle = .full
                    let formattedInterval = intervalFormatter.string(from: timeInterval) ?? "\(timeInterval) seconds"
                    let formattedCount = NumberFormatter.localizedString(from: NSNumber(value: maximumCountOfRequests), number: .decimal)
                    failureReason = "More than \(formattedCount) requests have been made with this access token within a period of \(formattedInterval)."
                }
                if let rolloverTime = response.rateLimitResetTime {
                    let formattedDate = DateFormatter.localizedString(from: rolloverTime, dateStyle: .long, timeStyle: .long)
                    recoverySuggestion = "Wait until \(formattedDate) before retrying."
                }
            default:
                // `message` is v4 or v5; `error` is v4
                failureReason = json["message"] as? String ?? json["error"] as? String
            }
            userInfo[NSLocalizedFailureReasonErrorKey] = failureReason ?? userInfo[NSLocalizedFailureReasonErrorKey] ?? HTTPURLResponse.localizedString(forStatusCode: error?.code ?? -1)
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = recoverySuggestion ?? userInfo[NSLocalizedRecoverySuggestionErrorKey]
        }
        if let error = error {
            userInfo[NSUnderlyingErrorKey] = error
        }
        return NSError(domain: error?.domain ?? MBDirectionsErrorDomain, code: error?.code ?? -1, userInfo: userInfo)
    }
}

