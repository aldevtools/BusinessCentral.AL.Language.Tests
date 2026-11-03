// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-get-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables 67156, 67157
// Probe: RecordRef.Get(RecordId) corners. A ref open on table A with a filter, with marks, and temporary, each given the RecordId of a row of A; a RecordId of a
// row of table B on a ref open on A (does the ref switch tables?); a RecordId of a row of B that was deleted; a blank RecordId whose result is not used; the
// Number and the current row after each. Object ids 67156 - 67158.

table 67156 "LT RG A"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 67157 "LT RG B"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Note; Text[20]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 67158 "LT RG Get RecordId"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        A: Record "LT RG A";
        B: Record "LT RG B";
        Index: Integer;
    begin
        A.DeleteAll();
        B.DeleteAll();
        for Index := 1 to 4 do begin
            A.Init();
            A.Id := Index;
            A.Name := 'A' + Format(Index);
            A.Insert();
        end;
        B.Init();
        B.Code := 'B1';
        B.Note := 'note b1';
        B.Insert();
        B.Init();
        B.Code := 'B2';
        B.Note := 'note b2';
        B.Insert();
    end;

    local procedure IdOfA(Id: Integer): RecordId
    var
        A: Record "LT RG A";
    begin
        A.Get(Id);
        exit(A.RecordId());
    end;

    local procedure IdOfB(Code: Code[10]): RecordId
    var
        B: Record "LT RG B";
    begin
        B.Get(Code);
        exit(B.RecordId());
    end;

    [TryFunction]
    local procedure TryGet(var RR: RecordRef; Id: RecordId; var Got: Boolean)
    begin
        Got := RR.Get(Id);
    end;

    [TryFunction]
    local procedure TryGetStatement(var RR: RecordRef; Id: RecordId)
    begin
        RR.Get(Id);
    end;

    local procedure State(var RR: RecordRef): Text
    var
        Row: Text;
    begin
        if RR.Number() = Database::"LT RG A" then
            Row := 'A:' + Format(RR.Field(1).Value)
        else
            Row := 'B:' + Format(RR.Field(1).Value);
        exit('number=' + Format(RR.Number()) + '|row=' + Row + '|name=' + RR.Name() + '|count=' + Format(RR.Count()) + '|filter=' + RR.GetFilters());
    end;

    local procedure Try(var RR: RecordRef; Id: RecordId): Text
    var
        Got: Boolean;
    begin
        ClearLastError();
        if TryGet(RR, Id, Got) then
            exit('ok:' + Format(Got) + '|' + State(RR));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Get_RowOutsideTheFilter()
    var
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RR.Open(Database::"LT RG A");
        RR.Field(1).SetRange(1, 2);
        Observer.Observe('row_inside_filter', Try(RR, IdOfA(2)));
        Observer.Observe('row_outside_filter', Try(RR, IdOfA(4)));
        Observer.Observe('after_filter', RR.GetFilters());
        Observer.Observe('after_count', Format(RR.Count()));
        Observer.Expect('row_inside_filter', 'ok:Yes|number=67156|row=A:2|name=LT RG A|count=2|filter=Id: 1..2');
        Observer.Expect('row_outside_filter', 'ok:Yes|number=67156|row=A:4|name=LT RG A|count=2|filter=Id: 1..2');
        Observer.Expect('after_filter', 'Id: 1..2');
        Observer.Expect('after_count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Get_WithMarks()
    var
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RR.Open(Database::"LT RG A");
        RR.Get(IdOfA(1));
        RR.Mark(true);
        RR.MarkedOnly(true);
        Observer.Observe('marked_row', Try(RR, IdOfA(1)));
        Observer.Observe('unmarked_row', Try(RR, IdOfA(3)));
        Observer.Observe('marked_only_after', Format(RR.MarkedOnly()));
        Observer.Observe('count_marked_only', Format(RR.Count()));
        Observer.Expect('marked_row', 'ok:Yes|number=67156|row=A:1|name=LT RG A|count=1|filter=Marked: Yes');
        Observer.Expect('unmarked_row', 'ok:Yes|number=67156|row=A:3|name=LT RG A|count=1|filter=Marked: Yes');
        Observer.Expect('marked_only_after', 'Yes');
        Observer.Expect('count_marked_only', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Get_OnTemporaryRef()
    var
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RR.Open(Database::"LT RG A", true);
        Observer.Observe('is_temporary', Format(RR.IsTemporary()));
        Observer.Observe('row_of_the_real_table', Try(RR, IdOfA(2)));
        RR.Field(1).Value := 2;
        RR.Field(2).Value := 'T2';
        RR.Insert();
        Observer.Observe('row_after_temp_insert', Try(RR, IdOfA(2)));
        Observer.Observe('name_after', Format(RR.Field(2).Value));
        Observer.Expect('is_temporary', 'Yes');
        Observer.Expect('row_of_the_real_table', 'ok:No|number=67156|row=A:0|name=LT RG A|count=0|filter=');
        Observer.Expect('row_after_temp_insert', 'ok:Yes|number=67156|row=A:2|name=LT RG A|count=1|filter=');
        Observer.Expect('name_after', 'T2');
        Observer.Verify();
    end;

    [Test]
    procedure Get_RecordIdOfAnotherTable()
    var
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RR.Open(Database::"LT RG A");
        RR.Field(1).SetRange(1, 3);
        Observer.Observe('other_table_row', Try(RR, IdOfB('B1')));
        Observer.Observe('number_after', Format(RR.Number()));
        Observer.Observe('is_a_after', Format(RR.Number() = Database::"LT RG A"));
        Observer.Expect('other_table_row', 'ok:Yes|number=67157|row=B:B1|name=LT RG B|count=2|filter=');
        Observer.Expect('number_after', '67157');
        Observer.Expect('is_a_after', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Get_MissingRowOfAnotherTable()
    var
        RR: RecordRef;
        B: Record "LT RG B";
        Missing: RecordId;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Missing := IdOfB('B2');
        B.Get('B2');
        B.Delete();
        RR.Open(Database::"LT RG A");
        Observer.Observe('missing_other_table_row', Try(RR, Missing));
        Observer.Observe('number_after', Format(RR.Number()));
        Observer.Expect('missing_other_table_row', 'ok:No|number=67156|row=A:0|name=LT RG A|count=4|filter=');
        Observer.Expect('number_after', '67156');
        Observer.Verify();
    end;

    [Test]
    procedure Get_BlankRecordId_ResultUnused()
    var
        RR: RecordRef;
        Blank: RecordId;
        Observer: Codeunit "Probe Observer";
        Got: Boolean;
    begin
        Seed();
        RR.Open(Database::"LT RG A");
        Observer.Observe('blank_try', Try(RR, Blank));
        ClearLastError();
        Observer.Observe('blank_record_id_text', Format(Blank));
        Observer.Observe('blank_is_blank', Format(Format(Blank) = ''));
        Got := RR.Get(IdOfA(1));
        Observer.Observe('then_valid', Format(Got));
        Observer.Expect('blank_try', 'ok:No|number=67156|row=A:0|name=LT RG A|count=4|filter=');
        Observer.Expect('blank_record_id_text', '');
        Observer.Expect('blank_is_blank', 'Yes');
        Observer.Expect('then_valid', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Get_BlankRecordId_AsStatement()
    var
        RR: RecordRef;
        Blank: RecordId;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RR.Open(Database::"LT RG A");
        ClearLastError();
        Observer.Observe('statement_outcome', Format(TryGetStatement(RR, Blank)));
        Observer.ObserveError('statement');
        Observer.Observe('statement_missing_row_outcome', Format(TryGetStatement(RR, IdOfB('B1'))));
        Observer.ObserveError('statement_other_table');
        Observer.Expect('statement_outcome', 'No');
        Observer.Expect('statement|text', 'You tried to invoke the Table object with the ID 0 from the object LT RG Get RecordId. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('statement|code', 'AL:MetadataNotFound');
        Observer.Expect('statement_missing_row_outcome', 'Yes');
        Observer.Expect('statement_other_table|text', '');
        Observer.Expect('statement_other_table|code', '');
        Observer.Verify();
    end;
}
