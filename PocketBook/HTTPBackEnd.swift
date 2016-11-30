import Foundation

class HTTPBackEnd {
    /* The protocol to use */
    let networkProtocol = "http"
    
    /* The Web server that supplies the JSON API Endpoint */
    let host = "book.vader.io"
    
    let endpoint = ""

    /* An environment for making HTTP requests. This method is more verbose than the Image Fetcher code but gives us more
    control such as setting the timeout value which is normally 60 seconds. Even more fine-grain control can be
    achieved by setting the delegate, such as being notified when every small chunk of data arrives within a large response. */
    var session: NSURLSession = {
        Util.logBackEnd("creating URL session with 15.0s timeout")
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = 15.0
        /* Now create our session which will allow us to create the tasks */
        let s = NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        return s
        }()
    
    /* Computed property that just assembles the static portion of the Web endpoint */
    var staticURL: String {
        get {
            let url = "\(networkProtocol)://\(host)/\(endpoint)"
            Util.logBackEnd("computed URL \(url) from \(networkProtocol), \(host)/\(endpoint)")
            return url
        }
    }
    
    /* Creates a valid URL out of a URL string that may have arbitrary punctuation. This allows '/', ':' etc to
    be embedded in the GET query parameter values */
    func encode(urlFragment: String) -> String {
        return urlFragment.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
    }
    
    /* Creates a URL GET query string out of a dictionary. A convenience to bridge from Swift data structure to a URL */
    func encode(vals: [String: String]) -> String {
        let result = Array(vals.keys).reduce("") {
            (accumulator, key) in
            let prefix = (accumulator == "") ? "?" : "&"
            return "\(accumulator)\(prefix)\(encode(key))=\(encode(vals[key]!))"
        }
        Util.logBackEnd("Returning \(result) from dictionary: \(vals)")
        return result
    }
    
    /*
    Make a URL request on the network thread, and call back 'handler' with the received data when done.
    Error message is returned in 'message', if any, and 'data' may be nil if error occurred
    NOTE: rawDataDidArrive is called on the BACKGROUND queue, not the main queue. This is in case it is
    compute-intensive.
    */
    func httpRequest(url: NSURL, rawDataDidArrive: (data: NSData?, message: String?) -> Void) {
        // a task is a process description, but it doesn't run yet
        let task = session.dataTaskWithURL(url) {
            [unowned self]
            (data: NSData?, response: NSURLResponse?, netError: NSError?) in
            /* This closure runs on the network thread, and only once low-level networking code
            has completed */
            var errmsg: String?
            
            if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                if statusCode == 200 {
                    errmsg = nil
                }
                else { // status code other than 200
                    errmsg = "HTTP Error \(statusCode): \(NSHTTPURLResponse.localizedStringForStatusCode(statusCode))"
                }
            }
            else { // No HTTP response available at all, couldn't hit server
                if let netErr = netError { // for example, cannot resolve name into IP address
                    errmsg = "Network Error: \(netErr.localizedDescription)"
                    if let badURL = netErr.userInfo?["NSErrorFailingURLStringKey"] as? String {
                        errmsg! += " (Bad URL was \(badURL))"
                    }
                }
                else {
                    errmsg = "OS Error: network error was empty"
                }
            }
            /* The callback runs as a closure on the UI (main) thread. New concept: calling a closure
            within a closure to communicate between threads */
            rawDataDidArrive(data: data, message: errmsg)
        } // end of Ch the HTTP processing closure
        
        /* All we did thus far was to set up the task. It's just an object that stores the network request
        closure. Now we actually dispatch it onto the network thread. The counterintuitive command
        for this is 'resume', even though it hasn't started yet. */
        Util.logBackEnd("Requesting HTTP task to start on network queue")
        task.resume() // returns immediately
    }
}