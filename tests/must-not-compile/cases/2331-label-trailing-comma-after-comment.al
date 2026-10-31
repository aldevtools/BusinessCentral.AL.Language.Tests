// @expect AL0301 | A list must end with a member; not a separator ,.
// A Label declaration with a trailing comma after the Comment property is rejected (al-runner issue 6436, writer Y12).
// Recorded with AL 30.0.42.60748.
codeunit 50000 "MNC Codeunit"
{
    var
        SetupLbl: Label 'C', Comment = 'c',;
}
