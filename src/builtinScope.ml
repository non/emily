(* Populates a prototype for scopes *)
(* Note: Scope does not inherit true because it isn't user accessible yet. *)
let scopePrototypeTable = Value.tableBlank Value.TrueBlank
let scopePrototype = Value.TableValue(scopePrototypeTable)

let badArg name var = failwith @@ "Bad argument to "^name^": Need closure, got " ^ Pretty.dumpValue(var)
let impossibleArg name = failwith @@ "Internal failure: Impossible argument to "^name

let rethis = Value.snippetClosure 2 (function
    | [a;Value.ClosureValue(b)] -> Value.ClosureValue( Value.rethis a b )
    | [a;b] -> badArg "rethis" b
    | _ -> impossibleArg "rethis")

let dethis = Value.snippetClosure 1 (function
    | [Value.ClosureValue(a)] -> Value.ClosureValue( Value.dethis a )
    | [a] -> badArg "dethis" a
    | _ -> impossibleArg "dethis")

let decontext = Value.snippetClosure 1 (function
    | [Value.ClosureValue(a)] -> Value.ClosureValue( Value.decontext a )
    | [a] -> badArg "decontext" a
    | _ -> impossibleArg "decontext")

let makeSuper current this = Value.snippetTextClosure
    ["rethis",rethis;"callCurrent",current;"obj",this]
    ["arg"]
    "(rethis obj (callCurrent.parent arg))"

let rawTern = Value.snippetClosure 3 (function
    | [Value.Null;_;v] -> v
    | [_;v;_] -> v
    | _ -> impossibleArg "rawTern")

let tern = Value.snippetTextClosure
    ["rawTern", rawTern; "null", Value.Null]
    ["pred"; "a"; "b"]
    "(rawTern pred a b) null"

let doConstruct = Value.snippetTextClosure
    ["null", Value.Null]
    ["f"]
    "f null"

let nullfn = Value.snippetTextClosure
    ["null", Value.Null]
    []
    "^(null)"

let loop = Value.snippetTextClosure
    ["tern", tern; "null", Value.Null]
    ["f"]
    "{let .loop ^f ( tern (f null) ^(loop f) ^(null) ); loop} f" (* FIXME: This is garbage *)

let ifConstruct = Value.snippetTextClosure
    ["tern", tern; "null", Value.Null]
    ["predicate"; "body"]
    "{let .if ^condition body (
        tern condition ^(body null) ^(null) );
    if} predicate body" (* Garbage construct again *)

let whileConstruct = Value.snippetTextClosure
    ["tern", tern; "null", Value.Null]
    ["predicate"; "body"]
    "{let .while ^predicate body (
        tern (predicate null) ^(body null; while predicate body) ^(null)
    ); while} predicate body" (* Garbage construct again *)

let () =
    let (setAtomValue, setAtomFn, setAtomMethod) = BuiltinNull.atomFuncs scopePrototypeTable in

    setAtomFn "print" (
        let rec printFunction v =
            print_string (Pretty.dumpValueForUser v);
            Value.BuiltinFunctionValue(printFunction)
        in printFunction
    );

    setAtomValue "ln" (Value.StringValue "\n");

    setAtomValue "null" (Value.Null);
    setAtomValue "true" (Value.True);

    setAtomValue "rethis" rethis;
    setAtomValue "dethis" dethis;
    setAtomValue "decontext" rethis;
    setAtomValue "tern" tern;
    setAtomValue "nullfn" nullfn;
    setAtomValue "do" doConstruct;
    setAtomValue "loop" loop;
    setAtomValue "if" ifConstruct;
    setAtomValue "while" whileConstruct;

    setAtomFn "not" (fun v -> match v with Value.Null -> Value.True | _ -> Value.Null);

    setAtomFn "println" (
        let rec printFunction v =
            print_endline (Pretty.dumpValueForUser v);
            Value.BuiltinFunctionValue(printFunction)
        in printFunction
    );
