// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-obsoletestate-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 93315-93320 (SingleInstance log 93320 is used only by test codeunit 93319)
// Probe (writer Y64, al-runner issue 6652): ObsoleteState = Pending with ObsoleteReason and ObsoleteTag on the sub-elements of a report, a report
//   extension, a query and an XmlPort request page that take them: report data item (also a nested one, with RequestFilterFields), report column,
//   request page, request page group, field and action, report extension column, data item and request page field, query column and filter,
//   XmlPort request page field. The reporter's shape (report 93316: obsolete report and data item, SetTableView, UseRequestPage(false), Run) and
//   the same objects run with a request page, the query read with a filter on the obsolete filter column, the XmlPort exported.
// Compile facts (AL compiler 30, BC 27-29): AL0124 "The property 'ObsoleteState' cannot be used in this context" (and the same for ObsoleteReason
//   and ObsoleteTag) on an XmlPort textelement, tableelement, fieldelement and fieldattribute (must-not-compile 2620) and on a query data item
//   (2621). ObsoleteState = Removed on these elements is AL0169 (must-not-compile 0797, 0798). Pinned elsewhere: objects (misc/lt-u-obsolete-pending),
//   page controls (pages/lt-obsolete-layout-parts), report columns (errors/lt-ms-refusals-138/P138ColObsolete.al), table keys and fields.
// BC versions: 27-29

table 93315 "LT Y64 Obs Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

codeunit 93320 "LT Y64 Obs Log"
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

report 93316 "LT Y64 Obs Report"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Will be replaced.';
    ObsoleteTag = '1.0';
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(MyItem; "LT Y64 Obs Row")
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Will be replaced.';
            ObsoleteTag = '1.0';
            RequestFilterFields = "No.";

            column(NoCol; "No.")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Column replaced.';
                ObsoleteTag = '1.0';
            }
            dataitem(Inner; Integer)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Inner replaced.';
                ObsoleteTag = '1.0';
                DataItemTableView = sorting(Number) where(Number = const(1));

                trigger OnAfterGetRecord()
                begin
                    Log.Add('inner ' + MyItem."No.");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                MyProc(MyItem);
            end;
        }
    }

    requestpage
    {
        ObsoleteState = Pending;
        ObsoleteReason = 'Request page replaced.';
        ObsoleteTag = '1.0';

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Group replaced.';
                    ObsoleteTag = '1.0';

                    field(Flag; FlagValue)
                    {
                        Caption = 'Flag';
                        ObsoleteState = Pending;
                        ObsoleteReason = 'Field replaced.';
                        ObsoleteTag = '1.0';
                    }
                }
            }
        }

        actions
        {
            area(Processing)
            {
                action(RpAction)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Action replaced.';
                    ObsoleteTag = '1.0';

                    trigger OnAction()
                    begin
                        Log.Add('rp action');
                    end;
                }
            }
        }
    }

    trigger OnPostReport()
    begin
        Log.Add('post flag=' + Format(FlagValue) + ' extflag=' + Format(ExtFlagValue));
    end;

    var
        Log: Codeunit "LT Y64 Obs Log";
        FlagValue: Boolean;
        ExtFlagValue: Boolean;

    local procedure MyProc(var Row: Record "LT Y64 Obs Row")
    begin
        Log.Add('row ' + Row."No.");
    end;

    procedure SetExtFlag(Value: Boolean)
    begin
        ExtFlagValue := Value;
    end;
}

reportextension 93317 "LT Y64 Obs Report Ext" extends "LT Y64 Obs Report"
{
    dataset
    {
        add(MyItem)
        {
            column(ExtName; Name)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Ext column replaced.';
                ObsoleteTag = '1.0';
            }
        }
        addlast(MyItem)
        {
            dataitem(ExtItem; Integer)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Ext data item replaced.';
                ObsoleteTag = '1.0';
                DataItemTableView = sorting(Number) where(Number = const(1));

                trigger OnAfterGetRecord()
                begin
                    ExtLog.Add('ext item ' + MyItem."No.");
                end;
            }
        }
    }

    requestpage
    {
        layout
        {
            addlast(Options)
            {
                field(ExtFlag; ExtFlagField)
                {
                    Caption = 'Ext flag';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Ext field replaced.';
                    ObsoleteTag = '1.0';

                    trigger OnValidate()
                    begin
                        SetExtFlag(ExtFlagField);
                    end;
                }
            }
        }
    }

    var
        ExtLog: Codeunit "LT Y64 Obs Log";
        ExtFlagField: Boolean;
}

query 93318 "LT Y64 Obs Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT Y64 Obs Row")
        {
            column(No; "No.")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Column replaced.';
                ObsoleteTag = '1.0';
            }
            column(Name; Name) { }
            filter(NameFilter; Name)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Filter replaced.';
                ObsoleteTag = '1.0';
            }
        }
    }
}

xmlport 93319 "LT Y64 Obs XmlPort"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT Y64 Obs Row")
            {
                fieldattribute(No; Row."No.") { }
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(XFlag; XFlagValue)
                {
                    Caption = 'X flag';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'XmlPort field replaced.';
                    ObsoleteTag = '1.0';
                }
            }
        }
    }

    var
        XFlagValue: Boolean;
}

codeunit 93319 "LT Y64 Obsolete Sub Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y64 Obs Log";

    local procedure Seed()
    var
        Row: Record "LT Y64 Obs Row";
    begin
        Row.DeleteAll();
        Row."No." := 'A';
        Row.Name := 'alpha';
        Row.Insert();
        Row."No." := 'B';
        Row.Name := 'bravo';
        Row.Insert();
        Row."No." := 'C';
        Row.Name := 'charlie';
        Row.Insert();
        Log.Take();
    end;

    [Test]
    procedure Y64_ObsoleteDataItem_ReporterShape()
    var
        Observer: Codeunit "Probe Observer";
        MyRec: Record "LT Y64 Obs Row";
        MyReport: Report "LT Y64 Obs Report";
    begin
        Seed();
        MyRec.SetFilter("No.", 'A|C');
        MyReport.SetTableView(MyRec);
        MyReport.UseRequestPage(false);
        MyReport.Run();
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure ObsRequestPageHandler(var RequestPage: TestRequestPage "LT Y64 Obs Report")
    begin
        Log.Add('handler flag visible=' + Format(RequestPage.Flag.Visible()) + ' ext visible=' + Format(RequestPage.ExtFlag.Visible()));
        RequestPage.Flag.SetValue(true);
        RequestPage.ExtFlag.SetValue(true);
        RequestPage.RpAction.Invoke();
        RequestPage.MyItem.SetFilter("No.", 'B');
        RequestPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ObsRequestPageHandler')]
    procedure Y64_ObsoleteRequestPageElements_WithRequestPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.RunModal(Report::"LT Y64 Obs Report", true);
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y64_ObsoleteQueryColumnAndFilter()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT Y64 Obs Query";
        Result: Text;
    begin
        Seed();
        Q.SetFilter(NameFilter, '*a*');
        Q.Open();
        while Q.Read() do
            Result += Q.No + ':' + Q.Name + ';';
        Q.Close();
        Observer.Observe('rows', Result);
        Observer.Observe('filter', Q.GetFilter(NameFilter));
        Observer.Finish();
    end;

    [Test]
    procedure Y64_ObsoleteXmlPortRequestPageField_Export()
    var
        Observer: Codeunit "Probe Observer";
        Blob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Txt: Text;
        Line: Text;
    begin
        Seed();
        Blob.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT Y64 Obs XmlPort", OutS);
        Blob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Txt += Line;
        end;
        Observer.Observe('xml', Txt);
        Observer.Finish();
    end;
}
