// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT PnC Rec (71080)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: Property forms "Rec.Mark := b, Rec.MarkedOnly := b, Rec.Ascending := b, Rec.FilterGroup := n, ... are lowered as the call form with one argument. Assumed: the assignment and the call are the same operation"
// BC versions: 29 (27 and 28 by CI)

codeunit 71126 "LT PnC Prop Mark"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT PnC Rec";
        i: Integer;
    begin
        R.DeleteAll();
        for i := 1 to 4 do begin
            R.Init();
            R."No." := i;
            R.Insert();
        end;
    end;

    local procedure Count(var R: Record "LT PnC Rec"): Integer
    begin
        exit(R.Count());
    end;

    [Test]
    procedure Mark_AssignAndCall()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
    begin
        Seed();
        R.Get(2);
        R.Mark := true;
        Observer.Observe('assign.read', Format(R.Mark()));
        R.Get(3);
        R.Mark(true);
        Observer.Observe('call.read', Format(R.Mark()));
        R.MarkedOnly(true);
        Observer.Observe('markedOnly.count', Format(R.Count()));
        R.Get(2);
        R.Mark := false;
        Observer.Observe('assign.false.read', Format(R.Mark()));
        Observer.Observe('markedOnly.afterUnmark', Format(R.Count()));
        R.ClearMarks();
        Observer.Observe('afterClearMarks', Format(R.Count()));
        Observer.Observe('markedOnly.flag', Format(R.MarkedOnly()));
        Observer.Expect('assign.read', 'Yes');
        Observer.Expect('call.read', 'Yes');
        Observer.Expect('markedOnly.count', '2');
        Observer.Expect('assign.false.read', 'No');
        Observer.Expect('markedOnly.afterUnmark', '1');
        Observer.Expect('afterClearMarks', '0');
        Observer.Expect('markedOnly.flag', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MarkedOnly_AssignAndCall()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
    begin
        Seed();
        R.Get(1);
        R.Mark(true);
        R.MarkedOnly := true;
        Observer.Observe('assign.flag', Format(R.MarkedOnly()));
        Observer.Observe('assign.count', Format(R.Count()));
        R.MarkedOnly := false;
        Observer.Observe('assignFalse.flag', Format(R.MarkedOnly()));
        Observer.Observe('assignFalse.count', Format(R.Count()));
        R.MarkedOnly(true);
        Observer.Observe('call.flag', Format(R.MarkedOnly()));
        Observer.Observe('call.then.property', Format(R.MarkedOnly));
        Observer.Expect('assign.flag', 'Yes');
        Observer.Expect('assign.count', '1');
        Observer.Expect('assignFalse.flag', 'No');
        Observer.Expect('assignFalse.count', '4');
        Observer.Expect('call.flag', 'Yes');
        Observer.Expect('call.then.property', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Ascending_AssignAndCall()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
    begin
        Seed();
        Observer.Observe('default', Format(R.Ascending()));
        R.Ascending := false;
        Observer.Observe('assign.read', Format(R.Ascending()));
        R.FindFirst();
        Observer.Observe('assign.first', Format(R."No."));
        R.Ascending(true);
        Observer.Observe('call.read', Format(R.Ascending()));
        R.FindFirst();
        Observer.Observe('call.first', Format(R."No."));
        R.Ascending(false);
        Observer.Observe('property.read', Format(R.Ascending));
        Observer.Expect('default', 'Yes');
        Observer.Expect('assign.read', 'No');
        Observer.Expect('assign.first', '4');
        Observer.Expect('call.read', 'Yes');
        Observer.Expect('call.first', '1');
        Observer.Expect('property.read', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure FilterGroup_AssignAndCall()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
    begin
        Seed();
        Observer.Observe('default', Format(R.FilterGroup()));
        R.FilterGroup := 3;
        Observer.Observe('assign.read', Format(R.FilterGroup()));
        R.SetRange("No.", 2);
        R.FilterGroup := 0;
        Observer.Observe('group0.filters', '[' + R.GetFilters() + ']');
        R.FilterGroup(3);
        Observer.Observe('call.filters', R.GetFilters());
        R.FilterGroup(0);
        Observer.Observe('call.read', Format(R.FilterGroup()));
        R.FilterGroup := -1;
        Observer.Observe('negative', 'no error');
        Observer.Observe('afterError', Format(R.FilterGroup()));
        Observer.Expect('default', '0');
        Observer.Expect('assign.read', '3');
        Observer.Expect('group0.filters', '[]');
        Observer.Expect('call.filters', 'No.: 2');
        Observer.Expect('call.read', '0');
        Observer.Expect('negative', 'no error');
        Observer.Expect('afterError', '-1');
        Observer.Verify();
    end;
}

codeunit 71127 "LT PnC Prop Session"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure WorkDate_AssignAndCall()
    var
        Observer: Codeunit "Probe Observer";
        Saved: Date;
    begin
        Saved := WorkDate();
        WorkDate := DMY2Date(5, 3, 2024);
        Observer.Observe('assign.read', Format(WorkDate(), 0, 9));
        WorkDate(DMY2Date(6, 3, 2024));
        Observer.Observe('call.read', Format(WorkDate(), 0, 9));
        Observer.Observe('property.read', Format(WorkDate, 0, 9));
        WorkDate := 0D;
        Observer.Observe('assignUndefined.isDefault', Format(WorkDate() <> 0D));
        WorkDate(Saved);
        Observer.Expect('assign.read', '2024-03-05');
        Observer.Expect('call.read', '2024-03-06');
        Observer.Expect('property.read', '2024-03-06');
        Observer.Expect('assignUndefined.isDefault', 'Yes');
        Observer.Verify();
    end;
}

codeunit 71128 "LT PnC Prop ErrorInfo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ErrorInfo_Assign_Properties()
    var
        Observer: Codeunit "Probe Observer";
        E: ErrorInfo;
    begin
        E := ErrorInfo.Create();
        E.Message := 'm1';
        Observer.Observe('message.assign', E.Message());
        E.Message('m2');
        Observer.Observe('message.call', E.Message);
        E.DetailedMessage := 'd1';
        Observer.Observe('detailed.assign', E.DetailedMessage());
        E.Title := 't1';
        Observer.Observe('title.assign', E.Title());
        E.ControlName := 'c1';
        Observer.Observe('controlName.assign', E.ControlName());
        E.FieldNo := 7;
        Observer.Observe('fieldNo.assign', Format(E.FieldNo()));
        E.PageNo := 21;
        Observer.Observe('pageNo.assign', Format(E.PageNo()));
        E.TableId := 18;
        Observer.Observe('tableId.assign', Format(E.TableId()));
        E.Verbosity := Verbosity::Warning;
        Observer.Observe('verbosity.assign', Format(E.Verbosity()));
        E.DataClassification := DataClassification::SystemMetadata;
        Observer.Observe('dataClassification.assign', Format(E.DataClassification()));
        E.Collectible := false;
        Observer.Observe('collectible.assign', Format(E.Collectible()));
        E.ErrorType := ErrorType::Internal;
        Observer.Observe('errorType.assign', Format(E.ErrorType()));
        Observer.Expect('message.assign', 'm1');
        Observer.Expect('message.call', 'm2');
        Observer.Expect('detailed.assign', 'd1');
        Observer.Expect('title.assign', 't1');
        Observer.Expect('controlName.assign', 'c1');
        Observer.Expect('fieldNo.assign', '7');
        Observer.Expect('pageNo.assign', '21');
        Observer.Expect('tableId.assign', '18');
        Observer.Expect('verbosity.assign', 'Warning');
        Observer.Expect('dataClassification.assign', 'SystemMetadata');
        Observer.Expect('collectible.assign', 'No');
        Observer.Expect('errorType.assign', 'Internal');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorInfo_NeverCreated_Defaults()
    var
        Observer: Codeunit "Probe Observer";
        E: ErrorInfo;
        Created: ErrorInfo;
    begin
        Created := ErrorInfo.Create();
        Observer.Observe('untouched.verbosity', Format(E.Verbosity()));
        Observer.Observe('untouched.collectible', Format(E.Collectible()));
        Observer.Observe('untouched.errorType', Format(E.ErrorType()));
        Observer.Observe('untouched.dataClassification', Format(E.DataClassification()));
        Observer.Observe('untouched.tableId', Format(E.TableId()));
        Observer.Observe('untouched.message', '[' + E.Message() + ']');
        Observer.Observe('created.verbosity', Format(Created.Verbosity()));
        Observer.Observe('created.collectible', Format(Created.Collectible()));
        Observer.Observe('created.errorType', Format(Created.ErrorType()));
        E.Message := 'set on untouched';
        Observer.Observe('untouched.afterSet', E.Message());
        Observer.Observe('untouched.afterSet.collectible', Format(E.Collectible()));
        Observer.Expect('untouched.verbosity', 'Error');
        Observer.Expect('untouched.collectible', 'No');
        Observer.Expect('untouched.errorType', 'Client');
        Observer.Expect('untouched.dataClassification', 'CustomerContent');
        Observer.Expect('untouched.tableId', '0');
        Observer.Expect('untouched.message', '[]');
        Observer.Expect('created.verbosity', 'Error');
        Observer.Expect('created.collectible', 'Yes');
        Observer.Expect('created.errorType', 'Client');
        Observer.Expect('untouched.afterSet', 'set on untouched');
        Observer.Expect('untouched.afterSet.collectible', 'No');
        Observer.Verify();
    end;
}
