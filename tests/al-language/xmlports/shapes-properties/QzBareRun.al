// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope
// Fixtures used: own table 79005 "LT AJ Item" (types/lt-aj-probes/AjMisc.al); the tests are QZ_* in codeunit 79002 (AjRunAndXmlPort.al)
// Facts: a bare Run() and Run(Rec) (without this.) inside a codeunit: as a statement, as a Boolean result, with `if not Run(Rec) then`,
//   with an OnRun that raises an error, and whether it runs the OnRun of the same instance (globals shared) as this.Run() does.
// BC versions: 27.5+

codeunit 87680 "LT QZ Bare Run"
{
    var
        RunCount: Integer;

    trigger OnRun()
    begin
        RunCount += 1;
    end;

    procedure CallBareRun(): Boolean
    begin
        exit(Run());
    end;

    procedure CallBareRunAsStatement()
    begin
        Run();
    end;

    procedure CallBareRunInIf(): Text
    begin
        if Run() then
            exit('if true');
        exit('if false');
    end;

    procedure GetCount(): Integer
    begin
        exit(RunCount);
    end;
}

codeunit 87681 "LT QZ Bare Run Rec"
{
    TableNo = "LT AJ Item";

    var
        RunCount: Integer;

    trigger OnRun()
    begin
        RunCount += 1;
        if Rec.Txt = 'fail' then
            Error('LT QZ bare run rec failed');
        Rec.Txt := 'qz ran ' + Format(RunCount);
        Rec.Id += 10;
    end;

    procedure CallBareRunRec(var R: Record "LT AJ Item"): Boolean
    begin
        if not Run(R) then
            exit(false);
        exit(true);
    end;

    procedure CallBareRunRecAsStatement(var R: Record "LT AJ Item")
    begin
        Run(R);
    end;

    procedure GetCount(): Integer
    begin
        exit(RunCount);
    end;
}

codeunit 87682 "LT QZ Bare Run Error"
{
    trigger OnRun()
    begin
        Error('LT QZ bare run failed');
    end;

    procedure CallBareRun(): Boolean
    begin
        exit(Run());
    end;

    procedure CallBareRunAsStatement()
    begin
        Run();
    end;
}
