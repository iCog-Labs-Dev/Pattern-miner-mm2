(exec (0)
    (, (exec (surp $pri-surp $name-surp) $src-of-surp $sink-of-surp)
        (exec (emp-tv $pri-emp $name-emp) $src-of-emp $sink-of-emp)
    )
    (O
        (- (exec (emp-tv $pri-emp $name-emp) $src-of-emp $sink-of-emp))
        (+ (exec (surp 124 transition-to-emp) (,) (, (exec (emp-tv $pri-emp $name-emp) $src-of-emp $sink-of-emp))))
    )
)