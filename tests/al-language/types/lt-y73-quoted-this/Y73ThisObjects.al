// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-this-keyword
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); codeunits 93900 (publisher), 93901 (subject) and 93902 (log) of Y73ThisCodeunit.al; self-contained objects 93904-93920
// Probe: measured on Windows BC 27.5, 28.5, 29.0 and SaaS BC 29 (writer Y73, 2026-11-02); identical on all; every literal asserted below is what BC produced.
// Facts: a variable named "this" in quotes in a table, page, report, xmlport, query and in a table / page / report extension, next to the `this` keyword. Per kind two shapes:
//   (A) "this" has the object's own type: the call "this".SetTag('V') reaches the variable instance, this.GetTag() the running object, in a procedure called from outside and in a trigger;
//   (B) "this" is a Codeunit "LT Y73 Subject": BindSubscription("this") / UnbindSubscription("this") bind the variable, this.Bump() runs on the object itself.
// BC versions: 27, 28, 29

table 93904 "LT Y73 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    var
        "this": Record "LT Y73 Row";
        Tag: Text;

    procedure SetTag(NewTag: Text)
    begin
        Tag := NewTag;
    end;

    procedure GetTag(): Text
    begin
        exit(Tag);
    end;

    procedure OwnScenario(): Text
    begin
        Tag := 'S';
        "this".SetTag('V');
        exit(Tag + '|' + "this".GetTag() + '|' + this.GetTag());
    end;

    trigger OnInsert()
    var
        Log: Codeunit "LT Y73 Log";
    begin
        Log.Add('table-trigger=' + OwnScenario());
    end;
}

table 93905 "LT Y73 RowB"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    var
        "this": Codeunit "LT Y73 Subject";
        Own: Integer;

    procedure BindScenario(): Text
    var
        Pub: Codeunit "LT Y73 Pub";
        Bound: Text;
    begin
        "this".SetTag('V');
        BindSubscription("this");
        Bound := Pub.Fire();
        UnbindSubscription("this");
        this.Bump();
        Bump();
        exit(Bound + '|after=' + Pub.Fire() + '|own=' + Format(Own));
    end;

    procedure Bump()
    begin
        Own += 1;
    end;

    trigger OnInsert()
    var
        Log: Codeunit "LT Y73 Log";
    begin
        Log.Add('tableb-trigger=' + BindScenario());
    end;
}

page 93906 "LT Y73 PageA"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout { area(Content) { field(T; Tag) { ApplicationArea = All; } } }

    var
        "this": Page "LT Y73 PageA";
        Tag: Text;

    procedure SetTag(NewTag: Text)
    begin
        Tag := NewTag;
    end;

    procedure GetTag(): Text
    begin
        exit(Tag);
    end;

    procedure OwnScenario(): Text
    begin
        Tag := 'S';
        "this".SetTag('V');
        exit(Tag + '|' + "this".GetTag() + '|' + this.GetTag());
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT Y73 Log";
    begin
        Log.Add('page-trigger=' + OwnScenario());
    end;
}

page 93907 "LT Y73 PageB"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout { area(Content) { field(O; Own) { ApplicationArea = All; } } }

    var
        "this": Codeunit "LT Y73 Subject";
        Own: Integer;

    procedure BindScenario(): Text
    var
        Pub: Codeunit "LT Y73 Pub";
        Bound: Text;
    begin
        "this".SetTag('V');
        BindSubscription("this");
        Bound := Pub.Fire();
        UnbindSubscription("this");
        this.Bump();
        Bump();
        exit(Bound + '|after=' + Pub.Fire() + '|own=' + Format(Own));
    end;

    procedure Bump()
    begin
        Own += 1;
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT Y73 Log";
    begin
        Log.Add('pageb-trigger=' + BindScenario());
    end;
}

report 93908 "LT Y73 ReportA"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    var
        "this": Report "LT Y73 ReportA";
        Tag: Text;

    procedure SetTag(NewTag: Text)
    begin
        Tag := NewTag;
    end;

    procedure GetTag(): Text
    begin
        exit(Tag);
    end;

    procedure OwnScenario(): Text
    begin
        Tag := 'S';
        "this".SetTag('V');
        exit(Tag + '|' + "this".GetTag() + '|' + this.GetTag());
    end;

    trigger OnPreReport()
    var
        Log: Codeunit "LT Y73 Log";
    begin
        Log.Add('report-trigger=' + OwnScenario());
    end;
}

report 93909 "LT Y73 ReportB"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    var
        "this": Codeunit "LT Y73 Subject";
        Own: Integer;

    procedure BindScenario(): Text
    var
        Pub: Codeunit "LT Y73 Pub";
        Bound: Text;
    begin
        "this".SetTag('V');
        BindSubscription("this");
        Bound := Pub.Fire();
        UnbindSubscription("this");
        this.Bump();
        Bump();
        exit(Bound + '|after=' + Pub.Fire() + '|own=' + Format(Own));
    end;

    procedure Bump()
    begin
        Own += 1;
    end;

    trigger OnPreReport()
    var
        Log: Codeunit "LT Y73 Log";
    begin
        Log.Add('reportb-trigger=' + BindScenario());
    end;
}

xmlport 93910 "LT Y73 XmlPortA"
{
    Direction = Export;

    schema { textelement(Root) { } }

    var
        "this": XmlPort "LT Y73 XmlPortA";
        Tag: Text;

    procedure SetTag(NewTag: Text)
    begin
        Tag := NewTag;
    end;

    procedure GetTag(): Text
    begin
        exit(Tag);
    end;

    procedure OwnScenario(): Text
    begin
        Tag := 'S';
        "this".SetTag('V');
        exit(Tag + '|' + "this".GetTag() + '|' + this.GetTag());
    end;

    trigger OnPreXmlPort()
    var
        Log: Codeunit "LT Y73 Log";
    begin
        Log.Add('xmlport-trigger=' + OwnScenario());
    end;
}

xmlport 93911 "LT Y73 XmlPortB"
{
    Direction = Export;

    schema { textelement(Root) { } }

    var
        "this": Codeunit "LT Y73 Subject";
        Own: Integer;

    procedure BindScenario(): Text
    var
        Pub: Codeunit "LT Y73 Pub";
        Bound: Text;
    begin
        "this".SetTag('V');
        BindSubscription("this");
        Bound := Pub.Fire();
        UnbindSubscription("this");
        this.Bump();
        Bump();
        exit(Bound + '|after=' + Pub.Fire() + '|own=' + Format(Own));
    end;

    procedure Bump()
    begin
        Own += 1;
    end;

    trigger OnPreXmlPort()
    var
        Log: Codeunit "LT Y73 Log";
    begin
        Log.Add('xmlportb-trigger=' + BindScenario());
    end;
}

query 93913 "LT Y73 QueryA"
{
    elements { dataitem(I; "LT Y73 Row") { column(Id; Id) { } } }

    var
        "this": Query "LT Y73 QueryA";
        Tag: Text;

    procedure SetTag(NewTag: Text)
    begin
        Tag := NewTag;
    end;

    procedure GetTag(): Text
    begin
        exit(Tag);
    end;

    procedure OwnScenario(): Text
    begin
        Tag := 'S';
        "this".SetTag('V');
        exit(Tag + '|' + "this".GetTag() + '|' + this.GetTag());
    end;

    trigger OnBeforeOpen()
    var
        Log: Codeunit "LT Y73 Log";
    begin
        Log.Add('query-trigger=' + OwnScenario());
    end;
}

query 93914 "LT Y73 QueryB"
{
    elements { dataitem(I; "LT Y73 Row") { column(Id; Id) { } } }

    var
        "this": Codeunit "LT Y73 Subject";
        Own: Integer;

    procedure BindScenario(): Text
    var
        Pub: Codeunit "LT Y73 Pub";
        Bound: Text;
    begin
        "this".SetTag('V');
        BindSubscription("this");
        Bound := Pub.Fire();
        UnbindSubscription("this");
        this.Bump();
        Bump();
        exit(Bound + '|after=' + Pub.Fire() + '|own=' + Format(Own));
    end;

    procedure Bump()
    begin
        Own += 1;
    end;

    trigger OnBeforeOpen()
    var
        Log: Codeunit "LT Y73 Log";
    begin
        Log.Add('queryb-trigger=' + BindScenario());
    end;
}

tableextension 93915 "LT Y73 RowBExt" extends "LT Y73 RowB"
{
    fields { field(93915; ExtraField; Integer) { } }

    var
        "this": Codeunit "LT Y73 Subject";
        ExtOwn: Integer;

    procedure ExtBindScenario(): Text
    var
        Pub: Codeunit "LT Y73 Pub";
        Bound: Text;
    begin
        "this".SetTag('EV');
        BindSubscription("this");
        Bound := Pub.Fire();
        UnbindSubscription("this");
        this.ExtBump();
        ExtOwn += 0;
        exit(Bound + '|after=' + Pub.Fire());
    end;

    procedure ExtBump()
    begin
    end;

    trigger OnAfterModify()
    var
        Log: Codeunit "LT Y73 Log";
    begin
        Log.Add('tableext-trigger=' + ExtBindScenario());
    end;
}

pageextension 93916 "LT Y73 PageBExt" extends "LT Y73 PageB"
{
    var
        "this": Codeunit "LT Y73 Subject";

    trigger OnOpenPage()
    var
        Pub: Codeunit "LT Y73 Pub";
        Log: Codeunit "LT Y73 Log";
        Bound: Text;
    begin
        "this".SetTag('EV');
        BindSubscription("this");
        Bound := Pub.Fire();
        UnbindSubscription("this");
        Log.Add('pageext-trigger=' + Bound + '|after=' + Pub.Fire());
    end;
}

reportextension 93917 "LT Y73 ReportBExt" extends "LT Y73 ReportB"
{
    var
        "this": Codeunit "LT Y73 Subject";

    trigger OnPreReport()
    var
        Pub: Codeunit "LT Y73 Pub";
        Log: Codeunit "LT Y73 Log";
        Bound: Text;
    begin
        "this".SetTag('EV');
        BindSubscription("this");
        Bound := Pub.Fire();
        UnbindSubscription("this");
        Log.Add('reportext-trigger=' + Bound + '|after=' + Pub.Fire());
    end;
}

codeunit 93918 "LT Y73 Object Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Table_OwnType_And_Codeunit_Variable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y73 Log";
        Row: Record "LT Y73 Row";
        RowB: Record "LT Y73 RowB";
    begin
        Log.Take();
        Observer.Observe('table_procedure', Row.OwnScenario());
        Row.Id := 1;
        Row.Insert(true);
        Observer.Observe('table_trigger', Log.Take());
        Observer.Observe('tableb_procedure', RowB.BindScenario());
        RowB.Id := 1;
        RowB.Insert(true);
        Observer.Observe('tableb_trigger', Log.Take());
        Observer.Expect('table_procedure', 'S|V|S');
        Observer.Expect('table_trigger', 'table-trigger=S|V|S;');
        Observer.Expect('tableb_procedure', '[V]|after=|own=2');
        Observer.Expect('tableb_trigger', 'tableb-trigger=[V]|after=|own=4;');
        Observer.Verify();
    end;

    [Test]
    procedure TableExtension_Codeunit_Variable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y73 Log";
        RowB: Record "LT Y73 RowB";
    begin
        Log.Take();
        Observer.Observe('tableext_procedure', RowB.ExtBindScenario());
        RowB.Id := 2;
        RowB.Insert(false);
        RowB.Modify(true);
        Observer.Observe('tableext_trigger', Log.Take());
        Observer.Expect('tableext_procedure', '[EV]|after=');
        Observer.Expect('tableext_trigger', 'tableext-trigger=[EV]|after=;');
        Observer.Verify();
    end;

    [Test]
    procedure Page_OwnType_And_Codeunit_Variable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y73 Log";
        PageA: Page "LT Y73 PageA";
        PageB: Page "LT Y73 PageB";
        TestA: TestPage "LT Y73 PageA";
        TestB: TestPage "LT Y73 PageB";
    begin
        Log.Take();
        Observer.Observe('page_procedure', PageA.OwnScenario());
        TestA.OpenView();
        TestA.Close();
        Observer.Observe('page_trigger', Log.Take());
        Observer.Observe('pageb_procedure', PageB.BindScenario());
        TestB.OpenView();
        TestB.Close();
        Observer.Observe('pageb_trigger', Log.Take());
        Observer.Expect('page_procedure', 'S|V|S');
        Observer.Expect('page_trigger', 'page-trigger=S|V|S;');
        Observer.Expect('pageb_procedure', '[V]|after=|own=2');
        Observer.Expect('pageb_trigger', 'pageb-trigger=[V]|after=|own=2;pageext-trigger=[EV]|after=;');
        Observer.Verify();
    end;

    [Test]
    procedure Report_OwnType_And_Codeunit_Variable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y73 Log";
        ReportA: Report "LT Y73 ReportA";
        ReportB: Report "LT Y73 ReportB";
    begin
        Log.Take();
        Observer.Observe('report_procedure', ReportA.OwnScenario());
        ReportA.UseRequestPage(false);
        ReportA.Run();
        Observer.Observe('report_trigger', Log.Take());
        Observer.Observe('reportb_procedure', ReportB.BindScenario());
        ReportB.UseRequestPage(false);
        ReportB.Run();
        Observer.Observe('reportb_trigger', Log.Take());
        Observer.Expect('report_procedure', 'S|V|S');
        Observer.Expect('report_trigger', 'report-trigger=S|V|S;');
        Observer.Expect('reportb_procedure', '[V]|after=|own=2');
        Observer.Expect('reportb_trigger', 'reportb-trigger=[V]|after=|own=4;reportext-trigger=[EV]|after=;');
        Observer.Verify();
    end;

    [Test]
    procedure XmlPort_OwnType_And_Codeunit_Variable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y73 Log";
        XmlPortA: XmlPort "LT Y73 XmlPortA";
        XmlPortB: XmlPort "LT Y73 XmlPortB";
        Stream: OutStream;
        TempBlob: Codeunit "Temp Blob";
    begin
        Log.Take();
        Observer.Observe('xmlport_procedure', XmlPortA.OwnScenario());
        TempBlob.CreateOutStream(Stream);
        XmlPortA.SetDestination(Stream);
        XmlPortA.Export();
        Observer.Observe('xmlport_trigger', Log.Take());
        Observer.Observe('xmlportb_procedure', XmlPortB.BindScenario());
        TempBlob.CreateOutStream(Stream);
        XmlPortB.SetDestination(Stream);
        XmlPortB.Export();
        Observer.Observe('xmlportb_trigger', Log.Take());
        Observer.Expect('xmlport_procedure', 'S|V|S');
        Observer.Expect('xmlport_trigger', 'xmlport-trigger=S|V|S;');
        Observer.Expect('xmlportb_procedure', '[V]|after=|own=2');
        Observer.Expect('xmlportb_trigger', 'xmlportb-trigger=[V]|after=|own=4;');
        Observer.Verify();
    end;

    [Test]
    procedure Query_OwnType_And_Codeunit_Variable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y73 Log";
        QueryA: Query "LT Y73 QueryA";
        QueryB: Query "LT Y73 QueryB";
    begin
        Log.Take();
        Observer.Observe('query_procedure', QueryA.OwnScenario());
        QueryA.Open();
        QueryA.Close();
        Observer.Observe('query_trigger', Log.Take());
        Observer.Observe('queryb_procedure', QueryB.BindScenario());
        QueryB.Open();
        QueryB.Close();
        Observer.Observe('queryb_trigger', Log.Take());
        Observer.Expect('query_procedure', 'S|V|S');
        Observer.Expect('query_trigger', 'query-trigger=S|V|S;');
        Observer.Expect('queryb_procedure', '[V]|after=|own=2');
        Observer.Expect('queryb_trigger', 'queryb-trigger=[V]|after=|own=4;');
        Observer.Verify();
    end;
}
