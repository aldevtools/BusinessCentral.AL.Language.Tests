// @expect AL0185 | DotNet 'System.Text.StringBuilder' is missing
// @target OnPrem
// A DotNet variable that names the .NET full type name of a type the app declares under another alias (writer Y20, al-runner issue 6488):
// the name is namespace System.Text + alias StringBuilder, which no app declares (System Application declares StringBuilder in namespace
// System, so `DotNet System.StringBuilder` compiles): tests/al-language-onprem-dotnet/lt-y20-dotnet-fullname/Y20DotNetFullTypeName.al.
dotnet
{
    assembly(mscorlib)
    {
        type("System.Text.StringBuilder"; MncY20Builder2358) { }
    }
}

codeunit 52358 "MNC Y20 DN Full Name 2358"
{
    procedure P()
    var
        Builder: DotNet System.Text.StringBuilder;
    begin
    end;
}
