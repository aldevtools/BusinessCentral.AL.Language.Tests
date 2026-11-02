// @expect AL0275 | 'String' is an ambiguous reference between 'String' defined by the extension
// @target OnPrem
// An app declares, outside a namespace, a dotnet alias with the name of one System Application declares in namespace System (writer Y20,
// al-runner issue 6488): the bare alias is ambiguous. `DotNet System.String` reaches System Application's alias:
// tests/al-language-onprem-dotnet/lt-y20-dotnet-fullname/Y20DotNetFullTypeName.al.
dotnet
{
    assembly(mscorlib)
    {
        type("System.Text.StringBuilder"; String) { }
    }
}

codeunit 52359 "MNC Y20 DN Ambiguous 2359"
{
    procedure P()
    var
        B: DotNet String;
    begin
    end;
}
