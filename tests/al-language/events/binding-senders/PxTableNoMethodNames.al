// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 82151 "LT BN With Row" (WithStatementAmbiguous.al)
// Writer PX (runtime probes-needed, PR 331): in a codeunit with TableNo, which declaration a bare call binds to when the codeunit has its own
// procedure with the name of a record method (Count, IsEmpty, GetFilters, Reset, IsDirty): in OnRun (implicit `with Rec`) and in a
// procedure outside OnRun (called from OnRun and from outside). WithStatementAmbiguous.al pins IsDirty() inside OnRun (BC 29 only).
// BC versions: 27-29
codeunit 86237 "LT PX TableNo Names Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(var Row: Record "LT BN With Row")
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Description := 'stored';
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Row.Get(1);
    end;

    [Test]
    procedure PX_TableNo_BareNamesInOnRun()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BN With Row";
        Names: Codeunit "LT PX TableNo Names";
    begin
        Seed(Row);
        Names.Run(Row);
        Observer.Observe('onrun', Names.Trace());
        Observer.Expect('onrun', 'Count=1;IsEmpty=No;GetFilters=Id: 1;after Reset Rec.GetFilters=;outside[Count=42,IsEmpty=Yes,GetFilters=own-getfilters,IsDirty=Yes]');
        Observer.Verify();
    end;

    [Test]
    procedure PX_TableNo_BareNamesOutsideOnRun()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BN With Row";
        Names: Codeunit "LT PX TableNo Names";
    begin
        Seed(Row);
        Observer.Observe('outside_called_directly', Names.Outside());
        Observer.Expect('outside_called_directly', 'Count=42,IsEmpty=Yes,GetFilters=own-getfilters,IsDirty=Yes');
        Observer.Verify();
    end;
}

codeunit 86238 "LT PX TableNo Names"
{
    TableNo = "LT BN With Row";

    var
        Log: Text;

    trigger OnRun()
    begin
        Rec.Description := 'changed';
        Rec.SetRange(Id, 1);
        Log := 'Count=' + Format(Count()) + ';';
        Log += 'IsEmpty=' + Format(IsEmpty()) + ';';
        Log += 'GetFilters=' + GetFilters() + ';';
        Reset();
        Log += 'after Reset Rec.GetFilters=' + Rec.GetFilters() + ';';
        Log += 'outside[' + Outside() + ']';
    end;

    local procedure Count(): Integer
    begin
        Log += 'own Count;';
        exit(42);
    end;

    local procedure IsEmpty(): Boolean
    begin
        Log += 'own IsEmpty;';
        exit(true);
    end;

    local procedure GetFilters(): Text
    begin
        exit('own-getfilters');
    end;

    local procedure Reset()
    begin
        Log += 'own Reset;';
    end;

    local procedure IsDirty(): Boolean
    begin
        exit(true);
    end;

    procedure Outside(): Text
    begin
        exit('Count=' + Format(Count()) + ',IsEmpty=' + Format(IsEmpty()) + ',GetFilters=' + GetFilters() + ',IsDirty=' + Format(IsDirty()));
    end;

    procedure Trace(): Text
    begin
        exit(Log);
    end;
}
