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

-- HUD weapon icons (16x6)
S.hud_w1 = {
  ".....KKKKKKKKKK.",
  ".....KAAAAAAAAAK",
  ".....KKKDDDDDDK.",
  ".......KDDKKKK..",
  "......KDDK......",
  "......KKK.......",
}
S.hud_w2 = {
  "KKKK.KKKKKKKKKKK",
  "KBBBKKAAAAAAAAAK",
  "KBBBBKDDDDDDDDK.",
  ".KBBBKKNNNK.....",
  "..KKK..KKK......",
  "................",
}
S.hud_w3 = {
  "...KKKKKKKKKKK..",
  "..KAAAAAAAAAAAK.",
  "KKKDDDDDDDDDKKK.",
  "KDDKKDDKKKK.....",
  "KKK..KDDK.......",
  ".....KKKK.......",
}
S.hud_w4 = {
  ".KKKKKKKKKKKKKK.",
  "KUUUUUUUUUUUUURK",
  "KUUUUUUUUUUUURRK",
  ".KKKKBBKKKKKKKK.",
  "....KBBK........",
  "....KKKK........",
}
S.hud_heart = {
  ".RR.RR.",
  "RWRRRRR",
  "RRRRRRR",
  ".RRRRR.",
  "..RRR..",
  "...R...",
}
S.hud_skull = {
  ".WWWWW.",
  "WWWWWWW",
  "WKKWKKW",
  "WWWKWWW",
  ".WWWWW.",
  ".W.W.W.",
}

-- biome props (based on MiniWorld Sprites by Shade, CC0)
S.snowpine = {
  ".....KK.....",
  "....KWWK....",
  "...KWWWWK...",
  "...KWWWWK...",
  "..KWWWWWWK..",
  "..KWWWWWWK..",
  ".KWWWWWWWWK.",
  ".KWWWWWWWWK.",
  "KLWWWWWWWWLK",
  "KLLWLWWWWLLK",
  "KLLLLLLLLLLK",
  ".KLLLLLLLLK.",
  "..KKBBBBKK..",
  "...KBBBBK...",
  "...KBBBBK...",
}
S.snowoak = {
  "....KKKK....",
  "...KWWWWK...",
  "..KWWWWWWK..",
  "..KWWWWWWK..",
  ".KWWWWWWWWK.",
  ".KWWWWWWWWK.",
  "KLWWWWWWWWLK",
  "KLWWWWWWWWLK",
  "KLLWWWWWWLLK",
  "KLLLLLLLLLLK",
  ".KLLLLLLLLK.",
  "..KKBBBBKK..",
  "...KBBBBK...",
  "...KBBBBK...",
}
S.snowrock = {
  "......KKKK....",
  ".....KWWWWK...",
  "....KAWWWWWK..",
  "..KKKWWWWWWAK.",
  ".KWWWAWWWWWAK.",
  "KWWWWWAWWWAAAK",
  "KWWWWWWAAAAAAK",
  "KWWWWWWWAWWWWK",
  "KAWWWWAAWWWWWK",
  "KAWWWAWWWWWWWK",
  "KAWWWAWWWWWAAK",
  "KAWWWAWWWWWAAK",
  "..WWAAWWWWWAAK",
}
S.cactus = {
  "....KK....",
  "...KYYK...",
  "..KKYYK...",
  ".KYKggKK..",
  ".KgKggKYK.",
  ".KggggKgK.",
  ".KKKggggK.",
  "KYKKggKKK.",
  "KgKKggKKYK",
  "KgggggKKgK",
  ".KKKgggggK",
  "...KggKKK.",
  "...KggK...",
}
S.cactus2 = {
  ".KK.KK..KK...",
  "KYYKYYKKYYK..",
  "KggKggKKggK..",
  ".KgYYgKYYgK..",
  ".KKggKKggKKK.",
  "KYggYYKgYYgYK",
  "KYgKggKKgggYK",
  ".KKKgYYgYgKK.",
  "....KgggYK...",
  "....KggKK....",
  "....KggK.....",
}
S.palm = {
  "........KK...",
  "...KKK.KggK..",
  "..KZZgKggKK..",
  ".KZZggggZZZK.",
  "KgggggNgggggK",
  "KgggZZgZggKK.",
  ".KKZggggZZgK.",
  ".KgggggggggK.",
  ".KggNNNNNggK.",
  ".KgKNNgNNKgK.",
  "..K.KNNKK.KK.",
  "...KNNNK.....",
  "...KgggK.....",
  "..KNNNK......",
  "..KNNNK......",
}
S.palm2 = {
  "...KK........",
  "..KggK.KKK...",
  "..KKggKgZZK..",
  ".KZZZggggZZK.",
  "KgggggNgggggK",
  ".KKggZgZZgggK",
  ".KgZZggggZKK.",
  ".KgggggggggK.",
  ".KggKKNNKggK.",
  ".KgK.KggKKgK.",
  ".KK..KNNK.K..",
  ".....KNNNK...",
  ".....KgggK...",
  "......KNNNK..",
  "......KNNNK..",
}
S.deadtree = {
  "....K.KK.K....",
  "...KBKBBKBK...",
  "..KKBNBBNBKK..",
  ".KBKKNBBNKKBK.",
  ".KBKBKBBKBKBK.",
  ".KBNBKBBKBNBK.",
  ".KKKBNBBKBKKK.",
  "KBKBKNBBNBBKBK",
  "KBNBKKBBKKBNBK",
  ".KKBBNBBNBBKK.",
  "...KKKBBKKK...",
  ".....KBBK.....",
  ".....KBBK.....",
  ".....KBBK.....",
}
S.tomb = {
  "....KK....",
  "..KKWWKK..",
  "..KWAAWK..",
  "..KAAAAK..",
  ".KWWAAWWK.",
  "KAWWAAWWAK",
  "KAWWWWWWAK",
  "KAAAAAAAAK",
  "KAAAAAAAAK",
  "KAAAAAAAAK",
  "KAAAAAAAAK",
  "KAAAAAAAAK",
  "KAAAAAAAAK",
}
S.mossrock = {
  "..KKKKK.......",
  ".KLgggLK......",
  "KLggggggKKKK..",
  "KLgggggLLggLK.",
  "KLgggggLggggLK",
  "KLgggggLggggLK",
  "KDLLgggLggggLK",
  "KDAALLLLggLLLK",
  "KDAAAADALLAADK",
  "KDAAAADAAAAADK",
  "..DAAADDAAAD..",
}
S.tumble = {
  ".....K....",
  ".K.KKNK.K.",
  "KNKYYYNKYK",
  ".KYYYYYYNK",
  "KNYNYNNYK.",
  "KYYYNYNYNK",
  ".KNYNYYNK.",
  "..KNYNNK..",
}
S.redrock = {
  "..KKKKK.......",
  ".KNOOONK......",
  "KNOOOOOOKKKK..",
  "KNOOOOONNOONK.",
  "KNOOOOONOOOONK",
  "KNOOOOONOOOONK",
  "KBNNOOONOOOONK",
  "KBBBNNNNOONNNK",
  "KBBBBBBBNNBBBK",
  "KBBBBBBBBBBBBK",
  "..BBBBBBBBBB..",
}
-- biome ground decoration
S.d_snow1 = { "A.A" }
S.d_snow2 = { ".A", "A." }
S.d_ice = { "C" }
S.d_slush1 = { "WWW", ".WW" }
S.d_slush2 = { "CC." }
S.d_crack = { "D.", ".D" }
S.d_sand1 = { "N.N" }
S.d_sand2 = { ".Y", "Y." }
S.d_bones = { "W.W", ".W." }
S.d_crack2 = { "B..", ".BB" }
S.d_stripe = { "OOO" }
S.d_moss = { "Z.Z", ".Z." }
S.d_mud = { ".BB", "BBB", "BB." }
S.d_puddle = { ".UU", "UUU" }
S.d_reed = { "L.L", "L.L" }
S.d_leaf = { "g.g", "ggg" }
S.d_fern = { "L.L", ".L." }
S.d_flowerR = { "R" }
S.d_flowerY = { "Y" }
S.d_shroom = { "RR", ".W" }
S.d_shade = { "LL", "L." }

-- HUD mage weapon icons (16x6)
S.hud_w5 = {
  "............KKK.",
  "...........KCWCK",
  "KKKKKKKKKKKKCCCK",
  "KBBBBBBBBBBKKCK.",
  "KKKKKKKKKKKK.K..",
  "................",
}
S.hud_w6 = {
  "............KK..",
  "KKKKKKKKKKKKCWK.",
  "KAAAAAAAAAYKWWCK",
  "KKKKKKKKKKKKCWK.",
  "............KK..",
  "................",
}
S.hud_w7 = {
  "...........KKKK.",
  "..........KYYK..",
  "KKKKKKKKKKKYYYYK",
  "KBBBBBBBBBAKYYK.",
  "KKKKKKKKKKKKYK..",
  "...........KK...",
}
S.hud_w8 = {
  ".............K..",
  "............KCK.",
  "KKKKKKKKKKKKCWCK",
  "KUUUUUUUUUUUKCK.",
  "KKKKKKKKKKKK.K..",
  "................",
}
S.hud_w9 = {
  "............KK..",
  "...........KOOK.",
  "KKKKKKKKKKKORYOK",
  "KNNNNNNNNNNKORK.",
  "KKKKKKKKKKKKKK..",
  "................",
}

-- cemetery
S.crypt = {
  "........KKKKKK........",
  "......KKAAAAAAKK......",
  "....KKAAWWWWWWAAKK....",
  "..KKAAAAAAAAAAAAAAKK..",
  "KKKKKKKKKKKKKKKKKKKKKK",
  ".KAAKAAAAKKKKAAAAKAAK.",
  ".KAAKAAAKDDDDKAAAKAAK.",
  ".KWAKAAKDDDDDDKAAKAWK.",
  ".KAAKAAKDDDDDDKAAKAAK.",
  ".KAAKAAKDDRRDDKAAKAAK.",
  ".KAAKAAKDDDDDDKAAKAAK.",
  ".KWAKAAKDDDDDDKAAKAWK.",
  ".KAAKAAKDDDDDDKAAKAAK.",
  "KKKKKKKKKKKKKKKKKKKKKK",
  "KAAAAAAAAAAAAAAAAAAAAK",
  "KKKKKKKKKKKKKKKKKKKKKK",
}
S.grave = {
  ".KKK.",
  "KAAAK",
  "KAWAK",
  "KAAAK",
  "KAAAK",
  "KKKKK",
}
S.grave2 = {
  "..K..",
  ".KAK.",
  "KAAAK",
  ".KAK.",
  ".KAK.",
  "KKKKK",
}
S.crypt_chest = {
  "KKKKKKKK",
  "KDADDADK",
  "KAAAAAAK",
  "KKKRRKKK",
  "KDADDADK",
  "KDDDDDDK",
  "KKKKKKKK",
}

return S
