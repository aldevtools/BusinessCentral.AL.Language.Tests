// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-datasetview-property
// Scope: in-scope (Cloud)
// local object: the view / filter property of the object is what is under test, so each case needs its own page or report; the capture codeunit is SingleInstance and outlives a test
// Fixtures used: Probe Observer (codeunit 69160); own objects in 96600..96699
// BC versions: 27, 28, 29
// Area matrix (al-runner issue 7423): DataItemTableView = where(...) on a report data item, crossed with the value forms of
//   pages/view-properties/VwPageViews.al (same table "VW Row", same five rows). Each report has UseRequestPage = false; the data item
//   notes Rec.GetFilters() and Rec.GetView() in OnPreDataItem and the "No." of every row it reads.

report 96601 "VW Report 01"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(CodeF = const(''));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96602 "VW Report 02"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(CodeF = filter(''));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96603 "VW Report 03"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(CodeF = filter(<> ''));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96604 "VW Report 04"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(CodeF = const('A'));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96605 "VW Report 05"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(CodeF = filter('A|B'));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96606 "VW Report 06"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(CodeF = filter('='''''));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96607 "VW Report 07"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(TextF = const(''));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96608 "VW Report 08"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(TextF = filter(<> ''));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96609 "VW Report 09"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(IntF = const(Database::"VW Row"));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96610 "VW Report 10"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(IntF = filter(Database::"VW Row"));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96611 "VW Report 11"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(IntF = filter(<> Database::"VW Row"));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96612 "VW Report 12"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(IntF = filter(Database::"VW Row" | 1));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96613 "VW Report 13"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(IntF = const(0));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96614 "VW Report 14"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(IntF = filter(1 .. 2));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96615 "VW Report 15"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(KindF = const(Item));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96616 "VW Report 16"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(KindF = filter(Item));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96617 "VW Report 17"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(KindF = filter("VW Kind"::Item));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96618 "VW Report 18"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(KindF = filter(KindF::Item));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96619 "VW Report 19"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(KindF = filter(<> "VW Kind"::Item));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96620 "VW Report 20"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(KindF = filter(<> KindF::Item));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96621 "VW Report 21"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(KindF = filter(KindF::Item | KindF::Resource));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96622 "VW Report 22"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(KindF = filter("VW Kind"::"Fixed Asset"));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96623 "VW Report 23"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(KindF = const("Fixed Asset"));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96624 "VW Report 24"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(KindF = const("VW Kind"::Resource));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96625 "VW Report 25"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(DateF = filter(''));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96626 "VW Report 26"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(DateF = filter('='''''));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96627 "VW Report 27"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(DateF = filter(<> ''));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96628 "VW Report 28"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(BoolF = const(true));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96629 "VW Report 29"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(BoolF = const(false));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96630 "VW Report 30"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(BoolF = filter(true));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96631 "VW Report 31"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(OptF = const(B));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96632 "VW Report 32"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(OptF = filter(<> A));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96633 "VW Report 33"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(DecF = filter(> 0));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96634 "VW Report 34"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(KindF = filter(KindF::Item), CodeF = const(''));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96635 "VW Report 35"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(KindF = filter("VW Kind"::Item), CodeF = const(''));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

report 96636 "VW Report 36"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "VW Row")
        {
            DataItemTableView = where(CodeF = const(''), IntF = const(Database::"VW Row"), KindF = filter(<> "VW Kind"::Item));

            trigger OnPreDataItem()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.Note('D', Source.GetFilters(), Source.GetView(true), Source.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Capture: Codeunit "VW Capture";
            begin
                Capture.AddRow(Source."No.");
            end;
        }
    }
}

codeunit 96604 "VW Data Item Table View Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Capture: Codeunit "VW Capture";

    local procedure Initialize()
    begin
        Capture.Seed();
        Capture.Reset();
    end;

    [TryFunction]
    local procedure Run01()
    begin
        Report.Run(Report::"VW Report 01");
    end;

    // CLAIM: DataItemTableView = where(CodeF = const('')) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_CodeConstBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run01() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run02()
    begin
        Report.Run(Report::"VW Report 02");
    end;

    // CLAIM: DataItemTableView = where(CodeF = filter('')) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_CodeFilterBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run02() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run03()
    begin
        Report.Run(Report::"VW Report 03");
    end;

    // CLAIM: DataItemTableView = where(CodeF = filter(<> '')) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_CodeFilterNotBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run03() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run04()
    begin
        Report.Run(Report::"VW Report 04");
    end;

    // CLAIM: DataItemTableView = where(CodeF = const('A')) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_CodeConstA()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run04() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run05()
    begin
        Report.Run(Report::"VW Report 05");
    end;

    // CLAIM: DataItemTableView = where(CodeF = filter('A|B')) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_CodeFilterOr()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run05() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run06()
    begin
        Report.Run(Report::"VW Report 06");
    end;

    // CLAIM: DataItemTableView = where(CodeF = filter('=''''')) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_CodeFilterEqualsBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run06() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run07()
    begin
        Report.Run(Report::"VW Report 07");
    end;

    // CLAIM: DataItemTableView = where(TextF = const('')) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_TextConstBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run07() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run08()
    begin
        Report.Run(Report::"VW Report 08");
    end;

    // CLAIM: DataItemTableView = where(TextF = filter(<> '')) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_TextFilterNotBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run08() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run09()
    begin
        Report.Run(Report::"VW Report 09");
    end;

    // CLAIM: DataItemTableView = where(IntF = const(Database::"VW Row")) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_IntConstDatabase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run09() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run10()
    begin
        Report.Run(Report::"VW Report 10");
    end;

    // CLAIM: DataItemTableView = where(IntF = filter(Database::"VW Row")) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_IntFilterDatabase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run10() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run11()
    begin
        Report.Run(Report::"VW Report 11");
    end;

    // CLAIM: DataItemTableView = where(IntF = filter(<> Database::"VW Row")) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_IntFilterNotDatabase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run11() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run12()
    begin
        Report.Run(Report::"VW Report 12");
    end;

    // CLAIM: DataItemTableView = where(IntF = filter(Database::"VW Row" | 1)) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_IntFilterDatabaseOrNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run12() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run13()
    begin
        Report.Run(Report::"VW Report 13");
    end;

    // CLAIM: DataItemTableView = where(IntF = const(0)) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_IntConstZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run13() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run14()
    begin
        Report.Run(Report::"VW Report 14");
    end;

    // CLAIM: DataItemTableView = where(IntF = filter(1 .. 2)) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_IntFilterRange()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run14() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run15()
    begin
        Report.Run(Report::"VW Report 15");
    end;

    // CLAIM: DataItemTableView = where(KindF = const(Item)) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_EnumConst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run15() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run16()
    begin
        Report.Run(Report::"VW Report 16");
    end;

    // CLAIM: DataItemTableView = where(KindF = filter(Item)) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_EnumFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run16() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run17()
    begin
        Report.Run(Report::"VW Report 17");
    end;

    // CLAIM: DataItemTableView = where(KindF = filter("VW Kind"::Item)) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_EnumFilterTypeQualified()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run17() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run18()
    begin
        Report.Run(Report::"VW Report 18");
    end;

    // CLAIM: DataItemTableView = where(KindF = filter(KindF::Item)) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_EnumFilterFieldQualified()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run18() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run19()
    begin
        Report.Run(Report::"VW Report 19");
    end;

    // CLAIM: DataItemTableView = where(KindF = filter(<> "VW Kind"::Item)) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_EnumFilterNotTypeQualified()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run19() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run20()
    begin
        Report.Run(Report::"VW Report 20");
    end;

    // CLAIM: DataItemTableView = where(KindF = filter(<> KindF::Item)) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_EnumFilterNotFieldQualified()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run20() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run21()
    begin
        Report.Run(Report::"VW Report 21");
    end;

    // CLAIM: DataItemTableView = where(KindF = filter(KindF::Item | KindF::Resource)) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_EnumFilterTwoQualified()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run21() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run22()
    begin
        Report.Run(Report::"VW Report 22");
    end;

    // CLAIM: DataItemTableView = where(KindF = filter("VW Kind"::"Fixed Asset")) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_EnumFilterQuotedMember()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run22() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run23()
    begin
        Report.Run(Report::"VW Report 23");
    end;

    // CLAIM: DataItemTableView = where(KindF = const("Fixed Asset")) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_EnumConstQuotedMember()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run23() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run24()
    begin
        Report.Run(Report::"VW Report 24");
    end;

    // CLAIM: DataItemTableView = where(KindF = const("VW Kind"::Resource)) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_EnumConstTypeQualified()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run24() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run25()
    begin
        Report.Run(Report::"VW Report 25");
    end;

    // CLAIM: DataItemTableView = where(DateF = filter('')) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_DateFilterBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run25() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run26()
    begin
        Report.Run(Report::"VW Report 26");
    end;

    // CLAIM: DataItemTableView = where(DateF = filter('=''''')) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_DateFilterEqualsBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run26() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run27()
    begin
        Report.Run(Report::"VW Report 27");
    end;

    // CLAIM: DataItemTableView = where(DateF = filter(<> '')) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_DateFilterNotBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run27() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run28()
    begin
        Report.Run(Report::"VW Report 28");
    end;

    // CLAIM: DataItemTableView = where(BoolF = const(true)) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_BoolConstTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run28() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run29()
    begin
        Report.Run(Report::"VW Report 29");
    end;

    // CLAIM: DataItemTableView = where(BoolF = const(false)) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_BoolConstFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run29() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run30()
    begin
        Report.Run(Report::"VW Report 30");
    end;

    // CLAIM: DataItemTableView = where(BoolF = filter(true)) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_BoolFilterTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run30() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run31()
    begin
        Report.Run(Report::"VW Report 31");
    end;

    // CLAIM: DataItemTableView = where(OptF = const(B)) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_OptionConst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run31() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run32()
    begin
        Report.Run(Report::"VW Report 32");
    end;

    // CLAIM: DataItemTableView = where(OptF = filter(<> A)) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_OptionFilterNot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run32() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run33()
    begin
        Report.Run(Report::"VW Report 33");
    end;

    // CLAIM: DataItemTableView = where(DecF = filter(> 0)) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_DecimalFilterPositive()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run33() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run34()
    begin
        Report.Run(Report::"VW Report 34");
    end;

    // CLAIM: DataItemTableView = where(KindF = filter(KindF::Item), CodeF = const('')) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_TwoConditionsEnumCode()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run34() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run35()
    begin
        Report.Run(Report::"VW Report 35");
    end;

    // CLAIM: DataItemTableView = where(KindF = filter("VW Kind"::Item), CodeF = const('')) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_TwoConditionsTypeQualifiedEnumCode()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run35() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Run36()
    begin
        Report.Run(Report::"VW Report 36");
    end;

    // CLAIM: DataItemTableView = where(CodeF = const(''), IntF = const(Database::"VW Row"), KindF = filter(<> "VW Kind"::Item)) reads the rows and filters recorded below.
    [Test]
    procedure DataItemTableView_ThreeConditionsDatabaseCodeEnum()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Run36() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('D.filters'));
            Observer.Observe('view', Capture.Get('D.view'));
            Observer.Observe('viewCaptions', Capture.Get('D.viewCaptions'));
        end else
            Observer.ObserveError('run');
        Observer.Finish();
    end;
}
