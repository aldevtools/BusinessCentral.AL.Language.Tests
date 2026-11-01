// @expect AL0132 | 'XmlPort "MNC Y66 XP B"' does not contain a definition for 'UseRequestPage'
// UseRequestPage is an XmlPort property, not a method of an XmlPort variable (al-runner issue 6657, writer Y66); a Report variable has it.
xmlport 52641 "MNC Y66 XP B"
{
    schema
    {
        textelement(Root) { }
    }
}

codeunit 52645 "MNC Y66 XP UseRequestPage"
{
    procedure P()
    var
        Port: XmlPort "MNC Y66 XP B";
    begin
        Port.UseRequestPage(false);
    end;
}
