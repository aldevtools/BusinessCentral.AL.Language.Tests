// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-deleteall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 95620 (head with FlowFields), 95621 (lines), 95622 (log), test codeunit 95623
// Probe (al-runner issue 6961): DeleteAll() and DeleteAll(true) on a record filtered on a FlowField: an Exist, a Sum (also with a FlowFilter),
//   a Count, a Lookup and an Exist over the same table (a head whose parent head exists). Which rows go, does OnDelete run per row, and are
//   the rows chosen before the first delete (the self-referencing Exist: deleting a parent would make its child match the filter).
//   Also a temporary record (its FlowFields are calculated from the real tables) and RecordRef.DeleteAll.
// Result (BC 29.0, corpus CI): a FlowField filter is applied to DeleteAll as to FindSet (Exist, Sum with a FlowFilter, Count, Lookup with
//   '<>' matching a blank lookup). DeleteAll() runs no OnDelete and takes the rows chosen before the first delete (the self-referencing
//   Exist deletes heads 1 and 5 only). DeleteAll(true) runs OnDelete per row in the key order (descending with Ascending(false)) and
//   tests each row against the filters when it reaches it, after the earlier deletes: the self-referencing Exist = false deletes the whole
//   chain 1..5; Exist = true deletes 2 and 4 (head 3 lost its parent when head 2 went). A temporary record calculates from the real tables.
// BC versions: 27, 28, 29

table 95620 "LT R6961 Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Parent; Integer) { }
        field(3; Kind; Code[10]) { }
        field(10; HasLines; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("LT R6961 Line" where(HeadId = field(Id)));
        }
        field(11; LineSum; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT R6961 Line".Amount where(HeadId = field(Id), PostDate = field(DateFilter)));
        }
        field(12; LineCount; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT R6961 Line" where(HeadId = field(Id)));
        }
        field(13; ParentExists; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("LT R6961 Head" where(Id = field(Parent)));
        }
        field(14; DateFilter; Date)
        {
            FieldClass = FlowFilter;
        }
        field(15; LastLineKind; Code[10])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT R6961 Line".Kind where(HeadId = field(Id)));
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnDelete()
    var
        Log: Record "LT R6961 Log";
    begin
        Log.Add('del ' + Format(Id));
    end;
}

table 95621 "LT R6961 Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; HeadId; Integer) { }
        field(2; LineNo; Integer) { }
        field(3; Amount; Decimal) { }
        field(4; PostDate; Date) { }
        field(5; Kind; Code[10]) { }
    }

    keys
    {
        key(PK; HeadId, LineNo) { Clustered = true; }
    }
}

table 95622 "LT R6961 Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Seq; Integer) { AutoIncrement = true; }
        field(2; Msg; Text[100]) { }
    }

    keys
    {
        key(PK; Seq) { Clustered = true; }
    }

    procedure Add(Text: Text)
    var
        Log: Record "LT R6961 Log";
    begin
        Log.Init();
        Log.Seq := 0;
        Log.Msg := CopyStr(Text, 1, MaxStrLen(Log.Msg));
        Log.Insert();
    end;

    procedure Dump(): Text
    var
        Log: Record "LT R6961 Log";
        Result: Text;
    begin
        if Log.FindSet() then
            repeat
                Result += Log.Msg + ';';
            until Log.Next() = 0;
        exit(Result);
    end;
}

codeunit 95623 "LT R6961 DeleteAll FlowFilter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Reset()
    var
        Head: Record "LT R6961 Head";
        Line: Record "LT R6961 Line";
        Log: Record "LT R6961 Log";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Log.DeleteAll();
    end;

    // Heads 1..4 (kind A, B, A, B); lines on head 1 (amount 5, 2030-01-10, kind X) and head 3 (amounts 20 on 2030-01-10 and 30 on
    // 2030-02-10, kinds Y then Z).
    local procedure Seed()
    begin
        Reset();
        AddHead(1, 0, 'A');
        AddHead(2, 0, 'B');
        AddHead(3, 0, 'A');
        AddHead(4, 0, 'B');
        AddLine(1, 10000, 5, DMY2Date(10, 1, 2030), 'X');
        AddLine(3, 10000, 20, DMY2Date(10, 1, 2030), 'Y');
        AddLine(3, 20000, 30, DMY2Date(10, 2, 2030), 'Z');
    end;

    // A chain 1 <- 2 <- 3 <- 4 (each head's parent is the one before; head 1 has parent 0, which does not exist) and head 5 whose parent 9
    // does not exist.
    local procedure SeedChain()
    begin
        Reset();
        AddHead(1, 0, 'A');
        AddHead(2, 1, 'A');
        AddHead(3, 2, 'A');
        AddHead(4, 3, 'A');
        AddHead(5, 9, 'A');
    end;

    local procedure AddHead(Id: Integer; Parent: Integer; Kind: Code[10])
    var
        Head: Record "LT R6961 Head";
    begin
        Head.Init();
        Head.Id := Id;
        Head.Parent := Parent;
        Head.Kind := Kind;
        Head.Insert();
    end;

    local procedure AddLine(HeadId: Integer; LineNo: Integer; Amount: Decimal; PostDate: Date; Kind: Code[10])
    var
        Line: Record "LT R6961 Line";
    begin
        Line.Init();
        Line.HeadId := HeadId;
        Line.LineNo := LineNo;
        Line.Amount := Amount;
        Line.PostDate := PostDate;
        Line.Kind := Kind;
        Line.Insert();
    end;

    local procedure Heads(): Text
    var
        Head: Record "LT R6961 Head";
        Result: Text;
    begin
        if Head.FindSet() then
            repeat
                Result += Format(Head.Id) + ',';
            until Head.Next() = 0;
        exit(Result);
    end;

    local procedure LineCount(): Text
    var
        Line: Record "LT R6961 Line";
    begin
        exit(Format(Line.Count()));
    end;

    [Test]
    procedure DeleteAll_ExistFalse_NoTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT R6961 Head";
        Log: Record "LT R6961 Log";
    begin
        Seed();
        Head.SetRange(HasLines, false);
        Observer.Observe('count before', Format(Head.Count()));
        Head.DeleteAll();
        Observer.Observe('heads', Heads());
        Observer.Observe('lines', LineCount());
        Observer.Observe('log', Log.Dump());
        Observer.Observe('filters after', Head.GetFilters());
        Observer.Expect('count before', '2');
        Observer.Expect('heads', '1,3,');
        Observer.Expect('lines', '3');
        Observer.Expect('log', '');
        Observer.Expect('filters after', 'HasLines: No');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAll_ExistFalse_RunTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT R6961 Head";
        Log: Record "LT R6961 Log";
    begin
        Seed();
        Head.SetRange(HasLines, false);
        Head.DeleteAll(true);
        Observer.Observe('heads', Heads());
        Observer.Observe('log', Log.Dump());
        Observer.Expect('heads', '1,3,');
        Observer.Expect('log', 'del 2;del 4;');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAll_ExistTrue_RunTrigger_Descending()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT R6961 Head";
        Log: Record "LT R6961 Log";
    begin
        Seed();
        Head.Ascending(false);
        Head.SetRange(HasLines, true);
        Head.DeleteAll(true);
        Observer.Observe('heads', Heads());
        Observer.Observe('lines', LineCount());
        Observer.Observe('log', Log.Dump());
        Observer.Expect('heads', '2,4,');
        Observer.Expect('lines', '3');
        Observer.Expect('log', 'del 3;del 1;');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAll_SumFilter_RunTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT R6961 Head";
        Log: Record "LT R6961 Log";
    begin
        Seed();
        Head.SetFilter(LineSum, '>%1', 10);
        Head.DeleteAll(true);
        Observer.Observe('heads', Heads());
        Observer.Observe('log', Log.Dump());
        Observer.Expect('heads', '1,2,4,');
        Observer.Expect('log', 'del 3;');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAll_SumFilterWithFlowFilter_NoTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT R6961 Head";
        Log: Record "LT R6961 Log";
    begin
        Seed();
        // Only the January lines count: head 1 sums 5, head 3 sums 20.
        Head.SetRange(DateFilter, DMY2Date(1, 1, 2030), DMY2Date(31, 1, 2030));
        Head.SetFilter(LineSum, '>%1&<%2', 1, 10);
        Head.DeleteAll();
        Observer.Observe('heads', Heads());
        Observer.Observe('log', Log.Dump());
        Observer.Expect('heads', '2,3,4,');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAll_CountAndNormalFilter_RunTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT R6961 Head";
        Log: Record "LT R6961 Log";
    begin
        Seed();
        Head.SetFilter(LineCount, '>=%1', 1);
        Head.SetRange(Kind, 'A');
        Head.SetRange(Id, 2, 4);
        Head.DeleteAll(true);
        Observer.Observe('heads', Heads());
        Observer.Observe('log', Log.Dump());
        Observer.Expect('heads', '1,2,4,');
        Observer.Expect('log', 'del 3;');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAll_LookupNotEqual_RunTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT R6961 Head";
        Log: Record "LT R6961 Log";
    begin
        Seed();
        // The lookup reads the first line of a head (X for head 1, Y for head 3) and blank for a head without lines.
        Head.SetFilter(LastLineKind, '<>%1', 'Y');
        Head.DeleteAll(true);
        Observer.Observe('heads', Heads());
        Observer.Observe('log', Log.Dump());
        Observer.Expect('heads', '3,');
        Observer.Expect('log', 'del 1;del 2;del 4;');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAll_NoRowMatches_RunTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT R6961 Head";
        Log: Record "LT R6961 Log";
    begin
        Seed();
        Head.SetFilter(LineSum, '>%1', 1000);
        Head.DeleteAll(true);
        Observer.Observe('heads', Heads());
        Observer.Observe('log', Log.Dump());
        Observer.Expect('heads', '1,2,3,4,');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAll_SelfReferenceExist_NoTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT R6961 Head";
        Log: Record "LT R6961 Log";
    begin
        SeedChain();
        // Before any delete only heads 1 and 5 have no parent row. Deleting head 1 first would leave head 2 without its parent.
        Head.SetRange(ParentExists, false);
        Observer.Observe('count before', Format(Head.Count()));
        Head.DeleteAll();
        Observer.Observe('heads', Heads());
        Observer.Observe('log', Log.Dump());
        Observer.Expect('count before', '2');
        Observer.Expect('heads', '2,3,4,');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAll_SelfReferenceExist_RunTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT R6961 Head";
        Log: Record "LT R6961 Log";
    begin
        SeedChain();
        Head.SetRange(ParentExists, false);
        Head.DeleteAll(true);
        Observer.Observe('heads', Heads());
        Observer.Observe('log', Log.Dump());
        Observer.Expect('heads', '');
        Observer.Expect('log', 'del 1;del 2;del 3;del 4;del 5;');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAll_SelfReferenceExistTrue_RunTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT R6961 Head";
        Log: Record "LT R6961 Log";
    begin
        SeedChain();
        // Heads 2, 3 and 4 have a parent row. Deleting head 2 first leaves head 3 without its parent.
        Head.SetRange(ParentExists, true);
        Head.DeleteAll(true);
        Observer.Observe('heads', Heads());
        Observer.Observe('log', Log.Dump());
        Observer.Expect('heads', '1,3,5,');
        Observer.Expect('log', 'del 2;del 4;');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAll_Temporary_ExistFalse_RunTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT R6961 Head";
        TempHead: Record "LT R6961 Head" temporary;
        Log: Record "LT R6961 Log";
        Result: Text;
    begin
        Seed();
        if Head.FindSet() then
            repeat
                TempHead := Head;
                TempHead.Insert();
            until Head.Next() = 0;
        TempHead.SetRange(HasLines, false);
        TempHead.DeleteAll(true);
        TempHead.Reset();
        if TempHead.FindSet() then
            repeat
                Result += Format(TempHead.Id) + ',';
            until TempHead.Next() = 0;
        Observer.Observe('temp heads', Result);
        Observer.Observe('real heads', Heads());
        Observer.Observe('log', Log.Dump());
        Observer.Expect('temp heads', '1,3,');
        Observer.Expect('real heads', '1,2,3,4,');
        Observer.Expect('log', 'del 2;del 4;');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_DeleteAll_ExistFalse_RunTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT R6961 Log";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Seed();
        RecRef.Open(Database::"LT R6961 Head");
        FldRef := RecRef.Field(10);
        FldRef.SetRange(false);
        RecRef.DeleteAll(true);
        RecRef.Close();
        Observer.Observe('heads', Heads());
        Observer.Observe('log', Log.Dump());
        Observer.Expect('heads', '1,3,');
        Observer.Expect('log', 'del 2;del 4;');
        Observer.Verify();
    end;
}
