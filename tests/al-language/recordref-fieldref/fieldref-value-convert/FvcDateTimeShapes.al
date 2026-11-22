// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), FVC Source (75980)
// Probe: written against a local BC 27.5 / 28.5 / 29.0 observe host; every literal asserted below is what BC produced.
// Facts: FieldRef.Value of an Integer, BigInteger, Decimal, Duration or Boolean field assigned to a DateTime (runner issue 8662, extends FvcIntegerField, FvcOtherFields).
//   Four assignment shapes per value: a var parameter, a plain declared local, a by-value parameter and a named return value.
//   The var parameter shape matches the earlier probe; the other three measure whether the target slot changes the result.
//   Values beyond the earlier probe: more Decimal values (negative, many decimals, whole, 1000 or more) and Duration values (days, other milliseconds, 0, negative).
// BC versions: see the asserted values; a version guard is used only where the versions differ.

codeunit 75985 "FVC DateTime Shapes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure IntField_To_DateTime_Shapes()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 0;
        Shapes(Observer, FR, '0');
        FR.Value := 1;
        Shapes(Observer, FR, '1');
        FR.Value := 1000;
        Shapes(Observer, FR, '1000');
        FR.Value := -1;
        Shapes(Observer, FR, 'neg1');
        Observer.Finish();
    end;

    [Test]
    procedure BigField_To_DateTime_Shapes()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(BigF));
        FR.Value := 1;
        Shapes(Observer, FR, '1');
        FR.Value := 3000000000;
        Shapes(Observer, FR, '3e9');
        FR.Value := -1;
        Shapes(Observer, FR, 'neg1');
        Observer.Finish();
    end;

    [Test]
    procedure DecField_To_DateTime_Shapes_Small()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DecF));
        FR.Value := -0.5;
        Shapes(Observer, FR, 'neg half');
        FR.Value := 0.123456789;
        Shapes(Observer, FR, 'many decimals');
        FR.Value := 999.99;
        Shapes(Observer, FR, '999.99');
        FR.Value := 1.5;
        Shapes(Observer, FR, '1.5');
        Observer.Finish();
    end;

    [Test]
    procedure DecField_To_DateTime_Shapes_Large()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DecF));
        FR.Value := 1000.5;
        Shapes(Observer, FR, '1000.5');
        FR.Value := 0;
        Shapes(Observer, FR, 'zero');
        FR.Value := 1;
        Shapes(Observer, FR, 'one');
        FR.Value := 5;
        Shapes(Observer, FR, 'five');
        FR.Value := -1000.25;
        Shapes(Observer, FR, 'neg 1000.25');
        Observer.Finish();
    end;

    [Test]
    procedure DurField_To_DateTime_Shapes_Small()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DurF));
        FR.Value := 1;
        Shapes(Observer, FR, '1 ms');
        FR.Value := 65000;
        Shapes(Observer, FR, '65000');
        FR.Value := 65001;
        Shapes(Observer, FR, '65001');
        FR.Value := 0;
        Shapes(Observer, FR, '0');
        FR.Value := -1;
        Shapes(Observer, FR, 'neg1');
        Observer.Finish();
    end;

    [Test]
    procedure DurField_To_DateTime_Shapes_Large()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DurF));
        FR.Value := 1000;
        Shapes(Observer, FR, '1000');
        FR.Value := 93780000;
        Shapes(Observer, FR, '1 day 2h 3m');
        FR.Value := 86400000;
        Shapes(Observer, FR, '1 day');
        FR.Value := 7200000;
        Shapes(Observer, FR, '2h');
        Observer.Finish();
    end;

    [Test]
    procedure BoolField_To_DateTime_Shapes()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(BoolF));
        FR.Value := true;
        Shapes(Observer, FR, 'true');
        FR.Value := false;
        Shapes(Observer, FR, 'false');
        Observer.Finish();
    end;

    local procedure Shapes(var Observer: Codeunit "Probe Observer"; var FR: FieldRef; Label: Text)
    var
        Res: Text;
    begin
        Res := '';
        if TryVarParam(FR, Res) then Observer.Observe(Label + ' var', Res) else Observer.ObserveError(Label + ' var');
        Res := '';
        if TryLocal(FR, Res) then Observer.Observe(Label + ' local', Res) else Observer.ObserveError(Label + ' local');
        Res := '';
        if TryByValue(FR, Res) then Observer.Observe(Label + ' byval', Res) else Observer.ObserveError(Label + ' byval');
        Res := '';
        if TryNamedReturn(FR, Res) then Observer.Observe(Label + ' named', Res) else Observer.ObserveError(Label + ' named');
    end;

    [TryFunction]
    local procedure TryVarParam(var FR: FieldRef; var Res: Text)
    var
        P: DateTime;
    begin
        FillVar(FR, P);
        Res := Format(P, 0, 9);
    end;

    local procedure FillVar(var FR: FieldRef; var R: DateTime)
    begin
        R := FR.Value;
    end;

    [TryFunction]
    local procedure TryLocal(var FR: FieldRef; var Res: Text)
    var
        L: DateTime;
    begin
        L := FR.Value;
        Res := Format(L, 0, 9);
    end;

    [TryFunction]
    local procedure TryByValue(var FR: FieldRef; var Res: Text)
    begin
        Res := FillByValue(FR, 0DT);
    end;

    local procedure FillByValue(var FR: FieldRef; R: DateTime): Text
    begin
        R := FR.Value;
        exit(Format(R, 0, 9));
    end;

    [TryFunction]
    local procedure TryNamedReturn(var FR: FieldRef; var Res: Text)
    begin
        Res := Format(NamedReturn(FR), 0, 9);
    end;

    local procedure NamedReturn(var FR: FieldRef) R: DateTime
    begin
        R := FR.Value;
    end;
}
