
import Foundation


public func pure<A>(f: A) -> (A -> ()) -> () {
    return { $0(f) }
}

infix operator <%> { associativity left }
public func <%> <A,B>(f: A -> B, fa: (A -> ()) -> ()) -> (B -> ()) -> () {
    return { cont in fa { cont(f($0)) } }
}

infix operator <*> { associativity left }
public func <*> <A,B>(ff: ((A -> B) -> ()) -> (), fa: (A -> ()) -> ()) -> (B -> ()) -> () {
    return { cont in fa { a in ff { cont($0(a)) } } }
}

func calc(i: Int)(j: Int)(k: Int) -> Int {
    return (i + j) * k
}

func async<T>(t: T)(c: T -> ()) {
    if (runAsync) {
        dispatch_async(dispatch_get_main_queue()) {
            c(t)
        }
    } else {
        c(t)
    }
}

let runAsync = false

let x = calc(2) <%> async(5) <*> async(3)
x { print("x=\($0)") }

let y = pure(calc) <*> async(2) <*> async(3) <*> async(6)
y { print("y=\($0)") }

