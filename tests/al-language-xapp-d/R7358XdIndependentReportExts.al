// Cross-app fixtures for al-runner issue 7358, app D (depends on A, not on B). See tests/al-language-xapp-a/R7358XaIndependentReports.al.

reportextension 96306 "RPT Indep One Alpha" extends "RPT XA Indep One"
{
    dataset
    {
        add(Head)
        {
            column(DCol; DValue) { }
        }
        addfirst(Head)
        {
            dataitem(DFirst; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(DFirstNo; Number) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('D:First row');
                end;
            }
        }
        addlast(Head)
        {
            dataitem(DLast; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(DLastNo; Number) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('D:Last row');
                end;
            }
        }
        addbefore(Inner)
        {
            dataitem(DBefore; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(DBeforeNo; Number) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('D:Before row');
                end;
            }
        }
        addafter(Inner)
        {
            dataitem(DAfter; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(DAfterNo; Number) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('D:After row');
                end;
            }
        }
        modify(Head)
        {
            trigger OnBeforePreDataItem()
            begin
                Log.Add('D:Head OnBeforePreDataItem');
            end;

            trigger OnAfterPreDataItem()
            begin
                Log.Add('D:Head OnAfterPreDataItem');
            end;

            trigger OnBeforeAfterGetRecord()
            begin
                Log.Add('D:Head OnBeforeAfterGetRecord');
            end;

            trigger OnAfterAfterGetRecord()
            begin
                Log.Add('D:Head OnAfterAfterGetRecord');
            end;

            trigger OnBeforePostDataItem()
            begin
                Log.Add('D:Head OnBeforePostDataItem');
            end;

            trigger OnAfterPostDataItem()
            begin
                Log.Add('D:Head OnAfterPostDataItem');
            end;
        }
    }

    requestpage
    {
        layout
        {
            addafter(BaseOption)
            {
                field(DField; DFieldValue)
                {
                    ApplicationArea = All;
                    Caption = 'D field';
                }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('D:rp open');
        end;

        trigger OnClosePage()
        begin
            Log.Add('D:rp close');
        end;
    }

    labels
    {
        DLabel = 'D';
    }

    trigger OnPreReport()
    begin
        Log.Add('D:pre');
    end;

    trigger OnPostReport()
    begin
        Log.Add('D:post');
    end;

    var
        Log: Codeunit "RPT XA Indep Log";
        DValue: Integer;
        DFieldValue: Boolean;
}

reportextension 61165 "RPT Indep Two Zulu" extends "RPT XA Indep Two"
{
    dataset
    {
        add(Head)
        {
            column(DCol; DValue) { }
        }
        addfirst(Head)
        {
            dataitem(DFirst; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(DFirstNo; Number) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('D:First row');
                end;
            }
        }
        addlast(Head)
        {
            dataitem(DLast; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(DLastNo; Number) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('D:Last row');
                end;
            }
        }
        addbefore(Inner)
        {
            dataitem(DBefore; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(DBeforeNo; Number) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('D:Before row');
                end;
            }
        }
        addafter(Inner)
        {
            dataitem(DAfter; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(DAfterNo; Number) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('D:After row');
                end;
            }
        }
        modify(Head)
        {
            trigger OnBeforePreDataItem()
            begin
                Log.Add('D:Head OnBeforePreDataItem');
            end;

            trigger OnAfterPreDataItem()
            begin
                Log.Add('D:Head OnAfterPreDataItem');
            end;

            trigger OnBeforeAfterGetRecord()
            begin
                Log.Add('D:Head OnBeforeAfterGetRecord');
            end;

            trigger OnAfterAfterGetRecord()
            begin
                Log.Add('D:Head OnAfterAfterGetRecord');
            end;

            trigger OnBeforePostDataItem()
            begin
                Log.Add('D:Head OnBeforePostDataItem');
            end;

            trigger OnAfterPostDataItem()
            begin
                Log.Add('D:Head OnAfterPostDataItem');
            end;
        }
    }

    requestpage
    {
        layout
        {
            addafter(BaseOption)
            {
                field(DField; DFieldValue)
                {
                    ApplicationArea = All;
                    Caption = 'D field';
                }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('D:rp open');
        end;

        trigger OnClosePage()
        begin
            Log.Add('D:rp close');
        end;
    }

    labels
    {
        DLabel = 'D';
    }

    trigger OnPreReport()
    begin
        Log.Add('D:pre');
    end;

    trigger OnPostReport()
    begin
        Log.Add('D:post');
    end;

    var
        Log: Codeunit "RPT XA Indep Log";
        DValue: Integer;
        DFieldValue: Boolean;
}
