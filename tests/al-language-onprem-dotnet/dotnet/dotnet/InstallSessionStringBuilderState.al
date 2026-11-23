// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: OnPrem DotNet, installation and test-session object lifetime
// BC versions: 27.5, 28.5, 29.0
// local object: dedicated installation observation and SingleInstance owner keep this probe isolated.
// Related: AL Runner issue 8954. Native results pending.

dotnet
{
    assembly("Microsoft.Dynamics.Nav.Types")
    {
        type("Microsoft.Dynamics.Nav.Types.ALConfigSettings"; LtInstallSettings) { }
    }
    assembly("Microsoft.Dynamics.Nav.NavUserAccount")
    {
        type("Microsoft.Dynamics.Nav.NavUserAccount.NavUserAccountHelper"; LtInstallUserAccount) { }
    }
    assembly("mscorlib")
    {
        type("System.Text.StringBuilder"; LtInstallSessionBuilder) { }
    }
}

codeunit 99453 "LT Install Builder State"
{
    SingleInstance = true;

    var
        Builder: DotNet LtInstallSessionBuilder;

    procedure SetValue(Value: Text)
    begin
        Builder := Builder.StringBuilder();
        Builder.Append(Value);
    end;

    procedure ReadValue(): Text
    begin
        if IsNull(Builder) then
            exit('');
        exit(Builder.ToString());
    end;

    procedure ResetValue()
    begin
        Clear(Builder);
    end;
}
