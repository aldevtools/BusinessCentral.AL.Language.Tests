// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/reportinstance/reportinstance-break-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 73319, SingleInstance log 73320 (used only by test codeunit 73325), report 73321, report extension 73322
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CurrReport.Break and CurrReport.Skip in the triggers a report extension adds to a data item (OnBeforeAfterGetRecord, OnAfterAfterGetRecord, OnBeforePreDataItem, OnAfterPostDataItem):
// the log of the triggers of base report and extension that ran and whether the run raised an error (text and code).
// BC versions: 29 (27 and 28 by CI)

table 73319 "LT P129 BrkX Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73320 "LT P129 BrkX Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Mode: Text;

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

    procedure SetMode(NewMode: Text)
    begin
        Mode := NewMode;
    end;

    procedure GetMode(): Text
    begin
        exit(Mode);
    end;
}

report 73321 "LT P129 BrkX Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P129 BrkX Row")
        {
            trigger OnPreDataItem()
            begin
                L.Add('base row pre');
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('base row get ' + Format(Row.Id));
            end;

            trigger OnPostDataItem()
            begin
                L.Add('base row post');
            end;
        }
    }

    trigger OnPreReport()
    begin
        L.Add('base prereport');
    end;

    trigger OnPostReport()
    begin
        L.Add('base postreport');
    end;

    var
        L: Codeunit "LT P129 BrkX Log";
}

reportextension 73322 "LT P129 BrkX Ext" extends "LT P129 BrkX Report"
{
    dataset
    {
        modify(Row)
        {
            trigger OnBeforePreDataItem()
            begin
                L.Add('ext before pre');
                if L.GetMode() = 'BeforePreBreak' then
                    CurrReport.Break();
            end;

            trigger OnBeforeAfterGetRecord()
            begin
                L.Add('ext before get ' + Format(Row.Id));
                if (L.GetMode() = 'BeforeGetSkipId2') and (Row.Id = 2) then
                    CurrReport.Skip();
                if (L.GetMode() = 'BeforeGetBreakId2') and (Row.Id = 2) then
                    CurrReport.Break();
            end;

            trigger OnAfterAfterGetRecord()
            begin
                L.Add('ext after get ' + Format(Row.Id));
                if (L.GetMode() = 'AfterGetSkipId2') and (Row.Id = 2) then
                    CurrReport.Skip();
                if (L.GetMode() = 'AfterGetBreakId2') and (Row.Id = 2) then
                    CurrReport.Break();
            end;

            trigger OnAfterPostDataItem()
            begin
                L.Add('ext after post');
                if L.GetMode() = 'AfterPostBreak' then
                    CurrReport.Break();
            end;
        }
    }

    var
        L: Codeunit "LT P129 BrkX Log";
}

codeunit 73325 "LT P129 Report Ext Break"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P129 BrkX Log";

    [TryFunction]
    local procedure TryRun()
    begin
        Report.Run(Report::"LT P129 BrkX Report");
    end;

    local procedure RunMode(Mode: Text): Text
    var
        Row: Record "LT P129 BrkX Row";
        Outcome: Text;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Row.Id := 3;
        Row.Insert();
        L.Take();
        L.SetMode(Mode);
        ClearLastError();
        if TryRun() then
            Outcome := 'ran'
        else
            Outcome := 'err|' + GetLastErrorText() + '|' + GetLastErrorCode();
        L.SetMode('');
        exit(Outcome + '|' + L.Take());
    end;

    [Test]
    procedure P129_ReportExtension_BreakAndSkip()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('control', RunMode(''));
        Observer.Observe('OnBeforePreDataItem Break', RunMode('BeforePreBreak'));
        Observer.Observe('OnBeforeAfterGetRecord Skip id 2', RunMode('BeforeGetSkipId2'));
        Observer.Observe('OnBeforeAfterGetRecord Break id 2', RunMode('BeforeGetBreakId2'));
        Observer.Observe('OnAfterAfterGetRecord Skip id 2', RunMode('AfterGetSkipId2'));
        Observer.Observe('OnAfterAfterGetRecord Break id 2', RunMode('AfterGetBreakId2'));
        Observer.Observe('OnAfterPostDataItem Break', RunMode('AfterPostBreak'));
        Observer.Expect('control', 'ran|base prereport;ext before pre;base row pre;ext before get 1;base row get 1;ext after get 1;ext before get 2;base row get 2;ext after get 2;ext before get 3;base row get 3;ext after get 3;base row post;ext after post;base postreport;');
        Observer.Expect('OnBeforePreDataItem Break', 'ran|base prereport;ext before pre;base row pre;base row post;ext after post;base postreport;');
        Observer.Expect('OnBeforeAfterGetRecord Skip id 2', 'ran|base prereport;ext before pre;base row pre;ext before get 1;base row get 1;ext after get 1;ext before get 2;base row get 2;ext after get 2;ext before get 3;base row get 3;ext after get 3;base row post;ext after post;base postreport;');
        Observer.Expect('OnBeforeAfterGetRecord Break id 2', 'ran|base prereport;ext before pre;base row pre;ext before get 1;base row get 1;ext after get 1;ext before get 2;base row get 2;ext after get 2;base row post;ext after post;base postreport;');
        Observer.Expect('OnAfterAfterGetRecord Skip id 2', 'ran|base prereport;ext before pre;base row pre;ext before get 1;base row get 1;ext after get 1;ext before get 2;base row get 2;ext after get 2;ext before get 3;base row get 3;ext after get 3;base row post;ext after post;base postreport;');
        Observer.Expect('OnAfterAfterGetRecord Break id 2', 'ran|base prereport;ext before pre;base row pre;ext before get 1;base row get 1;ext after get 1;ext before get 2;base row get 2;ext after get 2;base row post;ext after post;base postreport;');
        Observer.Expect('OnAfterPostDataItem Break', 'ran|base prereport;ext before pre;base row pre;ext before get 1;base row get 1;ext after get 1;ext before get 2;base row get 2;ext after get 2;ext before get 3;base row get 3;ext after get 3;base row post;ext after post;base postreport;');
        Observer.Verify();
    end;
}
