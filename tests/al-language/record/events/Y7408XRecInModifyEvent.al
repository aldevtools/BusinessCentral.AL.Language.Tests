// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// local object: the table's filter state and its secondary key are what is under test, so the probe needs its own table with two keys
// Fixtures used: Probe Observer (codeunit 69160); own table 99900, subscriber codeunit 99901, test codeunit 99902
// Probe (al-runner issue 7408): what xRec carries in an OnBeforeModifyEvent subscriber when the caller left filters, a secondary current key
//   or no filter on the record variable. Readings: GetFilters and HasFilter of Rec and xRec, Format(xRec) = Format(Rec), what a copy of xRec
//   (Copy and plain assignment) carries, and whether Find on the copy finds the row.
// BC versions: 27, 28, 29

table 99900 "LT K12 XRec Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Company; Code[20]) { }
        field(3; Member; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(ByCompany; Company, "No.") { }
    }
}

codeunit 99901 "LT K12 XRec Subscriber"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;

    [TryFunction]
    local procedure TryFindStatement(var Copied: Record "LT K12 XRec Row")
    begin
        Copied.Find();
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT K12 XRec Row", OnBeforeModifyEvent, '', false, false)]
    local procedure OnBeforeModify(var Rec: Record "LT K12 XRec Row"; var xRec: Record "LT K12 XRec Row"; RunTrigger: Boolean)
    var
        Copied: Record "LT K12 XRec Row";
        Assigned: Record "LT K12 XRec Row";
        Probe: Record "LT K12 XRec Row";
        Same: Boolean;
        StatementOk: Boolean;
        Text1: Text;
    begin
        Same := Format(xRec) = Format(Rec);
        Copied.Copy(xRec);
        Assigned := xRec;
        Probe.Copy(xRec);
        ClearLastError();
        StatementOk := TryFindStatement(Probe);
        Text1 := GetLastErrorText();
        Log := 'rec filters=[' + Rec.GetFilters() + '] hasfilter=' + Format(Rec.HasFilter()) + ' key=' + Rec.CurrentKey() +
            '; xrec filters=[' + xRec.GetFilters() + '] hasfilter=' + Format(xRec.HasFilter()) + ' key=' + xRec.CurrentKey() +
            '; formats equal=' + Format(Same) +
            '; xrec no=' + xRec."No." + ' member=[' + xRec.Member + '] rec member=[' + Rec.Member + ']' +
            '; copy filters=[' + Copied.GetFilters() + '] copy find=' + Format(Copied.Find()) +
            '; assigned filters=[' + Assigned.GetFilters() + '] assigned find=' + Format(Assigned.Find()) +
            '; copy find statement ok=' + Format(StatementOk) + ' err=[' + Text1 + ']' +
            '; xrec find=' + Format(xRec.Find());
    end;
}

codeunit 99902 "LT K12 XRec Modify Event"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Subscriber: Codeunit "LT K12 XRec Subscriber";

    local procedure Seed()
    var
        Row: Record "LT K12 XRec Row";
    begin
        Row.DeleteAll();
        Row."No." := 'CT1';
        Row.Company := '0001';
        Row.Insert();
        Row."No." := 'CT2';
        Row.Company := '0002';
        Row.Insert();
        Row."No." := 'CT3';
        Row.Company := '0001';
        Row.Insert();
        Subscriber.Take();
    end;

    [Test]
    procedure Y7408_Modify_CallerFilterExcludesRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT K12 XRec Row";
    begin
        Seed();
        Row.SetRange(Company, '0001');
        Row.Get('CT2');
        Row.Member := 'X-1';
        Row.Modify();
        Observer.Observe('modify, filter excludes the row', Subscriber.Take());
        Observer.Observe('caller filters after', Row.GetFilters());
        Observer.Finish();
    end;

    [Test]
    procedure Y7408_Modify_CallerFilterIncludesRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT K12 XRec Row";
    begin
        Seed();
        Row.SetRange(Company, '0001');
        Row.Get('CT1');
        Row.Member := 'X-1';
        Row.Modify();
        Observer.Observe('modify, filter includes the row', Subscriber.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y7408_Modify_NoFilter_And_ModifyFalse()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT K12 XRec Row";
    begin
        Seed();
        Row.Get('CT2');
        Row.Member := 'X-1';
        Row.Modify();
        Observer.Observe('modify, no filter', Subscriber.Take());
        Row.Reset();
        Row.SetRange(Company, '0001');
        Row.Get('CT2');
        Row.Member := 'X-2';
        Row.Modify(false);
        Observer.Observe('modify(false), filter excludes the row', Subscriber.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y7408_Modify_SecondaryKey_And_PrimaryKeyFilter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT K12 XRec Row";
    begin
        Seed();
        Row.SetCurrentKey(Company, "No.");
        Row.SetRange(Company, '0002');
        Row.FindFirst();
        Row.Member := 'X-1';
        Row.Modify();
        Observer.Observe('modify, secondary key and filter', Subscriber.Take());
        Row.Reset();
        Row.SetFilter("No.", 'CT1|CT3');
        Row.Get('CT2');
        Row.Member := 'X-2';
        Row.Modify();
        Observer.Observe('modify, filter on the primary key excludes the row', Subscriber.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y7408_Modify_FindWithFilterThenSetOtherValue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT K12 XRec Row";
    begin
        Seed();
        Row.SetRange(Company, '0001');
        Row.FindFirst();
        Row.Member := 'X-1';
        Row.Modify();
        Observer.Observe('modify, row found under the filter', Subscriber.Take());
        Row.Company := '0002';
        Row.Modify();
        Observer.Observe('modify, field in the filter changed to leave it', Subscriber.Take());
        Observer.Finish();
    end;
}
