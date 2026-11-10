// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setcurrentkey-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own enum 66360, tables 66361 and 66362, test codeunit 66363
// local object: the CalcFormula definitions and the declared keys are what the tests measure.
// Probe (al-runner issue 7427: SetCurrentKey("My Flag", "My Type", "My Date") whose first field is a Boolean Lookup FlowField; the code
//   then filters the Enum and the Date field and reads the rows): observation form, the values are read from the corpus CI matrix.
//   A FlowField in a declared key does not compile (AL0256, tests/must-not-compile/cases/3100-flowfield-in-table-key.al), so every key
//   here is only named in SetCurrentKey; the table declares the key (My Type, My Date) of the stored fields.
// Area: the row order of a key whose first field is a Lookup FlowField. Lookup FlowFields of type Boolean, Integer, Text and Date over a
//   setup table; one setup row is missing, so one row's lookup finds nothing. Keys named in SetCurrentKey: (Flag, My Type, My Date),
//   (Rank, Id), (SetupName, My Type, My Date), (SetupDay, My Type, My Date) and their prefixes. Per key: what SetCurrentKey answers, CurrentKey, the order of
//   FindSet without filters, with a range on the Enum field and a date range (the reported shape), with Ascending(false), FindFirst and
//   FindLast, Next(-1) from the last row, the same on a temporary copy, and whether the loop record holds the FlowField value without
//   CalcFields. The seed makes three orders differ: by the looked-up value, by the stored key fields alone, and by the primary key.
// Existing pins: record/flowfields/FfmOperations.al FlowFieldSort_* pins SetCurrentKey(FlowField) and SetCurrentKey(FlowField, Rank) for
//   Text and Decimal lookups that are not in a declared key; keys-sorting/PwFlowFieldKeyRule.al and SetCurrentKeyFlowFieldOrder.al pin
//   count, sum and exist FlowFields.
// BC versions: 27, 28, 29 by CI

enum 66360 "REC LkKey Type"
{
    Extensible = false;
    value(0; A) { }
    value(1; B) { }
}

table 66361 "REC LkKey Setup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Flag; Boolean) { }
        field(3; Rank; Integer) { }
        field(4; Name; Text[20]) { }
        field(5; Day; Date) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 66362 "REC LkKey Part"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Type Code"; Code[10]) { }
        field(3; "My Type"; Enum "REC LkKey Type") { }
        field(4; "My Date"; Date) { }
        field(10; Flag; Boolean) { FieldClass = FlowField; CalcFormula = lookup("REC LkKey Setup".Flag where("Code" = field("Type Code"))); }
        field(11; Rank; Integer) { FieldClass = FlowField; CalcFormula = lookup("REC LkKey Setup".Rank where("Code" = field("Type Code"))); }
        field(12; SetupName; Text[20]) { FieldClass = FlowField; CalcFormula = lookup("REC LkKey Setup".Name where("Code" = field("Type Code"))); }
        field(13; SetupDay; Date) { FieldClass = FlowField; CalcFormula = lookup("REC LkKey Setup".Day where("Code" = field("Type Code"))); }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByTypeDate; "My Type", "My Date") { }
    }
}

codeunit 66363 "REC LkKey Tests"
{
    Subtype = Test;

    local procedure Initialize()
    var
        S: Record "REC LkKey Setup";
        P: Record "REC LkKey Part";
    begin
        S.DeleteAll();
        P.DeleteAll();
        AddSetup('S1', true, 3, 'gamma', 20260303D);
        AddSetup('S2', false, 1, 'Alpha', 20260101D);
        AddSetup('S3', true, 2, 'beta', 20260202D);
        AddPart(P, 1, 'S1', P."My Type"::A, 20260120D);
        AddPart(P, 2, 'S2', P."My Type"::A, 20260110D);
        AddPart(P, 3, 'S3', P."My Type"::B, 20260105D);
        AddPart(P, 4, 'S2', P."My Type"::A, 20260130D);
        AddPart(P, 5, 'S1', P."My Type"::A, 20260105D);
        AddPart(P, 6, 'S4', P."My Type"::A, 20260115D);
        AddPart(P, 7, 'S3', P."My Type"::A, 20260125D);
        AddPart(P, 8, 'S2', P."My Type"::B, 20260101D);
    end;

    local procedure AddSetup(SetupCode: Code[10]; Flag: Boolean; Rank: Integer; Name: Text[20]; Day: Date)
    var
        S: Record "REC LkKey Setup";
    begin
        S."Code" := SetupCode;
        S.Flag := Flag;
        S.Rank := Rank;
        S.Name := Name;
        S.Day := Day;
        S.Insert();
    end;

    local procedure AddPart(var P: Record "REC LkKey Part"; Id: Integer; TypeCode: Code[10]; MyType: Enum "REC LkKey Type"; MyDate: Date)
    begin
        P.Init();
        P.Id := Id;
        P."Type Code" := TypeCode;
        P."My Type" := MyType;
        P."My Date" := MyDate;
        P.Insert();
    end;

    [TryFunction]
    local procedure TryOrder(var P: Record "REC LkKey Part"; var Result: Text)
    begin
        Result := '';
        if P.FindSet() then
            repeat
                Result += Format(P.Id) + ' ';
            until P.Next() = 0;
    end;

    local procedure Order(var P: Record "REC LkKey Part"): Text
    var
        Result: Text;
    begin
        if TryOrder(P, Result) then
            exit(Result);
        Result := 'E after [' + Result + ']: ' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']';
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure TrySelect(var P: Record "REC LkKey Part"; KeyName: Text; var Answer: Boolean)
    begin
        case KeyName of
            'flag':
                Answer := P.SetCurrentKey(Flag, "My Type", "My Date");
            'flag only':
                Answer := P.SetCurrentKey(Flag);
            'flag, date':
                Answer := P.SetCurrentKey(Flag, "My Date");
            'rank':
                Answer := P.SetCurrentKey(Rank, Id);
            'rank only':
                Answer := P.SetCurrentKey(Rank);
            'name':
                Answer := P.SetCurrentKey(SetupName, "My Type", "My Date");
            'day':
                Answer := P.SetCurrentKey(SetupDay, "My Type", "My Date");
            'type, date':
                Answer := P.SetCurrentKey("My Type", "My Date");
            else
                Error('unknown key %1', KeyName);
        end;
    end;

    local procedure Select(var Observer: Codeunit "Probe Observer"; var P: Record "REC LkKey Part"; KeyName: Text): Boolean
    var
        Answer: Boolean;
    begin
        if not TrySelect(P, KeyName, Answer) then begin
            Observer.ObserveError(KeyName + ' SetCurrentKey');
            exit(false);
        end;
        Observer.Observe(KeyName + ' SetCurrentKey', Format(Answer, 0, 9));
        Observer.Observe(KeyName + ' CurrentKey', P.CurrentKey());
        exit(true);
    end;

    local procedure KeyCells(var Observer: Codeunit "Probe Observer"; KeyName: Text)
    var
        P: Record "REC LkKey Part";
    begin
        if not Select(Observer, P, KeyName) then
            exit;
        Observer.Observe(KeyName + ' all rows', Order(P));
        P.SetRange("My Type", P."My Type"::A);
        P.SetFilter("My Date", '%1..%2', 20260106D, 20260126D);
        Observer.Observe(KeyName + ' type A and date range', Order(P));
        P.SetRange("My Date");
        Observer.Observe(KeyName + ' type A', Order(P));
        P.Ascending(false);
        Observer.Observe(KeyName + ' type A descending', Order(P));
        P.Ascending(true);
        if P.FindFirst() then
            Observer.Observe(KeyName + ' FindFirst', Format(P.Id))
        else
            Observer.Observe(KeyName + ' FindFirst', 'none');
        if P.FindLast() then begin
            Observer.Observe(KeyName + ' FindLast', Format(P.Id));
            if P.Next(-1) <> 0 then
                Observer.Observe(KeyName + ' Next(-1) from the last', Format(P.Id))
            else
                Observer.Observe(KeyName + ' Next(-1) from the last', 'none');
        end else
            Observer.Observe(KeyName + ' FindLast', 'none');
    end;

    [Test]
    procedure SetCurrentKey_BooleanLookupFirst_RowOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        KeyCells(Observer, 'flag');
        Observer.Expect('flag SetCurrentKey', 'true');
        Observer.Expect('flag CurrentKey', 'Flag,My Type,My Date');
        Observer.Expect('flag all rows', '2 6 4 8 5 1 7 3 ');
        Observer.Expect('flag type A and date range', '2 6 1 7 ');
        Observer.Expect('flag type A', '2 6 4 5 1 7 ');
        Observer.Expect('flag type A descending', '7 1 5 4 6 2 ');
        Observer.Expect('flag FindFirst', '2');
        Observer.Expect('flag FindLast', '7');
        Observer.Expect('flag Next(-1) from the last', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_IntegerLookupFirst_RowOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        KeyCells(Observer, 'rank');
        Observer.Expect('rank SetCurrentKey', 'true');
        Observer.Expect('rank CurrentKey', 'Rank,Id');
        Observer.Expect('rank all rows', '6 2 4 8 3 7 1 5 ');
        Observer.Expect('rank type A and date range', '6 2 7 1 ');
        Observer.Expect('rank type A', '6 2 4 7 1 5 ');
        Observer.Expect('rank type A descending', '5 1 7 4 2 6 ');
        Observer.Expect('rank FindFirst', '6');
        Observer.Expect('rank FindLast', '5');
        Observer.Expect('rank Next(-1) from the last', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_TextLookupFirst_RowOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        KeyCells(Observer, 'name');
        Observer.Expect('name SetCurrentKey', 'true');
        Observer.Expect('name CurrentKey', 'SetupName,My Type,My Date');
        Observer.Expect('name all rows', '6 2 4 8 7 3 5 1 ');
        Observer.Expect('name type A and date range', '6 2 7 1 ');
        Observer.Expect('name type A', '6 2 4 7 5 1 ');
        Observer.Expect('name type A descending', '1 5 7 4 2 6 ');
        Observer.Expect('name FindFirst', '6');
        Observer.Expect('name FindLast', '1');
        Observer.Expect('name Next(-1) from the last', '5');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_DateLookupFirst_RowOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        KeyCells(Observer, 'day');
        Observer.Expect('day SetCurrentKey', 'true');
        Observer.Expect('day CurrentKey', 'SetupDay,My Type,My Date');
        Observer.Expect('day all rows', '6 2 4 8 7 3 5 1 ');
        Observer.Expect('day type A and date range', '6 2 7 1 ');
        Observer.Expect('day type A', '6 2 4 7 5 1 ');
        Observer.Expect('day type A descending', '1 5 7 4 2 6 ');
        Observer.Expect('day FindFirst', '6');
        Observer.Expect('day FindLast', '1');
        Observer.Expect('day Next(-1) from the last', '5');
        Observer.Verify();
    end;

    [Test]
    procedure KeyPrefixes_BooleanAndIntegerLookup_RowOrder()
    var
        Observer: Codeunit "Probe Observer";
        P: Record "REC LkKey Part";
    begin
        Initialize();
        if Select(Observer, P, 'flag only') then
            Observer.Observe('flag only all rows', Order(P));
        P.Reset();
        if Select(Observer, P, 'flag, date') then
            Observer.Observe('flag, date all rows', Order(P));
        P.Reset();
        if Select(Observer, P, 'rank only') then
            Observer.Observe('rank only all rows', Order(P));
        P.Reset();
        if Select(Observer, P, 'type, date') then
            Observer.Observe('type, date all rows', Order(P));
        P.Reset();
        Observer.Observe('primary key all rows', Order(P));
        Observer.Expect('flag only SetCurrentKey', 'true');
        Observer.Expect('flag only CurrentKey', 'Flag');
        Observer.Expect('flag only all rows', '2 4 6 8 1 3 5 7 ');
        Observer.Expect('flag, date SetCurrentKey', 'true');
        Observer.Expect('flag, date CurrentKey', 'Flag,My Date');
        Observer.Expect('flag, date all rows', '8 2 6 4 3 5 1 7 ');
        Observer.Expect('rank only SetCurrentKey', 'true');
        Observer.Expect('rank only CurrentKey', 'Rank');
        Observer.Expect('rank only all rows', '6 2 4 8 3 7 1 5 ');
        Observer.Expect('type, date SetCurrentKey', 'true');
        Observer.Expect('type, date CurrentKey', 'My Type,My Date');
        Observer.Expect('type, date all rows', '5 2 6 1 7 4 8 3 ');
        Observer.Expect('primary key all rows', '1 2 3 4 5 6 7 8 ');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_BooleanLookupFirst_LoopRecordValues()
    var
        Observer: Codeunit "Probe Observer";
        P: Record "REC LkKey Part";
        Line: Text;
    begin
        Initialize();
        P.SetCurrentKey(Flag, "My Type", "My Date");
        P.SetRange("My Type", P."My Type"::A);
        if P.FindSet() then
            repeat
                Line += Format(P.Id) + ':' + Format(P.Flag, 0, 9) + '/' + Format(P.Rank) + ' ';
            until P.Next() = 0;
        Observer.Observe('values without CalcFields', Line);
        Line := '';
        P.SetAutoCalcFields(Flag, Rank);
        if P.FindSet() then
            repeat
                Line += Format(P.Id) + ':' + Format(P.Flag, 0, 9) + '/' + Format(P.Rank) + ' ';
            until P.Next() = 0;
        Observer.Observe('values with SetAutoCalcFields', Line);
        Observer.Expect('values without CalcFields', '2:false/0 6:false/0 4:false/0 5:true/0 1:true/0 7:true/0 ');
        Observer.Expect('values with SetAutoCalcFields', '2:false/1 6:false/0 4:false/1 5:true/3 1:true/3 7:true/2 ');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_BooleanLookupFirst_FilterOnTheFlowField()
    var
        Observer: Codeunit "Probe Observer";
        P: Record "REC LkKey Part";
    begin
        Initialize();
        P.SetCurrentKey(Flag, "My Type", "My Date");
        P.SetRange(Flag, true);
        Observer.Observe('flag true', Order(P));
        P.SetRange(Flag, false);
        Observer.Observe('flag false', Order(P));
        P.SetRange("My Type", P."My Type"::A);
        Observer.Observe('flag false, type A', Order(P));
        Observer.Expect('flag true', '5 1 7 3 ');
        Observer.Expect('flag false', '2 6 4 8 ');
        Observer.Expect('flag false, type A', '2 6 4 ');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_BooleanLookupFirst_TemporaryCopy()
    var
        Observer: Codeunit "Probe Observer";
        P: Record "REC LkKey Part";
        Temp: Record "REC LkKey Part" temporary;
        Answer: Boolean;
        Result: Text;
    begin
        Initialize();
        if P.FindSet() then
            repeat
                Temp := P;
                Temp.Insert();
            until P.Next() = 0;
        if not TrySelect(Temp, 'flag', Answer) then
            Observer.ObserveError('SetCurrentKey')
        else begin
            Observer.Observe('SetCurrentKey', Format(Answer, 0, 9));
            Observer.Observe('CurrentKey', Temp.CurrentKey());
            if TryOrder(Temp, Result) then
                Observer.Observe('all rows', Result)
            else
                Observer.ObserveError('all rows');
            Temp.SetRange("My Type", Temp."My Type"::A);
            Temp.SetFilter("My Date", '%1..%2', 20260106D, 20260126D);
            if TryOrder(Temp, Result) then
                Observer.Observe('type A and date range', Result)
            else
                Observer.ObserveError('type A and date range');
        end;
        Observer.Expect('SetCurrentKey', 'false');
        Observer.Expect('CurrentKey', 'Id');
        Observer.Expect('all rows', '1 2 3 4 5 6 7 8 ');
        Observer.Expect('type A and date range', '1 2 6 7 ');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_BooleanLookupFirst_AfterSetupChange()
    var
        Observer: Codeunit "Probe Observer";
        P: Record "REC LkKey Part";
        S: Record "REC LkKey Setup";
    begin
        Initialize();
        P.SetCurrentKey(Flag, "My Type", "My Date");
        Observer.Observe('before', Order(P));
        S.Get('S2');
        S.Flag := true;
        S.Modify();
        S.Get('S1');
        S.Flag := false;
        S.Modify();
        Observer.Observe('after S1 and S2 swapped flags', Order(P));
        Observer.Expect('before', '2 6 4 8 5 1 7 3 ');
        Observer.Expect('after S1 and S2 swapped flags', '5 6 1 2 7 4 8 3 ');
        Observer.Verify();
    end;
}
