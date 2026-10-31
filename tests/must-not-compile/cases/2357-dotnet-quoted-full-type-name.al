// @expect AL0185 | DotNet 'System.Text.StringBuilder' is missing
// @target OnPrem
// A DotNet variable that names, in quotes, the .NET full type name of a type the app declares under another alias (writer Y20, al-runner
// issue 6488): the name is looked up as an alias. An alias that is literally "System.Text.StringBuilder" is reached quoted:
// tests/al-language-onprem-dotnet/lt-y20-dotnet-fullname/Y20DotNetFullTypeName.al.
dotnet
{
    assembly(mscorlib)
    {
        type("System.Text.StringBuilder"; MncY20Builder) { }
    }
}

codeunit 52357 "MNC Y20 DN Quoted 2357"
{
    procedure P()
    var
        Quoted: DotNet "System.Text.StringBuilder";
    begin
    end;
}
