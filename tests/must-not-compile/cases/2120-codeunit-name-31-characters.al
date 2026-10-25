// @expect AL0305 | The length of the application object identifier 'MNC SH Name Length Probe Object' cannot exceed 30 characters.
// A plain codeunit (no Subtype = Test) whose name has 31 characters (30 is the limit; 2115 is the test codeunit form).
codeunit 50001 "MNC SH Name Length Probe Object"
{
}
