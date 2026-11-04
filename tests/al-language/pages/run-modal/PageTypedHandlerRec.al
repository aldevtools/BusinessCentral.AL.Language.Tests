// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 74880, page 74881, test codeunit 74884
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: a ModalPageHandler typed as the page (var P: Page X).
//   (1) A page procedure does Rec := X after the test called SetTableView, then RunModal: the handler reads Rec (Id and Name) through a page procedure, for X inside and
//   outside the view. Settles typed-handler-keeps-rec-after-settableview.
//   (2) The handler calls P.SetRecord(R2) and answers LookupOK: the record handed to Page.RunModal(PageId, Rec) and the one read by P.GetRecord afterwards;
//   the same with Cancel, with LookupOK and no SetRecord, and with LookupMode(true) on a page variable. Settles typed-handler-lookupok-hands-back-rec.
// BC versions: all (CI)

table 74880 "LT THR Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 74881 "LT THR List"
{
    PageType = List;
    SourceTable = "LT THR Row";
    ApplicationArea = All;
    UsageCategory = None;

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

    procedure AssignRec(Row: Record "LT THR Row")
    begin
        Rec := Row;
    end;

    procedure RecText(): Text
    begin
        exit(Format(Rec.Id) + '/' + Rec.Name);
    end;
}

codeunit 74884 "LT THR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        Mode: Text;
        Reply: Action;
        ToSet: Record "LT THR Row";

    local procedure Seed()
    var
        Row: Record "LT THR Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 5 do begin
            Row.Id := i;
            Row.Name := 'row' + Format(i);
            Row.Insert();
        end;
    end;

    [ModalPageHandler]
    procedure ReadRecHandler(var P: Page "LT THR List"; var Response: Action)
    begin
        Obs.Observe('handlerRec', P.RecText());
        Response := Action::Cancel;
    end;

    [ModalPageHandler]
    procedure SetRecordHandler(var P: Page "LT THR List"; var Response: Action)
    begin
        Obs.Observe('handlerRecBefore', P.RecText());
        if Mode = 'set' then
            P.SetRecord(ToSet);
        Obs.Observe('handlerRecAfter', P.RecText());
        Response := Reply;
    end;

    [Test]
    [HandlerFunctions('ReadRecHandler')]
    procedure SettableView_ThenAssignRecInsideView()
    var
        View: Record "LT THR Row";
        Target: Record "LT THR Row";
        P: Page "LT THR List";
    begin
        Seed();
        View.SetFilter(Id, '>=2');
        P.SetTableView(View);
        Target.Get(4);
        P.AssignRec(Target);
        P.RunModal();
        Obs.Expect('handlerRec', '4/row4');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('ReadRecHandler')]
    procedure SettableView_ThenAssignRecOutsideView()
    var
        View: Record "LT THR Row";
        Target: Record "LT THR Row";
        P: Page "LT THR List";
    begin
        Seed();
        View.SetFilter(Id, '>=2');
        P.SetTableView(View);
        Target.Get(1);
        P.AssignRec(Target);
        P.RunModal();
        Obs.Expect('handlerRec', '1/row1');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('ReadRecHandler')]
    procedure NoSettableView_AssignRec()
    var
        Target: Record "LT THR Row";
        P: Page "LT THR List";
    begin
        Seed();
        Target.Get(3);
        P.AssignRec(Target);
        P.RunModal();
        Obs.Expect('handlerRec', '3/row3');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('SetRecordHandler')]
    procedure RunModalWithRecord_HandlerSetRecord_LookupOK()
    var
        Row: Record "LT THR Row";
        Act: Action;
    begin
        Seed();
        Mode := 'set';
        Reply := Action::LookupOK;
        Row.Get(1);
        ToSet.Get(4);
        Act := Page.RunModal(Page::"LT THR List", Row);
        Obs.Observe('action', Format(Act));
        Obs.Observe('rowAfter', Format(Row.Id) + '/' + Row.Name);
        Obs.Expect('handlerRecBefore', '1/row1');
        Obs.Expect('handlerRecAfter', '4/row4');
        Obs.Expect('action', 'LookupOK');
        Obs.Expect('rowAfter', '4/row4');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('SetRecordHandler')]
    procedure RunModalWithRecord_HandlerSetRecord_Cancel()
    var
        Row: Record "LT THR Row";
        Act: Action;
    begin
        Seed();
        Mode := 'set';
        Reply := Action::Cancel;
        Row.Get(1);
        ToSet.Get(4);
        Act := Page.RunModal(Page::"LT THR List", Row);
        Obs.Observe('action', Format(Act));
        Obs.Observe('rowAfter', Format(Row.Id) + '/' + Row.Name);
        Obs.Expect('handlerRecBefore', '1/row1');
        Obs.Expect('handlerRecAfter', '4/row4');
        Obs.Expect('action', 'Cancel');
        Obs.Expect('rowAfter', '1/row1');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('SetRecordHandler')]
    procedure RunModalWithRecord_NoSetRecord_LookupOK()
    var
        Row: Record "LT THR Row";
        Act: Action;
    begin
        Seed();
        Mode := 'none';
        Reply := Action::LookupOK;
        Row.Get(2);
        Act := Page.RunModal(Page::"LT THR List", Row);
        Obs.Observe('action', Format(Act));
        Obs.Observe('rowAfter', Format(Row.Id) + '/' + Row.Name);
        Obs.Expect('handlerRecBefore', '2/row2');
        Obs.Expect('handlerRecAfter', '2/row2');
        Obs.Expect('action', 'LookupOK');
        Obs.Expect('rowAfter', '2/row2');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('SetRecordHandler')]
    procedure PageVariable_LookupMode_HandlerSetRecord_LookupOK()
    var
        Row: Record "LT THR Row";
        Out: Record "LT THR Row";
        P: Page "LT THR List";
        Act: Action;
    begin
        Seed();
        Mode := 'set';
        Reply := Action::LookupOK;
        Row.Get(1);
        ToSet.Get(5);
        P.LookupMode(true);
        P.SetRecord(Row);
        Act := P.RunModal();
        P.GetRecord(Out);
        Obs.Observe('action', Format(Act));
        Obs.Observe('rowAfter', Format(Row.Id) + '/' + Row.Name);
        Obs.Observe('getRecord', Format(Out.Id) + '/' + Out.Name);
        Obs.Expect('handlerRecBefore', '1/row1');
        Obs.Expect('handlerRecAfter', '5/row5');
        Obs.Expect('action', 'LookupOK');
        Obs.Expect('rowAfter', '1/row1');
        Obs.Expect('getRecord', '5/row5');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('SetRecordHandler')]
    procedure PageVariable_LookupMode_HandlerSetRecord_Cancel()
    var
        Row: Record "LT THR Row";
        Out: Record "LT THR Row";
        P: Page "LT THR List";
        Act: Action;
    begin
        Seed();
        Mode := 'set';
        Reply := Action::Cancel;
        Row.Get(1);
        ToSet.Get(5);
        P.LookupMode(true);
        P.SetRecord(Row);
        Act := P.RunModal();
        P.GetRecord(Out);
        Obs.Observe('action', Format(Act));
        Obs.Observe('getRecord', Format(Out.Id) + '/' + Out.Name);
        Obs.Expect('handlerRecBefore', '1/row1');
        Obs.Expect('handlerRecAfter', '5/row5');
        Obs.Expect('action', 'Cancel');
        Obs.Expect('getRecord', '5/row5');
        Obs.Verify();
    end;
}
