// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetable-property
// Scope: in-scope
// Fixtures used: LT Y Helper (75500), LT Y Seen (75501), table LT Y Line (75530, YRequestPage.al); own reports 88560-88564 and 88566. The tests are in YRequestPageTests.al (codeunit 75512).
// Probe: observed values; every literal asserted in codeunit 75512 for these reports is what the BC tiers of the corpus matrix produced.
// Facts (al-runner issue 5756): the Rec of a report request page that declares SourceTable is a normal record of that table. It compiles in the request page
// triggers, in the report triggers and in report procedures (a request page without SourceTable has no Rec: must-not-compile cases 2110 and 2113).
// Rec.Modify and Rec.Insert in OnOpenPage write to the database; the report triggers, data item triggers and procedures see the same Rec as the request page,
// and a value typed into a control bound to Rec is written to the row when the request page is closed with OK. In OnInitReport Rec raises ReportRequestPageNotInitialized.
// BC versions: 27-29

// The reporter's shape: a processing-only report with no data item whose request page OnOpenPage calls Rec.Modify on a Rec it never positioned.
report 88560 "LT RS RP Modify Unpositioned"
{
    UsageCategory = None;
    ProcessingOnly = true;
    Permissions = tabledata "LT Y Line" = m;

    requestpage
    {
        SourceTable = "LT Y Line";

        layout
        {
            area(Content)
            {
                field(DocNoCtl; Rec.DocNo) { ApplicationArea = All; }
            }
        }

        trigger OnOpenPage()
        var
            Seen: Codeunit "LT Y Seen";
        begin
            Seen.Put('open_rec', '[' + Rec.DocNo + '/' + Format(Rec.LineNo) + '] filters=[' + Rec.GetFilters() + '] count=' + Format(Rec.Count()) + ' temporary=' + Format(Rec.IsTemporary()) + ' table=' + Rec.TableName());
            Seen.Put('modify_bool', Format(Rec.Modify()));
        end;
    }
}

// OnOpenPage finds a row, changes it and calls Rec.Modify; then inserts a new row through Rec.
report 88561 "LT RS RP Modify Found"
{
    UsageCategory = None;
    ProcessingOnly = true;

    requestpage
    {
        SourceTable = "LT Y Line";

        layout
        {
            area(Content)
            {
                field(DocNoCtl; Rec.DocNo) { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            }
        }

        trigger OnOpenPage()
        var
            Seen: Codeunit "LT Y Seen";
        begin
            Rec.FindLast();
            Rec.Descr := 'modified';
            Seen.Put('modify', Format(Rec.Modify()));
            Rec.Init();
            Rec.DocNo := 'N';
            Rec.LineNo := 1;
            Rec.Descr := 'inserted';
            Seen.Put('insert', Format(Rec.Insert()));
            Seen.Put('open_rec', '[' + Rec.DocNo + '/' + Format(Rec.LineNo) + '/' + Rec.Descr + '] count=' + Format(Rec.Count()));
        end;
    }
}

// Rec in the report triggers: the request page OnOpenPage positions it on the second row, the handler types into a control bound to Rec,
// and OnPreReport and OnPostReport read Rec.
report 88562 "LT RS RP Rec In Report"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Int; Integer)
        {
            DataItemTableView = where(Number = const(1));

            trigger OnAfterGetRecord()
            var
                Seen: Codeunit "LT Y Seen";
            begin
                Seen.Put('dataitem_rec', '[' + Rec.DocNo + '/' + Format(Rec.LineNo) + '/' + Rec.Descr + ']');
            end;
        }
    }

    requestpage
    {
        SourceTable = "LT Y Line";

        layout
        {
            area(Content)
            {
                field(DocNoCtl; Rec.DocNo) { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            }
        }

        trigger OnOpenPage()
        var
            Seen: Codeunit "LT Y Seen";
        begin
            Rec.FindFirst();
            Rec.Next();
            Seen.Put('open_rec', '[' + Rec.DocNo + '/' + Format(Rec.LineNo) + '/' + Rec.Descr + ']');
        end;
    }

    trigger OnPreReport()
    var
        Seen: Codeunit "LT Y Seen";
    begin
        Seen.Put('pre_rec', '[' + Rec.DocNo + '/' + Format(Rec.LineNo) + '/' + Rec.Descr + '] filters=[' + Rec.GetFilters() + '] count=' + Format(Rec.Count()) + ' temporary=' + Format(Rec.IsTemporary()));
    end;

    trigger OnPostReport()
    var
        Seen: Codeunit "LT Y Seen";
    begin
        Seen.Put('post_rec', '[' + Rec.DocNo + '/' + Format(Rec.LineNo) + '/' + Rec.Descr + ']');
        Seen.Put('proc_rec', RecText());
    end;

    procedure RecText(): Text
    begin
        exit('[' + Rec.DocNo + '/' + Format(Rec.LineNo) + '/' + Rec.Descr + ']');
    end;
}

// The reporter's exact trigger: a bare Rec.Modify on an unpositioned Rec, not caught. Run without a [RequestPageHandler], the report fails with
// 'Unhandled UI' before OnOpenPage runs. With a handler it is not run: an error in OnOpenPage could leave the handler queued for a later
// codeunit (see handlers/TestReportRequestPageSourceTable.al); report 88560 calls Modify in its returning form, and report 88564 shows the error of a Modify that finds no row.
report 88563 "LT RS RP Modify Raises"
{
    UsageCategory = None;
    ProcessingOnly = true;

    requestpage
    {
        SourceTable = "LT Y Line";

        layout
        {
            area(Content)
            {
                field(DocNoCtl; Rec.DocNo) { ApplicationArea = All; }
            }
        }

        trigger OnOpenPage()
        var
            Seen: Codeunit "LT Y Seen";
        begin
            Seen.Put('before_modify', 'reached');
            Rec.Modify();
            Seen.Put('after_modify', 'reached');
        end;
    }
}

// SourceTableTemporary: Modify and Insert in OnOpenPage reach only the temporary table; OnPreReport sees the temporary Rec.
report 88564 "LT RS RP Temp Rec In Report"
{
    UsageCategory = None;
    ProcessingOnly = true;

    requestpage
    {
        SourceTable = "LT Y Line";
        SourceTableTemporary = true;

        layout
        {
            area(Content)
            {
                field(DocNoCtl; Rec.DocNo) { ApplicationArea = All; }
            }
        }

        trigger OnOpenPage()
        var
            Helper: Codeunit "LT Y Helper";
            Seen: Codeunit "LT Y Seen";
        begin
            ClearLastError();
            if TryModify(Rec) then
                Seen.Put('modify', 'ok')
            else
                Seen.Put('modify', Helper.Failed());
            Rec.Init();
            Rec.DocNo := 'T';
            Rec.LineNo := 1;
            Seen.Put('insert', Format(Rec.Insert()));
        end;
    }

    trigger OnPreReport()
    var
        Seen: Codeunit "LT Y Seen";
    begin
        Seen.Put('pre_rec', '[' + Rec.DocNo + '/' + Format(Rec.LineNo) + '] count=' + Format(Rec.Count()) + ' temporary=' + Format(Rec.IsTemporary()));
    end;

    [TryFunction]
    local procedure TryModify(var Line: Record "LT Y Line")
    begin
        Line.Modify();
    end;
}

// Rec read in OnInitReport: the request page is not initialized yet, so the read raises (report 88562 reads Rec only from OnOpenPage on).
report 88566 "LT RS RP Rec In Init"
{
    UsageCategory = None;
    ProcessingOnly = true;

    requestpage
    {
        SourceTable = "LT Y Line";
    }

    trigger OnInitReport()
    var
        Seen: Codeunit "LT Y Seen";
    begin
        Seen.Put('init_before', 'reached');
        Seen.Put('init_rec', '[' + Rec.DocNo + '/' + Format(Rec.LineNo) + ']');
        Seen.Put('init_after', 'reached');
    end;
}
