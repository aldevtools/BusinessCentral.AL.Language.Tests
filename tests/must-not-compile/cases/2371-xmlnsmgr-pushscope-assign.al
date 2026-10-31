// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// XmlNamespaceManager.PushScope has no parameter: the assignment form is refused. (al-runner 6526; writer Y29)
codeunit 50000 "MNC C2371"
{
    procedure Run1()
    var
        M: XmlNamespaceManager;
    begin
        M.PushScope := true;
    end;
}
