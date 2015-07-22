
import Foundation


public func pure<A>(f: A) -> (A -> ()) -> () {
    return { $0(f) }
}

public func pure<A,B>(f: A -> B) -> A -> (B -> ()) -> () {
    return { a in { $0(f(a)) } }
}

infix operator <%> { associativity left }
public func <%> <A,B>(f: A -> B, fa: (A -> ()) -> ()) -> (B -> ()) -> () {
    return { cont in fa { cont(f($0)) } }
}

infix operator <*> { associativity left }
public func <*> <A,B>(ff: ((A -> B) -> ()) -> (), fa: (A -> ()) -> ()) -> (B -> ()) -> () {
    return { cont in fa { a in ff { cont($0(a)) } } }
}

infix operator >>= { associativity left }
public func >>= <A,B>(mv: (A -> ()) -> (), f: A -> (B -> ()) -> ()) -> (B -> ()) -> () {
    return { cont in mv { a in f(a)(cont) } }
}
public func >>= <A>(mv: (A -> ()) -> (), f: A -> ()) {
    mv { a in f(a) }
}

func calc(i: Int)(j: Int)(k: Int) -> Int {
    return (i + j) * k
}

func doAsync(c: ()->()) {
    if runAsync {
        dispatch_async(dispatch_get_main_queue(), c)
    } else {
        c()
    }
}

func async<T>(t: T)(c: T -> ()) {
    doAsync { c(t) }
}

let runAsync = false

let x = calc(2) <%> async(5) <*> async(3)
x { print("x=\($0)") }

let y = pure(calc) <*> async(2) <*> async(3) <*> async(6)
y { print("y=\($0)") }

func syncFoo(a: Int) -> Int {
    return a+1
}

func syncBar(b: Int) -> Int {
    return b*2
}

func asyncFoo(a: Int)(completion: (Int -> ())) {
    doAsync { completion(syncFoo(a)) }
}

func asyncBar(b: Int)(completion: (Int -> ())) {
    doAsync { completion(syncBar(b)) }
}

asyncFoo(2)
    >>= asyncBar
    >>= { print($0) }

asyncFoo(2)
    >>= pure(syncBar)
    >>= asyncFoo
    >>= { print($0) }

let sequence = [ asyncFoo, asyncBar, asyncFoo, asyncBar ]
(sequence.reduce(asyncFoo(2), combine: >>=)) { print($0) }

