// @expect AL0264 | An application object of type 'ReportExtension' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0264 | An application object of type 'ReportExtension' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// Two report extensions of one report with the same id.
report 50000 "MNC SH Base Report"
{
    ProcessingOnly = true;
}

reportextension 50001 "MNC SH Report Ext A" extends "MNC SH Base Report"
{
}

reportextension 50001 "MNC SH Report Ext B" extends "MNC SH Base Report"
{
}
