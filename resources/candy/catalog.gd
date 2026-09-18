class_name CandyCatalog
extends RefCounted

const FAMILIES: Array[String] = ["Lollipops", "Wrapped sweets", "Chocolate bars", "Boxed sweets"]
const NAMES: Array[String] = ["Strawberry", "Lemon", "Blueberry", "Grape", "Cherry", "Orange", "Apple", "Blackberry", "Milk", "Dark", "Mint", "Caramel", "Peach rings", "Sour watermelon", "Rainbow bites", "Berry chews"]
const COLORS: Array[Color] = [Color("f53c81"), Color("ffd831"), Color("2698f2"), Color("9b45d9"), Color("eb3154"), Color("ff8d22"), Color("61cd47"), Color("6543ad"), Color("de6950"), Color("553647"), Color("22c8a6"), Color("e9ad35"), Color("ff9970"), Color("39c887"), Color("22bfdf"), Color("d24bc1")]
const PATTERNS: Array[String] = ["heart / stripes", "sun / dots", "diamond / checks", "star / chevrons"]
const ICONS: Array[String] = ["♥", "●", "◆", "★"]
const SHORT: Array[String] = ["ST", "LE", "BL", "GR", "CH", "OR", "AP", "BB", "MI", "DA", "MT", "CA", "PE", "WA", "RA", "BE"]
const TOTAL: int = 320
const VARIANT_COUNT: int = 16
const COPIES: int = 20
const DESTINATION_COUNT: int = 16

static func family(variant: int) -> int:
	return variant / 4

static func describe(variant: int) -> String:
	return "%s · %s · %s" % [NAMES[variant], FAMILIES[family(variant)], PATTERNS[variant % 4]]
