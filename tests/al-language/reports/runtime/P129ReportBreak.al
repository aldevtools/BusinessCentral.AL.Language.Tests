// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/reportinstance/reportinstance-break-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 73314 and 73315, SingleInstance log 73316 (used only by test codeunit 73318), report 73317
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CurrReport.Break and CurrReport.Skip in places that report/W3ReportSkipBreakQuit.al does not cover: OnInitReport (directly and from a procedure), a procedure called from OnPreDataItem,
// OnPostDataItem or OnAfterGetRecord, a procedure called from OnPreReport, and OnPostDataItem of a nested data item: the log of the triggers that ran and whether the run raised an error (text and code).
// BC versions: 29 (27 and 28 by CI)

table 73314 "LT P129 Brk Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 73315 "LT P129 Brk Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73316 "LT P129 Brk Log"
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

report 73317 "LT P129 Brk Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P129 Brk Row")
        {
            dataitem(Child; "LT P129 Brk Child")
            {
                DataItemLink = ParentId = field(Id);

                trigger OnPreDataItem()
                begin
                    L.Add('child pre of ' + Format(Row.Id));
                end;

                trigger OnAfterGetRecord()
                begin
                    L.Add('child get ' + Format(Child.Id));
                end;

                trigger OnPostDataItem()
                begin
                    L.Add('child post of ' + Format(Row.Id));
                    if L.GetMode() = 'ChildPostBreak' then
                        CurrReport.Break();
                    if L.GetMode() = 'ChildPostSkip' then
                        CurrReport.Skip();
                end;
            }

            trigger OnPreDataItem()
            begin
                L.Add('row pre');
                if L.GetMode() = 'PreItemProcBreak' then
                    DoBreak();
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('row get ' + Format(Row.Id));
                if (L.GetMode() = 'AgrProcSkipId2') and (Row.Id = 2) then
                    DoSkip();
            end;

            trigger OnPostDataItem()
            begin
                L.Add('row post');
                if L.GetMode() = 'PostItemProcSkip' then
                    DoSkip();
                if L.GetMode() = 'PostItemProcBreak' then
                    DoBreak();
            end;
        }
    }

    trigger OnInitReport()
    begin
        L.Add('init');
        if L.GetMode() = 'InitBreak' then
            CurrReport.Break();
        if L.GetMode() = 'InitSkip' then
            CurrReport.Skip();
        if L.GetMode() = 'InitProcBreak' then
            DoBreak();
    end;

    trigger OnPreReport()
    begin
        L.Add('prereport');
        if L.GetMode() = 'PreReportProcSkip' then
            DoSkip();
        if L.GetMode() = 'PreReportProcBreak' then
            DoBreak();
    end;

    trigger OnPostReport()
    begin
        L.Add('postreport');
    end;

    local procedure DoBreak()
    begin
        CurrReport.Break();
    end;

    local procedure DoSkip()
    begin
        CurrReport.Skip();
    end;

    var
        L: Codeunit "LT P129 Brk Log";
}

codeunit 73318 "LT P129 Report Break"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P129 Brk Log";

    [TryFunction]
    local procedure TryRun()
    begin
        Report.Run(Report::"LT P129 Brk Report");
    end;

    local procedure RunMode(Mode: Text): Text
    var
        Row: Record "LT P129 Brk Row";
        Child: Record "LT P129 Brk Child";
        Outcome: Text;
    begin
        Row.DeleteAll();
        Child.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Row.Id := 3;
        Row.Insert();
        Child.Id := 10;
        Child.ParentId := 1;
        Child.Insert();
        Child.Id := 20;
        Child.ParentId := 2;
        Child.Insert();
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
    procedure P129_Report_BreakAndSkip_InOnInitReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('control', RunMode(''));
        Observer.Observe('Break', RunMode('InitBreak'));
        Observer.Observe('Skip', RunMode('InitSkip'));
        Observer.Observe('Break in procedure', RunMode('InitProcBreak'));
        Observer.Expect('control', 'ran|init;prereport;row pre;row get 1;child pre of 1;child get 10;child post of 1;row get 2;child pre of 2;child get 20;child post of 2;row get 3;child pre of 3;child post of 3;row post;postreport;');
        Observer.Expect('Break', 'ran|init;prereport;row pre;row get 1;child pre of 1;child get 10;child post of 1;row get 2;child pre of 2;child get 20;child post of 2;row get 3;child pre of 3;child post of 3;row post;postreport;');
        Observer.Expect('Skip', 'ran|init;prereport;row pre;row get 1;child pre of 1;child get 10;child post of 1;row get 2;child pre of 2;child get 20;child post of 2;row get 3;child pre of 3;child post of 3;row post;postreport;');
        Observer.Expect('Break in procedure', 'ran|init;prereport;row pre;row get 1;child pre of 1;child get 10;child post of 1;row get 2;child pre of 2;child get 20;child post of 2;row get 3;child pre of 3;child post of 3;row post;postreport;');
        Observer.Verify();
    end;

    [Test]
    procedure P129_Report_BreakAndSkip_InProceduresOfOtherTriggers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('OnPreDataItem procedure Break', RunMode('PreItemProcBreak'));
        Observer.Observe('OnPostDataItem procedure Skip', RunMode('PostItemProcSkip'));
        Observer.Observe('OnPostDataItem procedure Break', RunMode('PostItemProcBreak'));
        Observer.Observe('OnAfterGetRecord procedure Skip id 2', RunMode('AgrProcSkipId2'));
        Observer.Observe('OnPreReport procedure Skip', RunMode('PreReportProcSkip'));
        Observer.Observe('OnPreReport procedure Break', RunMode('PreReportProcBreak'));
        Observer.Expect('OnPreDataItem procedure Break', 'ran|init;prereport;row pre;row post;postreport;');
        Observer.Expect('OnPostDataItem procedure Skip', 'ran|init;prereport;row pre;row get 1;child pre of 1;child get 10;child post of 1;row get 2;child pre of 2;child get 20;child post of 2;row get 3;child pre of 3;child post of 3;row post;postreport;');
        Observer.Expect('OnPostDataItem procedure Break', 'ran|init;prereport;row pre;row get 1;child pre of 1;child get 10;child post of 1;row get 2;child pre of 2;child get 20;child post of 2;row get 3;child pre of 3;child post of 3;row post;postreport;');
        Observer.Expect('OnAfterGetRecord procedure Skip id 2', 'ran|init;prereport;row pre;row get 1;child pre of 1;child get 10;child post of 1;row get 2;row get 3;child pre of 3;child post of 3;row post;postreport;');
        Observer.Expect('OnPreReport procedure Skip', 'ran|init;prereport;row pre;row get 1;child pre of 1;child get 10;child post of 1;row get 2;child pre of 2;child get 20;child post of 2;row get 3;child pre of 3;child post of 3;row post;postreport;');
        Observer.Expect('OnPreReport procedure Break', 'ran|init;prereport;row pre;row get 1;child pre of 1;child get 10;child post of 1;row get 2;child pre of 2;child get 20;child post of 2;row get 3;child pre of 3;child post of 3;row post;postreport;');
        Observer.Verify();
    end;

    [Test]
    procedure P129_Report_BreakAndSkip_InNestedOnPostDataItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('child post Break', RunMode('ChildPostBreak'));
        Observer.Observe('child post Skip', RunMode('ChildPostSkip'));
        Observer.Expect('child post Break', 'ran|init;prereport;row pre;row get 1;child pre of 1;child get 10;child post of 1;row get 2;child pre of 2;child get 20;child post of 2;row get 3;child pre of 3;child post of 3;row post;postreport;');
        Observer.Expect('child post Skip', 'ran|init;prereport;row pre;row get 1;child pre of 1;child get 10;child post of 1;row get 2;child pre of 2;child get 20;child post of 2;row get 3;child pre of 3;child post of 3;row post;postreport;');
        Observer.Verify();
    end;
}
