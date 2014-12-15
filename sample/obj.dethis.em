# Test magic "dethis"/"decontext" functions
# Expect:
# 2.
# 2.
# 2.
# 3.
# 3.
# 3.

let .obj1 [
    let .var1 2
    let .meth1 ^(println (current.var1) (this.var1))
]

let .obj2 [
    let .var1 3
    let .meth2 (dethis    (obj1.meth1))
    let .meth3 (decontext (obj1.meth1))
]

obj1.meth1 null
obj2.meth2 null
obj2.meth3 null
