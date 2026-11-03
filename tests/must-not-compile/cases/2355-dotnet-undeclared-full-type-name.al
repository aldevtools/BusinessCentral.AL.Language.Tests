// @expect AL0791 | The namespace 'Collections' is unknown.
// @expect AL0791 | The namespace 'Specialized' is unknown.
// @target OnPrem
// A DotNet variable named A.B.C is namespace A.B + alias C (writer Y20, al-runner issue 6488): a name whose namespace no app declares fails
// on each unknown namespace part. System.DateTime compiles because System Application declares alias DateTime in namespace System:
// tests/al-language-onprem-dotnet/lt-y20-dotnet-fullname/Y20DotNetFullTypeName.al.
codeunit 52355 "MNC Y20 DN Undeclared 2355"
{
    procedure P()
    var
        C: DotNet System.Collections.Specialized.StringCollection;
    begin
    end;
}
