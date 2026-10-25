// @expect AL0264 | An application object of type 'Enum' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0264 | An application object of type 'Enum' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// Two enums with the same id.
enum 50001 "MNC SH Enum A"
{
    value(0; None) { }
}

enum 50001 "MNC SH Enum B"
{
    value(0; None) { }
}
