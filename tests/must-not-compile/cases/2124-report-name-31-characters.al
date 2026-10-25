// @expect AL0305 | The length of the application object identifier 'MNC SH Name Length Probe Object' cannot exceed 30 characters.
// A report whose name has 31 characters.
report 50001 "MNC SH Name Length Probe Object"
{
    ProcessingOnly = true;
}
