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
        field(3; Member; Code[20])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT K12 XRec Subscriber";
            begin
                Log.Add('field OnValidate Member=' + Member + ' xrec=' + xRec.Member + ' xrecfilters=[' + xRec.GetFilters() + ']');
            end;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(ByCompany; Company, "No.") { }
    }

    trigger OnModify()
    var
        Log: Codeunit "LT K12 XRec Subscriber";
    begin
        Log.Add('table OnModify Member=' + Member + ' xrec=' + xRec.Member + ' xrecfilters=[' + xRec.GetFilters() + '] recfilters=[' + GetFilters() + ']');
    end;
}

codeunit 99901 "LT K12 XRec Subscriber"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Line: Text)
    begin
        Log += Line + '; ';
    end;

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
        Log += 'before-modify event: rec filters=[' + Rec.GetFilters() + '] hasfilter=' + Format(Rec.HasFilter()) + ' key=' + Rec.CurrentKey() +
            '; xrec filters=[' + xRec.GetFilters() + '] hasfilter=' + Format(xRec.HasFilter()) + ' key=' + xRec.CurrentKey() +
            '; formats equal=' + Format(Same) +
            '; xrec no=' + xRec."No." + ' member=[' + xRec.Member + '] rec member=[' + Rec.Member + ']' +
            '; copy filters=[' + Copied.GetFilters() + '] copy find=' + Format(Copied.Find()) +
            '; assigned filters=[' + Assigned.GetFilters() + '] assigned find=' + Format(Assigned.Find()) +
            '; copy find statement ok=' + Format(StatementOk) + ' err=[' + Text1 + ']' +
            '; xrec find=' + Format(xRec.Find()) + '; ';
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT K12 XRec Row", OnAfterModifyEvent, '', false, false)]
    local procedure OnAfterModify(var Rec: Record "LT K12 XRec Row"; var xRec: Record "LT K12 XRec Row"; RunTrigger: Boolean)
    begin
        Log += 'after-modify event: rec member=' + Rec.Member + ' xrec member=' + xRec.Member + ' xrecfilters=[' + xRec.GetFilters() + '] equal=' + Format(Format(Rec) = Format(xRec)) + '; ';
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT K12 XRec Row", OnBeforeValidateEvent, Member, false, false)]
    local procedure OnBeforeValidateMember(var Rec: Record "LT K12 XRec Row"; var xRec: Record "LT K12 XRec Row"; CurrFieldNo: Integer)
    begin
        Log += 'before-validate event: rec member=' + Rec.Member + ' xrec member=' + xRec.Member + ' xrecfilters=[' + xRec.GetFilters() + ']; ';
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT K12 XRec Row", OnAfterValidateEvent, Member, false, false)]
    local procedure OnAfterValidateMember(var Rec: Record "LT K12 XRec Row"; var xRec: Record "LT K12 XRec Row"; CurrFieldNo: Integer)
    begin
        Log += 'after-validate event: rec member=' + Rec.Member + ' xrec member=' + xRec.Member + ' xrecfilters=[' + xRec.GetFilters() + ']; ';
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
        Observer.Expect('modify, filter excludes the row', 'before-modify event: rec filters=[Company: 0001] hasfilter=Yes key=No.; xrec filters=[Company: 0001] hasfilter=Yes key=No.; formats equal=Yes; xrec no=CT2 member=[X-1] rec member=[X-1]; copy filters=[Company: 0001] copy find=No; assigned filters=[] assigned find=Yes; copy find statement ok=No err=[The LT K12 XRec Row does not exist. Identification fields and values: No.=''CT2'']; xrec find=No; after-modify event: rec member=X-1 xrec member=X-1 xrecfilters=[Company: 0001] equal=Yes; ');
        Observer.Expect('caller filters after', 'Company: 0001');
        Observer.Verify();
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
        Observer.Expect('modify, filter includes the row', 'before-modify event: rec filters=[Company: 0001] hasfilter=Yes key=No.; xrec filters=[Company: 0001] hasfilter=Yes key=No.; formats equal=Yes; xrec no=CT1 member=[X-1] rec member=[X-1]; copy filters=[Company: 0001] copy find=Yes; assigned filters=[] assigned find=Yes; copy find statement ok=Yes err=[]; xrec find=Yes; after-modify event: rec member=X-1 xrec member= xrecfilters=[Company: 0001] equal=No; ');
        Observer.Verify();
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
        Observer.Expect('modify, no filter', 'before-modify event: rec filters=[] hasfilter=No key=No.; xrec filters=[] hasfilter=No key=No.; formats equal=Yes; xrec no=CT2 member=[X-1] rec member=[X-1]; copy filters=[] copy find=Yes; assigned filters=[] assigned find=Yes; copy find statement ok=Yes err=[]; xrec find=Yes; after-modify event: rec member=X-1 xrec member= xrecfilters=[] equal=No; ');
        Observer.Expect('modify(false), filter excludes the row', 'before-modify event: rec filters=[Company: 0001] hasfilter=Yes key=No.; xrec filters=[Company: 0001] hasfilter=Yes key=No.; formats equal=Yes; xrec no=CT2 member=[X-2] rec member=[X-2]; copy filters=[Company: 0001] copy find=No; assigned filters=[] assigned find=Yes; copy find statement ok=No err=[The LT K12 XRec Row does not exist. Identification fields and values: No.=''CT2'']; xrec find=No; after-modify event: rec member=X-2 xrec member=X-2 xrecfilters=[Company: 0001] equal=Yes; ');
        Observer.Verify();
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
        Observer.Expect('modify, secondary key and filter', 'before-modify event: rec filters=[Company: 0002] hasfilter=Yes key=Company,No.; xrec filters=[Company: 0002] hasfilter=Yes key=Company,No.; formats equal=Yes; xrec no=CT2 member=[X-1] rec member=[X-1]; copy filters=[Company: 0002] copy find=Yes; assigned filters=[] assigned find=Yes; copy find statement ok=Yes err=[]; xrec find=Yes; after-modify event: rec member=X-1 xrec member= xrecfilters=[Company: 0002] equal=No; ');
        Observer.Expect('modify, filter on the primary key excludes the row', 'before-modify event: rec filters=[No.: CT1|CT3] hasfilter=Yes key=No.; xrec filters=[No.: CT1|CT3] hasfilter=Yes key=No.; formats equal=Yes; xrec no=CT2 member=[X-2] rec member=[X-2]; copy filters=[No.: CT1|CT3] copy find=No; assigned filters=[] assigned find=Yes; copy find statement ok=No err=[The LT K12 XRec Row does not exist. Identification fields and values: No.=''CT2'']; xrec find=No; after-modify event: rec member=X-2 xrec member=X-2 xrecfilters=[No.: CT1|CT3] equal=Yes; ');
        Observer.Verify();
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
        Observer.Expect('modify, row found under the filter', 'before-modify event: rec filters=[Company: 0001] hasfilter=Yes key=No.; xrec filters=[Company: 0001] hasfilter=Yes key=No.; formats equal=Yes; xrec no=CT1 member=[X-1] rec member=[X-1]; copy filters=[Company: 0001] copy find=Yes; assigned filters=[] assigned find=Yes; copy find statement ok=Yes err=[]; xrec find=Yes; after-modify event: rec member=X-1 xrec member= xrecfilters=[Company: 0001] equal=No; ');
        Observer.Expect('modify, field in the filter changed to leave it', 'before-modify event: rec filters=[Company: 0001] hasfilter=Yes key=No.; xrec filters=[Company: 0001] hasfilter=Yes key=No.; formats equal=Yes; xrec no=CT1 member=[X-1] rec member=[X-1]; copy filters=[Company: 0001] copy find=Yes; assigned filters=[] assigned find=Yes; copy find statement ok=Yes err=[]; xrec find=Yes; after-modify event: rec member=X-1 xrec member=X-1 xrecfilters=[Company: 0001] equal=No; ');
        Observer.Verify();
    end;

    // Matrix: how the change happens (cells below) x where xRec is read (field OnValidate, before/after validate event, table OnModify,
    // before/after modify event), each with a filter left on the caller's variable and without. One row of the matrix per observation.
    [Test]
    procedure Y7408_Matrix_ValidateInCode_ThenModify()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT K12 XRec Row";
    begin
        Seed();
        Row.Get('CT1');
        Row.Validate(Member, 'V-1');
        Observer.Observe('Validate (new value), no filter', Subscriber.Take());
        Row.Modify(true);
        Observer.Observe('then Modify(true), no filter', Subscriber.Take());
        Row.SetRange(Company, '0002');
        Row.Get('CT3');
        Row.Validate(Member, 'V-2');
        Observer.Observe('Validate on a row outside the filter', Subscriber.Take());
        Row.Modify(true);
        Observer.Observe('then Modify(true) outside the filter', Subscriber.Take());
        Observer.Expect('Validate (new value), no filter', 'before-validate event: rec member=V-1 xrec member= xrecfilters=[]; field OnValidate Member=V-1 xrec= xrecfilters=[]; after-validate event: rec member=V-1 xrec member= xrecfilters=[]; ');
        Observer.Expect('then Modify(true), no filter', 'before-modify event: rec filters=[] hasfilter=No key=No.; xrec filters=[] hasfilter=No key=No.; formats equal=Yes; xrec no=CT1 member=[V-1] rec member=[V-1]; copy filters=[] copy find=Yes; assigned filters=[] assigned find=Yes; copy find statement ok=Yes err=[]; xrec find=Yes; table OnModify Member=V-1 xrec= xrecfilters=[] recfilters=[]; after-modify event: rec member=V-1 xrec member= xrecfilters=[] equal=No; ');
        Observer.Expect('Validate on a row outside the filter', 'before-validate event: rec member=V-2 xrec member= xrecfilters=[Company: 0002]; field OnValidate Member=V-2 xrec= xrecfilters=[Company: 0002]; after-validate event: rec member=V-2 xrec member= xrecfilters=[Company: 0002]; ');
        Observer.Expect('then Modify(true) outside the filter', 'before-modify event: rec filters=[Company: 0002] hasfilter=Yes key=No.; xrec filters=[Company: 0002] hasfilter=Yes key=No.; formats equal=Yes; xrec no=CT3 member=[V-2] rec member=[V-2]; copy filters=[Company: 0002] copy find=No; assigned filters=[] assigned find=Yes; copy find statement ok=No err=[The LT K12 XRec Row does not exist. Identification fields and values: No.=''CT3'']; xrec find=No; table OnModify Member=V-2 xrec=V-2 xrecfilters=[Company: 0002] recfilters=[Company: 0002]; after-modify event: rec member=V-2 xrec member=V-2 xrecfilters=[Company: 0002] equal=Yes; ');
        Observer.Verify();
    end;

    [Test]
    procedure Y7408_Matrix_ValidateSameValue_And_AssignThenValidate()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT K12 XRec Row";
    begin
        Seed();
        Row.Get('CT1');
        Row.Member := 'A';
        Row.Modify();
        Subscriber.Take();
        Row.Validate(Member, 'A');
        Observer.Observe('Validate with the value already held', Subscriber.Take());
        Row.Member := 'B';
        Row.Validate(Member);
        Observer.Observe('assign, then Validate(field) without a value', Subscriber.Take());
        Row.Modify();
        Observer.Observe('then Modify', Subscriber.Take());
        Row.Modify();
        Observer.Observe('second Modify with no change', Subscriber.Take());
        Observer.Expect('Validate with the value already held', 'before-validate event: rec member=A xrec member=A xrecfilters=[]; field OnValidate Member=A xrec=A xrecfilters=[]; after-validate event: rec member=A xrec member=A xrecfilters=[]; ');
        Observer.Expect('assign, then Validate(field) without a value', 'before-validate event: rec member=B xrec member=B xrecfilters=[]; field OnValidate Member=B xrec=B xrecfilters=[]; after-validate event: rec member=B xrec member=B xrecfilters=[]; ');
        Observer.Expect('then Modify', 'before-modify event: rec filters=[] hasfilter=No key=No.; xrec filters=[] hasfilter=No key=No.; formats equal=Yes; xrec no=CT1 member=[B] rec member=[B]; copy filters=[] copy find=Yes; assigned filters=[] assigned find=Yes; copy find statement ok=Yes err=[]; xrec find=Yes; after-modify event: rec member=B xrec member=A xrecfilters=[] equal=No; ');
        Observer.Expect('second Modify with no change', 'before-modify event: rec filters=[] hasfilter=No key=No.; xrec filters=[] hasfilter=No key=No.; formats equal=Yes; xrec no=CT1 member=[B] rec member=[B]; copy filters=[] copy find=Yes; assigned filters=[] assigned find=Yes; copy find statement ok=Yes err=[]; xrec find=Yes; after-modify event: rec member=B xrec member=B xrecfilters=[] equal=Yes; ');
        Observer.Verify();
    end;

    [Test]
    procedure Y7408_Matrix_ModifyFalse_ModifyAll_Rename()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT K12 XRec Row";
    begin
        Seed();
        Row.SetRange(Company, '0001');
        Row.ModifyAll(Member, 'M-ALL', true);
        Observer.Observe('ModifyAll(true) under a filter', Subscriber.Take());
        Row.Reset();
        Row.Get('CT2');
        Row.Member := 'Z';
        Row.Modify(false);
        Observer.Observe('Modify(false), no filter', Subscriber.Take());
        Observer.Expect('ModifyAll(true) under a filter', 'before-modify event: rec filters=[Company: 0001] hasfilter=Yes key=No.; xrec filters=[Company: 0001] hasfilter=Yes key=No.; formats equal=Yes; xrec no=CT1 member=[M-ALL] rec member=[M-ALL]; copy filters=[Company: 0001] copy find=Yes; assigned filters=[] assigned find=Yes; copy find statement ok=Yes err=[]; xrec find=Yes; table OnModify Member=M-ALL xrec= xrecfilters=[Company: 0001] recfilters=[Company: 0001]; after-modify event: rec member=M-ALL xrec member= xrecfilters=[Company: 0001] equal=No; before-modify event: rec filters=[Company: 0001] hasfilter=Yes key=No.; xrec filters=[Company: 0001] hasfilter=Yes key=No.; formats equal=Yes; xrec no=CT3 member=[M-ALL] rec member=[M-ALL]; copy filters=[Company: 0001] copy find=Yes; assigned filters=[] assigned find=Yes; copy find statement ok=Yes err=[]; xrec find=Yes; table OnModify Member=M-ALL xrec= xrecfilters=[Company: 0001] recfilters=[Company: 0001]; after-modify event: rec member=M-ALL xrec member= xrecfilters=[Company: 0001] equal=No; ');
        Observer.Expect('Modify(false), no filter', 'before-modify event: rec filters=[] hasfilter=No key=No.; xrec filters=[] hasfilter=No key=No.; formats equal=Yes; xrec no=CT2 member=[Z] rec member=[Z]; copy filters=[] copy find=Yes; assigned filters=[] assigned find=Yes; copy find statement ok=Yes err=[]; xrec find=Yes; after-modify event: rec member=Z xrec member= xrecfilters=[] equal=No; ');
        Observer.Verify();
    end;
}
