// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onaftergetrecord-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73864 (log), table 73865, pages 73866 and 73867, codeunit 73868
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "Action" (Page reads after an action, and a list that ends inside its window, corpus bump 7)
// Facts: log of OnAfterGetRecord (R), OnAfterGetCurrRecord (C) and the action body (A) around an action of a card and of a list, with the cursor on the first or a later row,
//   with an action that calls CurrPage.Update(false) or CurrPage.Update(true), and with 3, 25 and 40 rows
// BC versions: 29 (27 and 28 by CI)

codeunit 73864 "LT PnF AR Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

table 73865 "LT PnF AR Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 73866 "LT PnF AR List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PnF AR Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NoChange)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT PnF AR Log";
                begin
                    Log.Add('A');
                end;
            }
            action(UpdateFalse)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT PnF AR Log";
                begin
                    Log.Add('A');
                    CurrPage.Update(false);
                end;
            }
            action(UpdateTrue)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT PnF AR Log";
                begin
                    Log.Add('A');
                    CurrPage.Update(true);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnF AR Log";
    begin
        Log.Add('R');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PnF AR Log";
    begin
        Log.Add('C');
    end;
}

page 73867 "LT PnF AR Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PnF AR Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NoChange)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT PnF AR Log";
                begin
                    Log.Add('A');
                end;
            }
            action(UpdateFalse)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT PnF AR Log";
                begin
                    Log.Add('A');
                    CurrPage.Update(false);
                end;
            }
            action(UpdateTrue)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT PnF AR Log";
                begin
                    Log.Add('A');
                    CurrPage.Update(true);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnF AR Log";
    begin
        Log.Add('R');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PnF AR Log";
    begin
        Log.Add('C');
    end;
}

codeunit 73868 "LT PnF Action Reads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Rows: Integer)
    var
        Row: Record "LT PnF AR Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to Rows do begin
            Row.Id := i;
            Row.Name := 'n' + Format(i);
            Row.Insert();
        end;
    end;

    local procedure Reads(Seq: Text; Letter: Text[1]): Text
    begin
        exit(Format(StrLen(Seq) - StrLen(DelChr(Seq, '=', Letter))));
    end;

    local procedure ListAction(Rows: Integer; MoveNext: Integer; Which: Text; Name: Text; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF AR Log";
        P: TestPage "LT PnF AR List";
        Seq: Text;
        i: Integer;
    begin
        Seed(Rows);
        P.OpenView();
        for i := 1 to MoveNext do
            P.Next();
        Log.Take();
        case Which of
            'none':
                P.NoChange.Invoke();
            'false':
                P.UpdateFalse.Invoke();
            'true':
                P.UpdateTrue.Invoke();
        end;
        Seq := Log.Take();
        Observer.Observe(Name + '|seq', Seq);
        Observer.Observe(Name + '|R', Reads(Seq, 'R'));
        Observer.Observe(Name + '|C', Reads(Seq, 'C'));
        Observer.Observe(Name + '|row', P.Id.Value());
        P.Close();
        Log.Take();
    end;

    local procedure CardAction(Which: Text; Name: Text; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF AR Log";
        P: TestPage "LT PnF AR Card";
        Seq: Text;
    begin
        Seed(3);
        P.OpenView();
        Log.Take();
        case Which of
            'none':
                P.NoChange.Invoke();
            'false':
                P.UpdateFalse.Invoke();
            'true':
                P.UpdateTrue.Invoke();
        end;
        Seq := Log.Take();
        Observer.Observe(Name + '|seq', Seq);
        Observer.Observe(Name + '|R', Reads(Seq, 'R'));
        Observer.Observe(Name + '|C', Reads(Seq, 'C'));
        P.Close();
        Log.Take();
    end;

    [Test]
    procedure Action_Card()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CardAction('none', 'card_none', Observer);
        CardAction('false', 'card_update_false', Observer);
        CardAction('true', 'card_update_true', Observer);
        Observer.Expect('card_none|seq', 'RARRC');
        Observer.Expect('card_none|R', '3');
        Observer.Expect('card_none|C', '1');
        Observer.Expect('card_update_false|seq', 'RARRC');
        Observer.Expect('card_update_false|R', '3');
        Observer.Expect('card_update_false|C', '1');
        Observer.Expect('card_update_true|seq', 'RARRC');
        Observer.Expect('card_update_true|R', '3');
        Observer.Expect('card_update_true|C', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Action_List_FirstRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListAction(3, 0, 'none', 'list3_none', Observer);
        ListAction(3, 0, 'false', 'list3_update_false', Observer);
        ListAction(3, 0, 'true', 'list3_update_true', Observer);
        Observer.Expect('list3_none|seq', 'RARRRRRRC');
        Observer.Expect('list3_none|R', '7');
        Observer.Expect('list3_none|C', '1');
        Observer.Expect('list3_none|row', '1');
        Observer.Expect('list3_update_false|seq', 'RARRRRRRC');
        Observer.Expect('list3_update_false|R', '7');
        Observer.Expect('list3_update_false|C', '1');
        Observer.Expect('list3_update_false|row', '1');
        Observer.Expect('list3_update_true|seq', 'RARRRRRRC');
        Observer.Expect('list3_update_true|R', '7');
        Observer.Expect('list3_update_true|C', '1');
        Observer.Expect('list3_update_true|row', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Action_List_LaterRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListAction(3, 1, 'none', 'list3_row2_none', Observer);
        ListAction(3, 2, 'none', 'list3_row3_none', Observer);
        ListAction(3, 1, 'false', 'list3_row2_update_false', Observer);
        ListAction(3, 1, 'true', 'list3_row2_update_true', Observer);
        Observer.Expect('list3_row2_none|seq', 'RARRRRRRRC');
        Observer.Expect('list3_row2_none|R', '8');
        Observer.Expect('list3_row2_none|C', '1');
        Observer.Expect('list3_row2_none|row', '2');
        Observer.Expect('list3_row3_none|seq', 'RARRRRRRC');
        Observer.Expect('list3_row3_none|R', '7');
        Observer.Expect('list3_row3_none|C', '1');
        Observer.Expect('list3_row3_none|row', '3');
        Observer.Expect('list3_row2_update_false|seq', 'RARRRRRRRC');
        Observer.Expect('list3_row2_update_false|R', '8');
        Observer.Expect('list3_row2_update_false|C', '1');
        Observer.Expect('list3_row2_update_false|row', '2');
        Observer.Expect('list3_row2_update_true|seq', 'RARRRRRRRC');
        Observer.Expect('list3_row2_update_true|R', '8');
        Observer.Expect('list3_row2_update_true|C', '1');
        Observer.Expect('list3_row2_update_true|row', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Action_List_ManyRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListAction(25, 0, 'none', 'list25_none', Observer);
        ListAction(25, 0, 'false', 'list25_update_false', Observer);
        ListAction(25, 5, 'none', 'list25_row6_none', Observer);
        ListAction(40, 0, 'none', 'list40_none', Observer);
        ListAction(40, 0, 'true', 'list40_update_true', Observer);
        Observer.Expect('list25_none|seq', 'RARRRRRRRRRRRRRRRRRRRRRRRC');
        Observer.Expect('list25_none|R', '24');
        Observer.Expect('list25_none|C', '1');
        Observer.Expect('list25_none|row', '1');
        Observer.Expect('list25_update_false|seq', 'RARRRRRRRRRRRRRRRRRRRRRRRC');
        Observer.Expect('list25_update_false|R', '24');
        Observer.Expect('list25_update_false|C', '1');
        Observer.Expect('list25_update_false|row', '1');
        Observer.Expect('list25_row6_none|seq', 'RARRRRRRRRRRRRRRRRRRRRRRRRRRRRRC');
        Observer.Expect('list25_row6_none|R', '30');
        Observer.Expect('list25_row6_none|C', '1');
        Observer.Expect('list25_row6_none|row', '6');
        Observer.Expect('list40_none|seq', 'RARRRRRRRRRRRRRRRRRRRRRRRC');
        Observer.Expect('list40_none|R', '24');
        Observer.Expect('list40_none|C', '1');
        Observer.Expect('list40_none|row', '1');
        Observer.Expect('list40_update_true|seq', 'RARRRRRRRRRRRRRRRRRRRRRRRC');
        Observer.Expect('list40_update_true|R', '24');
        Observer.Expect('list40_update_true|C', '1');
        Observer.Expect('list40_update_true|row', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Action_List_FewRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListAction(1, 0, 'none', 'list1_none', Observer);
        ListAction(2, 0, 'none', 'list2_none', Observer);
        ListAction(19, 0, 'none', 'list19_none', Observer);
        ListAction(20, 0, 'none', 'list20_none', Observer);
        Observer.Expect('list1_none|seq', 'RARRRC');
        Observer.Expect('list1_none|R', '4');
        Observer.Expect('list1_none|C', '1');
        Observer.Expect('list1_none|row', '1');
        Observer.Expect('list2_none|seq', 'RARRRRRC');
        Observer.Expect('list2_none|R', '6');
        Observer.Expect('list2_none|C', '1');
        Observer.Expect('list2_none|row', '1');
        Observer.Expect('list19_none|seq', 'RARRRRRRRRRRRRRRRRRRRRRRC');
        Observer.Expect('list19_none|R', '23');
        Observer.Expect('list19_none|C', '1');
        Observer.Expect('list19_none|row', '1');
        Observer.Expect('list20_none|seq', 'RARRRRRRRRRRRRRRRRRRRRRRRC');
        Observer.Expect('list20_none|R', '24');
        Observer.Expect('list20_none|C', '1');
        Observer.Expect('list20_none|row', '1');
        Observer.Verify();
    end;
}
