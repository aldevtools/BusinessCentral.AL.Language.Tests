// @expect AL0301 | A list must end with a member; not a separator ,.
// A Label declaration with a trailing comma after a property (Locked = true,;) is rejected. A trailing comma right after the label text
// ('x',;) compiles: tests/al-language/text/lt-label-textbuilder/TxCLabel.al, Y12_Label_TrailingComma (al-runner issue 6436, writer Y12).
// Recorded with AL 30.0.42.60748.
codeunit 50000 "MNC Codeunit"
{
    var
        SetupLbl: Label 'L', Locked = true,;
}
