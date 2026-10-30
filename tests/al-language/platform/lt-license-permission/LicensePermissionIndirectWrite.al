// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-permissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: a write to G/L Entry (17), a table a license may grant only indirectly, from a codeunit with no Permissions property,
// with Permissions = tabledata "G/L Entry" = i and with = rimd. No permission set is changed: the test user's own permissions and
// the license decide. Every write runs inside asserterror and ends with Error('LT Y4 rolled back'), so nothing is kept: the observed
// error is either that text (the write was allowed) or the permission error BC raised first.
// Facts: see the Expect lines of each test.
// BC versions: 27-29

codeunit 90952 "LT Y4 Indirect Write"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure GLEntry_Insert_ByPermissionsProperty()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Codeunit "LT Y4 GL Writer Plain";
        Indirect: Codeunit "LT Y4 GL Writer Indirect";
        Direct: Codeunit "LT Y4 GL Writer Rimd";
    begin
        asserterror Plain.Write(1);
        Observer.ObserveError('plain_insert');
        asserterror Indirect.Write(1);
        Observer.ObserveError('indirect_insert');
        asserterror Direct.Write(1);
        Observer.ObserveError('rimd_insert');
        Observer.Finish();
    end;

    [Test]
    procedure GLEntry_InsertModify_ByPermissionsProperty()
    var
        Observer: Codeunit "Probe Observer";
        Indirect: Codeunit "LT Y4 GL Writer Indirect";
        Direct: Codeunit "LT Y4 GL Writer Rimd";
    begin
        asserterror Indirect.Write(2);
        Observer.ObserveError('indirect_modify');
        asserterror Direct.Write(2);
        Observer.ObserveError('rimd_modify');
        Observer.Finish();
    end;

    [Test]
    procedure GLEntry_InsertDelete_ByPermissionsProperty()
    var
        Observer: Codeunit "Probe Observer";
        Indirect: Codeunit "LT Y4 GL Writer Indirect";
        Direct: Codeunit "LT Y4 GL Writer Rimd";
    begin
        asserterror Indirect.Write(3);
        Observer.ObserveError('indirect_delete');
        asserterror Direct.Write(3);
        Observer.ObserveError('rimd_delete');
        Observer.Finish();
    end;

    [Test]
    procedure GLEntry_Read_ByPermissionsProperty()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Codeunit "LT Y4 GL Writer Plain";
        Indirect: Codeunit "LT Y4 GL Writer Indirect";
    begin
        asserterror Plain.Read();
        Observer.ObserveError('plain_read');
        asserterror Indirect.Read();
        Observer.ObserveError('indirect_read');
        Observer.Finish();
    end;
}

// No Permissions property.
codeunit 90953 "LT Y4 GL Writer Plain"
{
    procedure Write(Step: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry."Entry No." := 2147480001;
        GLEntry.Insert(false);
        Error('LT Y4 rolled back');
    end;

    procedure Read()
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Entry No.", 2147480001);
        if GLEntry.IsEmpty() then
            Error('LT Y4 read done');
        Error('LT Y4 read found a row');
    end;
}

codeunit 90954 "LT Y4 GL Writer Indirect"
{
    Permissions = tabledata "G/L Entry" = i;

    procedure Write(Step: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry."Entry No." := 2147480001;
        GLEntry.Insert(false);
        case Step of
            2:
                begin
                    GLEntry.Description := 'LT Y4';
                    GLEntry.Modify(false);
                end;
            3:
                GLEntry.Delete(false);
        end;
        Error('LT Y4 rolled back');
    end;

    procedure Read()
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Entry No.", 2147480001);
        if GLEntry.IsEmpty() then
            Error('LT Y4 read done');
        Error('LT Y4 read found a row');
    end;
}

codeunit 90955 "LT Y4 GL Writer Rimd"
{
    Permissions = tabledata "G/L Entry" = rimd;

    procedure Write(Step: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry."Entry No." := 2147480001;
        GLEntry.Insert(false);
        case Step of
            2:
                begin
                    GLEntry.Description := 'LT Y4';
                    GLEntry.Modify(false);
                end;
            3:
                GLEntry.Delete(false);
        end;
        Error('LT Y4 rolled back');
    end;
}
