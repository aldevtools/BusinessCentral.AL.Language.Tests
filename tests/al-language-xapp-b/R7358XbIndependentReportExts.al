// Cross-app fixtures for al-runner issue 7358, app B (depends on A, not on D). See tests/al-language-xapp-a/R7358XaIndependentReports.al.

reportextension 96296 "RPT Indep One Zulu" extends "RPT XA Indep One"
{
    dataset
    {
        add(Head)
        {
            column(BCol; BValue) { }
        }
        addfirst(Head)
        {
            dataitem(BFirst; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(BFirstNo; Number) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('B:First row');
                end;
            }
        }
        addlast(Head)
        {
            dataitem(BLast; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(BLastNo; Number) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('B:Last row');
                end;
            }
        }
        addbefore(Inner)
        {
            dataitem(BBefore; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(BBeforeNo; Number) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('B:Before row');
                end;
            }
        }
        addafter(Inner)
        {
            dataitem(BAfter; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(BAfterNo; Number) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('B:After row');
                end;
            }
        }
        modify(Head)
        {
            trigger OnBeforePreDataItem()
            begin
                Log.Add('B:Head OnBeforePreDataItem');
            end;

            trigger OnAfterPreDataItem()
            begin
                Log.Add('B:Head OnAfterPreDataItem');
            end;

            trigger OnBeforeAfterGetRecord()
            begin
                Log.Add('B:Head OnBeforeAfterGetRecord');
            end;

            trigger OnAfterAfterGetRecord()
            begin
                Log.Add('B:Head OnAfterAfterGetRecord');
            end;

            trigger OnBeforePostDataItem()
            begin
                Log.Add('B:Head OnBeforePostDataItem');
            end;

            trigger OnAfterPostDataItem()
            begin
                Log.Add('B:Head OnAfterPostDataItem');
            end;
        }
    }

    requestpage
    {
        layout
        {
            addafter(BaseOption)
            {
                field(BField; BFieldValue)
                {
                    ApplicationArea = All;
                    Caption = 'B field';
                }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('B:rp open');
        end;

        trigger OnClosePage()
        begin
            Log.Add('B:rp close');
        end;
    }

    labels
    {
        BLabel = 'B';
    }

    trigger OnPreReport()
    begin
        Log.Add('B:pre');
    end;

    trigger OnPostReport()
    begin
        Log.Add('B:post');
    end;

    var
        Log: Codeunit "RPT XA Indep Log";
        BValue: Integer;
        BFieldValue: Boolean;
}

reportextension 96297 "RPT Indep Two Alpha" extends "RPT XA Indep Two"
{
    dataset
    {
        add(Head)
        {
            column(BCol; BValue) { }
        }
        addfirst(Head)
        {
            dataitem(BFirst; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(BFirstNo; Number) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('B:First row');
                end;
            }
        }
        addlast(Head)
        {
            dataitem(BLast; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(BLastNo; Number) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('B:Last row');
                end;
            }
        }
        addbefore(Inner)
        {
            dataitem(BBefore; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(BBeforeNo; Number) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('B:Before row');
                end;
            }
        }
        addafter(Inner)
        {
            dataitem(BAfter; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(BAfterNo; Number) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('B:After row');
                end;
            }
        }
        modify(Head)
        {
            trigger OnBeforePreDataItem()
            begin
                Log.Add('B:Head OnBeforePreDataItem');
            end;

            trigger OnAfterPreDataItem()
            begin
                Log.Add('B:Head OnAfterPreDataItem');
            end;

            trigger OnBeforeAfterGetRecord()
            begin
                Log.Add('B:Head OnBeforeAfterGetRecord');
            end;

            trigger OnAfterAfterGetRecord()
            begin
                Log.Add('B:Head OnAfterAfterGetRecord');
            end;

            trigger OnBeforePostDataItem()
            begin
                Log.Add('B:Head OnBeforePostDataItem');
            end;

            trigger OnAfterPostDataItem()
            begin
                Log.Add('B:Head OnAfterPostDataItem');
            end;
        }
    }

    requestpage
    {
        layout
        {
            addafter(BaseOption)
            {
                field(BField; BFieldValue)
                {
                    ApplicationArea = All;
                    Caption = 'B field';
                }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('B:rp open');
        end;

        trigger OnClosePage()
        begin
            Log.Add('B:rp close');
        end;
    }

    labels
    {
        BLabel = 'B';
    }

    trigger OnPreReport()
    begin
        Log.Add('B:pre');
    end;

    trigger OnPostReport()
    begin
        Log.Add('B:post');
    end;

    var
        Log: Codeunit "RPT XA Indep Log";
        BValue: Integer;
        BFieldValue: Boolean;
}
