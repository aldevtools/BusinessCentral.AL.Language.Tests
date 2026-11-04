// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// XmlElement.InnerText has only a getter: the assignment form is refused. (al-runner 6526; writer Y29)
codeunit 50000 "MNC C2366"
{
    procedure Run1()
    var
        E: XmlElement;
    begin
        E.InnerText := 'x';
    end;
}
