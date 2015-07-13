
import Foundation

public struct Cont<A> {
    let run : (A -> ()) -> ()
}

public func pure<A,B>(f: A -> B) -> ((A -> B) -> ()) -> () {
    return Cont(run: { _ in f }).run
}

public func fmap<A,B> (f: A -> B, fa: Cont<A>) -> Cont<B> {
    return Cont(run: { completion in
        fa.run { a in
            let b = f(a)
            completion(b)
        }
    })
}

public func apply<A,B> (ff: Cont<A -> B>, fa: Cont<A>) -> Cont<B> {
    return Cont(run: { completion in
        fa.run { a in
            ff.run { f in
                let b = f(a)
                completion(b)
            }
        }
    })
}

infix operator <%> { associativity left }
public func <%> <A,B>(f: A -> B, fa: (A -> ()) -> ()) -> (B -> ()) -> () {
    return fmap(f, fa: Cont(run: fa)).run
}

infix operator <*> { associativity left }
public func <*> <A,B>(f: ((A -> B) -> ()) -> (), fa: (A -> ()) -> ()) -> (B -> ()) -> () {
    return apply(Cont(run: f), fa: Cont(run: fa)).run
}


func calc(i: Int)(j: Int)(k: Int) -> Int {
    return (i + j) * k
}

func async<T>(t: T)(c: T -> ()) {
    dispatch_async(dispatch_get_main_queue()) {
        c(t)
    }
}

let x = calc(2) <%> async(5) <*> async(3)
x { print($0) }

let y = pure(calc) <*> async(2) <*> async(3) <*> async(1)
y { print($0) }
