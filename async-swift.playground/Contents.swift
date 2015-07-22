import Foundation

struct Future<Value> {
    let get : (Value -> ()) -> ()
}

func pure<F>(f: F) -> Future<F> {
    return Future() { $0(f) }
}

extension Future {
    func fmap<R>(f: Value -> R) -> Future<R> {
        return Future<R>() { getr in self.get { getr(f($0)) } }
    }
}

infix operator <%> { associativity left }
func <%> <A, B>(f: A -> B, fa: Future<A>) -> Future<B> {
    return fa.fmap(f)
}

infix operator <*> { associativity left }
func <*> <A,B>(ff: Future<A -> B>, fa: Future<A>) -> Future<B> {
    return Future() { getb in fa.get { a in ff.get { getb($0(a)) } } }
}

infix operator >>= { associativity left }
func >>= <A,B> (mv: Future<A>, f: A -> Future<B>) -> Future<B> {
    return Future() { getb in mv.get { f($0).get(getb) } }
}

func calc(i: Int)(j: Int)(k: Int) -> Int {
    return (i + j) * k
}

func add(i: Int)(j: Int) -> Int {
    return i + j
}

func doAsync(c: ()->()) {
    if runAsync {
        dispatch_async(dispatch_get_main_queue(), c)
    } else {
        c()
    }
}

func async<T>(t: T) -> Future<T> {
    return Future() { get in doAsync { get(t) } }
}

let runAsync = false

async(5).fmap(add(2)).get { print($0) }

let x = calc(2) <%> async(3) <*> async(4)
x.get { print($0) }

calc(2)
pure(calc(2))
pure(calc(2)) <*> async(5)
calc(2) <%> async(5)
(calc(2) <%> async(5) <*> async(7)).get { print($0) }

func syncFoo(a: Int) -> Int {
    return a+1
}

func syncBar(b: Int) -> Int {
    return b*2
}

func asyncFoo(a: Int) -> Future<Int> {
    return async(syncFoo(a))
}

func asyncBar(b: Int) -> Future<Int> {
    return async(syncBar(b))
}

(asyncFoo(2) >>= asyncBar).get { print($0) }

let sequence = [ asyncFoo, asyncBar, asyncFoo, asyncBar ]
(sequence.reduce(asyncFoo(2), combine: >>=)).get { print($0) }

