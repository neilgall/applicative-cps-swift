import Foundation

struct Future<Value> {
    let get : (Value -> ()) -> ()

    func fmap<R>(f: Value -> R) -> Future<R> {
        return Future<R>() { getr in self.get { getr(f($0)) } }
    }
}

enum Either<ValueType, ErrorType> {
    case Value(ValueType)
    case Error(ErrorType)
    
    func fmap<R>(f: ValueType -> R) -> Either<R, ErrorType> {
        switch self {
        case Value(let v): return .Value(f(v))
        case Error(let e): return .Error(e)
        }
    }
    
    func flatMap<R>(f: ValueType -> Either<R, ErrorType>) -> Either<R, ErrorType> {
        switch self {
        case Value(let v): return f(v)
        case Error(let e): return .Error(e)
        }
    }
}

func pure<F>(f: F) -> Future<F> {
    return Future() { $0(f) }
}

func lift<V>(f: Future<V>) -> Future<V?> {
    return Future() { getOptional in f.get { getOptional(.Some($0)) } }
}

func lift<V,E>(f: Future<V>) -> Future<Either<V,E>> {
    return Future() { getEither in f.get { getEither(.Value($0)) } }
}

infix operator <%> { associativity left }
func <%> <A, B>(f: A -> B, fa: Future<A>) -> Future<B> {
    return fa.fmap(f)
}

infix operator <*> { associativity left }
func <*> <A,B>(ff: Future<A -> B>, fa: Future<A>) -> Future<B> {
    return Future() { getb in fa.get { a in ff.get { getb($0(a)) } } }
}

infix operator >>- { associativity left }
func >>- <A,B> (mv: Future<A>, f: A -> Future<B>) -> Future<B> {
    return Future() { getb in mv.get { f($0).get(getb) } }
}

func calc(i: Int)(j: Int)(k: Int) -> Int {
    return (i + j) * k
}

func add(i: Int)(_ j: Int) -> Int {
    return i + j
}

func addOrNil(mi: Int?)(_ mj: Int?) -> Int? {
    return mi.flatMap { i in mj.map { j in i+j } }
}

func addOrError(ei: Either<Int, String>)(_ ej: Either<Int, String>) -> Either<Int, String> {
    return ei.flatMap { i in ej.fmap { j in i+j } }
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

func asyncFooOrNil(a: Int?) -> Future<Int?> {
    return async(a.map(syncFoo))
}

func asyncFooOrError(a: Either<Int, String>) -> Future<Either<Int, String>> {
    return async(a.fmap(syncFoo))
}

func asyncAddOrNil(i: Int?)(_ j: Int?) -> Future<Int?> {
    return async(addOrNil(i)(j))
}

func asyncAddOrError(ei: Either<Int, String>)(_ ej: Either<Int, String>) -> Future<Either<Int, String>> {
    return async(addOrError(ei)(ej))
}

let runAsync = false

add(2)(3)
addOrNil(2)(3)
addOrNil(2)(nil)
addOrNil(nil)(3)

addOrError(.Value(2))(.Value(3))
addOrError(.Value(2))(.Error("foo"))

async(5)
async(5).fmap(add(2)).get { print("simple fmap: \($0)") }

let x = calc(2) <%> async(3) <*> async(4)
x.get { print($0) }

calc(2)
pure(calc(2))
pure(calc(2)) <*> async(5)
calc(2) <%> async(5)
(calc(2) <%> async(5) <*> async(7)).get { print("applicative: \($0)") }

(asyncFoo(2) >>- asyncBar).get { print("monadic bind: \($0)") }

(pure(addOrNil(3)) <*> async(5)).get { print("applicative with optional: \($0)") }
(addOrNil(2) <%> async(nil)).get { print("applicative with optional: \($0)") }

(asyncFooOrNil(2) >>- asyncAddOrNil(4))
(asyncFooOrNil(2) >>- asyncAddOrNil(4)).get { print("monadic bind with optional: \($0)") }
(asyncFooOrNil(nil) >>- asyncAddOrNil(5)).get { print("monadic bind with optional: \($0)") }
(asyncFooOrNil(2) >>- asyncAddOrNil(nil)).get { print("monadic bind with optional: \($0)") }

asyncFoo(2)
lift(asyncFoo(2)).get { print("lift to optional: \($0)") }
(lift(asyncFoo(2)) >>- asyncAddOrNil(4)).get { print("lift to optional and bind: \($0)") }

(pure(addOrError(.Value(3))) <*> async(.Value(9))).get { print("applicative with either: \($0)") }
(addOrError(.Error("bad")) <%> async(.Value(1))).get { print("applicative with either: \($0)") }

asyncFooOrError(.Value(1))
(asyncFooOrError(.Value(6)) >>- asyncAddOrError(.Value(11))).get { print("monadic bind with either: \($0)") }
(asyncFooOrError(.Value(6)) >>- asyncAddOrError(.Error("foo"))).get { print("monadic bind with either: \($0)") }
(asyncFooOrError(.Error("bar")) >>- asyncAddOrError(.Error("foo"))).get { print("monadic bind with either: \($0)") }

let q: Future<Either<Int,String>> = lift(asyncFoo(3))
(lift(asyncFoo(2)) >>- asyncAddOrError(.Value(2))).get { print("lift to either and bind: \($0)") }

let sequence = [ asyncFoo, asyncBar, asyncFoo, asyncBar ]
(sequence.reduce(asyncFoo(2), combine: >>-)).get { print("folded monadic bind: \($0)") }
