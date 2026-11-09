// @expect AL0156 | 'Char' is not a valid field type. Use basic types (Text, Integer, Decimal, etc.) or reference custom types (Record, Enum, etc.).
// @expect AL0156 | 'Byte' is not a valid field type. Use basic types (Text, Integer, Decimal, etc.) or reference custom types (Record, Enum, etc.).
// A table field of type Char or Byte. The two types exist as variables only, so an XmlPort field element or attribute (which binds to a table
// field) can never carry a Char or a Byte (al-runner 7522).
table 53112 "MNC XP T3112"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Ch; Char) { }
        field(3; By; Byte) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
