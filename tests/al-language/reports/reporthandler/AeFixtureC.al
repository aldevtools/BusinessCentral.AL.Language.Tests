// Fixture of AeReportHandlerCalls.al: a copy of report 73841 and of log 73840 (lt-report-requestpage) so that no SingleInstance log is shared between test codeunits.

codeunit 78216 "LT AE Log C"
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

report 78217 "LT AE Request C"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT RpT Row")
        {
            RequestFilterFields = Id;

            trigger OnPreDataItem()
            begin
                L.Add('row pre filter=[' + Row.GetFilter(Id) + ']');
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(General)
                {
                    field(TextCtl; TextVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Text Control';

                        trigger OnValidate()
                        begin
                            L.Add('validate text=[' + TextVal + ']');
                        end;
                    }
                    field(IntCtl; IntVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Integer Control';

                        trigger OnValidate()
                        begin
                            L.Add('validate int=' + Format(IntVal));
                        end;
                    }
                    field(DecCtl; DecVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Decimal Control';
                    }
                    field(BoolCtl; BoolVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Boolean Control';
                    }
                    field(DateCtl; DateVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Date Control';
                    }
                    field(OptCtl; OptVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Option Control';
                    }
                    field(FixedCtl; FixedVal)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        Caption = 'Fixed Control';
                    }
                    field(HiddenCtl; HiddenVal)
                    {
                        ApplicationArea = All;
                        Visible = false;
                        Caption = 'Hidden Control';
                    }
                    field(DisabledCtl; DisabledVal)
                    {
                        ApplicationArea = All;
                        Enabled = false;
                        Caption = 'Disabled Control';
                    }
                    field(DynCtl; DynVal)
                    {
                        ApplicationArea = All;
                        Editable = DynEditable;
                        Visible = DynVisible;
                        Caption = 'Dynamic Control';
                    }
                }
            }
        }

        actions
        {
            area(Processing)
            {
                action(CustomAction)
                {
                    ApplicationArea = All;
                    Caption = 'Custom Action';

                    trigger OnAction()
                    begin
                        L.Add('custom action text=[' + TextVal + ']');
                    end;
                }
            }
        }

        trigger OnInit()
        begin
            L.Add('RP OnInit text=[' + TextVal + '] int=' + Format(IntVal));
            DynEditable := false;
            DynVisible := true;
        end;

        trigger OnOpenPage()
        begin
            L.Add('RP OnOpenPage text=[' + TextVal + '] int=' + Format(IntVal));
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            L.Add('RP OnQueryClosePage action=' + Format(CloseAction) + ' text=[' + TextVal + ']');
            exit(true);
        end;

        trigger OnClosePage()
        begin
            L.Add('RP OnClosePage text=[' + TextVal + ']');
        end;
    }

    var
        TextVal: Text[30];
        IntVal: Integer;
        DecVal: Decimal;
        BoolVal: Boolean;
        DateVal: Date;
        OptVal: Option A,B,C;
        FixedVal: Integer;
        HiddenVal: Integer;
        DisabledVal: Integer;
        DynVal: Integer;
        DynEditable: Boolean;
        DynVisible: Boolean;
        L: Codeunit "LT AE Log C";

    trigger OnInitReport()
    begin
        TextVal := 'init';
        IntVal := 7;
        DecVal := 1.5;
        BoolVal := true;
        DateVal := DMY2Date(2, 3, 2020);
        OptVal := OptVal::B;
        FixedVal := 99;
        L.Add('OnInitReport');
    end;

    trigger OnPreReport()
    begin
        L.Add('OnPreReport text=[' + TextVal + '] int=' + Format(IntVal) + ' dec=' + Format(DecVal) + ' bool=' + Format(BoolVal) + ' date=' + Format(DateVal, 0, 9) + ' opt=' + Format(OptVal) + ' fixed=' + Format(FixedVal));
    end;

    trigger OnPostReport()
    begin
        L.Add('OnPostReport');
    end;
}
