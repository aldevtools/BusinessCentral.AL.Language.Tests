// @expect AL0305 | The length of the application object identifier 'MNC SH Name Length Probe Object' cannot exceed 30 characters.
// A report extension whose name has 31 characters.
report 50002 "MNC SH Base Report"
{
    ProcessingOnly = true;
}

reportextension 50001 "MNC SH Name Length Probe Object" extends "MNC SH Base Report"
{
}
