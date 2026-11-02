// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// XmlDocument.NameTable has no setter: the assignment form is refused (XmlNamespaceManager.NameTable := compiles). (al-runner 6526; writer Y29)
codeunit 50000 "MNC C2365"
{
    procedure Run1()
    var
        D: XmlDocument;
        N: XmlNameTable;
    begin
        D.NameTable := N;
    end;
}
