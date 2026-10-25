// @expect AL0304 | Length of the identifier '"MNC SH Enum Name Of 119 Characters AbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcd"' cannot exceed 120 characters
// An enum name of 119 characters. Enum names have no 30 character limit (tests/al-language/misc/lt-cv-odd-leads/CvEnumLongNames.al uses 38),
// but every identifier stops at 120 characters, and the two quotes count: 118 characters in quotes compile, 119 do not.
enum 50001 "MNC SH Enum Name Of 119 Characters AbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcd"
{
    value(0; None) { }
}
