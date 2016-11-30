// Way to think about it:
// "Box up" nested series of closures; start innermost with the UI request, and wrap boxes around it
// outermost is the lowest level (networking)
// Run the slow network request, and then unbox on the network thread.
// As each result becomes available, unbox the next closure and pass in the result for that stage
// of processing
// Finally at the end, pass the final result back to the UI thread

import Foundation

class JSONBackEnd: HTTPBackEnd {
    static let singleInstance = JSONBackEnd()
    var response: [NSDictionary]?
    /* A JSON wrapper around the HTTP request. Performs JSON parsing immediately after network data arrives.
    Then calls the passed in block 'jsonDataDidArrive' on the main queue. This block should present the JSON data in the UI */
    func ajaxRequest(url: NSURL, jsonDataDidArrive: (dataDict: [NSDictionary]?, message: String?) -> ()) {
        Util.logBackEnd("Request received for \(url)")
        
        // named closure
        func translateRawDataToJSON(rawData: NSData?, netErr: String?) -> (jsonDict: [NSDictionary]?, errMsg: String?) {
            if let rawJSON = rawData {
                var jsonError: NSError?
                // Actually doing de-serialization right now
                let json: AnyObject? = NSJSONSerialization.JSONObjectWithData(rawJSON, options: .AllowFragments, error: &jsonError)
                
                // Assupmption based on structure of my API. THe JSON can be arbitrarily recursive, you just
                // need to know what to expect at the top level
                if let validParsedData = json as? [NSDictionary] { // Success clause at top, optimistic testing
                    Util.logBackEnd("finished translating JSON successfully, returning it")
                    return (jsonDict: validParsedData, errMsg: nil)
                }
                else { // unable to parse JSON as dictionary
                    let errmsg: String
                    // if you were able to parse, but it was not an array of dictionaries, then this
                    if let ajaxMessage = json as? String {
                        errmsg = "AJAX API Error: \(ajaxMessage)"
                    }
                        // might happen if missing closing brace
                    else if let jErr = jsonError {
                        errmsg = "JSON Parsing Error: \(jErr.localizedDescription)"
                    }
                        // might happen if server responds with 500 / config error
                    else {
                        errmsg = "Server implementation error: Neither error string nor expected dictionary"
                    }
                    return (jsonDict: nil, errMsg: errmsg)
                }
            }
            // no Raw data available; HTTP or network level error
            return (jsonDict: nil, errMsg: netErr) // Pass through the error message returned by httpRequest
        } // end of my named closure translateRawDataToJSON
        
        // Make the http request. When it's done the block below will get called. Subsequently, when the translation is done,
        // the jsonDataArrive block, will be called.
        httpRequest(url) {
            [unowned self] (rawData, message) in
            Util.logBackEnd("Response received for \(url), parsing now")
            let (parsedJSON, errMsg) = translateRawDataToJSON(rawData, message)
            jsonDataDidArrive(dataDict: parsedJSON, message: errMsg)
        }
    }
    
    
    /* Convenience wrapper around the above that expects and extracts a single integer.
    It expects the JSON data to be a 1-element array.
    That element should be a dictionary with one object: a named integer. */
    func ajaxRequest(url: NSURL, forSingleIntegerNamed intName: String, intDidArrive: (intValue: Int?, errMsg: String?) -> ()) {
        Util.logBackEnd("Request received for single integer named \(intName)")
        
        func jsonDataArrivedHandler(response: [NSDictionary]?, netErrMsg: String?) -> () {
            var intValue: Int? = nil
            var errMsg: String? = nil
            if let rowInfo = response {
                // Note! The JSON library far predates Swift, and uses entirely NS* Foundation classes. "as? Int" is not the same
                if rowInfo.count == 1 {
                    if let val = rowInfo[0][intName] as? NSInteger {
                        intValue = val
                    }
                    else {
                        errMsg = "Response has invalid field '\(intName)': \(rowInfo[0][intName])"
                    }
                }
                else {
                    errMsg = "Unexpected result count: \(rowInfo.count)"
                }
            }
            else {
                errMsg = netErrMsg
            }
            intDidArrive(intValue: intValue, errMsg: errMsg)
        }
        
        ajaxRequest(url, jsonDataDidArrive: jsonDataArrivedHandler)
    }
    
    func insertInTable(table: String, didInsertInTable: (recordId: Int?, message: String?) -> ()) {
        Util.logBackEnd("Request received for \(table)")
        
        func makeInsertQuery(tableName: String) -> NSURL {
            return NSURL(string: "\(staticURL)" + encode([ "request": "insert", "table": tableName]))!
        }
        
        ajaxRequest(makeInsertQuery(table), forSingleIntegerNamed: "record_id", intDidArrive: didInsertInTable)
    }
    
    func getBookDetails(bookId: Int, lookupResultsDidArrive: (results: [NSDictionary]?, errMsg: String?) -> ()) {
            Util.logBackEnd("Request received to find all books")
            
            ajaxRequest(NSURL(string: "\(staticURL)query/book_details/book_id/\(bookId)")!, jsonDataDidArrive: lookupResultsDidArrive)
    }
    
    func getChapter(bookId: String, chapterId: String,
        lookupResultsDidArrive: ([NSDictionary]?, errMsg: String?) -> ()) {
            Util.logBackEnd("Request received to find book \(bookId)")
            ajaxRequest(NSURL(string: "\(staticURL)book_id/\(bookId)/chapter_id/\(chapterId)" )!, jsonDataDidArrive: lookupResultsDidArrive)
    }
    
    func getBookList(lookupResultsDidArrive: ([NSDictionary]?, errMsg: String?) -> ()) {
            Util.logBackEnd("Request received to find book_list")
            ajaxRequest(NSURL(string: "\(staticURL)query/book_list" )!, jsonDataDidArrive: lookupResultsDidArrive)
    }
    
}
