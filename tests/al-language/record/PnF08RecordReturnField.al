// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-return-values
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73881, codeunit 73881
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "A field of what a procedure returns (GetLocation(Code)."Bin Mandatory")" (Tests-SCM round 2)
// Facts: p()."Field" and p().Field as an rvalue of a procedure that returns a Record (a copy of the row): in an expression, an argument, a condition, a flowfield-free field of a Text, Boolean, Decimal and Code type
// BC versions: 29 (27 and 28 by CI)

table 73881 "LT PnF Ret Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; "Bin Mandatory"; Boolean) { }
        field(3; "Name Text"; Text[30]) { }
        field(4; Amount; Decimal) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

codeunit 73881 "LT PnF Record Return"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Calls: Integer;

    local procedure GetRow(CodeValue: Code[10]): Record "LT PnF Ret Row"
    var
        Row: Record "LT PnF Ret Row";
    begin
        Calls += 1;
        if Row.Get(CodeValue) then;
        exit(Row);
    end;

    local procedure Echo(Value: Text): Text
    begin
        exit(Value);
    end;

    [Test]
    procedure ReturnedRecord_FieldRvalue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF Ret Row";
        B: Boolean;
        D: Decimal;
        C: Code[10];
        T: Text;
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row."Bin Mandatory" := true;
        Row."Name Text" := 'alpha';
        Row.Amount := 12.5;
        Row.Insert();
        Calls := 0;
        B := GetRow('A')."Bin Mandatory";
        D := GetRow('A').Amount;
        C := GetRow('A').Code;
        T := GetRow('A')."Name Text";
        Observer.Observe('bool', Format(B));
        Observer.Observe('decimal', Format(D));
        Observer.Observe('code', C);
        Observer.Observe('text', T);
        Observer.Observe('calls', Format(Calls));
        Observer.Observe('inline', Format(GetRow('A').Amount + 1));
        Observer.Observe('arg', Echo(GetRow('A')."Name Text"));
        if GetRow('A')."Bin Mandatory" then
            Observer.Observe('if', 'true')
        else
            Observer.Observe('if', 'false');
        Observer.Expect('bool', 'Yes');
        Observer.Expect('decimal', '12.5');
        Observer.Expect('code', 'A');
        Observer.Expect('text', 'alpha');
        Observer.Expect('calls', '4');
        Observer.Expect('inline', '13.5');
        Observer.Expect('arg', 'alpha');
        Observer.Expect('if', 'true');
        Observer.Verify();
    end;

    [Test]
    procedure ReturnedRecord_MissingRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF Ret Row";
    begin
        Row.DeleteAll();
        Observer.Observe('bool', Format(GetRow('NONE')."Bin Mandatory"));
        Observer.Observe('text', GetRow('NONE')."Name Text");
        Observer.Observe('decimal', Format(GetRow('NONE').Amount));
        Observer.Observe('code', GetRow('NONE').Code);
        Observer.Expect('bool', 'No');
        Observer.Expect('text', '');
        Observer.Expect('decimal', '0');
        Observer.Expect('code', '');
        Observer.Verify();
    end;

    [Test]
    procedure ReturnedRecord_IsCopy()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF Ret Row";
        Copy1: Record "LT PnF Ret Row";
    begin
        Row.DeleteAll();
        Row.Code := 'B';
        Row."Name Text" := 'beta';
        Row.Insert();
        Copy1 := GetRow('B');
        Copy1."Name Text" := 'changed';
        Observer.Observe('copy', Copy1."Name Text");
        Observer.Observe('again', GetRow('B')."Name Text");
        Row.Get('B');
        Observer.Observe('stored', Row."Name Text");
        Observer.Expect('copy', 'changed');
        Observer.Expect('again', 'beta');
        Observer.Expect('stored', 'beta');
        Observer.Verify();
    end;
}
