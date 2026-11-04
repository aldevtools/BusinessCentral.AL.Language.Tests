// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P105Fix.al; self-contained report 72265 and test codeunit 72266
// Facts: Report.WordXmlPart on a variable (default, false, true) and with the report id; unknown id; only lengths and contains are observed

report 72265 "LT P105 LytWxp Rep"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P105 Row")
        {
            column(Id; Id) { }
            column(Name; Name) { }
        }
    }
}

codeunit 72266 "LT P105 LytWxp Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P105 Helper";

    [Test]
    procedure P105_WordXmlPart_Instance_Extended()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT P105 LytWxp Rep";
        Plain: Text;
        Ext: Text;
    begin
        Helper.Seed();
        Plain := Rpt.WordXmlPart(false);
        Ext := Rpt.WordXmlPart(true);
        Observer.Observe('plain has text', Format(StrLen(Plain) > 0));
        Observer.Observe('ext has text', Format(StrLen(Ext) > 0));
        Observer.Observe('plain equals ext', Format(Plain = Ext));
        Observer.Observe('ext longer or equal', Format(StrLen(Ext) >= StrLen(Plain)));
        Observer.Observe('ext contains Row', Format(Ext.Contains('Row')));
        Observer.Expect('plain has text', 'Yes');
        Observer.Expect('ext has text', 'Yes');
        Observer.Expect('plain equals ext', 'No');
        Observer.Expect('ext longer or equal', 'Yes');
        Observer.Expect('ext contains Row', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P105_WordXmlPart_Instance_Default_EqualsFalse()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT P105 LytWxp Rep";
    begin
        Helper.Seed();
        Observer.Observe('default equals false', Format(Rpt.WordXmlPart() = Rpt.WordXmlPart(false)));
        Observer.Expect('default equals false', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P105_WordXmlPart_Static()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Text;
        Ext: Text;
    begin
        Helper.Seed();
        Plain := Report.WordXmlPart(Report::"LT P105 LytWxp Rep");
        Ext := Report.WordXmlPart(Report::"LT P105 LytWxp Rep", true);
        Observer.Observe('plain has text', Format(StrLen(Plain) > 0));
        Observer.Observe('ext has text', Format(StrLen(Ext) > 0));
        Observer.Observe('ext longer or equal', Format(StrLen(Ext) >= StrLen(Plain)));
        Observer.Expect('plain has text', 'Yes');
        Observer.Expect('ext has text', 'Yes');
        Observer.Expect('ext longer or equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P105_WordXmlPart_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT P105 LytWxp Rep";
        Xml: Text;
    begin
        Helper.SeedEmpty();
        Xml := Rpt.WordXmlPart();
        Observer.Observe('has text', Format(StrLen(Xml) > 0));
        Observer.Expect('has text', 'Yes');
        Observer.Verify();
    end;
}
