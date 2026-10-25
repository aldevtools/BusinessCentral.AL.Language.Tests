// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onopenpage-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT RZ Demand Line / Demand Ws / Demand Runner / Log Mgt (RzFixtures.al, writer RZ)
// Probe: a database Worksheet opened without a record whose OnOpenPage fills the table, sets a SECONDARY key, leaves Rec on a row and then
//   filters Level = 1 (the shape of page 1328 "Purch. Order From Sales Order", al-runner issue 5825). Rec before the view, inside it (first row
//   and not), between two rows of the view, after it, and on a row that is before the view by the secondary key but after it by the primary key.
//   Routes: lookup RunModal (handler reads the shown row and invokes OK, GetRecord), RunModal, TestPage OpenEdit and OpenView.
//   The same in the primary key is pinned in pages/lt-outside-worksheet-2/RtFillOnOpen.al.
// Result (BC 29.0, Windows container): the page opens on the row Find('=><') from Rec reaches in the SECONDARY key (Item Code), on every
//   route: HDR (before the view) -> X; Y (inside) -> Y; ZZZ (after) -> Y; XM (between X and Y) -> Y; TRL (before by Item Code, after by
//   Line No.) -> X. A lookup returns that row with LookupOK.
// Object ids 88921 (writer RZ).
// BC versions: 27, 28, 29

codeunit 88921 "LT RZ Ws Secondary Key Open"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        // Global so the helpers and handlers can record; every test starts with Discard (a failed test leaves no pairs behind).
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RZ Log Mgt";

    // Lookup mode, run modally (the reporter's route), one test per mode of LT RZ Demand Ws.
    [Test]
    [HandlerFunctions('PickShownHandler')]
    procedure RZ_Lookup_RecBeforeView()
    begin
        Lookup(1);
        Observer.Expect('open', 'X');
        Observer.Expect('open log', 'O:HDR;R:HDR;R:X;R:Y;R:X;R:X;R:X;C:X');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('picked', 'X');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickShownHandler')]
    procedure RZ_Lookup_RecInsideView()
    begin
        Lookup(2);
        Observer.Expect('open', 'Y');
        Observer.Expect('open log', 'O:Y;R:Y;R:Y;R:X;R:Y;R:Y;R:Y;C:Y');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('picked', 'Y');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickShownHandler')]
    procedure RZ_Lookup_RecAfterView()
    begin
        Lookup(3);
        Observer.Expect('open', 'Y');
        Observer.Expect('open log', 'O:ZZZ;R:ZZZ;R:Y;R:X;R:Y;R:Y;R:Y;C:Y');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('picked', 'Y');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickShownHandler')]
    procedure RZ_Lookup_RecBetweenViewRows()
    begin
        Lookup(4);
        Observer.Expect('open', 'Y');
        Observer.Expect('open log', 'O:XM;R:XM;R:Y;R:X;R:Y;R:Y;R:Y;C:Y');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('picked', 'Y');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickShownHandler')]
    procedure RZ_Lookup_RecBeforeBySecondaryAfterByPrimary()
    begin
        Lookup(5);
        Observer.Expect('open', 'X');
        Observer.Expect('open log', 'O:TRL;R:TRL;R:X;R:Y;R:X;R:X;R:X;C:X');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('picked', 'X');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickShownHandler')]
    procedure RZ_Lookup_RecFirstOfView()
    begin
        Lookup(6);
        Observer.Expect('open', 'X');
        Observer.Expect('open log', 'O:X;R:X;R:X;R:Y;R:X;R:X;R:X;C:X');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('picked', 'X');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    // Run modally, not in lookup mode.
    [Test]
    [HandlerFunctions('MovesHandler')]
    procedure RZ_RunModal_RecBeforeView()
    begin
        RunModalPlain(1);
        Observer.Expect('open', 'X');
        Observer.Expect('open log', 'O:HDR;R:HDR;R:X;R:Y;R:X;R:X;R:X;C:X');
        Observer.Expect('next', 'Yes|Y');
        Observer.Expect('previous', 'Yes|X');
        Observer.Expect('previous again', 'No|X');
        Observer.Expect('rows', 'X,Y,');
        Observer.Expect('result', 'OK');
        Observer.Expect('after close log', 'R:Y;R:Y;R:Y;C:Y;R:X;R:X;R:X;C:X;R:Y;R:Y;R:Y;C:Y');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MovesHandler')]
    procedure RZ_RunModal_RecBetweenViewRows()
    begin
        RunModalPlain(4);
        Observer.Expect('open', 'Y');
        Observer.Expect('open log', 'O:XM;R:XM;R:Y;R:X;R:Y;R:Y;R:Y;C:Y');
        Observer.Expect('next', 'No|Y');
        Observer.Expect('previous', 'Yes|X');
        Observer.Expect('previous again', 'No|X');
        Observer.Expect('rows', 'X,Y,');
        Observer.Expect('result', 'OK');
        Observer.Expect('after close log', 'R:X;R:X;R:X;C:X;R:Y;R:Y;R:Y;C:Y');
        Observer.Verify();
    end;

    // TestPage OpenEdit and OpenView.
    [Test]
    procedure RZ_OpenEdit_RecBeforeView()
    begin
        OpenEdit(1);
        Observer.Expect('open', 'X');
        Observer.Expect('open log', 'O:HDR;R:HDR;R:X;R:Y;R:X;R:X;R:X;C:X');
        Observer.Expect('next', 'Yes|Y');
        Observer.Expect('previous', 'Yes|X');
        Observer.Expect('previous again', 'No|X');
        Observer.Expect('rows', 'X,Y,');
        Observer.Verify();
    end;

    [Test]
    procedure RZ_OpenEdit_RecInsideView()
    begin
        OpenEdit(2);
        Observer.Expect('open', 'Y');
        Observer.Expect('open log', 'O:Y;R:Y;R:Y;R:X;R:Y;R:Y;R:Y;C:Y');
        Observer.Expect('next', 'No|Y');
        Observer.Expect('previous', 'Yes|X');
        Observer.Expect('previous again', 'No|X');
        Observer.Expect('rows', 'X,Y,');
        Observer.Verify();
    end;

    [Test]
    procedure RZ_OpenEdit_RecAfterView()
    begin
        OpenEdit(3);
        Observer.Expect('open', 'Y');
        Observer.Expect('open log', 'O:ZZZ;R:ZZZ;R:Y;R:X;R:Y;R:Y;R:Y;C:Y');
        Observer.Expect('next', 'No|Y');
        Observer.Expect('previous', 'Yes|X');
        Observer.Expect('previous again', 'No|X');
        Observer.Expect('rows', 'X,Y,');
        Observer.Verify();
    end;

    [Test]
    procedure RZ_OpenEdit_RecBetweenViewRows()
    begin
        OpenEdit(4);
        Observer.Expect('open', 'Y');
        Observer.Expect('open log', 'O:XM;R:XM;R:Y;R:X;R:Y;R:Y;R:Y;C:Y');
        Observer.Expect('next', 'No|Y');
        Observer.Expect('previous', 'Yes|X');
        Observer.Expect('previous again', 'No|X');
        Observer.Expect('rows', 'X,Y,');
        Observer.Verify();
    end;

    [Test]
    procedure RZ_OpenEdit_RecBeforeBySecondaryAfterByPrimary()
    begin
        OpenEdit(5);
        Observer.Expect('open', 'X');
        Observer.Expect('open log', 'O:TRL;R:TRL;R:X;R:Y;R:X;R:X;R:X;C:X');
        Observer.Expect('next', 'Yes|Y');
        Observer.Expect('previous', 'Yes|X');
        Observer.Expect('previous again', 'No|X');
        Observer.Expect('rows', 'X,Y,');
        Observer.Verify();
    end;

    [Test]
    procedure RZ_OpenView_RecBeforeView()
    begin
        OpenView(1);
        Observer.Expect('open', 'X');
        Observer.Expect('open log', 'O:HDR;R:HDR;R:X;R:Y;R:X;R:X;R:X;C:X');
        Observer.Expect('next', 'Yes|Y');
        Observer.Expect('previous', 'Yes|X');
        Observer.Expect('previous again', 'No|X');
        Observer.Expect('rows', 'X,Y,');
        Observer.Verify();
    end;

    [Test]
    procedure RZ_OpenView_RecAfterView()
    begin
        OpenView(3);
        Observer.Expect('open', 'Y');
        Observer.Expect('open log', 'O:ZZZ;R:ZZZ;R:Y;R:X;R:Y;R:Y;R:Y;C:Y');
        Observer.Expect('next', 'No|Y');
        Observer.Expect('previous', 'Yes|X');
        Observer.Expect('previous again', 'No|X');
        Observer.Expect('rows', 'X,Y,');
        Observer.Verify();
    end;

    local procedure Lookup(Mode: Integer)
    var
        Picked: Record "LT RZ Demand Line";
        Runner: Codeunit "LT RZ Demand Runner";
    begin
        Observer.Discard();
        Log.Clear();
        Observer.Observe('result', Format(Runner.RunLookup(Mode, Picked)));
        Observer.Observe('picked', Picked."Item Code");
        Observer.Observe('after close log', Log.Take());
    end;

    local procedure RunModalPlain(Mode: Integer)
    var
        Runner: Codeunit "LT RZ Demand Runner";
    begin
        Observer.Discard();
        Log.Clear();
        Observer.Observe('result', Format(Runner.RunModalPlain(Mode)));
        Observer.Observe('after close log', Log.Take());
    end;

    local procedure OpenEdit(Mode: Integer)
    var
        Ws: TestPage "LT RZ Demand Ws";
    begin
        Observer.Discard();
        Log.SetMode(Mode);
        Log.Clear();
        Ws.OpenEdit();
        Observe(Ws);
        Ws.Close();
    end;

    local procedure OpenView(Mode: Integer)
    var
        Ws: TestPage "LT RZ Demand Ws";
    begin
        Observer.Discard();
        Log.SetMode(Mode);
        Log.Clear();
        Ws.OpenView();
        Observe(Ws);
        Ws.Close();
    end;

    local procedure Observe(var Ws: TestPage "LT RZ Demand Ws")
    begin
        Observer.Observe('open', Ws."Item Code".Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(Ws.Next()) + '|' + Ws."Item Code".Value());
        Observer.Observe('previous', Format(Ws.Previous()) + '|' + Ws."Item Code".Value());
        Observer.Observe('previous again', Format(Ws.Previous()) + '|' + Ws."Item Code".Value());
        Observer.Observe('rows', Rows(Ws));
    end;

    local procedure Rows(var Ws: TestPage "LT RZ Demand Ws") Result: Text
    begin
        if Ws.First() then
            repeat
                Result += Ws."Item Code".Value() + ',';
            until not Ws.Next();
    end;

    [ModalPageHandler]
    procedure PickShownHandler(var Ws: TestPage "LT RZ Demand Ws")
    begin
        Observer.Observe('open', Ws."Item Code".Value());
        Observer.Observe('open log', Log.Take());
        Ws.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure MovesHandler(var Ws: TestPage "LT RZ Demand Ws")
    begin
        Observe(Ws);
    end;
}
