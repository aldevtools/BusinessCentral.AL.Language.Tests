// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/reportinstance/reportinstance-data-type
// Scope: in-scope
// Fixtures used: tables and helper of RptFixtures.al; SingleInstance log 73820 is used only by test codeunit 73825
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// CurrReport.Skip, CurrReport.Break and CurrReport.Quit from the data item triggers and the report triggers (which later triggers still run),
// and the CurrReport members Language, FormatRegion, ShowOutput and Preview.
// BC versions: 29 (27 and 28 by CI)

codeunit 73820 "LT RpT Skip Log"
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

report 73821 "LT RpT Skip"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT RpT Row")
        {
            dataitem(Child; "LT RpT Child")
            {
                DataItemLink = ParentId = field(Id);

                trigger OnPreDataItem()
                begin
                    L.Add('Child pre of ' + Format(Row.Id));
                end;

                trigger OnAfterGetRecord()
                begin
                    L.Add('Child get ' + Format(Child.Id));
                    if (L.GetMode() = 'ChildSkip') and (Child.Id = 10) then
                        CurrReport.Skip();
                    if (L.GetMode() = 'ChildBreak') and (Child.Id = 10) then
                        CurrReport.Break();
                    if (L.GetMode() = 'ChildQuit') and (Child.Id = 10) then
                        CurrReport.Quit();
                end;

                trigger OnPostDataItem()
                begin
                    L.Add('Child post of ' + Format(Row.Id));
                end;
            }

            trigger OnPreDataItem()
            begin
                L.Add('Row pre');
                if L.GetMode() = 'PreDataItemSkip' then
                    CurrReport.Skip();
                if L.GetMode() = 'PreDataItemBreak' then
                    CurrReport.Break();
                if L.GetMode() = 'PreDataItemQuit' then
                    CurrReport.Quit();
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('Row get ' + Format(Row.Id));
                if (L.GetMode() = 'SkipId2') and (Row.Id = 2) then
                    CurrReport.Skip();
                if (L.GetMode() = 'BreakId2') and (Row.Id = 2) then
                    CurrReport.Break();
                if (L.GetMode() = 'QuitId2') and (Row.Id = 2) then
                    CurrReport.Quit();
                if (L.GetMode() = 'SkipAll') then
                    CurrReport.Skip();
                L.Add('Row done ' + Format(Row.Id));
            end;

            trigger OnPostDataItem()
            begin
                L.Add('Row post');
            end;

        }
    }

    trigger OnPreReport()
    begin
        L.Add('PreReport');
        if L.GetMode() = 'PreReportQuit' then
            CurrReport.Quit();
        if L.GetMode() = 'PreReportSkip' then
            CurrReport.Skip();
        if L.GetMode() = 'PreReportBreak' then
            CurrReport.Break();
    end;

    trigger OnPostReport()
    begin
        L.Add('PostReport');
        if L.GetMode() = 'PostReportQuit' then
            CurrReport.Quit();
    end;

    var
        L: Codeunit "LT RpT Skip Log";
}

report 73822 "LT RpT CurrReport"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT RpT Row")
        {
            trigger OnAfterGetRecord()
            begin
                L.Add('get ' + Format(Row.Id) + ' showoutput=' + Format(CurrReport.ShowOutput()));
            end;
        }
    }

    trigger OnPreReport()
    begin
        L.Add('pre language=' + Format(CurrReport.Language()));
        L.Add('pre formatregion=[' + CurrReport.FormatRegion() + ']');
        L.Add('pre preview=' + Format(CurrReport.Preview()));
        L.Add('pre showoutput=' + Format(CurrReport.ShowOutput()));
        CurrReport.Language := 1031;
        L.Add('set language=' + Format(CurrReport.Language()));
        CurrReport.FormatRegion := 'de-DE';
        L.Add('set formatregion=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPostReport()
    begin
        L.Add('post language=' + Format(CurrReport.Language()));
        L.Add('post formatregion=[' + CurrReport.FormatRegion() + ']');
    end;

    var
        L: Codeunit "LT RpT Skip Log";
}

codeunit 73825 "LT RpT Skip Break Quit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT RpT Skip Log";

    local procedure Seed()
    var
        Row: Record "LT RpT Row";
        Child: Record "LT RpT Child";
        I: Integer;
    begin
        Row.DeleteAll();
        Child.DeleteAll();
        L.Take();
        L.SetMode('');
        for I := 1 to 3 do begin
            Row.Id := I;
            Row.Grp := 1;
            Row.Insert();
        end;
        for I := 10 to 12 do begin
            Child.Id := I;
            Child.ParentId := 1;
            Child.Insert();
        end;
        Commit();
    end;

    local procedure RunMode(Mode: Text; var Observer: Codeunit "Probe Observer")
    begin
        Seed();
        L.SetMode(Mode);
        Report.Run(Report::"LT RpT Skip");
        Observer.Observe(Mode, L.Take());
        L.SetMode('');
    end;

    local procedure RunModeError(Mode: Text; var Observer: Codeunit "Probe Observer")
    begin
        Seed();
        L.SetMode(Mode);
        asserterror Report.Run(Report::"LT RpT Skip");
        Observer.ObserveError(Mode + ' error');
        Observer.Observe(Mode, L.Take());
        L.SetMode('');
    end;

    [Test]
    procedure Plain_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunMode('', Observer);
        Observer.Expect('', 'PreReport;Row pre;Row get 1;Row done 1;Child pre of 1;Child get 10;Child get 11;Child get 12;Child post of 1;Row get 2;Row done 2;Child pre of 2;Child post of 2;Row get 3;Row done 3;Child pre of 3;Child post of 3;Row post;PostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure Skip_InAfterGetRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunMode('SkipId2', Observer);
        RunMode('SkipAll', Observer);
        Observer.Expect('SkipId2', 'PreReport;Row pre;Row get 1;Row done 1;Child pre of 1;Child get 10;Child get 11;Child get 12;Child post of 1;Row get 2;Row get 3;Row done 3;Child pre of 3;Child post of 3;Row post;PostReport;');
        Observer.Expect('SkipAll', 'PreReport;Row pre;Row get 1;Row get 2;Row get 3;Row post;PostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure Break_InAfterGetRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunMode('BreakId2', Observer);
        Observer.Expect('BreakId2', 'PreReport;Row pre;Row get 1;Row done 1;Child pre of 1;Child get 10;Child get 11;Child get 12;Child post of 1;Row get 2;Row post;PostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure Quit_InAfterGetRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunMode('QuitId2', Observer);
        Observer.Expect('QuitId2', 'PreReport;Row pre;Row get 1;Row done 1;Child pre of 1;Child get 10;Child get 11;Child get 12;Child post of 1;Row get 2;');
        Observer.Verify();
    end;

    [Test]
    procedure Skip_Break_Quit_InChildItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunMode('ChildSkip', Observer);
        RunMode('ChildBreak', Observer);
        RunMode('ChildQuit', Observer);
        Observer.Expect('ChildSkip', 'PreReport;Row pre;Row get 1;Row done 1;Child pre of 1;Child get 10;Child get 11;Child get 12;Child post of 1;Row get 2;Row done 2;Child pre of 2;Child post of 2;Row get 3;Row done 3;Child pre of 3;Child post of 3;Row post;PostReport;');
        Observer.Expect('ChildBreak', 'PreReport;Row pre;Row get 1;Row done 1;Child pre of 1;Child get 10;Child post of 1;Row get 2;Row done 2;Child pre of 2;Child post of 2;Row get 3;Row done 3;Child pre of 3;Child post of 3;Row post;PostReport;');
        Observer.Expect('ChildQuit', 'PreReport;Row pre;Row get 1;Row done 1;Child pre of 1;Child get 10;');
        Observer.Verify();
    end;

    [Test]
    procedure PreDataItem_Skip_Break_Quit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunMode('PreDataItemSkip', Observer);
        RunMode('PreDataItemBreak', Observer);
        RunMode('PreDataItemQuit', Observer);
        Observer.Expect('PreDataItemSkip', 'PreReport;Row pre;Row get 1;Row done 1;Child pre of 1;Child get 10;Child get 11;Child get 12;Child post of 1;Row get 2;Row done 2;Child pre of 2;Child post of 2;Row get 3;Row done 3;Child pre of 3;Child post of 3;Row post;PostReport;');
        Observer.Expect('PreDataItemBreak', 'PreReport;Row pre;Row post;PostReport;');
        Observer.Expect('PreDataItemQuit', 'PreReport;Row pre;');
        Observer.Verify();
    end;

    [Test]
    procedure PreReport_Quit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunMode('PreReportQuit', Observer);
        Observer.Expect('PreReportQuit', 'PreReport;');
        Observer.Verify();
    end;

    [Test]
    procedure PostReport_Quit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunMode('PostReportQuit', Observer);
        Observer.Expect('PostReportQuit', 'PreReport;Row pre;Row get 1;Row done 1;Child pre of 1;Child get 10;Child get 11;Child get 12;Child post of 1;Row get 2;Row done 2;Child pre of 2;Child post of 2;Row get 3;Row done 3;Child pre of 3;Child post of 3;Row post;PostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure Execute_And_SaveAs_Quit()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RpT Helper";
        Xml: Text;
        Ok: Boolean;
    begin
        Seed();
        L.SetMode('QuitId2');
        Report.Execute(Report::"LT RpT Skip", '');
        Observer.Observe('execute', L.Take());
        Ok := Helper.Save(Report::"LT RpT Skip", '', Xml);
        Observer.Observe('saveas ok', Format(Ok));
        Observer.Observe('saveas', L.Take());
        L.SetMode('');
        Observer.Expect('execute', 'PreReport;Row pre;Row get 1;Row done 1;Child pre of 1;Child get 10;Child get 11;Child get 12;Child post of 1;Row get 2;');
        Observer.Expect('saveas ok', 'No');
        Observer.Expect('saveas', '');
        Observer.Verify();
    end;

    [Test]
    procedure CurrReport_Members()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT RpT CurrReport");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'pre language=1033;pre formatregion=[];pre preview=No;pre showoutput=No;set language=1031;set formatregion=[de-DE];get 1 showoutput=Nein;get 2 showoutput=Nein;get 3 showoutput=Nein;post language=1031;post formatregion=[de-DE];');
        Observer.Verify();
    end;

    [Test]
    procedure CurrReport_Members_SaveAs()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RpT Helper";
        Xml: Text;
    begin
        Seed();
        Helper.Save(Report::"LT RpT CurrReport", '', Xml);
        Observer.Observe('log', L.Take());
        Observer.Expect('log', '');
        Observer.Verify();
    end;
}
