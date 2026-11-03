// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotokey-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 90991 - 90993 (writer Y5)
// Probe: written against SaaS BC 29 and the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: al-runner issue 6381, second part. A table keyed (Grp, No) with a second key (No, Grp), 60 rows in each of groups 1 and 2.
//   (a) List page without a filter: an action that only calls Rec.SetCurrentKey(No, Grp), or only Rec.SetAscending(No, false);
//       then GoToKey, Next, First, Last.
//   (b) The filter-change shape of Y5GoToKeyAfterActionFilter.al (OnOpenPage SetRange(Grp, 1); action SetRange(Grp, 2),
//       FindFirst, CurrPage.Update(false)) on a list WITH OnAfterGetRecord (fills a page variable shown in a control), and on
//       a list with OnAfterGetRecord AND OnAfterGetCurrRecord (fills a second control).
// Result: SetCurrentKey in an action changes the order of Next and First at once; SetAscending(No, false) in an action has no
//   visible effect on the list. After the filter change, OnAfterGetRecord and OnAfterGetCurrRecord show the row GoToKey and Next
//   reach; a GoToKey that returns false leaves the shown values unchanged.
// Source: al-runner issue 6381.
// BC versions: 27, 28, 29

table 90991 "LT Y5 GK2 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Grp; Integer) { }
        field(2; No; Integer) { }
    }

    keys
    {
        key(PK; Grp, No) { Clustered = true; }
        key(ByNo; No, Grp) { }
    }
}

page 90991 "LT Y5 GK2 Key List"
{
    PageType = List;
    SourceTable = "LT Y5 GK2 Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field(No; Rec.No) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(KeyByNo)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.SetCurrentKey(No, Grp);
                end;
            }
            action(Descending)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.SetAscending(No, false);
                end;
            }
        }
    }
}

page 90992 "LT Y5 GK2 Rec List"
{
    PageType = List;
    SourceTable = "LT Y5 GK2 Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field(No; Rec.No) { ApplicationArea = All; }
                field(Shown; ShownText) { ApplicationArea = All; Caption = 'Shown'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NextGroup)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.SetRange(Grp, 2);
                    if Rec.FindFirst() then;
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Grp, 1);
    end;

    trigger OnAfterGetRecord()
    begin
        ShownText := 'row ' + Format(Rec.Grp) + '/' + Format(Rec.No);
    end;

    var
        ShownText: Text;
}

page 90993 "LT Y5 GK2 Curr List"
{
    PageType = List;
    SourceTable = "LT Y5 GK2 Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field(No; Rec.No) { ApplicationArea = All; }
                field(Shown; ShownText) { ApplicationArea = All; Caption = 'Shown'; }
                field(Current; CurrentText) { ApplicationArea = All; Caption = 'Current'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NextGroup)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.SetRange(Grp, 2);
                    if Rec.FindFirst() then;
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Grp, 1);
    end;

    trigger OnAfterGetRecord()
    begin
        ShownText := 'row ' + Format(Rec.Grp) + '/' + Format(Rec.No);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrentText := 'curr ' + Format(Rec.Grp) + '/' + Format(Rec.No);
    end;

    var
        ShownText: Text;
        CurrentText: Text;
}

codeunit 90991 "LT Y5 GK2 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Y5_GoToKeyAfterAction_SetCurrentKeyOnly()
    var
        L: TestPage "LT Y5 GK2 Key List";
        Observer: Codeunit "Probe Observer";
    begin
        InsertRows();
        L.OpenView();
        Observer.Observe('goto 1,50', Format(L.GoToKey(1, 50)));
        Observer.Observe('next before action', Format(L.Next()));
        Observer.Observe('row before action', Row(L));
        L.KeyByNo.Invoke();
        Observer.Observe('row after action', Row(L));
        Observer.Observe('goto 1,50 again', Format(L.GoToKey(1, 50)));
        Observer.Observe('row', Row(L));
        Observer.Observe('next', Format(L.Next()));
        Observer.Observe('row after next', Row(L));
        Observer.Observe('first', Format(L.First()));
        Observer.Observe('row first', Row(L));
        Observer.Observe('next after first', Format(L.Next()));
        Observer.Observe('row after first next', Row(L));
        L.Close();
        Observer.Expect('goto 1,50', 'Yes');
        Observer.Expect('next before action', 'Yes');
        Observer.Expect('row before action', '1/51');
        Observer.Expect('row after action', '1/51');
        Observer.Expect('goto 1,50 again', 'Yes');
        Observer.Expect('row', '1/50');
        Observer.Expect('next', 'Yes');
        Observer.Expect('row after next', '2/50');
        Observer.Expect('first', 'Yes');
        Observer.Expect('row first', '1/1');
        Observer.Expect('next after first', 'Yes');
        Observer.Expect('row after first next', '2/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y5_GoToKeyAfterAction_SetAscendingOnly()
    var
        L: TestPage "LT Y5 GK2 Key List";
        Observer: Codeunit "Probe Observer";
    begin
        InsertRows();
        L.OpenView();
        Observer.Observe('goto 1,50', Format(L.GoToKey(1, 50)));
        L.Descending.Invoke();
        Observer.Observe('row after action', Row(L));
        Observer.Observe('goto 2,10', Format(L.GoToKey(2, 10)));
        Observer.Observe('row', Row(L));
        Observer.Observe('next', Format(L.Next()));
        Observer.Observe('row after next', Row(L));
        Observer.Observe('first', Format(L.First()));
        Observer.Observe('row first', Row(L));
        Observer.Observe('next after first', Format(L.Next()));
        Observer.Observe('row after first next', Row(L));
        Observer.Observe('last', Format(L.Last()));
        Observer.Observe('row last', Row(L));
        L.Close();
        Observer.Expect('goto 1,50', 'Yes');
        Observer.Expect('row after action', '1/50');
        Observer.Expect('goto 2,10', 'Yes');
        Observer.Expect('row', '2/10');
        Observer.Expect('next', 'Yes');
        Observer.Expect('row after next', '2/11');
        Observer.Expect('first', 'Yes');
        Observer.Expect('row first', '1/1');
        Observer.Expect('next after first', 'Yes');
        Observer.Expect('row after first next', '1/2');
        Observer.Expect('last', 'Yes');
        Observer.Expect('row last', '2/60');
        Observer.Verify();
    end;

    [Test]
    procedure Y5_GoToKeyAfterActionFilter_WithOnAfterGetRecord()
    var
        L: TestPage "LT Y5 GK2 Rec List";
        Observer: Codeunit "Probe Observer";
    begin
        InsertRows();
        L.OpenView();
        Observer.Observe('goto 1,50', Format(L.GoToKey(1, 50)));
        Observer.Observe('shown 1,50', L.Shown.Value());
        L.NextGroup.Invoke();
        Observer.Observe('row after action', L.Grp.Value() + '/' + L.No.Value());
        Observer.Observe('shown after action', L.Shown.Value());
        Observer.Observe('goto 2,50', Format(L.GoToKey(2, 50)));
        Observer.Observe('row', L.Grp.Value() + '/' + L.No.Value());
        Observer.Observe('shown', L.Shown.Value());
        Observer.Observe('next', Format(L.Next()));
        Observer.Observe('shown after next', L.Shown.Value());
        Observer.Observe('goto 1,50 again', Format(L.GoToKey(1, 50)));
        Observer.Observe('shown after failed goto', L.Shown.Value());
        L.Close();
        Observer.Expect('goto 1,50', 'Yes');
        Observer.Expect('shown 1,50', 'row 1/50');
        Observer.Expect('row after action', '2/1');
        Observer.Expect('shown after action', 'row 2/1');
        Observer.Expect('goto 2,50', 'Yes');
        Observer.Expect('row', '2/50');
        Observer.Expect('shown', 'row 2/50');
        Observer.Expect('next', 'Yes');
        Observer.Expect('shown after next', 'row 2/51');
        Observer.Expect('goto 1,50 again', 'No');
        Observer.Expect('shown after failed goto', 'row 2/51');
        Observer.Verify();
    end;

    [Test]
    procedure Y5_GoToKeyAfterActionFilter_WithOnAfterGetCurrRecord()
    var
        L: TestPage "LT Y5 GK2 Curr List";
        Observer: Codeunit "Probe Observer";
    begin
        InsertRows();
        L.OpenView();
        Observer.Observe('goto 1,50', Format(L.GoToKey(1, 50)));
        Observer.Observe('shown 1,50', L.Shown.Value());
        Observer.Observe('current 1,50', L.Current.Value());
        L.NextGroup.Invoke();
        Observer.Observe('row after action', L.Grp.Value() + '/' + L.No.Value());
        Observer.Observe('shown after action', L.Shown.Value());
        Observer.Observe('current after action', L.Current.Value());
        Observer.Observe('goto 2,50', Format(L.GoToKey(2, 50)));
        Observer.Observe('row', L.Grp.Value() + '/' + L.No.Value());
        Observer.Observe('shown', L.Shown.Value());
        Observer.Observe('current', L.Current.Value());
        Observer.Observe('next', Format(L.Next()));
        Observer.Observe('shown after next', L.Shown.Value());
        Observer.Observe('current after next', L.Current.Value());
        L.Close();
        Observer.Expect('goto 1,50', 'Yes');
        Observer.Expect('shown 1,50', 'row 1/50');
        Observer.Expect('current 1,50', 'curr 1/50');
        Observer.Expect('row after action', '2/1');
        Observer.Expect('shown after action', 'row 2/1');
        Observer.Expect('current after action', 'curr 2/1');
        Observer.Expect('goto 2,50', 'Yes');
        Observer.Expect('row', '2/50');
        Observer.Expect('shown', 'row 2/50');
        Observer.Expect('current', 'curr 2/50');
        Observer.Expect('next', 'Yes');
        Observer.Expect('shown after next', 'row 2/51');
        Observer.Expect('current after next', 'curr 2/51');
        Observer.Verify();
    end;

    local procedure Row(var L: TestPage "LT Y5 GK2 Key List"): Text
    begin
        exit(L.Grp.Value() + '/' + L.No.Value());
    end;

    local procedure InsertRows()
    var
        GkRow: Record "LT Y5 GK2 Row";
        G: Integer;
        I: Integer;
    begin
        GkRow.DeleteAll();
        for G := 1 to 2 do
            for I := 1 to 60 do begin
                GkRow.Grp := G;
                GkRow.No := I;
                GkRow.Insert();
            end;
    end;
}
