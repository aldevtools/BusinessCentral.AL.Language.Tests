// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); NewRowListFixtures.al (table 72900, page 72901); test codeunit 72904
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: RunModal over a record filtered on one field with SetCurrentKey on a secondary key; the handler loops repeat ... until Next() = false: row count, the rows in order, the Next() result of the last step, whether a blank line follows the last row
// BC versions: 29 (27 and 28 by CI)

codeunit 72904 "LT NewRow SecKey Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Rows: Integer;
        Seen: Text;
        LastNext: Boolean;
        FirstOk: Boolean;
        LastId: Text;
        NextAfter: Boolean;

    local procedure Seed()
    var
        R: Record "LT NewRow Ref";
    begin
        R.DeleteAll();
        Rows := 0;
        Seen := '';
        Add(1, 2, 'B1');
        Add(2, 1, 'Z9');
        Add(3, 1, 'A5');
        Add(4, 2, 'A1');
        Add(5, 1, 'M3');
    end;

    local procedure Add(Id: Integer; RefType: Integer; RefNo: Code[20])
    var
        R: Record "LT NewRow Ref";
    begin
        R.Init();
        R.Id := Id;
        R.RefType := RefType;
        R.RefNo := RefNo;
        R.Descr := 'D' + Format(Id);
        R.Insert();
    end;

    local procedure Report(var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('first', Format(FirstOk));
        Observer.Observe('rows', Format(Rows));
        Observer.Observe('seen', Seen);
        Observer.Observe('lastNext', Format(LastNext));
        Observer.Observe('lastId', LastId);
        Observer.Observe('nextAfter', Format(NextAfter));
    end;

    [Test]
    [HandlerFunctions('LoopHandler')]
    procedure P197_SecKey_FilterOneField_SetCurrentKey()
    var
        R: Record "LT NewRow Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetCurrentKey(RefType, RefNo);
        R.SetRange(RefType, 1);
        Page.RunModal(Page::"LT NewRow Ref List", R);
        Report(Observer);
        Observer.Expect('first', 'Yes');
        Observer.Expect('rows', '4');
        Observer.Expect('seen', '[3/1/A5][5/1/M3][2/1/Z9][0/0/]');
        Observer.Expect('lastNext', 'No');
        Observer.Expect('lastId', '0');
        Observer.Expect('nextAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoopHandler')]
    procedure P197_SecKey_FilterOneField_NoSetCurrentKey()
    var
        R: Record "LT NewRow Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetRange(RefType, 1);
        Page.RunModal(Page::"LT NewRow Ref List", R);
        Report(Observer);
        Observer.Expect('first', 'Yes');
        Observer.Expect('rows', '4');
        Observer.Expect('seen', '[2/1/Z9][3/1/A5][5/1/M3][0/0/]');
        Observer.Expect('lastNext', 'No');
        Observer.Expect('lastId', '0');
        Observer.Expect('nextAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoopHandler')]
    procedure P197_SecKey_NoFilter_SetCurrentKey()
    var
        R: Record "LT NewRow Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetCurrentKey(RefType, RefNo);
        Page.RunModal(Page::"LT NewRow Ref List", R);
        Report(Observer);
        Observer.Expect('first', 'Yes');
        Observer.Expect('rows', '6');
        Observer.Expect('seen', '[3/1/A5][5/1/M3][2/1/Z9][4/2/A1][1/2/B1][0/0/]');
        Observer.Expect('lastNext', 'No');
        Observer.Expect('lastId', '0');
        Observer.Expect('nextAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoopHandler')]
    procedure P197_SecKey_Descending()
    var
        R: Record "LT NewRow Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetCurrentKey(RefType, RefNo);
        R.Ascending(false);
        R.SetRange(RefType, 1);
        Page.RunModal(Page::"LT NewRow Ref List", R);
        Report(Observer);
        Observer.Expect('first', 'Yes');
        Observer.Expect('rows', '4');
        Observer.Expect('seen', '[2/1/Z9][5/1/M3][3/1/A5][0/0/]');
        Observer.Expect('lastNext', 'No');
        Observer.Expect('lastId', '0');
        Observer.Expect('nextAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoopHandler')]
    procedure P197_SecKey_FilterOtherField_SetCurrentKey()
    var
        R: Record "LT NewRow Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetCurrentKey(RefType, RefNo);
        R.SetFilter(Id, '>=3');
        Page.RunModal(Page::"LT NewRow Ref List", R);
        Report(Observer);
        Observer.Expect('first', 'Yes');
        Observer.Expect('rows', '4');
        Observer.Expect('seen', '[3/1/A5][5/1/M3][4/2/A1][0/0/]');
        Observer.Expect('lastNext', 'No');
        Observer.Expect('lastId', '0');
        Observer.Expect('nextAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoopHandler')]
    procedure P197_SecKey_TwoFieldFilters()
    var
        R: Record "LT NewRow Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetCurrentKey(RefType, RefNo);
        R.SetRange(RefType, 1);
        R.SetFilter(RefNo, 'A*|M*');
        Page.RunModal(Page::"LT NewRow Ref List", R);
        Report(Observer);
        Observer.Expect('first', 'Yes');
        Observer.Expect('rows', '3');
        Observer.Expect('seen', '[3/1/A5][5/1/M3][0/0/]');
        Observer.Expect('lastNext', 'No');
        Observer.Expect('lastId', '0');
        Observer.Expect('nextAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoopHandler')]
    procedure P197_SecKey_FilterMatchesNothing()
    var
        R: Record "LT NewRow Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetCurrentKey(RefType, RefNo);
        R.SetRange(RefType, 99);
        Page.RunModal(Page::"LT NewRow Ref List", R);
        Report(Observer);
        Observer.Expect('first', 'No');
        Observer.Expect('rows', '0');
        Observer.Expect('seen', '');
        Observer.Expect('lastNext', 'No');
        Observer.Expect('lastId', '0');
        Observer.Expect('nextAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoopHandler')]
    procedure P197_SecKey_PositionedAfterFindFirst()
    var
        R: Record "LT NewRow Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetCurrentKey(RefType, RefNo);
        R.SetRange(RefType, 1);
        Observer.Observe('findfirst', Format(R.FindFirst()));
        Observer.Observe('pos', R.RefNo);
        Page.RunModal(Page::"LT NewRow Ref List", R);
        Report(Observer);
        Observer.Expect('findfirst', 'Yes');
        Observer.Expect('pos', 'A5');
        Observer.Expect('first', 'Yes');
        Observer.Expect('rows', '4');
        Observer.Expect('seen', '[3/1/A5][5/1/M3][2/1/Z9][0/0/]');
        Observer.Expect('lastNext', 'No');
        Observer.Expect('lastId', '0');
        Observer.Expect('nextAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoopHandler')]
    procedure P197_SecKey_PositionedAfterFindLast()
    var
        R: Record "LT NewRow Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetCurrentKey(RefType, RefNo);
        R.SetRange(RefType, 1);
        Observer.Observe('findlast', Format(R.FindLast()));
        Observer.Observe('pos', R.RefNo);
        Page.RunModal(Page::"LT NewRow Ref List", R);
        Report(Observer);
        Observer.Expect('findlast', 'Yes');
        Observer.Expect('pos', 'Z9');
        Observer.Expect('first', 'Yes');
        Observer.Expect('rows', '4');
        Observer.Expect('seen', '[3/1/A5][5/1/M3][2/1/Z9][0/0/]');
        Observer.Expect('lastNext', 'No');
        Observer.Expect('lastId', '0');
        Observer.Expect('nextAfter', 'No');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure LoopHandler(var P: TestPage "LT NewRow Ref List")
    begin
        Rows := 0;
        Seen := '';
        FirstOk := P.First();
        if FirstOk then
            repeat
                Rows += 1;
                Seen += '[' + P.IdF.Value() + '/' + P.TypeF.Value() + '/' + P.NoF.Value() + ']';
                LastNext := P.Next();
            until LastNext = false;
        LastId := P.IdF.Value();
        NextAfter := P.Next();
    end;
}
