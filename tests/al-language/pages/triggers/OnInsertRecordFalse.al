// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-oninsertrecord-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 74142, pages 74143 and 74144, counter codeunit 74145, test codeunit 74146
// Probe: written against BC on CI (no local container); every literal asserted below is what the CI tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a page whose OnInsertRecord runs Rec.Insert() itself and answers false, and whose OnModifyRecord runs Rec.Modify() and answers false.
//   Card: OpenNew, set the key, set a second field, OK (and Close). List: New, set the key, set a second field, move off the row.
//   How often each trigger runs after each step, and the row the database holds at the end.
// BC versions: 27, 28, 29 by CI

table 74142 "LT OI Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Val; Text[30]) { }
        field(3; Val2; Text[30]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

codeunit 74145 "LT OI Counter"
{
    SingleInstance = true;

    var
        Inserts: Integer;
        Modifies: Integer;

    procedure Reset()
    begin
        Inserts := 0;
        Modifies := 0;
    end;

    procedure CountInsert()
    begin
        Inserts += 1;
    end;

    procedure CountModify()
    begin
        Modifies += 1;
    end;

    procedure Text(): Text
    begin
        exit(StrSubstNo('ins=%1 mod=%2', Inserts, Modifies));
    end;
}

page 74143 "LT OI Card"
{
    PageType = Card;
    SourceTable = "LT OI Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec.Code) { ApplicationArea = All; }
            field(Val; Rec.Val) { ApplicationArea = All; }
            field(Val2; Rec.Val2) { ApplicationArea = All; }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Counter: Codeunit "LT OI Counter";
    begin
        Counter.CountInsert();
        Rec.Insert();
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Counter: Codeunit "LT OI Counter";
    begin
        Counter.CountModify();
        Rec.Modify();
        exit(false);
    end;
}

page 74144 "LT OI List"
{
    PageType = List;
    SourceTable = "LT OI Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec.Code) { ApplicationArea = All; }
                field(Val; Rec.Val) { ApplicationArea = All; }
                field(Val2; Rec.Val2) { ApplicationArea = All; }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Counter: Codeunit "LT OI Counter";
    begin
        Counter.CountInsert();
        Rec.Insert();
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Counter: Codeunit "LT OI Counter";
    begin
        Counter.CountModify();
        Rec.Modify();
        exit(false);
    end;
}

codeunit 74146 "LT OnInsertRecord False"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        Counter: Codeunit "LT OI Counter";

    local procedure Seed()
    var
        R: Record "LT OI Row";
    begin
        R.DeleteAll();
        Counter.Reset();
    end;

    local procedure ObserveRow(Prefix: Text)
    var
        R: Record "LT OI Row";
    begin
        Obs.Observe(Prefix + '.count', Format(R.Count()));
        if R.Get('K1') then
            Obs.Observe(Prefix + '.row', R.Code + '|' + R.Val + '|' + R.Val2);
    end;

    [Test]
    procedure Card_OpenNew_KeyThenField_OK()
    var
        Card: TestPage "LT OI Card";
    begin
        Seed();
        Card.OpenNew();
        Card.Code.SetValue('K1');
        Obs.Observe('after_key', Counter.Text());
        ObserveRow('after_key');
        Card.Val.SetValue('v1');
        Obs.Observe('after_val', Counter.Text());
        ObserveRow('after_val');
        Card.Val2.SetValue('v2');
        Obs.Observe('after_val2', Counter.Text());
        Card.OK().Invoke();
        Obs.Observe('after_ok', Counter.Text());
        ObserveRow('end');
        Obs.Expect('after_key', 'ins=0 mod=0');
        Obs.Expect('after_key.count', '0');
        Obs.Expect('after_val', 'ins=1 mod=0');
        Obs.Expect('after_val.count', '1');
        Obs.Expect('after_val.row', 'K1||');
        Obs.Expect('after_val2', 'ins=1 mod=0');
        Obs.Expect('after_ok', 'ins=1 mod=1');
        Obs.Expect('end.count', '1');
        Obs.Expect('end.row', 'K1|v1|v2');
        Obs.Verify();
    end;

    [Test]
    procedure Card_OpenNew_KeyThenField_Close()
    var
        Card: TestPage "LT OI Card";
    begin
        Seed();
        Card.OpenNew();
        Card.Code.SetValue('K1');
        Card.Val.SetValue('v1');
        Card.Close();
        Obs.Observe('after_close', Counter.Text());
        ObserveRow('end');
        Obs.Expect('after_close', 'ins=1 mod=1');
        Obs.Expect('end.count', '1');
        Obs.Expect('end.row', 'K1|v1|');
        Obs.Verify();
    end;

    [Test]
    procedure Card_OpenNew_KeyOnly_Close()
    var
        Card: TestPage "LT OI Card";
    begin
        Seed();
        Card.OpenNew();
        Card.Code.SetValue('K1');
        Card.Close();
        Obs.Observe('after_close', Counter.Text());
        ObserveRow('end');
        Obs.Expect('after_close', 'ins=1 mod=0');
        Obs.Expect('end.count', '1');
        Obs.Expect('end.row', 'K1||');
        Obs.Verify();
    end;

    [Test]
    procedure List_New_KeyThenField()
    var
        List: TestPage "LT OI List";
    begin
        Seed();
        List.OpenEdit();
        List.New();
        List.Code.SetValue('K1');
        Obs.Observe('after_key', Counter.Text());
        ObserveRow('after_key');
        List.Val.SetValue('v1');
        Obs.Observe('after_val', Counter.Text());
        ObserveRow('after_val');
        List.Val2.SetValue('v2');
        Obs.Observe('after_val2', Counter.Text());
        List.Close();
        Obs.Observe('after_close', Counter.Text());
        ObserveRow('end');
        Obs.Expect('after_key', 'ins=0 mod=0');
        Obs.Expect('after_key.count', '0');
        Obs.Expect('after_val', 'ins=1 mod=0');
        Obs.Expect('after_val.count', '1');
        Obs.Expect('after_val.row', 'K1||');
        Obs.Expect('after_val2', 'ins=1 mod=0');
        Obs.Expect('after_close', 'ins=1 mod=1');
        Obs.Expect('end.count', '1');
        Obs.Expect('end.row', 'K1|v1|v2');
        Obs.Verify();
    end;

    [Test]
    procedure List_ExistingRow_ModifyField()
    var
        R: Record "LT OI Row";
        List: TestPage "LT OI List";
    begin
        Seed();
        R.Code := 'K1';
        R.Insert();
        List.OpenEdit();
        List.Val.SetValue('v1');
        Obs.Observe('after_val', Counter.Text());
        List.Close();
        Obs.Observe('after_close', Counter.Text());
        ObserveRow('end');
        Obs.Expect('after_val', 'ins=0 mod=0');
        Obs.Expect('after_close', 'ins=0 mod=1');
        Obs.Expect('end.count', '1');
        Obs.Expect('end.row', 'K1|v1|');
        Obs.Verify();
    end;
}
