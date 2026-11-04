// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); cross-app fixtures A (table 95520, tableextension 95521, page 95522, report 95523) and B
//   (tableextension 95524); Base Application table "Sales Line" (no row is written); own objects below.
// Probe (al-runner issues 6983 and 6984): the full surface of `protected var` across apps and through another record variable.
// Facts:
//   - An extension of a table in app B (depends on app A) reads and writes a protected variable that app A's extension of the same table
//     declares, and one that app A's table declares; a field trigger of app B reads it. One variable per record variable, shared by all
//     the extensions and the table (issue 6983).
//   - A third app (this one, depends on A and B) reads and writes the protected variables of both.
//   - The member form `Other.ProtVar` on another record variable of the same table compiles in a table extension, for a protected
//     variable of the table and of another extension in another app; it reads and writes Other's variable, not Rec's. Microsoft's
//     "Sales Line" protected variable StatusCheckSuspended works the same way (issue 6984). In the same app the member form is read
//     only here: writing it (a variable of the table or of another extension in the same app) compiles with alc, but real BC 29
//     fails to compile the extension's C# (CS0131) and every use of the table raises "C# compilation has failed" (tables 95533,
//     95535).
//   - A page extension and a report extension in another app read and write a protected variable of their base page and report.
//   - Not compiling (must-not-compile): an app that does not depend on app B naming B's protected variable (2952); a codeunit naming a
//     protected variable of a table through a record variable (2953).
// local object: the protected variable uses of these extensions are under test.
// BC versions: 27, 28, 29 (by the corpus CI matrix)

tableextension 95526 "TBL ProtVar Main Ext" extends "TBL ProtVar XA Table"
{
    procedure MainGetExtHide(): Boolean
    begin
        exit(ExtHide);
    end;

    procedure MainSetXbCounter(Value: Integer)
    begin
        XbCounter := Value;
    end;

    procedure MainGetXbCounter(): Integer
    begin
        exit(XbCounter);
    end;

    procedure MainGetBaseText(): Text
    begin
        exit(BaseText);
    end;

    procedure MainSetOtherXbCounter(var Other: Record "TBL ProtVar XA Table"; Value: Integer)
    begin
        Other.XbCounter := Value;
    end;

    procedure MainGetOtherExtHide(var Other: Record "TBL ProtVar XA Table"): Boolean
    begin
        exit(Other.ExtHide);
    end;
}

// Same app, base table: a protected variable of the table, only read through another record variable. Written that way
// (`Other.Marker := Value`), real BC 29 fails to compile the extension's C# (CS0131, first run of corpus PR 1126), as for a
// sibling extension's variable below.
table 95533 "TBL ProtVar Same Table"
{
    DataClassification = SystemMetadata;

    fields { field(1; "Code"; Code[20]) { } }
    keys { key(PK; "Code") { Clustered = true; } }

    protected var
        Marker: Text;

    procedure SetMarker(Value: Text)
    begin
        Marker := Value;
    end;
}

tableextension 95534 "TBL ProtVar Same Table Ext" extends "TBL ProtVar Same Table"
{
    procedure ProtGetOtherMarker(var Other: Record "TBL ProtVar Same Table"): Text
    begin
        exit(Other.Marker);
    end;
}

// Same app, sibling extension: a protected variable of another extension of the same table in this app, only read through
// another record variable. Written that way (`Other.Counter := Value`), real BC 29 fails to compile the extension's C# (CS0131,
// "The left-hand side of an assignment must be a variable", first run of corpus PR 1126) and every use of the table raises
// "C# compilation has failed"; that form is therefore not in the corpus app.
table 95535 "TBL ProtVar Same Sib"
{
    DataClassification = SystemMetadata;

    fields { field(1; "Code"; Code[20]) { } }
    keys { key(PK; "Code") { Clustered = true; } }
}

tableextension 95536 "TBL ProtVar Same Sib Decl" extends "TBL ProtVar Same Sib"
{
    protected var
        Counter: Integer;

    procedure SetCounter(Value: Integer)
    begin
        Counter := Value;
    end;
}

tableextension 95537 "TBL ProtVar Same Sib Use" extends "TBL ProtVar Same Sib"
{
    procedure ProtGetOtherCounter(var Other: Record "TBL ProtVar Same Sib"): Integer
    begin
        exit(Other.Counter);
    end;
}

tableextension 95532 "TBL ProtVar Sales Line Ext" extends "Sales Line"
{
    // The shape of issue 6984: another Sales Line record variable, not Rec. No row is read or written.
    procedure ProtSuspendOther(var SalesLineToSplit: Record "Sales Line"; Suspend: Boolean)
    begin
        SalesLineToSplit.StatusCheckSuspended := Suspend;
    end;

    procedure ProtOtherSuspended(var SalesLineToSplit: Record "Sales Line"): Boolean
    begin
        exit(SalesLineToSplit.StatusCheckSuspended);
    end;

    procedure ProtOwnSuspended(): Boolean
    begin
        exit(StatusCheckSuspended);
    end;
}

pageextension 95529 "TBL ProtVar Card Ext" extends "TBL ProtVar XA Card"
{
    procedure MainGetPageText(): Text
    begin
        exit(PageText);
    end;

    procedure MainSetPageText(Value: Text)
    begin
        PageText := Value;
    end;
}

reportextension 95530 "TBL ProtVar Report Ext" extends "TBL ProtVar XA Report"
{
    procedure MainGetRepText(): Text
    begin
        exit(RepText);
    end;

    procedure MainSetRepText(Value: Text)
    begin
        RepText := Value;
    end;
}

codeunit 95531 "TBL ProtVar Cross App"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Issue 6983: app B reads and writes the protected variable of app A's extension; one value per record variable.
    [Test]
    procedure ProtVar_OtherAppExtensionVar_ReadAndWrite()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "TBL ProtVar XA Table";
        Second: Record "TBL ProtVar XA Table";
    begin
        R.XaSetExtHide(true);
        Observer.Observe('a_writes_b_reads', Format(R.XbGetExtHide()));
        R.XbSetExtHide(false);
        Observer.Observe('b_writes_a_reads', Format(R.XaGetExtHide()));
        R.XbSetExtText('from b');
        Observer.Observe('b_writes_text_a_reads', R.XaGetExtText());
        Second.XaSetExtHide(true);
        Observer.Observe('second_variable', Format(Second.XbGetExtHide()));
        Observer.Observe('first_after_second', Format(R.XbGetExtHide()));
        Observer.Expect('a_writes_b_reads', 'Yes');
        Observer.Expect('b_writes_a_reads', 'No');
        Observer.Expect('b_writes_text_a_reads', 'from b');
        Observer.Expect('second_variable', 'Yes');
        Observer.Expect('first_after_second', 'No');
        Observer.Verify();
    end;

    // The reporter's shape of issue 6983: a field trigger of app B reads app A's extension variable.
    [Test]
    procedure ProtVar_OtherAppExtensionVar_ReadInFieldTrigger()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "TBL ProtVar XA Table";
    begin
        R.XaSetExtHide(true);
        R.Validate("XB Weight", 5);
        Observer.Observe('hidden', Format(R."XB Synced"));
        R.XaSetExtHide(false);
        R.Validate("XB Weight", 6);
        Observer.Observe('not_hidden', Format(R."XB Synced"));
        Observer.Expect('hidden', 'No');
        Observer.Expect('not_hidden', 'Yes');
        Observer.Verify();
    end;

    // App B reads and writes the protected variables of app A's table.
    [Test]
    procedure ProtVar_OtherAppTableVar_ReadAndWrite()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "TBL ProtVar XA Table";
    begin
        R.XaSetBaseText('from a');
        Observer.Observe('a_writes_b_reads', R.XbGetBaseText());
        R.XbSetBaseText('from b');
        Observer.Observe('b_writes_a_reads', R.XaGetBaseText());
        R.XbSetBaseFlag(true);
        Observer.Observe('flag', Format(R.XaGetBaseFlag()));
        Observer.Expect('a_writes_b_reads', 'from a');
        Observer.Expect('b_writes_a_reads', 'from b');
        Observer.Expect('flag', 'Yes');
        Observer.Verify();
    end;

    // Member form in app B: Other.ExtHide (app A's extension) and Other.BaseText (app A's table) are Other's, not Rec's.
    [Test]
    procedure ProtVar_OtherRecordVariable_MemberForm_OtherApp()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "TBL ProtVar XA Table";
        Other: Record "TBL ProtVar XA Table";
    begin
        R.XbSetOtherExtHide(Other, true);
        Observer.Observe('other_ext', Format(Other.XaGetExtHide()));
        Observer.Observe('rec_ext', Format(R.XaGetExtHide()));
        Other.XaSetExtHide(false);
        R.XaSetExtHide(true);
        Observer.Observe('read_other_ext', Format(R.XbGetOtherExtHide(Other)));
        R.XbSetOtherBaseText(Other, 'other base');
        Observer.Observe('other_base', Other.XaGetBaseText());
        Observer.Observe('rec_base', R.XaGetBaseText());
        R.XaSetBaseText('rec base');
        Observer.Observe('read_other_base', R.XbGetOtherBaseText(Other));
        Observer.Expect('other_ext', 'Yes');
        Observer.Expect('rec_ext', 'No');
        Observer.Expect('read_other_ext', 'No');
        Observer.Expect('other_base', 'other base');
        Observer.Expect('rec_base', '');
        Observer.Expect('read_other_base', 'other base');
        Observer.Verify();
    end;

    // Member form on a local record variable, read back through procedures of the declaring objects; Rec's variables stay as they were.
    [Test]
    procedure ProtVar_LocalRecordVariable_MemberForm()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "TBL ProtVar XA Table";
    begin
        R.XbSetExtText('rec');
        R.XbSetBaseText('rec');
        Observer.Observe('round_trip', R.XbLocalOtherRoundTrip('local'));
        Observer.Expect('round_trip', 'local|local/base|rec|rec');
        Observer.Verify();
    end;

    // A third app (depends on A and B) reads and writes the protected variables of both, on Rec and through the member form.
    [Test]
    procedure ProtVar_ThirdApp_VarsOfTwoDependencies()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "TBL ProtVar XA Table";
        Other: Record "TBL ProtVar XA Table";
    begin
        R.XbSetCounter(4);
        Observer.Observe('b_writes_main_reads', Format(R.MainGetXbCounter()));
        R.MainSetXbCounter(5);
        Observer.Observe('main_writes_b_reads', Format(R.XbGetCounter()));
        R.XaSetExtHide(true);
        Observer.Observe('a_ext_main_reads', Format(R.MainGetExtHide()));
        R.XaSetBaseText('base');
        Observer.Observe('a_table_main_reads', R.MainGetBaseText());
        R.MainSetOtherXbCounter(Other, 9);
        Observer.Observe('other_counter', Format(Other.XbGetCounter()));
        Observer.Observe('rec_counter', Format(R.XbGetCounter()));
        Other.XaSetExtHide(false);
        Observer.Observe('read_other_ext', Format(R.MainGetOtherExtHide(Other)));
        Observer.Expect('b_writes_main_reads', '4');
        Observer.Expect('main_writes_b_reads', '5');
        Observer.Expect('a_ext_main_reads', 'Yes');
        Observer.Expect('a_table_main_reads', 'base');
        Observer.Expect('other_counter', '9');
        Observer.Expect('rec_counter', '5');
        Observer.Expect('read_other_ext', 'No');
        Observer.Verify();
    end;

    // Member form in the same app, on a protected variable of the table, read only: Other's, not Rec's.
    [Test]
    procedure ProtVar_OtherRecordVariable_MemberFormRead_SameAppTable()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "TBL ProtVar Same Table";
        Other: Record "TBL ProtVar Same Table";
    begin
        Other.SetMarker('m');
        Observer.Observe('read_other', R.ProtGetOtherMarker(Other));
        Observer.Observe('read_rec', R.ProtGetOtherMarker(R));
        Observer.Expect('read_other', 'm');
        Observer.Expect('read_rec', '');
        Observer.Verify();
    end;

    // Member form in the same app, on a protected variable of another extension of the table, read only.
    [Test]
    procedure ProtVar_OtherRecordVariable_MemberFormRead_SameAppSibling()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "TBL ProtVar Same Sib";
        Other: Record "TBL ProtVar Same Sib";
    begin
        Other.SetCounter(8);
        Observer.Observe('read_other', Format(R.ProtGetOtherCounter(Other)));
        Observer.Observe('read_rec', Format(R.ProtGetOtherCounter(R)));
        Observer.Expect('read_other', '8');
        Observer.Expect('read_rec', '0');
        Observer.Verify();
    end;

    // Issue 6984: Sales Line's protected StatusCheckSuspended set on another record variable from an extension of Sales Line.
    [Test]
    procedure ProtVar_SalesLineStatusCheckSuspended_MemberForm()
    var
        Observer: Codeunit "Probe Observer";
        SalesLine: Record "Sales Line";
        SalesLineToSplit: Record "Sales Line";
    begin
        SalesLine.ProtSuspendOther(SalesLineToSplit, true);
        Observer.Observe('other', Format(SalesLine.ProtOtherSuspended(SalesLineToSplit)));
        Observer.Observe('other_own', Format(SalesLineToSplit.ProtOwnSuspended()));
        Observer.Observe('rec', Format(SalesLine.ProtOwnSuspended()));
        SalesLineToSplit.SuspendStatusCheck(false);
        Observer.Observe('after_base_procedure', Format(SalesLine.ProtOtherSuspended(SalesLineToSplit)));
        Observer.Expect('other', 'Yes');
        Observer.Expect('other_own', 'Yes');
        Observer.Expect('rec', 'No');
        Observer.Expect('after_base_procedure', 'No');
        Observer.Verify();
    end;

    // A page extension in this app reads and writes the protected variable of app A's page (the page does not run).
    [Test]
    procedure ProtVar_PageExtension_OtherAppBasePageVar()
    var
        Observer: Codeunit "Probe Observer";
        P: Page "TBL ProtVar XA Card";
    begin
        P.XaSetPageText('from a');
        Observer.Observe('a_writes_ext_reads', P.MainGetPageText());
        P.MainSetPageText('from ext');
        Observer.Observe('ext_writes_a_reads', P.XaGetPageText());
        Observer.Expect('a_writes_ext_reads', 'from a');
        Observer.Expect('ext_writes_a_reads', 'from ext');
        Observer.Verify();
    end;

    // A report extension in this app reads and writes the protected variable of app A's report (the report does not run).
    [Test]
    procedure ProtVar_ReportExtension_OtherAppBaseReportVar()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "TBL ProtVar XA Report";
    begin
        Rep.XaSetRepText('from a');
        Observer.Observe('a_writes_ext_reads', Rep.MainGetRepText());
        Rep.MainSetRepText('from ext');
        Observer.Observe('ext_writes_a_reads', Rep.XaGetRepText());
        Observer.Expect('a_writes_ext_reads', 'from a');
        Observer.Expect('ext_writes_a_reads', 'from ext');
        Observer.Verify();
    end;
}
