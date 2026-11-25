// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-entering-criteria-in-filters
// Scope: in-scope. SetFilter and FieldRef.SetFilter with a lone '..' (and '..|x', ' .. ') on Code, Integer, BigInteger, Decimal, Date, Time, DateTime, Option, Boolean and Guid fields (the Text field is pinned in record/crud/RcAFilters.al).
// Fixtures used: Probe Observer (codeunit 69160); own objects 77811-77812 (FC Dots Row, Filter Dots Only Types)
// Probe: from al-runner issue 8213, part 1 (SetFilter '..'). Observed on
//   Windows BC containers 27.5, 28.5 and 29.0; every literal asserted below is what BC produced. The corpus CI matrix checks it on BC on Linux.
// Facts: SetFilter with '..' alone (and in or / and combinations, with spaces) on a Code, Integer, BigInteger, Decimal, Date, Time, DateTime, Option, Boolean and Guid field raises the error 'Both sides of the range cannot be empty' with the code Filter:CSide; 'A..' and '..A' on a Code field are accepted.
// BC versions: 27, 28, 29

table 77811 "FC Dots Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Num; Integer) { }
        field(3; Big; BigInteger) { }
        field(4; Amt; Decimal) { }
        field(5; D; Date) { }
        field(6; T; Time) { }
        field(7; DT; DateTime) { }
        field(8; Opt; Option) { OptionMembers = A,B; }
        field(9; Flag; Boolean) { }
        field(10; G; Guid) { }
        field(11; Body; Blob) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 77812 "Filter Dots Only Types"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetFilter(var RecRef: RecordRef; FieldNo: Integer; Filter: Text)
    begin
        RecRef.Field(FieldNo).SetFilter(Filter);
    end;

    [TryFunction]
    local procedure TryRecordSetFilter(var Row: Record "FC Dots Row"; FieldNo: Integer; Filter: Text)
    begin
        case FieldNo of
            1:
                Row.SetFilter("Code", Filter);
            2:
                Row.SetFilter(Num, Filter);
            3:
                Row.SetFilter(Big, Filter);
            4:
                Row.SetFilter(Amt, Filter);
            5:
                Row.SetFilter(D, Filter);
            6:
                Row.SetFilter(T, Filter);
            7:
                Row.SetFilter(DT, Filter);
            8:
                Row.SetFilter(Opt, Filter);
            9:
                Row.SetFilter(Flag, Filter);
            10:
                Row.SetFilter(G, Filter);
        end;
    end;

    local procedure Seed()
    var
        Row: Record "FC Dots Row";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Num := 1;
        Row.Insert();
        Row."Code" := 'B';
        Row.Num := 2;
        Row.Opt := Row.Opt::B;
        Row.Insert();
    end;

    local procedure ByRecord(FieldNo: Integer; Filter: Text): Text
    var
        Row: Record "FC Dots Row";
    begin
        if not TryRecordSetFilter(Row, FieldNo, Filter) then
            exit('error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode());
        exit('ok ' + Format(Row.Count()) + ' |' + Row.GetFilters());
    end;

    local procedure ByFieldRef(FieldNo: Integer; Filter: Text): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"FC Dots Row");
        if not TrySetFilter(RecRef, FieldNo, Filter) then
            exit('error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode());
        exit('ok ' + Format(RecRef.Count()) + ' |' + RecRef.GetFilters());
    end;

    [Test]
    procedure SetFilter_DotsOnly_PerType()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('code', ByRecord(1, '..'));
        Observer.Observe('integer', ByRecord(2, '..'));
        Observer.Observe('bigInteger', ByRecord(3, '..'));
        Observer.Observe('decimal', ByRecord(4, '..'));
        Observer.Observe('date', ByRecord(5, '..'));
        Observer.Observe('time', ByRecord(6, '..'));
        Observer.Observe('dateTime', ByRecord(7, '..'));
        Observer.Observe('option', ByRecord(8, '..'));
        Observer.Observe('boolean', ByRecord(9, '..'));
        Observer.Observe('guid', ByRecord(10, '..'));
        Observer.Expect('code', 'error: The filter ".." is not valid for the Code field on the FC Dots Row table. Both sides of the range (''..'') cannot be empty. | Filter:CSide');
        Observer.Expect('integer', 'error: The filter ".." is not valid for the Num field on the FC Dots Row table. Both sides of the range (''..'') cannot be empty. | Filter:CSide');
        Observer.Expect('bigInteger', 'error: The filter ".." is not valid for the Big field on the FC Dots Row table. Both sides of the range (''..'') cannot be empty. | Filter:CSide');
        Observer.Expect('decimal', 'error: The filter ".." is not valid for the Amt field on the FC Dots Row table. Both sides of the range (''..'') cannot be empty. | Filter:CSide');
        Observer.Expect('date', 'error: The filter ".." is not valid for the D field on the FC Dots Row table. Both sides of the range (''..'') cannot be empty. | Filter:CSide');
        Observer.Expect('time', 'error: The filter ".." is not valid for the T field on the FC Dots Row table. Both sides of the range (''..'') cannot be empty. | Filter:CSide');
        Observer.Expect('dateTime', 'error: The filter ".." is not valid for the DT field on the FC Dots Row table. Both sides of the range (''..'') cannot be empty. | Filter:CSide');
        Observer.Expect('option', 'error: The filter ".." is not valid for the Opt field on the FC Dots Row table. Both sides of the range (''..'') cannot be empty. | Filter:CSide');
        Observer.Expect('boolean', 'error: The filter ".." is not valid for the Flag field on the FC Dots Row table. Both sides of the range (''..'') cannot be empty. | Filter:CSide');
        Observer.Expect('guid', 'error: The filter ".." is not valid for the G field on the FC Dots Row table. Both sides of the range (''..'') cannot be empty. | Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_DotsOnly_Variants()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('codeDotsOrB', ByRecord(1, '..|B'));
        Observer.Observe('codeSpacedDots', ByRecord(1, ' .. '));
        Observer.Observe('codeDotsAndB', ByRecord(1, '..&B'));
        Observer.Observe('integerDotsOr2', ByRecord(2, '..|2'));
        Observer.Observe('codeAOpen', ByRecord(1, 'A..'));
        Observer.Observe('codeOpenB', ByRecord(1, '..A'));
        Observer.Expect('codeDotsOrB', 'error: The filter "..|B" is not valid for the Code field on the FC Dots Row table. Both sides of the range (''..'') cannot be empty. | Filter:CSide');
        Observer.Expect('codeSpacedDots', 'error: The filter " .. " is not valid for the Code field on the FC Dots Row table. Both sides of the range (''..'') cannot be empty. | Filter:CSide');
        Observer.Expect('codeDotsAndB', 'error: The filter "..&B" is not valid for the Code field on the FC Dots Row table. Both sides of the range (''..'') cannot be empty. | Filter:CSide');
        Observer.Expect('integerDotsOr2', 'error: The filter "..|2" is not valid for the Num field on the FC Dots Row table. Both sides of the range (''..'') cannot be empty. | Filter:CSide');
        Observer.Expect('codeAOpen', 'ok 2 |Code: A..');
        Observer.Expect('codeOpenB', 'ok 1 |Code: ..A');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRefSetFilter_DotsOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('code', ByFieldRef(1, '..'));
        Observer.Observe('integer', ByFieldRef(2, '..'));
        Observer.Observe('date', ByFieldRef(5, '..'));
        Observer.Expect('code', 'error: The filter ".." is not valid for the Code field on the FC Dots Row table. Both sides of the range (''..'') cannot be empty. | Filter:CSide');
        Observer.Expect('integer', 'error: The filter ".." is not valid for the Num field on the FC Dots Row table. Both sides of the range (''..'') cannot be empty. | Filter:CSide');
        Observer.Expect('date', 'error: The filter ".." is not valid for the D field on the FC Dots Row table. Both sides of the range (''..'') cannot be empty. | Filter:CSide');
        Observer.Verify();
    end;
}
