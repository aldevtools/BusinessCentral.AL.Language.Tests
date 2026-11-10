// Two Enum values named "" are refused.
// @expect AL0155 | A member of type EnumValue with name '' is already defined in Enum 'MNC OB E5'
// @expect AL0155 | A member of type EnumValue with name '' is already defined in Enum 'MNC OB E5'
enum 53304 "MNC OB E5"
{
    value(0; "") { }
    value(1; A) { }
    value(2; "") { }
}
