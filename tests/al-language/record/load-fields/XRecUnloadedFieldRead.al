// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setloadfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 99650 and 99651, test codeunit 99652
// local object: the table methods that read Rec and xRec are the thing under test, so the tables are own objects (standing rule 2)
// Probe: al-runner issue 7375 (reading an unloaded field on xRec inside a table method, after SetLoadFields and Get, is refused as a load of a
//   partial record whose key changed). Neighbours: P170JitLoadGone.al, R7000InitAfterLoadFields.al, P81LoadFields.al (partial records, JIT loads).
// Facts: a table method called on a record that was fetched with SetLoadFields("No.") and Get reads (a) a field of xRec, (b) a field of Rec that
//   is not in the load set, (c) both through an IsBlocked style method as in the issue; whether the read gives the stored value (a just-in-time
//   load) or an empty value, whether a row changed by another variable between the Get and the read shows its new or its old value, what xRec holds
//   after a Get, and the same reads after the key field was assigned (not renamed) and from the OnInsert trigger of a second table. A control
//   without SetLoadFields gives the same reads. Observed on real BC; every literal asserted below is what BC produced.
// BC versions: 27, 28, 29 (corpus CI)

table 99650 "XL Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Template Code"; Code[20]) { }
        field(3; Status; Text[10]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }

    procedure IsBlocked(): Boolean
    begin
        if xRec.IsInitial() or Rec.IsInitial() then
            exit(true);
    end;

    procedure IsInitial(): Boolean
    begin
        if "Template Code" = '' then
            exit(false);
        exit(Status = 'NEW');
    end;

    procedure ReadXRecStatus(): Text
    begin
        exit(xRec.Status);
    end;

    procedure ReadXRecTemplate(): Text
    begin
        exit(xRec."Template Code");
    end;

    procedure ReadXRecNo(): Text
    begin
        exit(xRec."No.");
    end;

    procedure ReadRecStatus(): Text
    begin
        exit(Status);
    end;

    procedure ReadRecTemplate(): Text
    begin
        exit("Template Code");
    end;
}

table 99651 "XL Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; "Header No."; Code[20]) { }
    }

    keys { key(PK; "Line No.") { Clustered = true; } }

    trigger OnInsert()
    var
        Header: Record "XL Header";
        BlockedErr: Label 'blocked';
    begin
        Header.SetLoadFields("No.");
        if Header.Get("Header No.") then
            if Header.IsBlocked() then
                Error(BlockedErr);
    end;
}

codeunit 99652 "XL XRec Unloaded Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Header: Record "XL Header";
        Line: Record "XL Line";
    begin
        Line.DeleteAll();
        Header.DeleteAll();
        Header."No." := 'A1';
        Header."Template Code" := 'T1';
        Header.Status := 'NEW';
        Header.Insert();
    end;

    local procedure ChangeStatusElsewhere()
    var
        Other: Record "XL Header";
    begin
        Other.Get('A1');
        Other.Status := 'CHANGED';
        Other.Modify();
    end;

    [Test]
    procedure PartialGet_IsBlocked_IssueShape()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "XL Header";
    begin
        Seed();
        Header.SetLoadFields("No.");
        Observer.Observe('get', Format(Header.Get('A1')));
        Observer.Observe('is blocked', Format(Header.IsBlocked()));
        Observer.Finish();
    end;

    [Test]
    procedure PartialGet_XRecFields_ReadInTableMethod()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "XL Header";
    begin
        Seed();
        Header.SetLoadFields("No.");
        Header.Get('A1');
        Observer.Observe('xrec no', Header.ReadXRecNo());
        Observer.Observe('xrec template', Header.ReadXRecTemplate());
        Observer.Observe('xrec status', Header.ReadXRecStatus());
        Observer.Finish();
    end;

    [Test]
    procedure PartialGet_RecUnloadedFields_ReadInTableMethod()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "XL Header";
    begin
        Seed();
        Header.SetLoadFields("No.");
        Header.Get('A1');
        Observer.Observe('rec template', Header.ReadRecTemplate());
        Observer.Observe('rec status', Header.ReadRecStatus());
        Observer.Finish();
    end;

    [Test]
    procedure PartialGet_RowChangedAfterGet_ReadInTableMethod()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "XL Header";
    begin
        Seed();
        Header.SetLoadFields("No.");
        Header.Get('A1');
        ChangeStatusElsewhere();
        Observer.Observe('rec status', Header.ReadRecStatus());
        Observer.Observe('xrec status', Header.ReadXRecStatus());
        Observer.Finish();
    end;

    [Test]
    procedure PartialGet_RowChangedAfterGet_XRecReadFirst()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "XL Header";
    begin
        Seed();
        Header.SetLoadFields("No.");
        Header.Get('A1');
        ChangeStatusElsewhere();
        Observer.Observe('xrec status', Header.ReadXRecStatus());
        Observer.Observe('rec status', Header.ReadRecStatus());
        Observer.Finish();
    end;

    [Test]
    procedure PartialGet_KeyAssignedAfterGet_ReadInTableMethod()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "XL Header";
    begin
        Seed();
        Header.SetLoadFields("No.");
        Header.Get('A1');
        Header."No." := 'A2';
        Observer.Observe('rec status', Header.ReadRecStatus());
        Observer.Observe('xrec no', Header.ReadXRecNo());
        Observer.Observe('xrec status', Header.ReadXRecStatus());
        Observer.Finish();
    end;

    [Test]
    procedure FullGet_XRecAndRecFields_ReadInTableMethod()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "XL Header";
    begin
        Seed();
        Header.Get('A1');
        Observer.Observe('xrec no', Header.ReadXRecNo());
        Observer.Observe('xrec status', Header.ReadXRecStatus());
        Observer.Observe('rec status', Header.ReadRecStatus());
        Observer.Observe('is blocked', Format(Header.IsBlocked()));
        Observer.Finish();
    end;

    [Test]
    procedure PartialGet_AfterModify_XRecFieldsInTableMethod()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "XL Header";
    begin
        Seed();
        Header.SetLoadFields("No.");
        Header.Get('A1');
        Header.Modify();
        Observer.Observe('xrec no', Header.ReadXRecNo());
        Observer.Observe('xrec status', Header.ReadXRecStatus());
        Observer.Observe('rec status', Header.ReadRecStatus());
        Observer.Finish();
    end;

    [Test]
    procedure LineOnInsert_PartialHeaderGet_IsBlocked()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XL Line";
    begin
        Seed();
        Line."Line No." := 1;
        Line."Header No." := 'A1';
        asserterror Line.Insert(true);
        Observer.ObserveError('insert');
        Observer.Finish();
    end;
}
