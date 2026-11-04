// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-triggers-and-events
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 74976, 74977 and 74981, log 74978, subscriber 74979, test codeunit 74980
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts (every write runs with RunTrigger true, because Insert(), Modify() and Delete() without it do not ask): how often Global Triggers.GetDatabaseTableTriggerSetup is asked for an own table, with the CompanyName() at each call: for the first write, further writes of the same table, a second table, a record variable moved with ChangeCompany to the same company, and a Modify and Delete. Only the calls for the two own tables are logged. A second company is not created (creating one takes minutes), so the setup per company is not covered.
// BC versions: 29 (27 and 28 by CI)

table 74976 "LT TS Row A"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 74977 "LT TS Row B"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 74981 "LT TS Row C"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 74978 "LT TS Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

codeunit 74979 "LT TS Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure Setup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        L: Codeunit "LT TS Log";
        Name: Text;
    begin
        if TableId = Database::"LT TS Row A" then
            Name := 'A'
        else
            if TableId = Database::"LT TS Row B" then
                Name := 'B'
            else
                if TableId = Database::"LT TS Row C" then
                    Name := 'C'
                else
                    exit;
        L.Add('Setup ' + Name + ' company=' + CompanyName());
    end;
}

codeunit 74980 "LT Table Trigger Setup Calls"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Clean()
    var
        A: Record "LT TS Row A";
        B: Record "LT TS Row B";
    begin
        A.DeleteAll();
        B.DeleteAll();
    end;

    // The first write of a table in the session may ask for the setup; the log shows whether a later test asks again. The tests share one session,
    // so every observation is a relation to the call count before the step.
    [Test]
    procedure Setup_AskedPerWrite()
    var
        A: Record "LT TS Row A";
        L: Codeunit "LT TS Log";
        Observer: Codeunit "Probe Observer";
    begin
        L.Take();
        Clean();
        Observer.Observe('clean', L.Take());
        A.Id := 1; A.Insert(true);
        Observer.Observe('first_insert', L.Take());
        A.Id := 2; A.Insert(true);
        Observer.Observe('second_insert', L.Take());
        A.Name := 'x';
        A.Modify(true);
        Observer.Observe('modify', L.Take());
        A.Delete(true);
        Observer.Observe('delete', L.Take());
        Observer.Expect('clean', 'Setup A company=<Company>;Setup B company=<Company>;');
        Observer.Expect('first_insert', '');
        Observer.Expect('second_insert', '');
        Observer.Expect('modify', '');
        Observer.Expect('delete', '');
        Observer.Verify();
    end;

    [Test]
    procedure Setup_AskedPerTable()
    var
        A: Record "LT TS Row A";
        B: Record "LT TS Row B";
        L: Codeunit "LT TS Log";
        Observer: Codeunit "Probe Observer";
    begin
        L.Take();
        Clean();
        Observer.Observe('clean', L.Take());
        B.Id := 1; B.Insert(true);
        Observer.Observe('b_insert', L.Take());
        A.Id := 1; A.Insert(true);
        Observer.Observe('a_insert', L.Take());
        B.Id := 2; B.Insert(true);
        Observer.Observe('b_insert_again', L.Take());
        Observer.Expect('clean', '');
        Observer.Expect('b_insert', '');
        Observer.Expect('a_insert', '');
        Observer.Expect('b_insert_again', '');
        Observer.Verify();
    end;

    [Test]
    procedure Setup_ReadsDoNotAskAndTriggerFlagIsFalse()
    var
        A: Record "LT TS Row A";
        L: Codeunit "LT TS Log";
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        A.Id := 1; A.Insert(true);
        L.Take();
        A.FindFirst();
        Observer.Observe('find', L.Take());
        Observer.Observe('count', Format(A.Count()));
        Observer.Observe('after_count', L.Take());
        A.Id := 2;
        A.Insert(false);
        Observer.Observe('insert_false', L.Take());
        Observer.Expect('find', '');
        Observer.Expect('count', '1');
        Observer.Expect('after_count', '');
        Observer.Expect('insert_false', '');
        Observer.Verify();
    end;

    [Test]
    procedure Setup_AfterChangeCompanyToSameCompany()
    var
        A: Record "LT TS Row A";
        Moved: Record "LT TS Row A";
        L: Codeunit "LT TS Log";
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        A.Id := 1; A.Insert(true);
        L.Take();
        Moved.ChangeCompany(CompanyName());
        Moved.Id := 2;
        Moved.Insert(true);
        Observer.Observe('moved_insert_same_company', L.Take());
        Moved.Id := 3;
        Moved.Insert(true);
        Observer.Observe('moved_insert_again', L.Take());
        A.Id := 4;
        A.Insert(true);
        Observer.Observe('original_insert_after', L.Take());
        Observer.Expect('moved_insert_same_company', '');
        Observer.Expect('moved_insert_again', '');
        Observer.Expect('original_insert_after', '');
        Observer.Verify();
    end;

    [Test]
    procedure Setup_FirstTouchOfATableIsAnInsertWithTrigger()
    var
        C: Record "LT TS Row C";
        L: Codeunit "LT TS Log";
        Observer: Codeunit "Probe Observer";
    begin
        L.Take();
        C.Id := 1;
        C.Insert(true);
        Observer.Observe('first_insert', L.Take());
        C.Id := 2;
        C.Insert(true);
        Observer.Observe('second_insert', L.Take());
        C.DeleteAll(true);
        Observer.Observe('delete_all', L.Take());
        Observer.Expect('first_insert', 'Setup C company=<Company>;');
        Observer.Expect('second_insert', '');
        Observer.Expect('delete_all', '');
        Observer.Verify();
    end;
}
