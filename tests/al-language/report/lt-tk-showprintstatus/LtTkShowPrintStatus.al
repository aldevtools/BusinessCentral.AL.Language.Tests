// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-showprintstatus-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), layout copies LtTkLayout_T/F/U.rdlc of this folder
// What a report with ShowPrintStatus = true, false and unset does when a test runs it: processing-only without request page,
// processing-only with request page (RequestPageHandler), and a report with an RDLC layout. Report.Run, RunModal, Execute, SaveAs.
// Is a handler needed, is a message or confirm raised, which triggers fire in which order, what is the result.
// Property metadata is pinned in metadata/lt-report-metadata-columns/ReportMetadata.al.
// BC versions: 27 - 29

codeunit 89940 "LT TK Log"
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


report 89941 "LT TK Proc T"
{
    ShowPrintStatus = true;
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(TkRow; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));

            trigger OnPreDataItem()
            begin
                TkLog.Add('PT OnPreDataItem');
            end;

            trigger OnAfterGetRecord()
            begin
                TkLog.Add('PT row ' + Format(Number));
            end;

            trigger OnPostDataItem()
            begin
                TkLog.Add('PT OnPostDataItem');
            end;
        }
    }

    trigger OnPreReport()
    begin
        TkLog.Add('PT OnPreReport');
    end;

    trigger OnPostReport()
    begin
        TkLog.Add('PT OnPostReport');
    end;

    var
        TkLog: Codeunit "LT TK Log";
}


report 89942 "LT TK Proc F"
{
    ShowPrintStatus = false;
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(TkRow; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));

            trigger OnPreDataItem()
            begin
                TkLog.Add('PF OnPreDataItem');
            end;

            trigger OnAfterGetRecord()
            begin
                TkLog.Add('PF row ' + Format(Number));
            end;

            trigger OnPostDataItem()
            begin
                TkLog.Add('PF OnPostDataItem');
            end;
        }
    }

    trigger OnPreReport()
    begin
        TkLog.Add('PF OnPreReport');
    end;

    trigger OnPostReport()
    begin
        TkLog.Add('PF OnPostReport');
    end;

    var
        TkLog: Codeunit "LT TK Log";
}


report 89943 "LT TK Proc U"
{
    
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(TkRow; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));

            trigger OnPreDataItem()
            begin
                TkLog.Add('PU OnPreDataItem');
            end;

            trigger OnAfterGetRecord()
            begin
                TkLog.Add('PU row ' + Format(Number));
            end;

            trigger OnPostDataItem()
            begin
                TkLog.Add('PU OnPostDataItem');
            end;
        }
    }

    trigger OnPreReport()
    begin
        TkLog.Add('PU OnPreReport');
    end;

    trigger OnPostReport()
    begin
        TkLog.Add('PU OnPostReport');
    end;

    var
        TkLog: Codeunit "LT TK Log";
}


report 89944 "LT TK Req T"
{
    ShowPrintStatus = true;
    ProcessingOnly = true;
    UseRequestPage = true;

    dataset
    {
        dataitem(TkRow; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));
            column(TkNum; Number) { }
            trigger OnPreDataItem()
            begin
                TkLog.Add('RT OnPreDataItem');
            end;

            trigger OnAfterGetRecord()
            begin
                TkLog.Add('RT row ' + Format(Number));
            end;

            trigger OnPostDataItem()
            begin
                TkLog.Add('RT OnPostDataItem');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(TkOpt; TkOpt)
                {
                    ApplicationArea = All;
                    Caption = 'Option text';
                }
            }
        }

        trigger OnOpenPage()
        begin
            TkLog.Add('RT req OnOpenPage');
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            TkLog.Add('RT req OnQueryClosePage');
            exit(true);
        end;
    }

    trigger OnPreReport()
    begin
        TkLog.Add('RT OnPreReport');
    end;

    trigger OnPostReport()
    begin
        TkLog.Add('RT OnPostReport');
    end;

    var
        TkLog: Codeunit "LT TK Log";
        TkOpt: Text[30];
}


report 89945 "LT TK Req F"
{
    ShowPrintStatus = false;
    ProcessingOnly = true;
    UseRequestPage = true;

    dataset
    {
        dataitem(TkRow; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));
            column(TkNum; Number) { }
            trigger OnPreDataItem()
            begin
                TkLog.Add('RF OnPreDataItem');
            end;

            trigger OnAfterGetRecord()
            begin
                TkLog.Add('RF row ' + Format(Number));
            end;

            trigger OnPostDataItem()
            begin
                TkLog.Add('RF OnPostDataItem');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(TkOpt; TkOpt)
                {
                    ApplicationArea = All;
                    Caption = 'Option text';
                }
            }
        }

        trigger OnOpenPage()
        begin
            TkLog.Add('RF req OnOpenPage');
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            TkLog.Add('RF req OnQueryClosePage');
            exit(true);
        end;
    }

    trigger OnPreReport()
    begin
        TkLog.Add('RF OnPreReport');
    end;

    trigger OnPostReport()
    begin
        TkLog.Add('RF OnPostReport');
    end;

    var
        TkLog: Codeunit "LT TK Log";
        TkOpt: Text[30];
}


report 89946 "LT TK Req U"
{
    
    ProcessingOnly = true;
    UseRequestPage = true;

    dataset
    {
        dataitem(TkRow; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));
            column(TkNum; Number) { }
            trigger OnPreDataItem()
            begin
                TkLog.Add('RU OnPreDataItem');
            end;

            trigger OnAfterGetRecord()
            begin
                TkLog.Add('RU row ' + Format(Number));
            end;

            trigger OnPostDataItem()
            begin
                TkLog.Add('RU OnPostDataItem');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(TkOpt; TkOpt)
                {
                    ApplicationArea = All;
                    Caption = 'Option text';
                }
            }
        }

        trigger OnOpenPage()
        begin
            TkLog.Add('RU req OnOpenPage');
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            TkLog.Add('RU req OnQueryClosePage');
            exit(true);
        end;
    }

    trigger OnPreReport()
    begin
        TkLog.Add('RU OnPreReport');
    end;

    trigger OnPostReport()
    begin
        TkLog.Add('RU OnPostReport');
    end;

    var
        TkLog: Codeunit "LT TK Log";
        TkOpt: Text[30];
}


report 89947 "LT TK Layout T"
{
    ShowPrintStatus = true;
    DefaultRenderingLayout = LtTkLayoutT;
    UseRequestPage = false;

    dataset
    {
        dataitem(TkRow; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));
            column(TkNum; Number) { }
            trigger OnPreDataItem()
            begin
                TkLog.Add('LT OnPreDataItem');
            end;

            trigger OnAfterGetRecord()
            begin
                TkLog.Add('LT row ' + Format(Number));
            end;

            trigger OnPostDataItem()
            begin
                TkLog.Add('LT OnPostDataItem');
            end;
        }
    }

    rendering
    {
        layout(LtTkLayoutT)
        {
            Type = RDLC;
            LayoutFile = './report/lt-tk-showprintstatus/LtTkLayout_T.rdlc';
        }
    }

    trigger OnPreReport()
    begin
        TkLog.Add('LT OnPreReport');
    end;

    trigger OnPostReport()
    begin
        TkLog.Add('LT OnPostReport');
    end;

    var
        TkLog: Codeunit "LT TK Log";
}


report 89948 "LT TK Layout F"
{
    ShowPrintStatus = false;
    DefaultRenderingLayout = LtTkLayoutF;
    UseRequestPage = false;

    dataset
    {
        dataitem(TkRow; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));
            column(TkNum; Number) { }
            trigger OnPreDataItem()
            begin
                TkLog.Add('LF OnPreDataItem');
            end;

            trigger OnAfterGetRecord()
            begin
                TkLog.Add('LF row ' + Format(Number));
            end;

            trigger OnPostDataItem()
            begin
                TkLog.Add('LF OnPostDataItem');
            end;
        }
    }

    rendering
    {
        layout(LtTkLayoutF)
        {
            Type = RDLC;
            LayoutFile = './report/lt-tk-showprintstatus/LtTkLayout_F.rdlc';
        }
    }

    trigger OnPreReport()
    begin
        TkLog.Add('LF OnPreReport');
    end;

    trigger OnPostReport()
    begin
        TkLog.Add('LF OnPostReport');
    end;

    var
        TkLog: Codeunit "LT TK Log";
}


report 89949 "LT TK Layout U"
{
    
    DefaultRenderingLayout = LtTkLayoutU;
    UseRequestPage = false;

    dataset
    {
        dataitem(TkRow; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));
            column(TkNum; Number) { }
            trigger OnPreDataItem()
            begin
                TkLog.Add('LU OnPreDataItem');
            end;

            trigger OnAfterGetRecord()
            begin
                TkLog.Add('LU row ' + Format(Number));
            end;

            trigger OnPostDataItem()
            begin
                TkLog.Add('LU OnPostDataItem');
            end;
        }
    }

    rendering
    {
        layout(LtTkLayoutU)
        {
            Type = RDLC;
            LayoutFile = './report/lt-tk-showprintstatus/LtTkLayout_U.rdlc';
        }
    }

    trigger OnPreReport()
    begin
        TkLog.Add('LU OnPreReport');
    end;

    trigger OnPostReport()
    begin
        TkLog.Add('LU OnPostReport');
    end;

    var
        TkLog: Codeunit "LT TK Log";
}


codeunit 89950 "LT TK ShowPrintStatus Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        TkLog: Codeunit "LT TK Log";
        CancelRequest: Boolean;

    [TryFunction]
    local procedure TryText(What: Integer; ReportId: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Saved: Boolean;
    begin
        case What of
            1:
                Report.Run(ReportId);
            2:
                Report.RunModal(ReportId);
            3:
                Report.Execute(ReportId, '');
            4:
                begin
                    TempBlob.CreateOutStream(OutS);
                    Saved := Report.SaveAs(ReportId, '', ReportFormat::Pdf, OutS);
                    Observer.Observe('saved', Format(Saved));
                    Observer.Observe('bytes_nonzero', Format(TempBlob.Length() > 0));
                end;
            5:
                begin
                    TempBlob.CreateOutStream(OutS);
                    Saved := Report.SaveAs(ReportId, '', ReportFormat::Xml, OutS);
                    Observer.Observe('saved', Format(Saved));
                    Observer.Observe('bytes_nonzero', Format(TempBlob.Length() > 0));
                end;
        end;
    end;

    local procedure Probe(What: Integer; ReportId: Integer)
    var
        Ok: Boolean;
    begin
        TkLog.Take();
        Ok := TryText(What, ReportId);
        Observer.Observe('ok', Format(Ok));
        if not Ok then begin
            Observer.Observe('err', GetLastErrorText());
            Observer.Observe('code', GetLastErrorCode());
            ClearLastError();
        end;
        Observer.Observe('log', TkLog.Take());
    end;

    local procedure Done()
    begin
        Observer.Finish();
    end;

    [Test]
    procedure Proc_T_Run()
    begin
        Probe(1, 89941);
        Done();
    end;

    [Test]
    procedure Proc_T_RunModal()
    begin
        Probe(2, 89941);
        Done();
    end;

    [Test]
    procedure Proc_T_Execute()
    begin
        Probe(3, 89941);
        Done();
    end;

    [Test]
    procedure Proc_T_SaveAsPdf()
    begin
        Probe(4, 89941);
        Done();
    end;

    [Test]
    procedure Proc_T_SaveAsXml()
    begin
        Probe(5, 89941);
        Done();
    end;

    [Test]
    procedure Proc_F_Run()
    begin
        Probe(1, 89942);
        Done();
    end;

    [Test]
    procedure Proc_F_RunModal()
    begin
        Probe(2, 89942);
        Done();
    end;

    [Test]
    procedure Proc_F_Execute()
    begin
        Probe(3, 89942);
        Done();
    end;

    [Test]
    procedure Proc_F_SaveAsPdf()
    begin
        Probe(4, 89942);
        Done();
    end;

    [Test]
    procedure Proc_F_SaveAsXml()
    begin
        Probe(5, 89942);
        Done();
    end;

    [Test]
    procedure Proc_U_Run()
    begin
        Probe(1, 89943);
        Done();
    end;

    [Test]
    procedure Proc_U_RunModal()
    begin
        Probe(2, 89943);
        Done();
    end;

    [Test]
    procedure Proc_U_Execute()
    begin
        Probe(3, 89943);
        Done();
    end;

    [Test]
    procedure Proc_U_SaveAsPdf()
    begin
        Probe(4, 89943);
        Done();
    end;

    [Test]
    procedure Proc_U_SaveAsXml()
    begin
        Probe(5, 89943);
        Done();
    end;

    [Test]
    [HandlerFunctions('OkTHandler')]
    procedure Req_T_Run()
    begin
        Probe(1, 89944);
        Done();
    end;

    [Test]
    [HandlerFunctions('CancelTHandler')]
    procedure Req_T_Run_Cancel()
    begin
        Probe(1, 89944);
        Done();
    end;

    [Test]
    [HandlerFunctions('OkTHandler')]
    procedure Req_T_RunModal()
    begin
        Probe(2, 89944);
        Done();
    end;

    [Test]
    [HandlerFunctions('CancelTHandler')]
    procedure Req_T_RunModal_Cancel()
    begin
        Probe(2, 89944);
        Done();
    end;

    [Test]
    procedure Req_T_Execute()
    begin
        Probe(3, 89944);
        Done();
    end;

    [Test]
    procedure Req_T_SaveAsPdf()
    begin
        Probe(4, 89944);
        Done();
    end;

    [Test]
    procedure Req_T_SaveAsXml()
    begin
        Probe(5, 89944);
        Done();
    end;

    [Test]
    [HandlerFunctions('OkFHandler')]
    procedure Req_F_Run()
    begin
        Probe(1, 89945);
        Done();
    end;

    [Test]
    [HandlerFunctions('CancelFHandler')]
    procedure Req_F_Run_Cancel()
    begin
        Probe(1, 89945);
        Done();
    end;

    [Test]
    [HandlerFunctions('OkFHandler')]
    procedure Req_F_RunModal()
    begin
        Probe(2, 89945);
        Done();
    end;

    [Test]
    [HandlerFunctions('CancelFHandler')]
    procedure Req_F_RunModal_Cancel()
    begin
        Probe(2, 89945);
        Done();
    end;

    [Test]
    procedure Req_F_Execute()
    begin
        Probe(3, 89945);
        Done();
    end;

    [Test]
    procedure Req_F_SaveAsPdf()
    begin
        Probe(4, 89945);
        Done();
    end;

    [Test]
    procedure Req_F_SaveAsXml()
    begin
        Probe(5, 89945);
        Done();
    end;

    [Test]
    [HandlerFunctions('OkUHandler')]
    procedure Req_U_Run()
    begin
        Probe(1, 89946);
        Done();
    end;

    [Test]
    [HandlerFunctions('CancelUHandler')]
    procedure Req_U_Run_Cancel()
    begin
        Probe(1, 89946);
        Done();
    end;

    [Test]
    [HandlerFunctions('OkUHandler')]
    procedure Req_U_RunModal()
    begin
        Probe(2, 89946);
        Done();
    end;

    [Test]
    [HandlerFunctions('CancelUHandler')]
    procedure Req_U_RunModal_Cancel()
    begin
        Probe(2, 89946);
        Done();
    end;

    [Test]
    procedure Req_U_Execute()
    begin
        Probe(3, 89946);
        Done();
    end;

    [Test]
    procedure Req_U_SaveAsPdf()
    begin
        Probe(4, 89946);
        Done();
    end;

    [Test]
    procedure Req_U_SaveAsXml()
    begin
        Probe(5, 89946);
        Done();
    end;

    [Test]
    procedure Req_T_Run_NoHandler()
    begin
        Probe(1, 89944);
        Done();
    end;

    [Test]
    procedure Req_T_RunModal_NoHandler()
    begin
        Probe(2, 89944);
        Done();
    end;

    [Test]
    procedure Req_F_Run_NoHandler()
    begin
        Probe(1, 89945);
        Done();
    end;

    [Test]
    procedure Req_F_RunModal_NoHandler()
    begin
        Probe(2, 89945);
        Done();
    end;

    [Test]
    procedure Req_U_Run_NoHandler()
    begin
        Probe(1, 89946);
        Done();
    end;

    [Test]
    procedure Req_U_RunModal_NoHandler()
    begin
        Probe(2, 89946);
        Done();
    end;

    [Test]
    procedure Layout_T_Run()
    begin
        Probe(1, 89947);
        Done();
    end;

    [Test]
    procedure Layout_T_RunModal()
    begin
        Probe(2, 89947);
        Done();
    end;

    [Test]
    procedure Layout_T_Execute()
    begin
        Probe(3, 89947);
        Done();
    end;

    [Test]
    procedure Layout_T_SaveAsPdf()
    begin
        Probe(4, 89947);
        Done();
    end;

    [Test]
    procedure Layout_T_SaveAsXml()
    begin
        Probe(5, 89947);
        Done();
    end;

    [Test]
    procedure Layout_F_Run()
    begin
        Probe(1, 89948);
        Done();
    end;

    [Test]
    procedure Layout_F_RunModal()
    begin
        Probe(2, 89948);
        Done();
    end;

    [Test]
    procedure Layout_F_Execute()
    begin
        Probe(3, 89948);
        Done();
    end;

    [Test]
    procedure Layout_F_SaveAsPdf()
    begin
        Probe(4, 89948);
        Done();
    end;

    [Test]
    procedure Layout_F_SaveAsXml()
    begin
        Probe(5, 89948);
        Done();
    end;

    [Test]
    procedure Layout_U_Run()
    begin
        Probe(1, 89949);
        Done();
    end;

    [Test]
    procedure Layout_U_RunModal()
    begin
        Probe(2, 89949);
        Done();
    end;

    [Test]
    procedure Layout_U_Execute()
    begin
        Probe(3, 89949);
        Done();
    end;

    [Test]
    procedure Layout_U_SaveAsPdf()
    begin
        Probe(4, 89949);
        Done();
    end;

    [Test]
    procedure Layout_U_SaveAsXml()
    begin
        Probe(5, 89949);
        Done();
    end;

    [RequestPageHandler]
    procedure OkTHandler(var Rp: TestRequestPage "LT TK Req T")
    begin
        TkLog.Add('handler OkT');
        Rp.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CancelTHandler(var Rp: TestRequestPage "LT TK Req T")
    begin
        TkLog.Add('handler CancelT');
        Rp.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure OkFHandler(var Rp: TestRequestPage "LT TK Req F")
    begin
        TkLog.Add('handler OkF');
        Rp.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CancelFHandler(var Rp: TestRequestPage "LT TK Req F")
    begin
        TkLog.Add('handler CancelF');
        Rp.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure OkUHandler(var Rp: TestRequestPage "LT TK Req U")
    begin
        TkLog.Add('handler OkU');
        Rp.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CancelUHandler(var Rp: TestRequestPage "LT TK Req U")
    begin
        TkLog.Add('handler CancelU');
        Rp.Cancel().Invoke();
    end;
}
