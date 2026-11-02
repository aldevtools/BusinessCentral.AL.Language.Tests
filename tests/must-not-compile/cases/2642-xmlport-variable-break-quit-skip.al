// @expect AL0161 | 'Break()' is inaccessible due to its protection level
// @expect AL0161 | 'BreakUnbound()' is inaccessible due to its protection level
// @expect AL0161 | 'Quit()' is inaccessible due to its protection level
// @expect AL0161 | 'Skip()' is inaccessible due to its protection level
// Break, BreakUnbound, Quit and Skip exist only inside the XmlPort (currXMLport); on an XmlPort variable they are inaccessible (al-runner
// issue 6657, writer Y66). The members a variable has: tests/al-language/xmlport/lt-y66-xmlport-var-members/Y66XmlPortVarMembers.al.
xmlport 52640 "MNC Y66 XP"
{
    schema
    {
        textelement(Root) { }
    }
}

codeunit 52644 "MNC Y66 XP Members"
{
    procedure P()
    var
        Port: XmlPort "MNC Y66 XP";
    begin
        Port.Break();
        Port.BreakUnbound();
        Port.Quit();
        Port.Skip();
    end;
}
