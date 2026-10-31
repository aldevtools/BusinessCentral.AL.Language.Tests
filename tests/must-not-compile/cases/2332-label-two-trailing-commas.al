// @expect AL0107 | Syntax error, identifier expected.
// A Label declaration with two commas after the text ('T',,;) is rejected; one comma compiles (al-runner issue 6436, writer Y12).
// Recorded with AL 30.0.42.60748.
codeunit 50000 "MNC Codeunit"
{
    var
        SetupLbl: Label 'T',,;
}
