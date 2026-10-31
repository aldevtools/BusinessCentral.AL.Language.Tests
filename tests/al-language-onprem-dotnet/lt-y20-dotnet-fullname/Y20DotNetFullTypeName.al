// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; dotnet declarations in Y20DotNetNsAliases.al
// Probe (writer Y20, al-runner issue 6488): observed on the corpus CI matrix (OnPrem DotNet legs).
// Facts: what `DotNet A.B.C` names. Microsoft's System Application declares, inside `namespace System;`, the aliases DateTime, String
//   and StringBuilder (type("System.DateTime"; "DateTime") and so on), and its AFS Format Helper declares
//   `DateTimeDotNet: DotNet System.DateTime`. The name is resolved as namespace + alias, not as a .NET full type name:
//   `DotNet System.DateTime` and `DotNet System.String` compile without a declaration in this app, and so does
//   `DotNet System.StringBuilder` (namespace System, alias StringBuilder), which is no .NET type name; the bare alias `DotNet DateTime`
//   compiles with no `using`; an alias of this app's namespace LtY20.DotNetNs is reached qualified or bare; an alias that is literally
//   "System.Text.StringBuilder" is reached quoted. The .NET full name of a type this app declares under another alias does not compile
//   (must-not-compile 2358, AL0185), nor quoted (2357, AL0185), nor a name with an unknown namespace (2355, AL0791); an alias this app
//   declares outside a namespace with the name of a System Application alias is ambiguous (2359, AL0275).
// BC versions: 27, 28, 29

codeunit 99477 "LT Y20 DotNet Full Type Name"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure AppendVia(var B: DotNet Y20NsBuilder; Value: Text)
    begin
        B.Append(Value);
    end;

    [Test]
    procedure Y20_DotNet_SystemString()
    var
        Observer: Codeunit "Probe Observer";
        S: DotNet System.String;
        Result: List of [Text];
    begin
        S := 'abc';
        Result.Add(S);
        Observer.Observe('list', Result.Get(1));
        Observer.Observe('length', Format(S.Length));
        Observer.Observe('upper', S.ToUpper());
        Observer.Finish();
    end;

    [Test]
    procedure Y20_DotNet_SystemDateTime_AndBareAlias()
    var
        Observer: Codeunit "Probe Observer";
        DateTimeDotNet: DotNet System.DateTime;
        Bare: DotNet DateTime;
    begin
        DateTimeDotNet := DateTimeDotNet.DateTime(2024, 3, 5, 9, 7, 2);
        Observer.Observe('parts', Format(DateTimeDotNet.Year) + '-' + Format(DateTimeDotNet.Month) + '-' + Format(DateTimeDotNet.Day) + ' ' +
            Format(DateTimeDotNet.Hour) + ':' + Format(DateTimeDotNet.Minute) + ':' + Format(DateTimeDotNet.Second));
        Observer.Observe('iso', DateTimeDotNet.ToString('yyyy-MM-ddTHH:mm:ss'));
        Bare := DateTimeDotNet;
        Observer.Observe('bare year', Format(Bare.Year));
        Observer.Finish();
    end;

    [Test]
    procedure Y20_DotNet_NamespaceAliasForms_SameType()
    var
        Observer: Codeunit "Probe Observer";
        SysBuilder: DotNet System.StringBuilder;
        Qualified: DotNet LtY20.DotNetNs.Y20NsBuilder;
        Bare: DotNet Y20NsBuilder;
        Quoted: DotNet "System.Text.StringBuilder";
    begin
        SysBuilder := SysBuilder.StringBuilder();
        SysBuilder.Append('s');
        Qualified := SysBuilder;
        Qualified.Append('q');
        Bare := Qualified;
        AppendVia(Bare, 'b');
        Quoted := Bare;
        Quoted.Append('u');
        AppendVia(Quoted, 'p');
        Observer.Observe('text', SysBuilder.ToString());
        Observer.Observe('same object', Format(SysBuilder.Equals(Quoted)));
        Observer.Finish();
    end;
}
