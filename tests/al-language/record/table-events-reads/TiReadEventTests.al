// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (69160); TiReadEventObjects.al (table 73600 with subscribers to its ten table events, in-memory log codeunit 73601)
// Probe (al-runner issue 8238): which table events a read of a record raises. Each test fills three rows, empties the log, runs one statement
//   at a time and observes the names of the events the statement raised ([] = no table event).
// BC result (measured on BC 28.5 and 27.5): no read raises a table event: IsEmpty, Get (found and missing), Find('-'/'+'/'='), FindFirst,
//   FindLast, FindSet/FindSet(true) with Next, Next(-1), Count, CountApprox, SetRange, SetFilter, Reset, SetCurrentKey, SetAscending, a field
//   read, a field assignment without Validate, Init, Copy, TransferFields, SetLoadFields + Get, LockTable + FindLast, GetFilters/HasFilter, and
//   RecordRef Open/IsEmpty/FindFirst/Next/Count/FieldRef read/FieldRef SetRange/Close; also not on an empty table. The control: Insert,
//   Modify, Delete (false and true), Rename and Validate of the subscribed field raise their OnBefore/OnAfter pair; Validate of another field
//   raises none; ModifyAll and DeleteAll raise the pair once per row, for RunTrigger false as well as true (the table has subscribers).
// BC versions: 27 - 29
codeunit 73604 "LT TI Read Events"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Setup()
    var
        Row: Record "LT TI Read Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Code := 'A';
        Row.Description := 'Alpha';
        Row.Amount := 1;
        Row.Insert();
        Row.Code := 'B';
        Row.Description := 'Beta';
        Row.Amount := 2;
        Row.Insert();
        Row.Code := 'C';
        Row.Description := 'Gamma';
        Row.Amount := 3;
        Row.Insert();
        Take();
    end;

    local procedure Take(): Text
    var
        Log: Codeunit "LT TI Row Event Log";
    begin
        exit(Log.Take());
    end;

    [Test]
    procedure Find_Family_RaisesNoTableEvent()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT TI Read Row";
        N: Integer;
    begin
        Setup();
        Observer.Observe('IsEmpty', Format(Row.IsEmpty()) + ' ' + Take());
        Observer.Observe('Get found', Format(Row.Get('B')) + ' ' + Take());
        Observer.Observe('Get missing', Format(Row.Get('Z')) + ' ' + Take());
        Observer.Observe('Find -', Format(Row.Find('-')) + ' ' + Take());
        Observer.Observe('Find +', Format(Row.Find('+')) + ' ' + Take());
        Observer.Observe('Find =', Format(Row.Find('=')) + ' ' + Take());
        Observer.Observe('FindFirst', Format(Row.FindFirst()) + ' ' + Take());
        Observer.Observe('FindLast', Format(Row.FindLast()) + ' ' + Take());
        N := 0;
        if Row.FindSet() then
            repeat
                N += 1;
            until Row.Next() = 0;
        Observer.Observe('FindSet Next', Format(N) + ' ' + Take());
        N := 0;
        if Row.FindSet(true) then
            repeat
                N += 1;
            until Row.Next() = 0;
        Observer.Observe('FindSet ForUpdate Next', Format(N) + ' ' + Take());
        Observer.Observe('Next -1', Format(Row.Next(-1)) + ' ' + Take());
        Observer.Observe('Count', Format(Row.Count()) + ' ' + Take());
        N := Row.CountApprox();
        Observer.Observe('CountApprox', Take());
        Observer.Expect('IsEmpty', 'No []');
        Observer.Expect('Get found', 'Yes []');
        Observer.Expect('Get missing', 'No []');
        Observer.Expect('Find -', 'Yes []');
        Observer.Expect('Find +', 'Yes []');
        Observer.Expect('Find =', 'Yes []');
        Observer.Expect('FindFirst', 'Yes []');
        Observer.Expect('FindLast', 'Yes []');
        Observer.Expect('FindSet Next', '3 []');
        Observer.Expect('FindSet ForUpdate Next', '3 []');
        Observer.Expect('Next -1', '-1 []');
        Observer.Expect('Count', '3 []');
        Observer.Expect('CountApprox', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Find_EmptyTable_RaisesNoTableEvent()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT TI Read Row";
    begin
        Setup();
        Row.DeleteAll();
        Observer.Observe('DeleteAll false on three rows', Take());
        Observer.Observe('IsEmpty', Format(Row.IsEmpty()) + ' ' + Take());
        Observer.Observe('FindFirst', Format(Row.FindFirst()) + ' ' + Take());
        Observer.Observe('FindSet', Format(Row.FindSet()) + ' ' + Take());
        Observer.Observe('Count', Format(Row.Count()) + ' ' + Take());
        Observer.Expect('DeleteAll false on three rows', '[Row.OnBeforeDelete,Row.OnAfterDelete,Row.OnBeforeDelete,Row.OnAfterDelete,Row.OnBeforeDelete,Row.OnAfterDelete]');
        Observer.Expect('IsEmpty', 'Yes []');
        Observer.Expect('FindFirst', 'No []');
        Observer.Expect('FindSet', 'No []');
        Observer.Expect('Count', '0 []');
        Observer.Verify();
    end;

    [Test]
    procedure Filters_Keys_Fields_RaiseNoTableEvent()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT TI Read Row";
        Other: Record "LT TI Read Row";
        Desc: Text;
        Amt: Decimal;
    begin
        Setup();
        Row.SetRange(Code, 'A', 'B');
        Observer.Observe('SetRange', Take());
        Row.SetFilter(Description, '%1|%2', 'Alpha', 'Gamma');
        Observer.Observe('SetFilter', Take());
        Observer.Observe('Count filtered', Format(Row.Count()) + ' ' + Take());
        Row.Reset();
        Observer.Observe('Reset', Take());
        Row.SetCurrentKey(Description);
        Observer.Observe('SetCurrentKey', Take());
        Row.SetAscending(Description, false);
        Observer.Observe('SetAscending', Take());
        Observer.Observe('FindFirst by key', Format(Row.FindFirst()) + ' ' + Row.Code + ' ' + Take());
        Desc := Row.Description;
        Amt := Row.Amount;
        Observer.Observe('field read', Desc + ' ' + Format(Amt) + ' ' + Take());
        Row.Description := 'Changed';
        Observer.Observe('field assign without Validate', Take());
        Row.Init();
        Observer.Observe('Init', Take());
        Other.Copy(Row);
        Observer.Observe('Copy', Take());
        Other.TransferFields(Row);
        Observer.Observe('TransferFields', Take());
        Row.SetLoadFields(Description);
        Observer.Observe('SetLoadFields Get', Format(Row.Get('C')) + ' ' + Take());
        Row.LockTable();
        Observer.Observe('LockTable FindLast', Format(Row.FindLast()) + ' ' + Take());
        Observer.Observe('GetFilters HasFilter', Row.GetFilters() + ' ' + Format(Row.HasFilter()) + ' ' + Take());
        Observer.Expect('SetRange', '[]');
        Observer.Expect('SetFilter', '[]');
        Observer.Expect('Count filtered', '1 []');
        Observer.Expect('Reset', '[]');
        Observer.Expect('SetCurrentKey', '[]');
        Observer.Expect('SetAscending', '[]');
        Observer.Expect('FindFirst by key', 'Yes C []');
        Observer.Expect('field read', 'Gamma 3 []');
        Observer.Expect('field assign without Validate', '[]');
        Observer.Expect('Init', '[]');
        Observer.Expect('Copy', '[]');
        Observer.Expect('TransferFields', '[]');
        Observer.Expect('SetLoadFields Get', 'Yes []');
        Observer.Expect('LockTable FindLast', 'Yes []');
        Observer.Expect('GetFilters HasFilter', ' No []');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_Reads_RaiseNoTableEvent()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Setup();
        RecRef.Open(Database::"LT TI Read Row");
        Observer.Observe('Open', Take());
        Observer.Observe('IsEmpty', Format(RecRef.IsEmpty()) + ' ' + Take());
        Observer.Observe('FindFirst', Format(RecRef.FindFirst()) + ' ' + Take());
        Observer.Observe('Next', Format(RecRef.Next()) + ' ' + Take());
        Observer.Observe('Count', Format(RecRef.Count()) + ' ' + Take());
        FldRef := RecRef.Field(2);
        Observer.Observe('FieldRef read', Format(FldRef.Value()) + ' ' + Take());
        FldRef.SetRange('Gamma');
        Observer.Observe('FieldRef SetRange FindFirst', Format(RecRef.FindFirst()) + ' ' + Take());
        RecRef.Close();
        Observer.Observe('Close', Take());
        Observer.Expect('Open', '[]');
        Observer.Expect('IsEmpty', 'No []');
        Observer.Expect('FindFirst', 'Yes []');
        Observer.Expect('Next', '1 []');
        Observer.Expect('Count', '3 []');
        Observer.Expect('FieldRef read', 'Beta []');
        Observer.Expect('FieldRef SetRange FindFirst', 'Yes []');
        Observer.Expect('Close', '[]');
        Observer.Verify();
    end;

    // The control: the subscribers are bound, and which events each write raises.
    [Test]
    procedure Writes_RaiseTheirTableEvents()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT TI Read Row";
    begin
        Setup();
        Row.Init();
        Row.Code := 'D';
        Row.Insert(false);
        Observer.Observe('Insert false', Take());
        Row.Code := 'E';
        Row.Insert(true);
        Observer.Observe('Insert true', Take());
        Row.Get('A');
        Row.Amount := 10;
        Row.Modify(false);
        Observer.Observe('Modify false', Take());
        Row.Modify(true);
        Observer.Observe('Modify true', Take());
        Row.Validate(Description, 'Validated');
        Observer.Observe('Validate', Take());
        Row.Validate(Amount, 11);
        Observer.Observe('Validate other field', Take());
        Row.Rename('F');
        Observer.Observe('Rename', Take());
        Row.Delete(false);
        Observer.Observe('Delete false', Take());
        Row.Get('B');
        Row.Delete(true);
        Observer.Observe('Delete true', Take());
        Row.Reset();
        Row.ModifyAll(Amount, 5, false);
        Observer.Observe('ModifyAll false', Take());
        Row.ModifyAll(Amount, 6, true);
        Observer.Observe('ModifyAll true', Take());
        Row.SetRange(Code, 'C');
        Row.DeleteAll(false);
        Observer.Observe('DeleteAll false one row', Take());
        Row.SetRange(Code);
        Row.DeleteAll(true);
        Observer.Observe('DeleteAll true', Take());
        Observer.Expect('Insert false', '[Row.OnBeforeInsert,Row.OnAfterInsert]');
        Observer.Expect('Insert true', '[Row.OnBeforeInsert,Row.OnAfterInsert]');
        Observer.Expect('Modify false', '[Row.OnBeforeModify,Row.OnAfterModify]');
        Observer.Expect('Modify true', '[Row.OnBeforeModify,Row.OnAfterModify]');
        Observer.Expect('Validate', '[Row.OnBeforeValidate,Row.OnAfterValidate]');
        Observer.Expect('Validate other field', '[]');
        Observer.Expect('Rename', '[Row.OnBeforeRename,Row.OnAfterRename]');
        Observer.Expect('Delete false', '[Row.OnBeforeDelete,Row.OnAfterDelete]');
        Observer.Expect('Delete true', '[Row.OnBeforeDelete,Row.OnAfterDelete]');
        Observer.Expect('ModifyAll false', '[Row.OnBeforeModify,Row.OnAfterModify,Row.OnBeforeModify,Row.OnAfterModify,Row.OnBeforeModify,Row.OnAfterModify]');
        Observer.Expect('ModifyAll true', '[Row.OnBeforeModify,Row.OnAfterModify,Row.OnBeforeModify,Row.OnAfterModify,Row.OnBeforeModify,Row.OnAfterModify]');
        Observer.Expect('DeleteAll false one row', '[Row.OnBeforeDelete,Row.OnAfterDelete]');
        Observer.Expect('DeleteAll true', '[Row.OnBeforeDelete,Row.OnAfterDelete,Row.OnBeforeDelete,Row.OnAfterDelete]');
        Observer.Verify();
    end;
}
