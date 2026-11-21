// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-provider-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); PVD Header (69140), PVD Line (69141), PVD Detail (69142); the log, part and host pages of
//   ProviderLinkedPartsMatrix.al (65401..65413); test codeunit 65415
// Probe: what the part linked to a Provider part shows when the Provider shows no row, while a row of the linked table holds the blank link
//   value (Line Ref = 0, the Line No. of an empty Line). ProviderLinkedPartsMatrix.al pins the same chains with no such row (a decoy with
//   Line Ref = 1 only). Hosts: Card (Provider in Content, linked part in FactBoxes; both shown and the Provider hidden), Document, ListPlus,
//   and a Card whose page extension adds both parts to FactBoxes. Moves: GoToKey, GoToRecord and Next of the host onto a header without lines.
// Expected (al-runner pages parts finding): the linked part shows no row; First on it answers No.
// local object: the host pages of ProviderLinkedPartsMatrix.al are the fixtures under test.
// BC versions: 27, 28, 29

codeunit 65415 "LT PV Provider Blank Link"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PV Log";

    local procedure Seed()
    var
        Header: Record "PVD Header";
        Line: Record "PVD Line";
        Detail: Record "PVD Detail";
    begin
        Detail.DeleteAll();
        Line.DeleteAll();
        Header.DeleteAll();
        InsertHeader('H1');
        InsertHeader('H2');
        InsertLine('H1', 10);
        InsertLine('H1', 20);
        InsertDetail(1, 10, 'ten');
        InsertDetail(2, 20, 'twenty');
        InsertDetail(3, 1, 'decoy');
        InsertDetail(4, 0, 'zero');
    end;

    local procedure InsertHeader(No: Code[20])
    var
        Header: Record "PVD Header";
    begin
        Header.Init();
        Header."No." := No;
        Header."Line No." := 1;
        Header.Insert();
    end;

    local procedure InsertLine(HeaderNo: Code[20]; LineNo: Integer)
    var
        Line: Record "PVD Line";
    begin
        Line.Init();
        Line."Header No." := HeaderNo;
        Line."Line No." := LineNo;
        Line.Insert();
    end;

    local procedure InsertDetail(EntryNo: Integer; LineRef: Integer; Info: Text[30])
    var
        Detail: Record "PVD Detail";
    begin
        Detail.Init();
        Detail."Entry No." := EntryNo;
        Detail."Line Ref" := LineRef;
        Detail.Info := Info;
        Detail.Insert();
    end;

    [Test]
    procedure Card_OpenView_GoToKeyEmptyProvider()
    var
        Card: TestPage "LT PV Host";
    begin
        Seed();
        Log.Reset('both');
        Card.OpenView();
        Card.GoToKey('H2');
        Observer.Observe('h2', 'detail=[' + Card.Detail.Info.Value + ']');
        Observer.Observe('first', Format(Card.Detail.First()) + ' detail=[' + Card.Detail.Info.Value + ']');
        Card.Close();
        Observer.Expect('h2', 'detail=[]');
        Observer.Expect('first', 'No detail=[]');
        Observer.Verify();
    end;

    [Test]
    procedure Card_OpenEdit_GoToKeyEmptyProvider()
    var
        Card: TestPage "LT PV Host";
    begin
        Seed();
        Log.Reset('both');
        Card.OpenEdit();
        Card.GoToKey('H2');
        Observer.Observe('h2', 'detail=[' + Card.Detail.Info.Value + ']');
        Observer.Observe('first', Format(Card.Detail.First()) + ' detail=[' + Card.Detail.Info.Value + ']');
        Card.Close();
        Observer.Expect('h2', 'detail=[]');
        Observer.Expect('first', 'No detail=[]');
        Observer.Verify();
    end;

    [Test]
    procedure Card_OpenView_GoToRecordEmptyProvider()
    var
        Header: Record "PVD Header";
        Card: TestPage "LT PV Host";
    begin
        Seed();
        Log.Reset('both');
        Card.OpenView();
        Header.Get('H2');
        Card.GoToRecord(Header);
        Observer.Observe('h2', 'detail=[' + Card.Detail.Info.Value + ']');
        Observer.Observe('first', Format(Card.Detail.First()) + ' detail=[' + Card.Detail.Info.Value + ']');
        Card.Close();
        Observer.Expect('h2', 'detail=[]');
        Observer.Expect('first', 'No detail=[]');
        Observer.Verify();
    end;

    [Test]
    procedure Card_OpenView_NextEmptyProvider()
    var
        Card: TestPage "LT PV Host";
    begin
        Seed();
        Log.Reset('both');
        Card.OpenView();
        Card.GoToKey('H1');
        Observer.Observe('next', Format(Card.Next()));
        Observer.Observe('h2', 'detail=[' + Card.Detail.Info.Value + ']');
        Observer.Observe('first', Format(Card.Detail.First()) + ' detail=[' + Card.Detail.Info.Value + ']');
        Card.Close();
        Observer.Expect('next', 'Yes');
        Observer.Expect('h2', 'detail=[]');
        Observer.Expect('first', 'No detail=[]');
        Observer.Verify();
    end;

    [Test]
    procedure Card_ProviderHidden_GoToKeyEmptyProvider()
    var
        Card: TestPage "LT PV Host";
    begin
        Seed();
        Log.Reset('hidden-provider');
        Card.OpenView();
        Card.GoToKey('H2');
        Observer.Observe('h2', 'detail=[' + Card.Detail.Info.Value + ']');
        Observer.Observe('first', Format(Card.Detail.First()) + ' detail=[' + Card.Detail.Info.Value + ']');
        Card.Close();
        Observer.Expect('h2', 'detail=[]');
        Observer.Expect('first', 'No detail=[]');
        Observer.Verify();
    end;

    [Test]
    procedure Document_OpenView_GoToKeyEmptyProvider()
    var
        Card: TestPage "LT PV Host Document";
    begin
        Seed();
        Log.Reset('both');
        Card.OpenView();
        Card.GoToKey('H2');
        Observer.Observe('h2', 'detail=[' + Card.Detail.Info.Value + ']');
        Observer.Observe('first', Format(Card.Detail.First()) + ' detail=[' + Card.Detail.Info.Value + ']');
        Card.Close();
        Observer.Expect('h2', 'detail=[]');
        Observer.Expect('first', 'No detail=[]');
        Observer.Verify();
    end;

    [Test]
    procedure ListPlus_OpenView_GoToKeyEmptyProvider()
    var
        Card: TestPage "LT PV Host ListPlus";
    begin
        Seed();
        Log.Reset('both');
        Card.OpenView();
        Card.GoToKey('H2');
        Observer.Observe('h2', 'detail=[' + Card.Detail.Info.Value + ']');
        Observer.Observe('first', Format(Card.Detail.First()) + ' detail=[' + Card.Detail.Info.Value + ']');
        Card.Close();
        Observer.Expect('h2', 'detail=[]');
        Observer.Expect('first', 'No detail=[]');
        Observer.Verify();
    end;

    [Test]
    procedure ExtFactBoxes_OpenView_GoToKeyEmptyProvider()
    var
        Card: TestPage "LT PV Host Base";
    begin
        Seed();
        Log.Reset('both');
        Card.OpenView();
        Card.GoToKey('H2');
        Observer.Observe('h2', 'detail=[' + Card.Detail.Info.Value + ']');
        Observer.Observe('first', Format(Card.Detail.First()) + ' detail=[' + Card.Detail.Info.Value + ']');
        Card.Close();
        Observer.Expect('h2', 'detail=[]');
        Observer.Expect('first', 'No detail=[]');
        Observer.Verify();
    end;
}
