// @expect AL0133 | Argument 1: cannot convert from 'XmlNodeList' to 'XmlDeclaration'
// The right side of the assignment form is checked as the argument of the one-parameter overload. (al-runner 6526; writer Y29)
codeunit 50000 "MNC C2372"
{
    procedure Run1()
    var
        D: XmlDocument;
    begin
        D.SetDeclaration := D.GetChildNodes();
    end;
}
