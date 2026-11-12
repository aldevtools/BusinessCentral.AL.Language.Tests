// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-howto-report-layout
// Scope: in-scope
// Fixtures used: none (objects of the static layout text tests, HtStaticTextTests.al)
// local object: two reports with hand-built Word layouts (HtMain.docx, HtOther.docx, HtDefaults.docx, HtExtras.docx, HtEmptyMain.docx, committed binary
//   fixtures built from the compiler's generated layout of each report: its custom XML parts are kept, word/document.xml and the parts it
//   needs are written by hand). Each marker text is unique, ASCII letters and digits, and appears in one place only.
// BC versions: 27 - 29

table 75220 "HT S Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer)
        {
        }
        field(2; Txt; Text[100])
        {
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }
}

report 75221 "HT Static Rpt"
{
    UsageCategory = None;
    DefaultRenderingLayout = HtMain;

    dataset
    {
        dataitem(HtSRow; "HT S Row")
        {
            column(Txt; Txt)
            {
            }
            column(Const; 'HTCONST1')
            {
            }
        }
    }

    rendering
    {
        layout(HtMain)
        {
            Type = Word;
            LayoutFile = './reports/layouts-html-text/HtMain.docx';
        }
        layout(HtOther)
        {
            Type = Word;
            LayoutFile = './reports/layouts-html-text/HtOther.docx';
        }
        layout(HtDefaults)
        {
            Type = Word;
            LayoutFile = './reports/layouts-html-text/HtDefaults.docx';
        }
        layout(HtExtras)
        {
            Type = Word;
            LayoutFile = './reports/layouts-html-text/HtExtras.docx';
        }
    }
}

report 75222 "HT Empty Rpt"
{
    UsageCategory = None;
    DefaultRenderingLayout = HtEmptyMain;

    dataset
    {
        dataitem(HtSRow; "HT S Row")
        {
            DataItemTableView = where(Id = const(-1));

            column(Txt; Txt)
            {
            }
            column(Const; 'HTCONST1')
            {
            }
        }
    }

    rendering
    {
        layout(HtEmptyMain)
        {
            Type = Word;
            LayoutFile = './reports/layouts-html-text/HtEmptyMain.docx';
        }
    }
}
