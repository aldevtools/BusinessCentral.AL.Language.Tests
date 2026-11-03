// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); NewRowListFixtures.al (table 72900, page 72901); test codeunit 72905
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: list over a TEMPORARY record in RunModal: is there a blank new-row line after FindFirst, after three Inserts, after a SetRange that leaves 0 rows, with a secondary key and a filter; the Next() result of the last step of repeat ... until Next() = false
// BC versions: 29 (27 and 28 by CI)

codeunit 72905 "LT NewRow Temp Rows"
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

    local procedure SeedTemp(var T: Record "LT NewRow Ref" temporary)
    begin
        T.Reset();
        T.DeleteAll();
        Rows := 0;
        Seen := '';
        Add(T, 1, 2, 'B1');
        Add(T, 2, 1, 'Z9');
        Add(T, 3, 1, 'A5');
    end;

    local procedure Add(var T: Record "LT NewRow Ref" temporary; Id: Integer; RefType: Integer; RefNo: Code[20])
    begin
        T.Init();
        T.Id := Id;
        T.RefType := RefType;
        T.RefNo := RefNo;
        T.Descr := 'D' + Format(Id);
        T.Insert();
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
    procedure P197_Temp_ThreeInserted_NoPosition()
    var
        T: Record "LT NewRow Ref" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        SeedTemp(T);
        Page.RunModal(Page::"LT NewRow Ref List", T);
        Report(Observer);
        Observer.Expect('first', 'Yes');
        Observer.Expect('rows', '4');
        Observer.Expect('seen', '[1/2/B1][2/1/Z9][3/1/A5][0/0/]');
        Observer.Expect('lastNext', 'No');
        Observer.Expect('lastId', '0');
        Observer.Expect('nextAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoopHandler')]
    procedure P197_Temp_AfterFindFirst()
    var
        T: Record "LT NewRow Ref" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        SeedTemp(T);
        Observer.Observe('findfirst', Format(T.FindFirst()));
        Observer.Observe('pos', Format(T.Id));
        Page.RunModal(Page::"LT NewRow Ref List", T);
        Report(Observer);
        Observer.Expect('findfirst', 'Yes');
        Observer.Expect('pos', '1');
        Observer.Expect('first', 'Yes');
        Observer.Expect('rows', '4');
        Observer.Expect('seen', '[1/2/B1][2/1/Z9][3/1/A5][0/0/]');
        Observer.Expect('lastNext', 'No');
        Observer.Expect('lastId', '0');
        Observer.Expect('nextAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoopHandler')]
    procedure P197_Temp_AfterFindLast()
    var
        T: Record "LT NewRow Ref" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        SeedTemp(T);
        Observer.Observe('findlast', Format(T.FindLast()));
        Observer.Observe('pos', Format(T.Id));
        Page.RunModal(Page::"LT NewRow Ref List", T);
        Report(Observer);
        Observer.Expect('findlast', 'Yes');
        Observer.Expect('pos', '3');
        Observer.Expect('first', 'Yes');
        Observer.Expect('rows', '4');
        Observer.Expect('seen', '[1/2/B1][2/1/Z9][3/1/A5][0/0/]');
        Observer.Expect('lastNext', 'No');
        Observer.Expect('lastId', '0');
        Observer.Expect('nextAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoopHandler')]
    procedure P197_Temp_SetRangeLeavesNoRows()
    var
        T: Record "LT NewRow Ref" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        SeedTemp(T);
        T.SetRange(RefType, 99);
        Observer.Observe('isempty', Format(T.IsEmpty()));
        Page.RunModal(Page::"LT NewRow Ref List", T);
        Report(Observer);
        Observer.Expect('isempty', 'Yes');
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
    procedure P197_Temp_SetRangeLeavesOneRow()
    var
        T: Record "LT NewRow Ref" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        SeedTemp(T);
        T.SetRange(RefType, 2);
        Page.RunModal(Page::"LT NewRow Ref List", T);
        Report(Observer);
        Observer.Expect('first', 'Yes');
        Observer.Expect('rows', '2');
        Observer.Expect('seen', '[1/2/B1][0/0/]');
        Observer.Expect('lastNext', 'No');
        Observer.Expect('lastId', '0');
        Observer.Expect('nextAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoopHandler')]
    procedure P197_Temp_SecondaryKeyAndFilter()
    var
        T: Record "LT NewRow Ref" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        SeedTemp(T);
        T.SetCurrentKey(RefType, RefNo);
        T.SetRange(RefType, 1);
        Page.RunModal(Page::"LT NewRow Ref List", T);
        Report(Observer);
        Observer.Expect('first', 'Yes');
        Observer.Expect('rows', '3');
        Observer.Expect('seen', '[3/1/A5][2/1/Z9][0/0/]');
        Observer.Expect('lastNext', 'No');
        Observer.Expect('lastId', '0');
        Observer.Expect('nextAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoopHandler')]
    procedure P197_Temp_SecondaryKeyAfterFindFirst()
    var
        T: Record "LT NewRow Ref" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        SeedTemp(T);
        T.SetCurrentKey(RefType, RefNo);
        T.SetRange(RefType, 1);
        Observer.Observe('findfirst', Format(T.FindFirst()));
        Observer.Observe('pos', T.RefNo);
        Page.RunModal(Page::"LT NewRow Ref List", T);
        Report(Observer);
        Observer.Expect('findfirst', 'Yes');
        Observer.Expect('pos', 'A5');
        Observer.Expect('first', 'Yes');
        Observer.Expect('rows', '3');
        Observer.Expect('seen', '[3/1/A5][2/1/Z9][0/0/]');
        Observer.Expect('lastNext', 'No');
        Observer.Expect('lastId', '0');
        Observer.Expect('nextAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoopHandler')]
    procedure P197_Temp_NothingInserted()
    var
        T: Record "LT NewRow Ref" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        SeedTemp(T);
        T.DeleteAll();
        Page.RunModal(Page::"LT NewRow Ref List", T);
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
    procedure P197_Temp_OneInserted()
    var
        T: Record "LT NewRow Ref" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        SeedTemp(T);
        T.DeleteAll();
        Add(T, 7, 1, 'X');
        Page.RunModal(Page::"LT NewRow Ref List", T);
        Report(Observer);
        Observer.Expect('first', 'Yes');
        Observer.Expect('rows', '2');
        Observer.Expect('seen', '[7/1/X][0/0/]');
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
