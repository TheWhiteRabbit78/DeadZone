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

S.meteor = {
  ".OO..",
  "OYYO.",
  "OYWYO",
  ".OYO.",
  "..O..",
}

-- friendlies, outposts, nests, lake decor
S.soldier = {
  "...KKKKK.....",
  "..KAAAAAK....",
  ".KAAAAAAAK...",
  "..KSSKSSK....",
  "..KSSSSSK....",
  "...KKKKK.....",
  "..KDDDDDK....",
  ".KDYDYDDSKKKK",
  ".KDDDDDDDDDDK",
  ".KDDDDDKKKKK.",
  "..KBBBBBK....",
  "..KBBKBBK....",
  "..KBBKBBK....",
  "..KKK.KKK....",
}

S.mg_nest = {
  "......KKKKK.........",
  ".....KAAAAAK........",
  "....KAAAAAAAK.......",
  ".....KSSKSSK..KKKKKK",
  ".....KSSSSSKKKDDDDDK",
  "...KKKKKKKKKKDDKKKKK",
  "..KSNSSNSSNSSNSK....",
  ".KSSNSSNSSNSSNSSK...",
  ".KNNKNNKNNKNNKNNK...",
  "KSSNSSNSSNSSNSSNSK..",
  "KSSSSSSSSSSSSSSSSK..",
  "KKKKKKKKKKKKKKKKKK..",
}

S.survivor = {
  "...KKKKK....",
  "..KNNNNNK...",
  "..KNSSSSK...",
  "..KSKSKSK...",
  "..KSSSSSK...",
  "KK.KKKKK.KK.",
  "KSKOOOOOKSK.",
  ".KKOOOOOKK..",
  "..KOOOOOK...",
  "..KOOOOOK...",
  "..KDDDDDK...",
  "..KDDKDDK...",
  "..KDDKDDK...",
  "..KKK.KKK...",
}

S.help = {
  "KKK",
  "KYK",
  "KYK",
  "KYK",
  "KKK",
  "KYK",
  "KKK",
}

S.follower = {
  "...KKKKK....",
  "..KNNNNNK...",
  "..KNSSSSK...",
  "..KSSKSSK...",
  "..KSSSSSK...",
  "...KKKKK....",
  "..KOOOOOK...",
  ".KOOOOOSKKK.",
  ".KOOOOODDDK.",
  ".KOOOOOKKK..",
  "..KDDDDDK...",
  "..KDDKDDK...",
  "..KDDKDDK...",
  "..KKK.KKK...",
}

S.tent = {
  "........K.........",
  ".......KAK........",
  "......KWWAK.......",
  ".....KWWWWAK......",
  "....KWWWWWWAK.....",
  "...KWWWKKKWWAK....",
  "..KWWWKDDDKWWAK...",
  ".KWWWKDDDDDKWWAK..",
  "KWWWKDDDDDDDKWWAK.",
  "KKKKKKKKKKKKKKKKK.",
}

S.flag = {
  "K......",
  "ACCCCK.",
  "ACWWCK.",
  "ACCCCK.",
  "AKKKK..",
  "A......",
  "A......",
  "A......",
  "A......",
  "A......",
  "KAK....",
  "KKK....",
}

S.crate = {
  "KKKKKKKK",
  "KNBNNBNK",
  "KBNBBNBK",
  "KNBNNBNK",
  "KBNBBNBK",
  "KNBNNBNK",
  "KKKKKKKK",
}

S.sandbags = {
  ".KKKKKKKKKKKKKK.",
  "KSSNSSNSSNSSNSSK",
  "KNNKNNKNNKNNKNNK",
  "KSSNSSNSSNSSNSSK",
  "KKKKKKKKKKKKKKKK",
}

S.nest = {
  ".......KKKK.........",
  ".....KKZZZZKK.......",
  "...KKZZDDDDZZKK.....",
  "..KZZDDRDDRDDZZK....",
  ".KZDDDDDDDDDDDDZK...",
  "KZDDWDDDKKDDDWDDZK..",
  "KZDWWWDKKKKDWWWDZK..",
  "KZZDDDDKKKKDDDDZZK..",
  ".KKZZZZZZZZZZZZKK...",
  "...KKKKKKKKKKKK.....",
}

S.ruined_tent = {
  ".......K..........",
  "......KAK.........",
  ".....KWWAK...K....",
  "....KWWZWAK.KZK...",
  "...KWZZKKWAKZZK...",
  "..KWWZKDDKZZWAK...",
  ".KWWKDDDDDKZWWAK..",
  "KZZKDDDDDDDKZZWAK.",
  "KKKKKKKKKKKKKKKKK.",
}

S.reed = {
  ".B.B",
  ".B.B",
  ".L.L",
  "L.LL",
  ".LL.",
}

S.lily = {
  ".gg.",
  "ggYg",
  "gggg",
  ".gg.",
}

S.sparkle = {
  "CC.",
  ".CC",
}

return S
