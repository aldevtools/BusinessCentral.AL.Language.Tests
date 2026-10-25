// @expect AL0304 | Length of the identifier 'AbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijA' cannot exceed 120 characters
// A table field name of 121 characters (unquoted). Field names have no 30 character limit; 120 compiles.
table 50001 "MNC SH T"
{
    fields { field(1; Id; Integer) { } field(2; AbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijA; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
