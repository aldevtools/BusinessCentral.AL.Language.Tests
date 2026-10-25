// @expect AL0264 | An application object of type 'Report' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0264 | An application object of type 'Report' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// Two reports with the same id.
report 50001 "MNC SH Report A"
{
    ProcessingOnly = true;
}

report 50001 "MNC SH Report B"
{
    ProcessingOnly = true;
}
