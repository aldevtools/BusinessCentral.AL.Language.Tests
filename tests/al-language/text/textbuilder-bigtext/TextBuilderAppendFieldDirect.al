// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/textbuilder/textbuilder-append-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 67410, codeunit 67411
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: TextBuilder.Append with FieldRef.Value() written directly as the argument (no Variant parameter in between), for an Integer, Decimal,
//   Boolean, Date and Code field, blank and set; the same with RecordRef.FieldIndex(i).Value() as the argument. Observed: the builder text or the error text and code.
// BC versions: all (CI)

table 67410 "LT TBD Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Int; Integer) { }
        field(3; Dec; Decimal) { }
        field(4; Flag; Boolean) { }
        field(5; D; Date) { }
        field(6; Cde; Code[10]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 67411 "LT TBD Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryAppendField(var TB: TextBuilder; var FR: FieldRef)
    begin
        TB.Append(FR.Value());
    end;

    [TryFunction]
    local procedure TryAppendIndex(var TB: TextBuilder; var RR: RecordRef; Index: Integer)
    begin
        TB.Append(RR.FieldIndex(Index).Value());
    end;

    local procedure Fill(var Row: Record "LT TBD Row")
    begin
        Row.Init();
        Row.Id := 1;
        Row.Int := 42;
        Row.Dec := 1234.5;
        Row.Flag := true;
        Row.D := DMY2Date(5, 3, 2024);
        Row.Cde := 'ABC';
    end;

    local procedure ObserveField(var Observer: Codeunit "Probe Observer"; Tag: Text; var FR: FieldRef)
    var
        TB: TextBuilder;
    begin
        if TryAppendField(TB, FR) then
            Observer.Observe(Tag, 'ok [' + TB.ToText() + ']')
        else begin
            Observer.Observe(Tag, 'error');
            Observer.ObserveError(Tag + '.err');
        end;
    end;

    local procedure ObserveIndex(var Observer: Codeunit "Probe Observer"; Tag: Text; var RR: RecordRef; Index: Integer)
    var
        TB: TextBuilder;
    begin
        if TryAppendIndex(TB, RR, Index) then
            Observer.Observe(Tag, 'ok [' + TB.ToText() + ']')
        else begin
            Observer.Observe(Tag, 'error');
            Observer.ObserveError(Tag + '.err');
        end;
    end;

    [Test]
    procedure FieldRef_Value_Direct_Set()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT TBD Row";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Fill(Row);
        RR.GetTable(Row);
        FR := RR.Field(Row.FieldNo(Int));
        ObserveField(Observer, 'set.int', FR);
        FR := RR.Field(Row.FieldNo(Dec));
        ObserveField(Observer, 'set.dec', FR);
        FR := RR.Field(Row.FieldNo(Flag));
        ObserveField(Observer, 'set.flag', FR);
        FR := RR.Field(Row.FieldNo(D));
        ObserveField(Observer, 'set.date', FR);
        FR := RR.Field(Row.FieldNo(Cde));
        ObserveField(Observer, 'set.code', FR);
        Observer.Expect('set.int', 'ok [42]');
        Observer.Expect('set.dec', 'ok [1,234.5]');
        Observer.Expect('set.flag', 'ok [Yes]');
        Observer.Expect('set.date', 'ok [03/05/24]');
        Observer.Expect('set.code', 'ok [ABC]');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRef_Value_Direct_Blank()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT TBD Row";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Row.Init();
        RR.GetTable(Row);
        FR := RR.Field(Row.FieldNo(Int));
        ObserveField(Observer, 'blank.int', FR);
        FR := RR.Field(Row.FieldNo(Dec));
        ObserveField(Observer, 'blank.dec', FR);
        FR := RR.Field(Row.FieldNo(Flag));
        ObserveField(Observer, 'blank.flag', FR);
        FR := RR.Field(Row.FieldNo(D));
        ObserveField(Observer, 'blank.date', FR);
        FR := RR.Field(Row.FieldNo(Cde));
        ObserveField(Observer, 'blank.code', FR);
        Observer.Expect('blank.int', 'ok [0]');
        Observer.Expect('blank.dec', 'ok [0]');
        Observer.Expect('blank.flag', 'ok [No]');
        Observer.Expect('blank.date', 'ok []');
        Observer.Expect('blank.code', 'ok []');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_FieldIndex_Value_Direct_Set()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT TBD Row";
        RR: RecordRef;
        i: Integer;
    begin
        Fill(Row);
        RR.GetTable(Row);
        for i := 2 to RR.FieldCount() do
            ObserveIndex(Observer, 'idx.' + Format(i), RR, i);
        Observer.Expect('idx.2', 'ok [42]');
        Observer.Expect('idx.3', 'ok [1,234.5]');
        Observer.Expect('idx.4', 'ok [Yes]');
        Observer.Expect('idx.5', 'ok [03/05/24]');
        Observer.Expect('idx.6', 'ok [ABC]');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_FieldIndex_Value_Direct_Blank()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT TBD Row";
        RR: RecordRef;
        i: Integer;
    begin
        Row.Init();
        RR.GetTable(Row);
        for i := 2 to RR.FieldCount() do
            ObserveIndex(Observer, 'idx.' + Format(i), RR, i);
        Observer.Expect('idx.2', 'ok [0]');
        Observer.Expect('idx.3', 'ok [0]');
        Observer.Expect('idx.4', 'ok [No]');
        Observer.Expect('idx.5', 'ok []');
        Observer.Expect('idx.6', 'ok []');
        Observer.Verify();
    end;
}
