// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/queryinstance-read-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 75081 and 75086, queries 75082-75084, test codeunit 75085
// local object: the grouping columns, the filters and the fields outside the query are the subject of the probe; no shared fixture has this shape
// Probe (observe only): al-runner issue 7434. QueryLiveWrite.al pins an aggregated query ordered by its one group column when rows are inserted,
//   modified and deleted between two Read calls. This probe asks the same for the reported shape: a Count column grouped by four fields, no OrderBy,
//   three filters set with SetRange, and inside the Read loop a Modify of
//     a field that is neither a column nor a filter of the query (every row read, and only one row),
//     a filter field of a row not read yet and of the row just read (the row leaves the filter),
//     a group column that is not a filter (Line Group) of a row not read yet,
//   an Insert of a row that meets the filters before and after the position, a Delete of a row not read yet, and a write to another table.
//   The same with OrderBy descending, and with a Sum column grouped by one field with no filter.
//   Rows: header H1 has lines 10, 20, 30, 40, 50 of contact C1 and kind 1; line 60 is contact C2; header H2 has line 10 of contact C1.
//   Each observation lists the rows in the order Read returned them, as LineNo:Qty (or Kind=Sum).
// BC versions: 27, 28, 29

table 75081 "LT QAW Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Header No."; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; "Contact No."; Code[10]) { }
        field(4; Kind; Integer) { }
        field(5; Status; Integer) { }
        field(6; "Error Description"; Text[50]) { }
        field(7; Amount; Decimal) { }
        field(8; "Line Group"; Code[10]) { }
    }

    keys
    {
        key(PK; "Header No.", "Line No.") { Clustered = true; }
    }
}

query 75082 "LT QAW Overlap"
{
    QueryType = Normal;

    elements
    {
        dataitem(L; "LT QAW Line")
        {
            column(Qty) { Method = Count; }
            column(ContactNo; "Contact No.") { }
            column(HeaderNo; "Header No.") { }
            column(Kind; Kind) { }
            column(LineNo; "Line No.") { }
            column(LineGroup; "Line Group") { }
        }
    }
}

query 75083 "LT QAW Overlap Descending"
{
    QueryType = Normal;
    OrderBy = descending(LineNo);

    elements
    {
        dataitem(L; "LT QAW Line")
        {
            column(Qty) { Method = Count; }
            column(ContactNo; "Contact No.") { }
            column(HeaderNo; "Header No.") { }
            column(Kind; Kind) { }
            column(LineNo; "Line No.") { }
        }
    }
}

query 75084 "LT QAW Sum By Kind"
{
    QueryType = Normal;

    elements
    {
        dataitem(L; "LT QAW Line")
        {
            column(Kind; Kind) { }
            column(Total; Amount) { Method = Sum; }
            column(Qty) { Method = Count; }
        }
    }
}

table 75086 "LT QAW Other"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 75085 "LT QAW Aggregated Write Loop"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Add(HeaderNo: Code[10]; LineNo: Integer; ContactNo: Code[10]; Kind: Integer; Amount: Decimal)
    var
        Line: Record "LT QAW Line";
    begin
        Line.Init();
        Line."Header No." := HeaderNo;
        Line."Line No." := LineNo;
        Line."Contact No." := ContactNo;
        Line.Kind := Kind;
        Line.Amount := Amount;
        Line."Line Group" := 'G';
        Line.Insert();
    end;

    local procedure Seed()
    var
        Line: Record "LT QAW Line";
        Other: Record "LT QAW Other";
    begin
        Line.DeleteAll();
        Other.DeleteAll();
        Add('H1', 10, 'C1', 1, 1);
        Add('H1', 20, 'C1', 1, 2);
        Add('H1', 30, 'C1', 1, 4);
        Add('H1', 40, 'C1', 1, 8);
        Add('H1', 50, 'C1', 1, 16);
        Add('H1', 60, 'C2', 1, 32);
        Add('H2', 10, 'C1', 1, 64);
    end;

    local procedure OpenFiltered(var Q: Query "LT QAW Overlap")
    begin
        Q.SetRange(Kind, 1);
        Q.SetRange(ContactNo, 'C1');
        Q.SetRange(HeaderNo, 'H1');
        Q.Open();
    end;

    // Action: what the loop does after the Read that returned line AtLine (0 = after every row).
    local procedure RunLoop(Action: Text; AtLine: Integer): Text
    var
        Q: Query "LT QAW Overlap";
        Result: Text;
        Guard: Integer;
    begin
        Seed();
        OpenFiltered(Q);
        while Q.Read() and (Guard < 30) do begin
            Guard += 1;
            Result += Format(Q.LineNo) + ':' + Format(Q.Qty) + ' ';
            if (AtLine = 0) or (Q.LineNo = AtLine) then
                DoAction(Action, Q.HeaderNo, Q.LineNo);
        end;
        Q.Close();
        exit(Result);
    end;

    local procedure DoAction(Action: Text; HeaderNo: Code[10]; LineNo: Integer)
    var
        Line: Record "LT QAW Line";
        Other: Record "LT QAW Other";
    begin
        case Action of
            'none':
                ;
            'modify status of the row read':
                begin
                    Line.Get(HeaderNo, LineNo);
                    Line.Status := 2;
                    Line."Error Description" := 'overlap';
                    Line.Modify(true);
                end;
            'modify status of line 40':
                begin
                    Line.Get('H1', 40);
                    Line.Status := 2;
                    Line.Modify();
                end;
            'modify status of line 10':
                begin
                    Line.Get('H1', 10);
                    Line.Status := 2;
                    Line.Modify();
                end;
            'modify without a change':
                begin
                    Line.Get(HeaderNo, LineNo);
                    Line.Modify();
                end;
            'line 40 leaves the contact filter':
                begin
                    Line.Get('H1', 40);
                    Line."Contact No." := 'C9';
                    Line.Modify();
                end;
            'the row read leaves the contact filter':
                begin
                    Line.Get(HeaderNo, LineNo);
                    Line."Contact No." := 'C9';
                    Line.Modify();
                end;
            'line 60 enters the contact filter':
                begin
                    Line.Get('H1', 60);
                    Line."Contact No." := 'C1';
                    Line.Modify();
                end;
            'line group of line 40 changes':
                begin
                    Line.Get('H1', 40);
                    Line."Line Group" := 'A';
                    Line.Modify();
                end;
            'insert line 25 and line 5':
                begin
                    Add('H1', 25, 'C1', 1, 100);
                    Add('H1', 5, 'C1', 1, 200);
                end;
            'insert line 70 of another contact':
                Add('H1', 70, 'C3', 1, 100);
            'delete line 40':
                begin
                    Line.Get('H1', 40);
                    Line.Delete();
                end;
            'delete line 10':
                begin
                    Line.Get('H1', 10);
                    Line.Delete();
                end;
            'write to another table':
                begin
                    Other.Init();
                    Other.Id := LineNo;
                    Other.Insert();
                end;
            'modify all status':
                Line.ModifyAll(Status, 3);
        end;
    end;

    [Test]
    procedure Aggregated_NoOrderBy_NoWrite_Control()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('no write', RunLoop('none', 0));
        Observer.Observe('write to another table after every row', RunLoop('write to another table', 0));
        Observer.Expect('no write', '10:1 20:1 30:1 40:1 50:1 ');
        Observer.Expect('write to another table after every row', '10:1 20:1 30:1 40:1 50:1 ');
        Observer.Verify();
    end;

    [Test]
    procedure Aggregated_NoOrderBy_ModifyOfFieldOutsideTheQuery()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('status of every row read', RunLoop('modify status of the row read', 0));
        Observer.Observe('status of the row read, at line 20 only', RunLoop('modify status of the row read', 20));
        Observer.Observe('status of line 40, at line 20', RunLoop('modify status of line 40', 20));
        Observer.Observe('status of line 10, at line 30', RunLoop('modify status of line 10', 30));
        Observer.Observe('Modify without a change, every row', RunLoop('modify without a change', 0));
        Observer.Observe('ModifyAll of status, at line 20', RunLoop('modify all status', 20));
        Observer.Expect('status of every row read', '10:1 20:1 30:1 40:1 50:1 ');
        Observer.Expect('status of the row read, at line 20 only', '10:1 20:1 30:1 40:1 50:1 ');
        Observer.Expect('status of line 40, at line 20', '10:1 20:1 30:1 40:1 50:1 ');
        Observer.Expect('status of line 10, at line 30', '10:1 20:1 30:1 40:1 50:1 ');
        Observer.Expect('Modify without a change, every row', '10:1 20:1 30:1 40:1 50:1 ');
        Observer.Expect('ModifyAll of status, at line 20', '10:1 20:1 30:1 40:1 50:1 ');
        Observer.Verify();
    end;

    [Test]
    procedure Aggregated_NoOrderBy_ModifyOfFilterAndGroupFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('line 40 leaves the filter, at line 20', RunLoop('line 40 leaves the contact filter', 20));
        Observer.Observe('the row read leaves the filter, every row', RunLoop('the row read leaves the contact filter', 0));
        Observer.Observe('the row read leaves the filter, at line 20', RunLoop('the row read leaves the contact filter', 20));
        Observer.Observe('line 60 enters the filter, at line 20', RunLoop('line 60 enters the contact filter', 20));
        Observer.Observe('line group of line 40 changes, at line 20', RunLoop('line group of line 40 changes', 20));
        Observer.Expect('line 40 leaves the filter, at line 20', '10:1 20:1 30:1 50:1 ');
        Observer.Expect('the row read leaves the filter, every row', '10:1 20:1 30:1 40:1 50:1 ');
        Observer.Expect('the row read leaves the filter, at line 20', '10:1 20:1 30:1 40:1 50:1 ');
        Observer.Expect('line 60 enters the filter, at line 20', '10:1 20:1 30:1 40:1 50:1 60:1 ');
        Observer.Expect('line group of line 40 changes, at line 20', '10:1 20:1 30:1 40:1 50:1 ');
        Observer.Verify();
    end;

    [Test]
    procedure Aggregated_NoOrderBy_InsertAndDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('insert lines 25 and 5, at line 20', RunLoop('insert line 25 and line 5', 20));
        Observer.Observe('insert a line outside the filter, at line 20', RunLoop('insert line 70 of another contact', 20));
        Observer.Observe('delete line 40, at line 20', RunLoop('delete line 40', 20));
        Observer.Observe('delete line 10, at line 30', RunLoop('delete line 10', 30));
        Observer.Expect('insert lines 25 and 5, at line 20', '10:1 20:1 25:1 30:1 40:1 50:1 ');
        Observer.Expect('insert a line outside the filter, at line 20', '10:1 20:1 30:1 40:1 50:1 ');
        Observer.Expect('delete line 40, at line 20', '10:1 20:1 30:1 50:1 ');
        Observer.Expect('delete line 10, at line 30', '10:1 20:1 30:1 40:1 50:1 ');
        Observer.Verify();
    end;

    local procedure RunDescending(Action: Text; AtLine: Integer): Text
    var
        Q: Query "LT QAW Overlap Descending";
        Result: Text;
        Guard: Integer;
    begin
        Seed();
        Q.SetRange(Kind, 1);
        Q.SetRange(ContactNo, 'C1');
        Q.SetRange(HeaderNo, 'H1');
        Q.Open();
        while Q.Read() and (Guard < 30) do begin
            Guard += 1;
            Result += Format(Q.LineNo) + ':' + Format(Q.Qty) + ' ';
            if (AtLine = 0) or (Q.LineNo = AtLine) then
                DoAction(Action, Q.HeaderNo, Q.LineNo);
        end;
        Q.Close();
        exit(Result);
    end;

    [Test]
    procedure Aggregated_OrderByDescending_WritesInLoop()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('no write', RunDescending('none', 0));
        Observer.Observe('status of every row read', RunDescending('modify status of the row read', 0));
        Observer.Observe('line 40 leaves the filter, at line 50', RunDescending('line 40 leaves the contact filter', 50));
        Observer.Observe('line 40 leaves the filter, at line 20', RunDescending('line 40 leaves the contact filter', 20));
        Observer.Observe('insert lines 25 and 5, at line 30', RunDescending('insert line 25 and line 5', 30));
        Observer.Observe('delete line 10, at line 30', RunDescending('delete line 10', 30));
        Observer.Expect('no write', '50:1 40:1 30:1 20:1 10:1 ');
        Observer.Expect('status of every row read', '50:1 40:1 30:1 20:1 10:1 ');
        Observer.Expect('line 40 leaves the filter, at line 50', '50:1 30:1 20:1 10:1 ');
        Observer.Expect('line 40 leaves the filter, at line 20', '50:1 40:1 30:1 20:1 10:1 ');
        Observer.Expect('insert lines 25 and 5, at line 30', '50:1 40:1 30:1 25:1 20:1 10:1 5:1 ');
        Observer.Expect('delete line 10, at line 30', '50:1 40:1 30:1 20:1 ');
        Observer.Verify();
    end;

    local procedure RunSums(Action: Text; AtKind: Integer): Text
    var
        Q: Query "LT QAW Sum By Kind";
        Line: Record "LT QAW Line";
        Result: Text;
        Guard: Integer;
    begin
        Seed();
        Line.Get('H1', 30);
        Line.Kind := 2;
        Line.Modify();
        Line.Get('H1', 40);
        Line.Kind := 3;
        Line.Modify();
        Line.Get('H1', 50);
        Line.Kind := 3;
        Line.Modify();
        Q.Open();
        while Q.Read() and (Guard < 30) do begin
            Guard += 1;
            Result += Format(Q.Kind) + '=' + Format(Q.Total, 0, 9) + '/' + Format(Q.Qty) + ' ';
            if Q.Kind = AtKind then
                case Action of
                    'status of a row of kind 3':
                        begin
                            Line.Get('H1', 40);
                            Line.Status := 2;
                            Line.Modify();
                        end;
                    'amount of a row of kind 3':
                        begin
                            Line.Get('H1', 40);
                            Line.Amount := 1000;
                            Line.Modify();
                        end;
                    'amount of a row of kind 1':
                        begin
                            Line.Get('H1', 10);
                            Line.Amount := 1000;
                            Line.Modify();
                        end;
                    'a row of kind 3 becomes kind 1':
                        begin
                            Line.Get('H1', 40);
                            Line.Kind := 1;
                            Line.Modify();
                        end;
                    'a row of kind 1 becomes kind 4':
                        begin
                            Line.Get('H1', 10);
                            Line.Kind := 4;
                            Line.Modify();
                        end;
                end;
        end;
        Q.Close();
        exit(Result);
    end;

    [Test]
    procedure AggregatedSum_NoOrderBy_NoFilter_WritesInLoop()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('no write', RunSums('none', 0));
        Observer.Observe('status of a row of kind 3, at kind 2', RunSums('status of a row of kind 3', 2));
        Observer.Observe('amount of a row of kind 3, at kind 2', RunSums('amount of a row of kind 3', 2));
        Observer.Observe('amount of a row of kind 1, at kind 2', RunSums('amount of a row of kind 1', 2));
        Observer.Observe('a row of kind 3 becomes kind 1, at kind 2', RunSums('a row of kind 3 becomes kind 1', 2));
        Observer.Observe('a row of kind 1 becomes kind 4, at kind 2', RunSums('a row of kind 1 becomes kind 4', 2));
        Observer.Expect('no write', '1=99/4 2=4/1 3=24/2 ');
        Observer.Expect('status of a row of kind 3, at kind 2', '1=99/4 2=4/1 3=24/2 ');
        Observer.Expect('amount of a row of kind 3, at kind 2', '1=99/4 2=4/1 3=1016/2 ');
        Observer.Expect('amount of a row of kind 1, at kind 2', '1=99/4 2=4/1 3=24/2 ');
        Observer.Expect('a row of kind 3 becomes kind 1, at kind 2', '1=99/4 2=4/1 3=16/1 ');
        Observer.Expect('a row of kind 1 becomes kind 4, at kind 2', '1=99/4 2=4/1 3=24/2 4=1/1 ');
        Observer.Verify();
    end;
}
