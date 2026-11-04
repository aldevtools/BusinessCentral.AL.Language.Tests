// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 70252, test codeunit 70253
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// to Text and Code variables: the text is observed next to Format(D), with the default language and GlobalLanguage = 1031 (always restored).
// Writer QO (al-runtime-rs assumption date-to-text-is-format): each conversion on its own (the P147 tests above stop at the first error):
//   a Variant that holds a Date (V := D), a Time and a DateTime, assigned to a Text and a Code variable and passed to a Text, Text[30] and
//   Code[20] parameter; FieldRef.Value of a Date, Time and DateTime field used directly in the same places; a Variant set from FieldRef.Value
//   in the same procedure. Each text is observed next to Format(X) and Format(X, 0, 9), and Evaluate reads it back. Dates: 03/05/2024,
//   0D and ClosingDate(03/05/2024). QO_ tests in codeunit 70253.
// BC versions: 29 (27 and 28 by CI)

table 70252 "LT P147 Dates"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; D; Date) { }
        field(3; DT; DateTime) { }
        field(4; T; Time) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 70253 "LT P147 Date To Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    local procedure TakeText(Value: Text): Text
    begin
        exit(Value);
    end;

    local procedure TakeText30(Value: Text[30]): Text
    begin
        exit(Value);
    end;

    local procedure TakeCode20(Value: Code[20]): Text
    begin
        exit(Value);
    end;

    local procedure TakeVariant(Value: Variant): Text
    var
        Txt: Text;
    begin
        Txt := Value;
        exit(Txt);
    end;

    local procedure DateVariant(Id: Integer; Which: Integer): Variant
    var
        Rec: Record "LT P147 Dates";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Rec.DeleteAll();
        Rec.Id := Id;
        Rec.D := DMY2Date(5, 3, 2024);
        Rec.DT := CreateDateTime(DMY2Date(5, 3, 2024), 134500T);
        Rec.T := 134500T;
        Rec.Insert();
        RecRef.GetTable(Rec);
        FldRef := RecRef.Field(Which);
        exit(FldRef.Value);
    end;

    local procedure ObserveAll(var Observer: Codeunit "Probe Observer"; Prefix: Text; V: Variant; FormatText: Text)
    var
        AsText: Text;
        AsCode: Code[20];
    begin
        Observer.Observe(Prefix + ' Format(D)', FormatText);
        Observer.Observe(Prefix + ' Text param', '[' + TakeText(V) + ']');
        Observer.Observe(Prefix + ' Text[30] param', '[' + TakeText30(V) + ']');
        Observer.Observe(Prefix + ' Code[20] param', '[' + TakeCode20(V) + ']');
        Observer.Observe(Prefix + ' Variant param then Text', '[' + TakeVariant(V) + ']');
        AsText := V;
        Observer.Observe(Prefix + ' Text assign', '[' + AsText + ']');
        AsCode := V;
        Observer.Observe(Prefix + ' Code assign', '[' + AsCode + ']');
        Observer.Observe(Prefix + ' Format(Variant)', Format(V));
    end;

    [Test]
    procedure P147_DateVariant_DefaultLanguage()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P147 Dates";
        V: Variant;
        D: Date;
    begin
        Rec.DeleteAll();
        V := DateVariant(1, 2);
        D := V;
        asserterror ObserveAll(Observer, 'date', V, Format(D));
        Observer.ObserveError('af99');
        Observer.Observe('is date', Format(V.IsDate()));
        Observer.Expect('date Format(D)', '03/05/24');
        Observer.Expect('af99|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('af99|code', 'TypeConversion');
        Observer.Expect('is date', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P147_DateVariant_German()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P147 Dates";
        V: Variant;
        D: Date;
        OldLanguage: Integer;
    begin
        Rec.DeleteAll();
        OldLanguage := GlobalLanguage();
        V := DateVariant(1, 2);
        D := V;
        GlobalLanguage(1031);
        asserterror ObserveAll(Observer, 'de date', V, Format(D));
        Observer.ObserveError('af119');
        GlobalLanguage(OldLanguage);
        Observer.Observe('language restored', Format(GlobalLanguage() = OldLanguage));
        Observer.Expect('de date Format(D)', '03/05/24');
        Observer.Expect('af119|text', 'Der Ausdruck Microsoft.Dynamics.Nav.Runtime.NavIndirectValue kann nicht in einen Microsoft.Dynamics.Nav.Runtime.NavText-Wert typkonvertiert werden.');
        Observer.Expect('af119|code', 'TypeConversion');
        Observer.Expect('language restored', 'Yes');
        Observer.Verify();
    end;

    // Writer QO. Kind 1 Text := V, 2 Text parameter, 3 Text[30] parameter, 4 Code[20] parameter, 5 Code[20] := V.
    [TryFunction]
    local procedure QoFromVariant(Kind: Integer; V: Variant; var Result: Text)
    var
        AsText: Text;
        AsCode: Code[20];
    begin
        case Kind of
            1:
                begin
                    AsText := V;
                    Result := AsText;
                end;
            2:
                Result := TakeText(V);
            3:
                Result := TakeText30(V);
            4:
                Result := TakeCode20(V);
            5:
                begin
                    AsCode := V;
                    Result := AsCode;
                end;
        end;
    end;

    // The same with FieldRef.Value used directly.
    [TryFunction]
    local procedure QoFromFieldRef(Kind: Integer; FldRef: FieldRef; var Result: Text)
    var
        AsText: Text;
        AsCode: Code[20];
        V: Variant;
    begin
        case Kind of
            1:
                begin
                    AsText := FldRef.Value;
                    Result := AsText;
                end;
            2:
                Result := TakeText(FldRef.Value);
            3:
                Result := TakeText30(FldRef.Value);
            4:
                Result := TakeCode20(FldRef.Value);
            5:
                begin
                    AsCode := FldRef.Value;
                    Result := AsCode;
                end;
            6:
                begin
                    V := FldRef.Value;
                    AsText := V;
                    Result := AsText;
                end;
        end;
    end;

    [TryFunction]
    local procedure QoEvaluate(Which: Integer; Txt: Text; var Result: Text)
    var
        D: Date;
        T: Time;
        DT: DateTime;
    begin
        case Which of
            2:
                begin
                    Evaluate(D, Txt);
                    Result := Format(D, 0, 9);
                end;
            3:
                begin
                    Evaluate(DT, Txt);
                    Result := Format(DT, 0, 9);
                end;
            4:
                begin
                    Evaluate(T, Txt);
                    Result := Format(T, 0, 9);
                end;
        end;
    end;

    local procedure QoObserveVariant(Prefix: Text; V: Variant; Which: Integer)
    var
        Kind: Integer;
        Result: Text;
        Back: Text;
    begin
        Obs.Observe(Prefix + '.fmt', Format(V));
        Obs.Observe(Prefix + '.fmt9', Format(V, 0, 9));
        for Kind := 1 to 5 do
            if QoFromVariant(Kind, V, Result) then begin
                Obs.Observe(Prefix + '.k' + Format(Kind), '[' + Result + ']');
                if Kind in [1, 5] then
                    if QoEvaluate(Which, Result, Back) then
                        Obs.Observe(Prefix + '.k' + Format(Kind) + '.eval', Back)
                    else
                        Obs.ObserveError(Prefix + '.k' + Format(Kind) + '.eval');
            end else
                Obs.ObserveError(Prefix + '.k' + Format(Kind));
    end;

    local procedure QoObserveFieldRef(Prefix: Text; Id: Integer; Which: Integer)
    var
        Rec: Record "LT P147 Dates";
        RecRef: RecordRef;
        FldRef: FieldRef;
        Kind: Integer;
        Result: Text;
        Back: Text;
    begin
        Rec.Get(Id);
        RecRef.GetTable(Rec);
        FldRef := RecRef.Field(Which);
        Obs.Observe(Prefix + '.fmt', Format(FldRef.Value));
        for Kind := 1 to 6 do
            if QoFromFieldRef(Kind, FldRef, Result) then begin
                Obs.Observe(Prefix + '.k' + Format(Kind), '[' + Result + ']');
                if Kind in [1, 5] then
                    if QoEvaluate(Which, Result, Back) then
                        Obs.Observe(Prefix + '.k' + Format(Kind) + '.eval', Back)
                    else
                        Obs.ObserveError(Prefix + '.k' + Format(Kind) + '.eval');
            end else
                Obs.ObserveError(Prefix + '.k' + Format(Kind));
    end;

    local procedure QoSeed()
    var
        Rec: Record "LT P147 Dates";
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.D := DMY2Date(5, 3, 2024);
        Rec.DT := CreateDateTime(DMY2Date(5, 3, 2024), 134500T);
        Rec.T := 134500T;
        Rec.Insert();
        Rec.Id := 2;
        Rec.D := 0D;
        Rec.DT := 0DT;
        Rec.T := 0T;
        Rec.Insert();
        Rec.Id := 3;
        Rec.D := ClosingDate(DMY2Date(5, 3, 2024));
        Rec.DT := 0DT;
        Rec.T := 0T;
        Rec.Insert();
    end;

    [Test]
    procedure QO_DateVariant_EachConversion()
    var
        V: Variant;
        D: Date;
    begin
        D := DMY2Date(5, 3, 2024);
        V := D;
        QoObserveVariant('d', V, 2);
        Obs.Expect('d.fmt', '03/05/24');
        Obs.Expect('d.fmt9', '2024-03-05');
        Obs.Expect('d.k1|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Obs.Expect('d.k1|code', 'TypeConversion');
        Obs.Expect('d.k2|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Obs.Expect('d.k2|code', 'TypeConversion');
        Obs.Expect('d.k3|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Obs.Expect('d.k3|code', 'TypeConversion');
        Obs.Expect('d.k4|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Obs.Expect('d.k4|code', 'TypeConversion');
        Obs.Expect('d.k5|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Obs.Expect('d.k5|code', 'TypeConversion');
        Obs.Verify();
    end;

    [Test]
    procedure QO_BlankDateVariant_EachConversion()
    var
        V: Variant;
        D: Date;
    begin
        D := 0D;
        V := D;
        QoObserveVariant('d0', V, 2);
        Obs.Expect('d0.fmt', '');
        Obs.Expect('d0.fmt9', '');
        Obs.Expect('d0.k1|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Obs.Expect('d0.k1|code', 'TypeConversion');
        Obs.Expect('d0.k2|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Obs.Expect('d0.k2|code', 'TypeConversion');
        Obs.Expect('d0.k3|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Obs.Expect('d0.k3|code', 'TypeConversion');
        Obs.Expect('d0.k4|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Obs.Expect('d0.k4|code', 'TypeConversion');
        Obs.Expect('d0.k5|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Obs.Expect('d0.k5|code', 'TypeConversion');
        Obs.Verify();
    end;

    [Test]
    procedure QO_ClosingDateVariant_EachConversion()
    var
        V: Variant;
        D: Date;
    begin
        D := ClosingDate(DMY2Date(5, 3, 2024));
        V := D;
        QoObserveVariant('dc', V, 2);
        Obs.Expect('dc.fmt', 'C03/05/24');
        Obs.Expect('dc.fmt9', '2024-03-05');
        Obs.Expect('dc.k1|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Obs.Expect('dc.k1|code', 'TypeConversion');
        Obs.Expect('dc.k2|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Obs.Expect('dc.k2|code', 'TypeConversion');
        Obs.Expect('dc.k3|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Obs.Expect('dc.k3|code', 'TypeConversion');
        Obs.Expect('dc.k4|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Obs.Expect('dc.k4|code', 'TypeConversion');
        Obs.Expect('dc.k5|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Obs.Expect('dc.k5|code', 'TypeConversion');
        Obs.Verify();
    end;

    [Test]
    procedure QO_TimeVariant_EachConversion()
    var
        V: Variant;
        T: Time;
    begin
        T := 134500T;
        V := T;
        QoObserveVariant('t', V, 4);
        Obs.Expect('t.fmt', ' 1:45:00 PM');
        Obs.Expect('t.fmt9', '13:45:00');
        Obs.Expect('t.k1|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Obs.Expect('t.k1|code', 'TypeConversion');
        Obs.Expect('t.k2|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Obs.Expect('t.k2|code', 'TypeConversion');
        Obs.Expect('t.k3|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Obs.Expect('t.k3|code', 'TypeConversion');
        Obs.Expect('t.k4|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Obs.Expect('t.k4|code', 'TypeConversion');
        Obs.Expect('t.k5|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Obs.Expect('t.k5|code', 'TypeConversion');
        Obs.Verify();
    end;

    [Test]
    procedure QO_DateTimeVariant_EachConversion()
    var
        V: Variant;
        DT: DateTime;
    begin
        DT := CreateDateTime(DMY2Date(5, 3, 2024), 134500T);
        V := DT;
        QoObserveVariant('dt', V, 3);
        Obs.Expect('dt.fmt', '03/05/24 01:45 PM');
        Obs.Expect('dt.fmt9', '2024-03-05T13:45:00Z');
        Obs.Expect('dt.k1|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Obs.Expect('dt.k1|code', 'TypeConversion');
        Obs.Expect('dt.k2|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Obs.Expect('dt.k2|code', 'TypeConversion');
        Obs.Expect('dt.k3|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Obs.Expect('dt.k3|code', 'TypeConversion');
        Obs.Expect('dt.k4|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Obs.Expect('dt.k4|code', 'TypeConversion');
        Obs.Expect('dt.k5|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Obs.Expect('dt.k5|code', 'TypeConversion');
        Obs.Verify();
    end;

    [Test]
    procedure QO_DateFieldRef_EachConversion()
    begin
        QoSeed();
        QoObserveFieldRef('fd', 1, 2);
        Obs.Expect('fd.fmt', '03/05/24');
        Obs.Expect('fd.k1', '[03/05/24]');
        Obs.Expect('fd.k1.eval', '2024-03-05');
        Obs.Expect('fd.k2', '[03/05/24]');
        Obs.Expect('fd.k3', '[03/05/24]');
        Obs.Expect('fd.k4', '[03/05/24]');
        Obs.Expect('fd.k5', '[03/05/24]');
        Obs.Expect('fd.k5.eval', '2024-03-05');
        Obs.Expect('fd.k6|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Obs.Expect('fd.k6|code', 'TypeConversion');
        Obs.Verify();
    end;

    [Test]
    procedure QO_BlankDateFieldRef_EachConversion()
    begin
        QoSeed();
        QoObserveFieldRef('fd0', 2, 2);
        Obs.Expect('fd0.fmt', '');
        Obs.Expect('fd0.k1', '[]');
        Obs.Expect('fd0.k1.eval', '');
        Obs.Expect('fd0.k2', '[]');
        Obs.Expect('fd0.k3', '[]');
        Obs.Expect('fd0.k4', '[]');
        Obs.Expect('fd0.k5', '[]');
        Obs.Expect('fd0.k5.eval', '');
        Obs.Expect('fd0.k6|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Obs.Expect('fd0.k6|code', 'TypeConversion');
        Obs.Verify();
    end;

    [Test]
    procedure QO_ClosingDateFieldRef_EachConversion()
    begin
        QoSeed();
        QoObserveFieldRef('fdc', 3, 2);
        Obs.Expect('fdc.fmt', 'C03/05/24');
        Obs.Expect('fdc.k1', '[C03/05/24]');
        Obs.Expect('fdc.k1.eval', '2024-03-05');
        Obs.Expect('fdc.k2', '[C03/05/24]');
        Obs.Expect('fdc.k3', '[C03/05/24]');
        Obs.Expect('fdc.k4', '[C03/05/24]');
        Obs.Expect('fdc.k5', '[C03/05/24]');
        Obs.Expect('fdc.k5.eval', '2024-03-05');
        Obs.Expect('fdc.k6|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Obs.Expect('fdc.k6|code', 'TypeConversion');
        Obs.Verify();
    end;

    [Test]
    procedure QO_TimeFieldRef_EachConversion()
    begin
        QoSeed();
        QoObserveFieldRef('ft', 1, 4);
        Obs.Expect('ft.fmt', ' 1:45:00 PM');
        Obs.Expect('ft.k1', '[ 1:45:00 PM]');
        Obs.Expect('ft.k1.eval', '13:45:00');
        Obs.Expect('ft.k2', '[ 1:45:00 PM]');
        Obs.Expect('ft.k3', '[ 1:45:00 PM]');
        Obs.Expect('ft.k4', '[1:45:00 PM]');
        Obs.Expect('ft.k5', '[1:45:00 PM]');
        Obs.Expect('ft.k5.eval', '13:45:00');
        Obs.Expect('ft.k6|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Obs.Expect('ft.k6|code', 'TypeConversion');
        Obs.Verify();
    end;

    [Test]
    procedure QO_DateTimeFieldRef_EachConversion()
    begin
        QoSeed();
        QoObserveFieldRef('fdt', 1, 3);
        Obs.Expect('fdt.fmt', '03/05/24 01:45 PM');
        Obs.Expect('fdt.k1', '[03/05/24 01:45 PM]');
        Obs.Expect('fdt.k1.eval', '2024-03-05T13:45:00Z');
        Obs.Expect('fdt.k2', '[03/05/24 01:45 PM]');
        Obs.Expect('fdt.k3', '[03/05/24 01:45 PM]');
        Obs.Expect('fdt.k4', '[03/05/24 01:45 PM]');
        Obs.Expect('fdt.k5', '[03/05/24 01:45 PM]');
        Obs.Expect('fdt.k5.eval', '2024-03-05T13:45:00Z');
        Obs.Expect('fdt.k6|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Obs.Expect('fdt.k6|code', 'TypeConversion');
        Obs.Verify();
    end;
}
