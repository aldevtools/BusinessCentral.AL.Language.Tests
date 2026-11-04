// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-insertallowed-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); NewRowListFixtures.al (table 72900, pages 72902 InsertAllowed = false, 72903 DelayedInsert = true); test codeunit 72906
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the same RunModal loop on a list with InsertAllowed = false and on a list with DelayedInsert = true, over a real record and a temporary record, filtered on a secondary key: row count, blank new-row line after the last row, Next() of the last step
// BC versions: 29 (27 and 28 by CI)

codeunit 72906 "LT NewRow InsDelayed Rows"
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

    local procedure SeedReal()
    var
        R: Record "LT NewRow Ref";
    begin
        R.DeleteAll();
        Rows := 0;
        Seen := '';
        Add(R, 1, 2, 'B1');
        Add(R, 2, 1, 'Z9');
        Add(R, 3, 1, 'A5');
    end;

    local procedure Add(var R: Record "LT NewRow Ref"; Id: Integer; RefType: Integer; RefNo: Code[20])
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
    [HandlerFunctions('NoInsHandler')]
    procedure P197_NoIns_Real_ThreeRows()
    var
        R: Record "LT NewRow Ref";
        Observer: Codeunit "Probe Observer";
    begin
        SeedReal();
        Page.RunModal(Page::"LT NewRow Ref List NoIns", R);
        Report(Observer);
        Observer.Expect('first', 'Yes');
        Observer.Expect('rows', '3');
        Observer.Expect('seen', '[1/2/B1][2/1/Z9][3/1/A5]');
        Observer.Expect('lastNext', 'No');
        Observer.Expect('lastId', '3');
        Observer.Expect('nextAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NoInsHandler')]
    procedure P197_NoIns_Real_SecKeyFilter()
    var
        R: Record "LT NewRow Ref";
        Observer: Codeunit "Probe Observer";
    begin
        SeedReal();
        R.SetCurrentKey(RefType, RefNo);
        R.SetRange(RefType, 1);
        Page.RunModal(Page::"LT NewRow Ref List NoIns", R);
        Report(Observer);
        Observer.Expect('first', 'Yes');
        Observer.Expect('rows', '2');
        Observer.Expect('seen', '[3/1/A5][2/1/Z9]');
        Observer.Expect('lastNext', 'No');
        Observer.Expect('lastId', '2');
        Observer.Expect('nextAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NoInsHandler')]
    procedure P197_NoIns_Temp_ThreeRows()
    var
        T: Record "LT NewRow Ref" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        SeedReal();
        Add(T, 1, 2, 'B1');
        Add(T, 2, 1, 'Z9');
        Add(T, 3, 1, 'A5');
        Page.RunModal(Page::"LT NewRow Ref List NoIns", T);
        Report(Observer);
        Observer.Expect('first', 'Yes');
        Observer.Expect('rows', '3');
        Observer.Expect('seen', '[1/2/B1][2/1/Z9][3/1/A5]');
        Observer.Expect('lastNext', 'No');
        Observer.Expect('lastId', '3');
        Observer.Expect('nextAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NoInsHandler')]
    procedure P197_NoIns_Real_NoRows()
    var
        R: Record "LT NewRow Ref";
        Observer: Codeunit "Probe Observer";
    begin
        SeedReal();
        R.SetRange(RefType, 99);
        Page.RunModal(Page::"LT NewRow Ref List NoIns", R);
        Report(Observer);
        Observer.Expect('first', 'No');
        Observer.Expect('rows', '0');
        Observer.Expect('seen', '');
        Observer.Expect('lastNext', 'No');
        Observer.Expect('lastId', '');
        Observer.Expect('nextAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DelayedHandler')]
    procedure P197_Delayed_Real_ThreeRows()
    var
        R: Record "LT NewRow Ref";
        Observer: Codeunit "Probe Observer";
    begin
        SeedReal();
        Page.RunModal(Page::"LT NewRow Ref List Delayed", R);
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
    [HandlerFunctions('DelayedHandler')]
    procedure P197_Delayed_Real_SecKeyFilter()
    var
        R: Record "LT NewRow Ref";
        Observer: Codeunit "Probe Observer";
    begin
        SeedReal();
        R.SetCurrentKey(RefType, RefNo);
        R.SetRange(RefType, 1);
        Page.RunModal(Page::"LT NewRow Ref List Delayed", R);
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
    [HandlerFunctions('DelayedHandler')]
    procedure P197_Delayed_Temp_ThreeRows()
    var
        T: Record "LT NewRow Ref" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        SeedReal();
        Add(T, 1, 2, 'B1');
        Add(T, 2, 1, 'Z9');
        Add(T, 3, 1, 'A5');
        Page.RunModal(Page::"LT NewRow Ref List Delayed", T);
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
    [HandlerFunctions('DelayedHandler')]
    procedure P197_Delayed_Real_NoRows()
    var
        R: Record "LT NewRow Ref";
        Observer: Codeunit "Probe Observer";
    begin
        SeedReal();
        R.SetRange(RefType, 99);
        Page.RunModal(Page::"LT NewRow Ref List Delayed", R);
        Report(Observer);
        Observer.Expect('first', 'No');
        Observer.Expect('rows', '0');
        Observer.Expect('seen', '');
        Observer.Expect('lastNext', 'No');
        Observer.Expect('lastId', '0');
        Observer.Expect('nextAfter', 'No');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure NoInsHandler(var P: TestPage "LT NewRow Ref List NoIns")
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

    [ModalPageHandler]
    procedure DelayedHandler(var P: TestPage "LT NewRow Ref List Delayed")
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
