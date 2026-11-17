-- DEAD ZONE sprites. Letters map to palette.lua, '.' = transparent.
-- Edit freely: rows must all be the same width.

local S = {}

S.player = {
  "...KKKKK....",
  "..KBBBBBK...",
  "..KBBBSSK...",
  "..KBSSKSK...",
  "..KSSSSSK...",
  "...KKKKK....",
  "..KUUUUUK...",
  ".KUUUUUSKKKK",
  ".KUUUUSDDDDK",
  ".KUUUUUKKKK.",
  "..KDDDDDK...",
  "..KDDKDDK...",
  "..KDDKDDK...",
  "..KKK.KKK...",
}

S.zombie = {
  "..KKKKK....",
  ".KZZZZZK...",
  ".KZZZZZK...",
  ".KZKRZKRK..",
  ".KZZZZZK...",
  ".KZKKKZK...",
  "..KKKKKKKKK",
  ".KNNNNZZZZK",
  ".KNNNNKKKK.",
  ".KNRNNK....",
  ".KNNRNK....",
  ".KDDDDK....",
  ".KDDKDDK...",
  ".KDK.KDK...",
  ".KK..KKK...",
}

S.ghoul = {
  "....KKKK...",
  "...KAAAAK..",
  "...KAKRAAK.",
  "...KAAAAAK.",
  "....KAKWKK.",
  "..KKNNNKK..",
  ".KAKNNNNKK.",
  "KAK.KNNNKAK",
  "KK..KNNNKAK",
  "...KDDKDKK.",
  "..KDK.KDDK.",
  "..KK...KKK.",
}

S.brute = {
  "....KKKKKK.....",
  "...KZZZZZZK....",
  "...KZKRZKRK....",
  "...KZZZZZZK....",
  "...KZWKWKZK....",
  "..KKKKKKKKKK...",
  ".KAAKNNNNKAAK..",
  "KAAAKNNNNKAAAK.",
  "KZZKNNRNNNKZZK.",
  "KZZKNNNNRNKZZK.",
  "KZZKNNNNNNKZZK.",
  ".KKKAAAAAAKKK..",
  "...KDDDKDDDK...",
  "...KDDDKDDDK...",
  "...KDDK.KDDK...",
  "...KKKK.KKKK...",
}

S.skeleton = {
  "..KKKKK.....",
  ".KWWWWWK.K..",
  ".KWKWKWK.KB.",
  ".KWWWWWK..KB",
  "..KWKWK...KB",
  "...KWK....KB",
  "..KWWWK..KWB",
  ".KWKWKWKKWKB",
  ".KWWWWWKK.KB",
  "..KWKWK...KB",
  "..KWWWK..KB.",
  "..KWKWK..K..",
  "..KW.KW.....",
  "..KK.KK.....",
}

S.bomb_imp = {
  "......YO...",
  ".....KY.O..",
  "...KKKKK...",
  "..KDDDDDK..",
  ".KDAADDDDK.",
  ".KDADDDDDK.",
  ".KDDDDDDDK.",
  "..KDDDDDK..",
  ".KRKKKKKRK.",
  "..KRRRRRK..",
  "..KRYRYRK..",
  "..KRRRRRK..",
  "...KRKRK...",
  "...KK.KK...",
}

S.boss = {
  "......Y..Y..Y......",
  "......YY.YY.YY.....",
  ".....KYYYYYYYYK....",
  "....KWWWWWWWWWWK...",
  "....KWKKWWWKKWWK...",
  "....KWKRWWWKRWWK...",
  "....KWWWWKWWWWWK...",
  ".....KWKWKWKWKK....",
  "...KKKKWWWWWKKKKK..",
  "..KNNNKKWWWKKNNNNK.",
  ".KNNNNNKWKWKNNNNNNK",
  ".KNWWNNKWWWKNNWWNNK",
  ".KNWWNNKWKWKNNWWNNK",
  ".KNNNNKWWWWWKNNNNNK",
  "..KWWKNNNNNNNKKWWK.",
  "..KWWKNNYYYNNK.KWWK",
  "..KKKKNNNNNNNK..KKK",
  ".....KDDDKDDDK.....",
  ".....KDDDKDDDK.....",
  ".....KWWK.KWWK.....",
  ".....KKKK.KKKK.....",
}

S.xp_orb = {
  ".CC.",
  "CWCC",
  "CCCC",
  ".CC.",
}

S.heart = {
  ".KK.KK.",
  "KRRKRRK",
  "KRWRRRK",
  ".KRRRK.",
  "..KRK..",
  "...K...",
}

S.magnet = {
  ".KKKKK.",
  "KRRRRRK",
  "KRKKKRK",
  "KRK.KRK",
  "KWK.KWK",
  "KAK.KAK",
  "KKK.KKK",
}

S.bullet = {
  "YY",
}

S.pellet = {
  "O",
}

S.rocket = {
  "..KK.",
  "OYDDA",
  "..KK.",
}

S.arrow = {
  "WBBBBA",
}

S.oak = {
  "....LLLLLL....",
  "..LLgggLLLLL..",
  ".LLggLLLLgLLL.",
  "LLgLLLLLggLLLL",
  "LLLLLgLLLLLLLL",
  "LgLLLLLLLgLLLL",
  "LLLLgLLLLLLLgL",
  ".LLLLLLgLLLLL.",
  "..LLLLLLLLLL..",
  "....LLBBLL....",
  ".....KBBK.....",
  ".....KBBK.....",
  ".....KBBK.....",
  "....KBBBBK....",
}

S.pine = {
  ".....L.....",
  "....LLL....",
  "...LLgLL...",
  "....LLL....",
  "...LLLgL...",
  "..LLgLLLL..",
  "...LLLLL...",
  "..LLLLLgL..",
  ".LLgLLLLLL.",
  "..LLLLLLL..",
  ".LLLLLgLLL.",
  "LLLgLLLLLLL",
  "....KBK....",
  "....KBK....",
}

S.rock = {
  "...KKKK...",
  "..KAAWAK..",
  ".KAAAAAAK.",
  "KAADAAAAAK",
  "KADDDAADDK",
  ".KKKKKKKK.",
}

S.xp_big = {
  ".YY.",
  "YWYY",
  "YYYY",
  ".YY.",
}

S.chest = {
  ".KKKKKK.",
  "KNNNNNNK",
  "KBBBBBBK",
  "KKKYYKKK",
  "KNNYYNNK",
  "KNNNNNNK",
  "KKKKKKKK",
}

S.saw1 = {
  "A.A.A",
  ".AWA.",
  "AWDWA",
  ".AWA.",
  "A.A.A",
}

S.saw2 = {
  "..A..",
  ".AWA.",
  "AWDWA",
  ".AWA.",
  "..A..",
}

return S
