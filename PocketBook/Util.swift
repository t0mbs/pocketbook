import Foundation

public class Util {
    static var debug = true
    static var debugBackEnd = false
    static var maxStack: Int?
    static var threadName: String {
        return NSThread.currentThread().isMainThread ? "[main]" : "[NOT main]"
    }
    
    static public func log(message: String, sourceAbsolutePath: String = __FILE__, line: Int = __LINE__, function: String = __FUNCTION__) {
        if debug {
            if message == "exit" {
                // disable these by default; it gets too verbose unless we want to find slow functions
                return
            }
            
            // For the morbidly curious
            if let max = maxStack {
                var stackDump = NSThread.callStackSymbols()
                stackDump.removeRange(0...2)
                stackDump.removeRange(max...(stackDump.count - 1))
                println(stackDump.reduce("") { "\($0)\n\($1)" })
            }
            
            // let threadType = NSThread.currentThread().isMainThread ? "main" : "other"
            let baseName = NSURL(fileURLWithPath: sourceAbsolutePath)?.lastPathComponent?.stringByDeletingPathExtension ?? "UNKNOWN_FILE"
            NSLog("\(threadName) \(baseName) \(function)[\(line)]: \(message)")
        }
    }
    
    static public func logBackEnd(message: String, sourceAbsolutePath: String = __FILE__, line: Int = __LINE__, function: String = __FUNCTION__) {
        if debugBackEnd {
            log(message)
        }
    }
    
    static public func setDebug(newVal: Bool) {
        debug = newVal
    }
}
