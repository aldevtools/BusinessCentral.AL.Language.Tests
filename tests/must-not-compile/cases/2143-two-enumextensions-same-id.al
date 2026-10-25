// @expect AL0264 | An application object of type 'EnumExtension' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0264 | An application object of type 'EnumExtension' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// Two enum extensions of one enum with the same id.
enum 50000 "MNC SH Base Enum"
{
    Extensible = true;
    value(0; None) { }
}

enumextension 50001 "MNC SH Enum Ext A" extends "MNC SH Base Enum"
{
    value(50001; A) { }
}

enumextension 50001 "MNC SH Enum Ext B" extends "MNC SH Base Enum"
{
    value(50002; B) { }
}
