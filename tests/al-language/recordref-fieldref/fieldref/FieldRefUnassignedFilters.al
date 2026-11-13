// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-setrange-method
// Scope: in-scope. The filter members of a FieldRef that holds no field (al-runner issue 7964, item 2), in the forms PnD05_UnassignedFieldRef.al
//   does not cover: SetRange with no, one (Text, Integer) and two Text values, SetFilter without substitution and with an empty text,
//   GetFilter, GetRangeMin and GetRangeMax. The same members on a FieldRef that was assigned and then cleared (Clear), and on a FieldRef
//   whose RecordRef was closed after the assignment.
// Fixtures used: Probe Observer (69160); self-contained table 71897 and codeunit 71898.
// Probe: written for al-runner issue 7964, observed on BC 27.5, 28.5 and 29.0. Every literal asserted below is what BC produced.
// Facts: <case> is 'no error' (and the read value after it, where the member returns one) when the [TryFunction] around the call
//   returned true, or <case>|text and <case>|code (GetLastErrorText and GetLastErrorCode) when it returned false.
// BC versions: 27, 28, 29

table 71897 "LT FrU Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 71898 "LT FrU Unassigned Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    // State 0: never assigned; 1: assigned, then Clear; 2: assigned, then the RecordRef closed.
    [TryFunction]
    local procedure TryMember(State: Integer; Member: Integer; var Result: Text)
    var
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        if State > 0 then begin
            RecRef.Open(Database::"LT FrU Row");
            Fld := RecRef.Field(2);
            if State = 1 then
                Clear(Fld)
            else
                RecRef.Close();
        end;
        case Member of
            1:
                Fld.SetRange();
            2:
                Fld.SetRange('A');
            3:
                Fld.SetRange(1);
            4:
                Fld.SetRange('A', 'B');
            5:
                Fld.SetFilter('A');
            6:
                Fld.SetFilter('');
            7:
                Result := Fld.GetFilter();
            8:
                Result := Format(Fld.GetRangeMin());
            9:
                Result := Format(Fld.GetRangeMax());
        end;
    end;

    local procedure Run(CaseName: Text; State: Integer; Member: Integer)
    var
        R: Text;
    begin
        ClearLastError();
        if TryMember(State, Member, R) then
            Observer.Observe(CaseName, 'no error, value=[' + R + ']')
        else
            Observer.ObserveError(CaseName);
    end;

    [Test]
    procedure Unassigned_SetRange_Forms()
    begin
        Run('setrange_none', 0, 1);
        Run('setrange_text', 0, 2);
        Run('setrange_int', 0, 3);
        Run('setrange_two', 0, 4);
        Observer.Finish();
    end;

    [Test]
    procedure Unassigned_SetFilter_GetFilter_Range()
    begin
        Run('setfilter_plain', 0, 5);
        Run('setfilter_empty', 0, 6);
        Run('getfilter', 0, 7);
        Run('getrangemin', 0, 8);
        Run('getrangemax', 0, 9);
        Observer.Finish();
    end;

    [Test]
    procedure Cleared_Filter_Members()
    begin
        Run('setrange_none', 1, 1);
        Run('setrange_text', 1, 2);
        Run('setfilter_plain', 1, 5);
        Run('getfilter', 1, 7);
        Run('getrangemin', 1, 8);
        Observer.Finish();
    end;

    [Test]
    procedure ClosedRecordRef_Filter_Members()
    begin
        Run('setrange_none', 2, 1);
        Run('setrange_text', 2, 2);
        Run('setfilter_plain', 2, 5);
        Run('getfilter', 2, 7);
        Run('getrangemin', 2, 8);
        Observer.Finish();
    end;
}
