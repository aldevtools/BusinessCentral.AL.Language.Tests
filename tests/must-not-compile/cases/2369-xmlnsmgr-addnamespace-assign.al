// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'Prefix' of 'AddNamespace(Text, Text)'
// XmlNamespaceManager.AddNamespace needs two arguments: the assignment form gives only one. (al-runner 6526; writer Y29)
codeunit 50000 "MNC C2369"
{
    procedure Run1()
    var
        M: XmlNamespaceManager;
    begin
        M.AddNamespace := 'urn:x';
    end;
}
