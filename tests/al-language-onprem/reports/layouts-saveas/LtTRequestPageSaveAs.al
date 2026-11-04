// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testrequestpage/testrequestpage-saveaspdf-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (File, TemporaryPath)
// Fixtures used: Probe Observer (codeunit 69160), table "LT T Save Row" (98100); layout ./report/lt-t-saveas/LtTSave2.rdl; self-contained // Linux suspects: RDLC rendering is stubbed on the Linux tier (every SaveAsExcel, SaveAsPdf and SaveAsWord ends in the stub error); kept as source, not compiled.
#if LT_T_LINUX_SUSPECT
report 98103, test codeunit 98104
// Facts: TestRequestPage.SaveAsExcel, SaveAsPdf and SaveAsWord from a request page handler: the file is written, and what the request page does afterwards.
// BC versions: 27.0 and later

report 98103 "LT T Save RP Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(T; "LT T Save Row")
        {
            column(Id; Id) { }
            column(Txt; Txt) { }

            trigger OnPreDataItem()
            begin
                T.SetFilter(Id, '>=%1', Threshold);
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ThresholdField; Threshold) { ApplicationArea = All; }
            }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './reports/layouts-saveas/LtTSave2.rdl';
            Caption = 'LT T RP layout';
        }
    }

    var
        Threshold: Integer;
}

codeunit 98104 "LT T Save RP Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Target: Text;
        Kind: Text;

    local procedure Seed()
    var
        Row: Record "LT T Save Row";
        Index: Integer;
    begin
        Row.DeleteAll();
        for Index := 1 to 4 do begin
            Row.Id := Index;
            Row.Txt := 'row' + Format(Index);
            Row.Insert();
        end;
        Commit();
    end;

    [RequestPageHandler]
    procedure SaveHandler(var RP: TestRequestPage "LT T Save RP Report")
    begin
        RP.ThresholdField.SetValue(3);
        case Kind of
            'excel':
                RP.SaveAsExcel(Target);
            'pdf':
                RP.SaveAsPdf(Target);
            'word':
                RP.SaveAsWord(Target);
        end;
        Observer.ObserveError(Kind + ' handler');
        asserterror RP.Cancel().Invoke();
        Observer.ObserveError(Kind + ' cancel after');
    end;

    local procedure Describe(Tag: Text)
    var
        SaveFile: File;
        InStr: InStream;
        Value: Byte;
        One: Text[1];
        Head: Text;
        Count: Integer;
    begin
        Observer.Observe(Tag + ' exists', Format(Exists(Target)));
        if Exists(Target) then begin
            SaveFile.Open(Target);
            SaveFile.CreateInStream(InStr);
            while (not InStr.EOS()) and (Count < 5) do begin
                InStr.Read(Value);
                One[1] := Value;
                Head += One;
                Count += 1;
            end;
            Observer.Observe(Tag + ' length>0', Format(SaveFile.Len() > 0));
            SaveFile.Close();
            Observer.Observe(Tag + ' head', Head);
            Erase(Target);
        end;
    end;

    local procedure RunKind(NewKind: Text; Ext: Text)
    begin
        Seed();
        Kind := NewKind;
        Target := TemporaryPath() + 'lt-t-rp-save.' + Ext;
        if Exists(Target) then
            Erase(Target);
        Report.Run(Report::"LT T Save RP Report");
        Describe(NewKind);
    end;

    [Test]
    [HandlerFunctions('SaveHandler')]
    procedure RequestPage_SaveAsExcel()
    begin
        RunKind('excel', 'xlsx');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('SaveHandler')]
    procedure RequestPage_SaveAsPdf()
    begin
        RunKind('pdf', 'pdf');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('SaveHandler')]
    procedure RequestPage_SaveAsWord()
    begin
        RunKind('word', 'docx');
        Observer.Finish();
    end;
}
#endif
