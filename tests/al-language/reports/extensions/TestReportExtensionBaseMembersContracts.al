// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68890, codeunit 68891 (log), report 68892,
//                report extensions 68893, 68894, 68895, codeunit 68896 (tests)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins how report extensions use the base report's members and in which order several of them run:
//  - Protected variables (Integer, Decimal, a Record, a Dialog) and a protected procedure of the base report are
//    named from an extension's triggers and procedures. The extension and the base share ONE instance:
//    the extension reads what the base set in OnPreReport (counter 10, decimal 1.5, record id 77), what an
//    extension writes in a trigger the base reads later (counter 20 in the extension's OnAfterPreDataItem, record
//    id 88 and decimal 3 in OnAfterAfterGetRecord, all seen by the base's OnPostReport), and a protected procedure
//    changes the shared counter. A Dialog variable of the base opens and updates from the extension.
//  - A public procedure of the base (PubProc) and a protected List variable (Names, filled by the base and the extension, count 2)
//    work from the extension the same way.
//  - A variable of the base that is not protected is a compile error in the extension (AL0161 "'Hidden' is
//    inaccessible due to its protection level"); a test cannot show that.
//  - Order: for every trigger the base runs first, then the extensions in OBJECT ID order, not in name order
//    (here ids 68893 "Probe BM Ext", 68894 "Probe BM Zeta", 68895 "Probe BM Alpha": Alpha has the first name and
//    runs last). The columns the extensions add follow the base's columns in the same order. The order between
//    apps is not probed.
// BC versions: 27.5

table 68890 "Probe BM Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 68891 "Probe BM Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

report 68892 "Probe BM Base"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(Row; "Probe BM Table")
        {
            column(Id; Id) { }

            trigger OnPreDataItem()
            begin
                BmLog.Add('base PreDataItem counter=' + Format(Counter));
            end;

            trigger OnAfterGetRecord()
            begin
                BmLog.Add('base Row counter=' + Format(Counter));
            end;
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbeBmLayout.rdl';
            Caption = 'Probe layout';
        }
    }

    protected var
        Counter: Integer;
        Dec: Decimal;
        Other: Record "Probe BM Table";
        Win: Dialog;
        Names: List of [Text];

    var
        Hidden: Integer;
        BmLog: Codeunit "Probe BM Log";

    trigger OnPreReport()
    begin
        Counter := 10;
        Dec := 1.5;
        Other.Id := 77;
        Hidden := 5;
        Names.Add('base');
        BmLog.Add('base PreReport');
    end;

    trigger OnPostReport()
    begin
        BmLog.Add('base PostReport counter=' + Format(Counter) + ' dec=' + Format(Dec) + ' other=' + Format(Other.Id) + ' bump=' + Format(Bump()) + ' names=' + Format(Names.Count()));
    end;

    procedure PubProc(Add: Integer): Integer
    begin
        Counter += Add;
        exit(Counter);
    end;

    protected procedure Bump(): Integer
    begin
        Counter += 100;
        exit(Counter);
    end;
}

reportextension 68893 "Probe BM Ext" extends "Probe BM Base"
{
    dataset
    {
        modify(Row)
        {
            trigger OnAfterPreDataItem()
            begin
                BmLog.Add('ext PreDataItem counter=' + Format(Counter) + ' dec=' + Format(Dec) + ' other=' + Format(Other.Id));
                Counter := 20;
                Names.Add('ext');
                BmLog.Add('ext PubProc=' + Format(PubProc(1)) + ' names=' + Format(Names.Count()));
                Win.Open('#1###');
                Win.Update(1, 5);
                Win.Close();
            end;

            trigger OnAfterAfterGetRecord()
            begin
                BmLog.Add('ext Row counter=' + Format(Counter));
                Counter := Bump();
                Dec := Dec * 2;
                Other.Id := 88;
                BmLog.Add('ext after Bump counter=' + Format(Counter));
            end;
        }
    }

    var
        BmLog: Codeunit "Probe BM Log";

    trigger OnPreReport()
    begin
        BmLog.Add('ext PreReport counter=' + Format(Counter) + ' bump=' + Format(Bump()));
    end;
}

reportextension 68894 "Probe BM Zeta" extends "Probe BM Base"
{
    dataset
    {
        modify(Row)
        {
            trigger OnAfterPreDataItem()
            begin
                BmLog.Add('Zeta PreDataItem counter=' + Format(Counter));
                Counter += 1;
            end;

            trigger OnAfterAfterGetRecord()
            begin
                BmLog.Add('Zeta Row counter=' + Format(Counter));
            end;
        }
        add(Row)
        {
            column(ZetaCol; Id) { }
        }
    }

    var
        BmLog: Codeunit "Probe BM Log";

    trigger OnPreReport()
    begin
        BmLog.Add('Zeta PreReport counter=' + Format(Counter));
        Counter += 1000;
    end;

    trigger OnPostReport()
    begin
        BmLog.Add('Zeta PostReport counter=' + Format(Counter));
    end;
}

reportextension 68895 "Probe BM Alpha" extends "Probe BM Base"
{
    dataset
    {
        modify(Row)
        {
            trigger OnAfterPreDataItem()
            begin
                BmLog.Add('Alpha PreDataItem counter=' + Format(Counter));
                Counter += 2;
            end;

            trigger OnAfterAfterGetRecord()
            begin
                BmLog.Add('Alpha Row counter=' + Format(Counter));
            end;
        }
        add(Row)
        {
            column(AlphaCol; Id) { }
        }
    }

    var
        BmLog: Codeunit "Probe BM Log";

    trigger OnPreReport()
    begin
        BmLog.Add('Alpha PreReport counter=' + Format(Counter));
        Counter += 2000;
    end;

    trigger OnPostReport()
    begin
        BmLog.Add('Alpha PostReport counter=' + Format(Counter));
    end;
}

codeunit 68896 "Probe Report Ext Base Members"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Extensions_ShareTheBaseReportsInstance_AndRunInObjectIdOrder()
    var
        BmRec: Record "Probe BM Table";
        BmLog: Codeunit "Probe BM Log";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Columns: Text;
    begin
        BmRec.DeleteAll();
        BmRec.Id := 1;
        BmRec.Insert();
        Commit();
        BmLog.Take();

        TempBlob.CreateOutStream(OutStr);
        Assert.IsTrue(Report.SaveAs(Report::"Probe BM Base", '', ReportFormat::Xml, OutStr), 'SaveAs');

        Assert.AreEqual(
            'base PreReport;ext PreReport counter=10 bump=110;Zeta PreReport counter=110;Alpha PreReport counter=1110;' +
            'base PreDataItem counter=3110;ext PreDataItem counter=3110 dec=1.5 other=77;ext PubProc=21 names=2;' +
            'Zeta PreDataItem counter=21;Alpha PreDataItem counter=22;' +
            'base Row counter=24;ext Row counter=24;ext after Bump counter=124;Zeta Row counter=124;Alpha Row counter=124;' +
            'base PostReport counter=124 dec=3 other=88 bump=224 names=2;Zeta PostReport counter=224;Alpha PostReport counter=224;',
            BmLog.Take(), 'trigger log');

        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Line := Line.Trim();
            if Line.StartsWith('<Column name="') then
                Columns += Line.Substring(15, Line.IndexOf('">') - 15) + ' ';
        end;
        Assert.AreEqual('Id ZetaCol AlphaCol ', Columns, 'columns');
    end;
}
