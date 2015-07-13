
import Foundation


public func pure<A,B>(f: A -> B) -> ((A -> B) -> ()) -> () {
    return { $0(f) }
}

infix operator <%> { associativity left }
public func <%> <A,B>(f: A -> B, fa: (A -> ()) -> ()) -> (B -> ()) -> () {
    return { completion in
        fa { a in
            let b = f(a)
            completion(b)
        }
    }
}

infix operator <*> { associativity left }
public func <*> <A,B>(ff: ((A -> B) -> ()) -> (), fa: (A -> ()) -> ()) -> (B -> ()) -> () {
    return { completion in
        fa { a in
            ff { f in
                let b = f(a)
                completion(b)
            }
        }
    }
}

func calc(i: Int)(j: Int)(k: Int) -> Int {
    return (i + j) * k
}

func async<T>(t: T)(c: T -> ()) {
    if (async) {
        dispatch_async(dispatch_get_main_queue()) {
            c(t)
        }
    } else {
        c(t)
    }
}

let async = false

let x = calc(2) <%> async(5) <*> async(3)
x { print("x=\($0)") }

let y = pure(calc) <*> async(2) <*> async(3) <*> async(6)
y { print("y=\($0)") }

