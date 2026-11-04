// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), enums of OjT71038.al, own table 71044, self-contained test codeunit 71045
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Enum as table field: default, Init, Insert, Validate, filters, TestField, invalid ordinal
// BC versions: 29 (27 and 28 by CI)

table 71044 "LT OjT Enum Rec"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Col; Enum "LT OjT Color") { }
        field(3; NoZ; Enum "LT OjT NoZero") { }
        field(4; Blk; Enum "LT OjT BlankName") { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(ByCol; Col) { }
    }
}

codeunit 71045 "LT OjT Enum Field"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Field_DefaultAndInit()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT OjT Enum Rec";
    begin
        Rec.DeleteAll();
        Observer.Observe('new.col', Format(Rec.Col) + '|' + Format(Rec.Col, 0, 2));
        Observer.Observe('new.noz', '[' + Format(Rec.NoZ) + ']|' + Format(Rec.NoZ, 0, 2));
        Observer.Observe('new.blk', '[' + Format(Rec.Blk) + ']|' + Format(Rec.Blk, 0, 2));
        Rec.Col := Enum::"LT OjT Color"::Yellow;
        Rec.Init();
        Observer.Observe('init.col', Format(Rec.Col, 0, 2));
        Rec.Col := Enum::"LT OjT Color"::Yellow;
        Rec."No." := 1;
        Rec.Insert();
        Observer.Observe('count', Format(Rec.Count()));
        Rec.Reset();
        Rec.Get(1);
        Observer.Observe('got.col', Format(Rec.Col) + '|' + Format(Rec.Col, 0, 2));
        Clear(Rec);
        Observer.Observe('cleared.col', Format(Rec.Col, 0, 2));
        Observer.Expect('new.col', 'Red|0');
        Observer.Expect('new.noz', '[0]|0');
        Observer.Expect('new.blk', '[ ]|0');
        Observer.Expect('init.col', '0');
        Observer.Expect('count', '1');
        Observer.Expect('got.col', 'Sunny|10');
        Observer.Expect('cleared.col', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Field_InsertModifyRead()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT OjT Enum Rec";
    begin
        Rec.DeleteAll();
        Rec."No." := 1;
        Rec.Col := Enum::"LT OjT Color"::Green;
        Rec.NoZ := Enum::"LT OjT NoZero"::Two;
        Rec.Blk := Enum::"LT OjT BlankName"::Three;
        Rec.Insert();
        Rec.Get(1);
        Observer.Observe('col', Format(Rec.Col));
        Observer.Observe('noz', Format(Rec.NoZ));
        Observer.Observe('blk', Format(Rec.Blk));
        Rec.Col := Enum::"LT OjT Color"::"Dark Blue";
        Rec.Modify();
        Rec.Get(1);
        Observer.Observe('modified', Format(Rec.Col, 0, 2));
        Observer.Observe('colOp', Format(Rec.Col = Rec.Col::"Dark Blue"));
        Observer.Observe('colOpNe', Format(Rec.Col = Rec.Col::Red));
        Observer.Expect('col', 'Green Caption');
        Observer.Expect('noz', 'Two');
        Observer.Expect('blk', 'Three');
        Observer.Expect('modified', '5');
        Observer.Expect('colOp', 'Yes');
        Observer.Expect('colOpNe', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Field_FilterAndCount()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT OjT Enum Rec";
        i: Integer;
    begin
        Rec.DeleteAll();
        for i := 1 to 6 do begin
            Rec.Init();
            Rec."No." := i;
            Rec.Col := Enum::"LT OjT Color".FromInteger(i mod 2);
            Rec.Insert();
        end;
        Rec."No." := 7;
        Rec.Col := Enum::"LT OjT Color"::Yellow;
        Rec.Insert();
        Rec.SetRange(Col, Enum::"LT OjT Color"::Red);
        Observer.Observe('red', Format(Rec.Count()));
        Observer.Observe('redFilter', Rec.GetFilter(Col));
        Rec.SetRange(Col, Enum::"LT OjT Color"::Green);
        Observer.Observe('green', Format(Rec.Count()));
        Rec.SetFilter(Col, '%1|%2', Enum::"LT OjT Color"::Green, Enum::"LT OjT Color"::Yellow);
        Observer.Observe('greenOrYellow', Format(Rec.Count()));
        Observer.Observe('greenOrYellowFilter', Rec.GetFilter(Col));
        Rec.SetFilter(Col, 'Yellow');
        Observer.Observe('byName', Format(Rec.Count()));
        Rec.SetFilter(Col, 'Navy');
        Observer.Observe('byCaption', Format(Rec.Count()));
        Rec.SetFilter(Col, '1');
        Observer.Observe('byOrdinal', Format(Rec.Count()));
        Rec.SetFilter(Col, '0..1');
        Observer.Observe('range01', Format(Rec.Count()));
        Rec.SetFilter(Col, '>=Green');
        Observer.Observe('geGreen', Format(Rec.Count()));
        Rec.Reset();
        Rec.SetCurrentKey(Col);
        Rec.FindLast();
        Observer.Observe('lastByCol', Format(Rec.Col, 0, 2));
        Rec.FindFirst();
        Observer.Observe('firstByCol', Format(Rec.Col, 0, 2));
        Observer.Expect('red', '3');
        Observer.Expect('redFilter', 'Red');
        Observer.Expect('green', '3');
        Observer.Expect('greenOrYellow', '4');
        Observer.Expect('greenOrYellowFilter', 'Green Caption|Sunny');
        Observer.Expect('byName', '1');
        Observer.Expect('byCaption', '0');
        Observer.Expect('byOrdinal', '3');
        Observer.Expect('range01', '6');
        Observer.Expect('geGreen', '4');
        Observer.Expect('lastByCol', '10');
        Observer.Expect('firstByCol', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Field_TestField()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT OjT Enum Rec";
    begin
        Rec.DeleteAll();
        Rec.Col := Enum::"LT OjT Color"::Green;
        Rec.TestField(Col, Enum::"LT OjT Color"::Green);
        Observer.Observe('ok', 'passed');
        asserterror Rec.TestField(Col, Enum::"LT OjT Color"::Red);
        Observer.ObserveError('wrong');
        Rec.TestField(Col);
        Observer.Observe('nonDefault', 'no error');
        Rec.Col := Enum::"LT OjT Color"::Red;
        asserterror Rec.TestField(Col);
        Observer.ObserveError('defaultValue');
        asserterror Rec.TestField(NoZ);
        Observer.ObserveError('noZero');
        Observer.Expect('ok', 'passed');
        Observer.Expect('wrong|text', 'Col must be equal to ''Red''  in LT OjT Enum Rec: No.=0. Current value is ''Green Caption''.');
        Observer.Expect('wrong|code', 'TestField');
        Observer.Expect('nonDefault', 'no error');
        Observer.Expect('defaultValue|text', 'Col must not be Red in LT OjT Enum Rec: No.=0');
        Observer.Expect('defaultValue|code', 'TestField');
        Observer.Expect('noZero|text', 'NoZ must not be 0 in LT OjT Enum Rec: No.=0');
        Observer.Expect('noZero|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure Field_FieldRefAndEvaluate()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT OjT Enum Rec";
        RecRef: RecordRef;
        FRef: FieldRef;
        Ok: Boolean;
    begin
        Rec.DeleteAll();
        Rec."No." := 1;
        Rec.Col := Enum::"LT OjT Color"::"Dark Blue";
        Rec.Insert();
        RecRef.GetTable(Rec);
        FRef := RecRef.Field(Rec.FieldNo(Col));
        Observer.Observe('format', Format(FRef.Value));
        Observer.Observe('type', Format(FRef.Type));
        Observer.Observe('class', Format(FRef.Class));
        Ok := Evaluate(Rec.Col, 'Yellow');
        Observer.Observe('evalField', Format(Ok) + '|' + Format(Rec.Col, 0, 2));
        FRef.Validate(Enum::"LT OjT Color"::Red);
        Observer.Observe('validateRef', Format(FRef.Value));
        Observer.Expect('format', 'Navy');
        Observer.Expect('type', 'Option');
        Observer.Expect('class', 'Normal');
        Observer.Expect('evalField', 'Yes|10');
        Observer.Expect('validateRef', 'Red');
        Observer.Verify();
    end;
}
