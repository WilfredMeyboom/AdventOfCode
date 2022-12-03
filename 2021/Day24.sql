/*
inp w       --M1
mul x 0     x = 0
add x z
mod x 26
div z 1     z = z = 0
add x 10    x = 10
eql x w     x = 0
eql x 0     x = 1
mul y 0     y = 0
add y 25    y  = 25
mul y x     y = 25
add y 1     y = 26
mul z y     z = 0
mul y 0     y = 0
add y w     y = w -- M1
add y 2     y = M1 + 2
mul y x     y = y
add z y     z = M1 + 2
inp w       -- M2
mul x 0     x = 0
add x z     x = M1 + 2
mod x 26    x = (M1 + 2)%26 = 0 (want 1 <= M1 <= 9)
div z 1     z = M1 + 2
add x 10    x = 10
eql x w     x = 0 (x > 10 en 1 <= M2 <= 9)
eql x 0     x = 1
mul y 0     y = 0
add y 25    y = 25
mul y x     y = 25
add y 1     y = 26
mul z y     z = 26 * (M1 + 2)
mul y 0     y = 0
add y w     y = M2
add y 4     y = M2 + 4
mul y x     y = M2 + 4
add z y     z = 26 * (M1 + 2) + M2 + 4
inp w       w = M3
mul x 0     x = 0
add x z     x = 26 * (M1 + 2) + M2 + 4
mod x 26    x = (26 * (M1 + 2) + M2 + 4) % 26 = M2 + 4
div z 1     z = z
add x 14    x = M2 + 18
eql x w     x = 0 (x > 10 en 1 <= M3 <= 9)
eql x 0     x = 1
mul y 0     y = 0
add y 25    y = 25
mul y x     y = 25
add y 1     y = 26
mul z y     z = 26 * (26 * (M1 + 2) + M2 + 4)
mul y 0     y = 0
add y w     y = M3
add y 8     y = M3 + 8
mul y x     y = M3 + 8
add z y     z = 26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8
inp w       M4
mul x 0     x = 0
add x z     x = 26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8
mod x 26    x = M3 + 8
div z 1     z = z
add x 11    x = M3 + 19
eql x w     x = 0
eql x 0     x = 1
mul y 0     y = 0
add y 25    y = 25
mul y x     y = 25
add y 1     y = 26
mul z y     z = 26 * ( 26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8)
mul y 0     y = 0
add y w     y = M4
add y 7     y = M4 + 7
mul y x     y = y
add z y     z = 26 * ( 26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8) + M4 + 7
inp w       M5
mul x 0     x = 0
add x z     x = 26 * ( 26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8) + M4 + 7
mod x 26    x = M4 + 7
div z 1     z = z
add x 14    x = M4 + 21
eql x w     x = 0 (same)
eql x 0     x = 1
mul y 0     y = 0
add y 25    y = 25
mul y x     y = 25
add y 1     y = 26
mul z y     z = 26 * (26 * ( 26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8) + M4 + 7)
mul y 0     y = 0 
add y w     y = M5
add y 12    y = M5 + 12
mul y x     y = y
add z y     z = 26 * (26 * ( 26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8) + M4 + 7) + M5 + 12
inp w       M6
mul x 0     x = 0
add x z     x = 26 * (26 * ( 26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8) + M4 + 7) + M5 + 12
mod x 26    x = M5 + 12
div z 26    z = FLOOR(26 * (26 * ( 26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8) + M4 + 7) + M5 + 12) / 26)
            z = 26 * ( 26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8) + M4 + 7
add x -14   x = M5 - 2
eql x w     M6 == M5 - 2 ? x = 1                                                                            M5 - 2 == M6
eql x 0     x = 0
mul y 0     y = 0
add y 25    y = 25
mul y x     y = 0
add y 1     y = 1
mul z y     z = z
mul y 0     y = 0
add y w     y = M6
add y 7     y = M6 + 7
mul y x     y = 0
add z y     z = z
inp w       M7
mul x 0     x = 0
add x z     x = 26 * ( 26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8) + M4 + 7
mod x 26    x = M4 + 7
div z 26    z = FLOOR((26 * ( 26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8) + M4 + 7) / 26)
            z = 26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8
add x 0     x = x
eql x w     M7 == M4 + 7 ? x = 1                                                                            M4 + 7 = M7
eql x 0     x = 0
mul y 0     y = 0
add y 25    y = 25
mul y x     y = 0
add y 1     y = 1
mul z y     z = z
mul y 0     y = 0
add y w     y = M7
add y 10    y = M7 + 10
mul y x     y = 0
add z y     z = z
inp w       M8
mul x 0     x = 0
add x z     x = 26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8
mod x 26    x = M3 + 8
div z 1     z = z
add x 10    x = M3 + 18
eql x w     x = 0
eql x 0     x = 1
mul y 0     y = 0
add y 25    y = 25
mul y x     y = 25
add y 1     y = 26
mul z y     z = 26 * (26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8)
mul y 0     y = 0
add y w     y = M8
add y 14    y = M8 + 14
mul y x     y = y
add z y     z = 26 * (26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8) + M8 + 14
inp w       M9
mul x 0     x = 0
add x z     x = 26 * (26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8) + M8 + 14
mod x 26    x = M8 + 14
div z 26    z = 26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8
add x -10   x = M8 + 4
eql x w     M8 + 4 == M9 ? x = 1                                                                            M9 = M8 + 4
eql x 0     x = 0
mul y 0     y = 0
add y 25    y = 25
mul y x     y = 0
add y 1     y = 1
mul z y     z = z
mul y 0     y = 0
add y w     y = M9
add y 2     y = M9 + 2
mul y x     y = 0
add z y     z = z
inp w       M10
mul x 0     x = 0
add x z     x = 26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8
mod x 26    x = M3 + 8
div z 1     z = z
add x 13    x = M3 + 21
eql x w     x = 0
eql x 0     x = 1
mul y 0     y = 0
add y 25    y = 25
mul y x     y = 25
add y 1     y = 26
mul z y     z = 26 * (26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8)
mul y 0     y = 0
add y w     y = M10
add y 6     y = M10 + 6
mul y x     y = y
add z y     z = 26 * (26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8) + M10 + 6
inp w       M11
mul x 0     x = 0
add x z     x = 26 * (26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8) + M10 + 6
mod x 26    x = M10 + 6
div z 26    z = 26 * (26 * (M1 + 2) + M2 + 4) + M3 + 8
add x -12   x = M10 - 6
eql x w     M10 - 6 == M11 ? x = 1                                                                          M11 = M10 - 6
eql x 0     x = 0
mul y 0     y = 0
add y 25    y = 25
mul y x     y = 0
add y 1     y = 1
mul z y     z = z
mul y 0     y = 0
add y w     y = M11
add y 8     y = M11 + 8
mul y x     y = 0
add z y     z = z
inp w       M12
mul x 0     x = 0
add x z     x = z
mod x 26    x = M3 + 8
div z 26    z = 26 * (M1 + 2) + M2 + 4
add x -3    x = M3 + 5
eql x w     M3 + 5 == M12 ? x = 1                                                                           M12 = M3 + 5
eql x 0     x = 0
mul y 0     y = 0
add y 25    y = 25
mul y x     y = 0
add y 1     y = 1
mul z y     z = z
mul y 0     y = 0
add y w     y = M12
add y 11    y = M12 + 11
mul y x     y = 0
add z y     z = z
inp w       M13
mul x 0     x = 0
add x z     x = 26 * (M1 + 2) + M2 + 4
mod x 26    x = M2 + 4
div z 26    z = M1 + 2
add x -11   x = M2 - 7
eql x w     M13 == M2 - 7 ? x = 1                                                                           M13 = M2 - 7
eql x 0     x = 0
mul y 0     y = 0
add y 25    y = 25
mul y x     y = 0
add y 1     y = 1
mul z y     z = z
mul y 0     y = 0
add y w     y = M13
add y 5     y = M13 + 5
mul y x     y = 0
add z y     z = z
inp w       M14
mul x 0     x = 0
add x z     x = M1 + 2
mod x 26    x = M1 + 2
div z 26    z = 0
add x -2    x = M1
eql x w     M1 == M14 ? x = 1                                                                               M1 = M14
eql x 0     x = 0
mul y 0     y = 0
add y 25    y = 25
mul y x     y = 0
add y 1     y = 1
mul z y     z = z
mul y 0     y = 0
add y w     y = M14
add y 11    y = M14 + 11
mul y x     y = 0
add z y     z = 0
*/


/*

M11 = M10 - 6

M9 = M8 + 4

M5 - 2 = M6

M4 + 7 = M7

M12 = M3 + 5

M13 = M2 - 7

M1 = M14


12345678901234
99429795993929

12345678901234
18113181571611

*/

