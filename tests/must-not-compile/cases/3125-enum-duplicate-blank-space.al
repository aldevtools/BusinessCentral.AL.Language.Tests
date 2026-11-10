// Two Enum values named " " are refused.
// @expect AL0155 | A member of type EnumValue with name ' ' is already defined in Enum 'MNC OB E6'
// @expect AL0155 | A member of type EnumValue with name ' ' is already defined in Enum 'MNC OB E6'
enum 53305 "MNC OB E6"
{
    value(0; " ") { }
    value(1; A) { }
    value(2; " ") { }
}
