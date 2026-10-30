// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotokey-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 90985 (writer Y5)
// Probe: written against SaaS BC 29 and the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: al-runner issue 6381. A List page over a table keyed (Grp, No) with 60 rows in each of groups 1 and 2. OnOpenPage
//   sets Rec.SetRange(Grp, 1). Action NextGroup runs Rec.SetRange(Grp, 2); Rec.FindFirst(); CurrPage.Update(false).
//   Action OnlyFilter runs only Rec.SetRange(Grp, 2). After the action the test calls GoToKey on a row of group 2 that the
//   page has not read yet, and GoToKey on a row of group 1 (now outside the filter). Read through a ModalPageHandler
//   (the reporter's shape) and through TestPage.OpenView.
// Result: OBSERVED_RESULT
// Source: al-runner issue 6381.
// BC versions: 27, 28, 29

table 90985 "LT Y5 GK Row"
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
    }
}

page 90985 "LT Y5 GK List"
{
    PageType = List;
    SourceTable = "LT Y5 GK Row";
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
            action(OnlyFilter)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.SetRange(Grp, 2);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Grp, 1);
    end;
}

codeunit 90985 "LT Y5 GK Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerLog: Text;

    [Test]
    [HandlerFunctions('Y5ListHandler')]
    procedure Y5_GoToKeyAfterActionFilter_InModalHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        InsertRows();
        HandlerLog := '';
        Page.RunModal(Page::"LT Y5 GK List");
        Observer.Observe('handler log', HandlerLog);
        Observer.Expect('handler log', 'goto 1,50=Yes;after action=2/1;goto 2,50=Yes;row=2/50;');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure Y5ListHandler(var L: TestPage "LT Y5 GK List")
    begin
        HandlerLog += 'goto 1,50=' + Format(L.GoToKey(1, 50)) + ';';
        L.NextGroup.Invoke();
        HandlerLog += 'after action=' + L.Grp.Value() + '/' + L.No.Value() + ';';
        HandlerLog += 'goto 2,50=' + Format(L.GoToKey(2, 50)) + ';';
        HandlerLog += 'row=' + L.Grp.Value() + '/' + L.No.Value() + ';';
    end;

    [Test]
    procedure Y5_GoToKeyAfterActionFilter_NextGroup()
    var
        L: TestPage "LT Y5 GK List";
        Observer: Codeunit "Probe Observer";
    begin
        InsertRows();
        L.OpenView();
        Observer.Observe('goto 1,50', Format(L.GoToKey(1, 50)));
        L.NextGroup.Invoke();
        Observer.Observe('row after action', L.Grp.Value() + '/' + L.No.Value());
        Observer.Observe('goto 2,50', Format(L.GoToKey(2, 50)));
        Observer.Observe('row', L.Grp.Value() + '/' + L.No.Value());
        Observer.Observe('next', Format(L.Next()));
        Observer.Observe('row after next', L.Grp.Value() + '/' + L.No.Value());
        Observer.Observe('previous', Format(L.Previous()));
        Observer.Observe('previous', Format(L.Previous()));
        Observer.Observe('row after two previous', L.Grp.Value() + '/' + L.No.Value());
        Observer.Observe('goto 2,10', Format(L.GoToKey(2, 10)));
        Observer.Observe('row 2,10', L.Grp.Value() + '/' + L.No.Value());
        Observer.Observe('first', Format(L.First()));
        Observer.Observe('row first', L.Grp.Value() + '/' + L.No.Value());
        Observer.Observe('last', Format(L.Last()));
        Observer.Observe('row last', L.Grp.Value() + '/' + L.No.Value());
        L.Close();
        Observer.Expect('goto 1,50', 'Yes');
        Observer.Expect('row after action', '2/1');
        Observer.Expect('goto 2,50', 'Yes');
        Observer.Expect('row', '2/50');
        Observer.Expect('next', 'Yes');
        Observer.Expect('row after next', '2/51');
        Observer.Expect('previous', 'Yes');
        Observer.Expect('previous', 'Yes');
        Observer.Expect('row after two previous', '2/49');
        Observer.Expect('goto 2,10', 'Yes');
        Observer.Expect('row 2,10', '2/10');
        Observer.Expect('first', 'Yes');
        Observer.Expect('row first', '2/1');
        Observer.Expect('last', 'Yes');
        Observer.Expect('row last', '2/60');
        Observer.Verify();
    end;

    [Test]
    procedure Y5_GoToKeyAfterActionFilter_RowOutsideTheNewFilter()
    var
        L: TestPage "LT Y5 GK List";
        Observer: Codeunit "Probe Observer";
    begin
        InsertRows();
        L.OpenView();
        L.NextGroup.Invoke();
        Observer.Observe('goto 1,50', Format(L.GoToKey(1, 50)));
        Observer.Observe('row', L.Grp.Value() + '/' + L.No.Value());
        L.Close();
        Observer.Expect('goto 1,50', 'No');
        Observer.Expect('row', '2/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y5_GoToKeyAfterActionFilter_OnlySetRange()
    var
        L: TestPage "LT Y5 GK List";
        Observer: Codeunit "Probe Observer";
    begin
        InsertRows();
        L.OpenView();
        Observer.Observe('goto 1,50', Format(L.GoToKey(1, 50)));
        L.OnlyFilter.Invoke();
        Observer.Observe('row after action', L.Grp.Value() + '/' + L.No.Value());
        Observer.Observe('goto 2,50', Format(L.GoToKey(2, 50)));
        Observer.Observe('row', L.Grp.Value() + '/' + L.No.Value());
        Observer.Observe('goto 1,40', Format(L.GoToKey(1, 40)));
        Observer.Observe('row after goto 1,40', L.Grp.Value() + '/' + L.No.Value());
        L.Close();
        Observer.Expect('goto 1,50', 'Yes');
        Observer.Expect('row after action', '2/1');
        Observer.Expect('goto 2,50', 'Yes');
        Observer.Expect('row', '2/50');
        Observer.Expect('goto 1,40', 'No');
        Observer.Expect('row after goto 1,40', '2/50');
        Observer.Verify();
    end;

    local procedure InsertRows()
    var
        Row: Record "LT Y5 GK Row";
        G: Integer;
        I: Integer;
    begin
        Row.DeleteAll();
        for G := 1 to 2 do
            for I := 1 to 60 do begin
                Row.Grp := G;
                Row.No := I;
                Row.Insert();
            end;
    end;
}
