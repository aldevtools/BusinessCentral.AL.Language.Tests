// Cross-app fixtures for al-runner issue 7358, app A: two reports that app B and app D each extend. B and D both depend on A and do
// not depend on each other, so no dependency path orders their report extensions.
//   Report 97994 "RPT XA Indep One": extension 96296 in B (name "RPT Indep One Zulu"), extension 96306 in D (name "RPT Indep One Alpha").
//   Report 97995 "RPT XA Indep Two": extension 96297 in B (name "RPT Indep Two Alpha"), extension 61165 in D (name "RPT Indep Two Zulu").
// What each candidate rule predicts (B before D is written B,D):
//   the app (id, name, publisher or publish order): the same order for both reports;
//   the extension object id: One B,D and Two D,B;
//   the extension object name: One D,B and Two B,D.
// The app-level rules cannot be told apart with two apps: app id as text, as Guid bytes and app name say B,D; publisher and the
// publish order of CI (A, D, B) say D,B.
// Every trigger of the reports and of the extensions appends '<app>:<trigger>' to the SingleInstance log 97993.
// Tests: tests/al-language/reports/extensions/IndependentAppsReportExtensions.al.

codeunit 97993 "RPT XA Indep Log"
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

report 97994 "RPT XA Indep One"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Head; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(HeadNo; Number) { }
            column(HeadText; HeadTextValue) { }
            dataitem(Inner; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(InnerNo; Number) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('A:Inner row');
                end;
            }

            trigger OnPreDataItem()
            begin
                Log.Add('A:Head pre');
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('A:Head row');
            end;

            trigger OnPostDataItem()
            begin
                Log.Add('A:Head post');
            end;
        }
        dataitem(Tail; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(TailNo; Number) { }

            trigger OnAfterGetRecord()
            begin
                Log.Add('A:Tail row');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(BaseOption; BaseOptionValue)
                {
                    ApplicationArea = All;
                    Caption = 'Base option';
                }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('A:rp open');
        end;

        trigger OnClosePage()
        begin
            Log.Add('A:rp close');
        end;
    }

    labels
    {
        BaseLabel = 'Base';
    }

    trigger OnInitReport()
    begin
        Log.Add('A:init');
    end;

    trigger OnPreReport()
    begin
        Log.Add('A:pre');
    end;

    trigger OnPostReport()
    begin
        Log.Add('A:post');
    end;

    var
        Log: Codeunit "RPT XA Indep Log";
        BaseOptionValue: Boolean;
        HeadTextValue: Text;
}

report 97995 "RPT XA Indep Two"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Head; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(HeadNo; Number) { }
            column(HeadText; HeadTextValue) { }
            dataitem(Inner; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(InnerNo; Number) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('A:Inner row');
                end;
            }

            trigger OnPreDataItem()
            begin
                Log.Add('A:Head pre');
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('A:Head row');
            end;

            trigger OnPostDataItem()
            begin
                Log.Add('A:Head post');
            end;
        }
        dataitem(Tail; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(TailNo; Number) { }

            trigger OnAfterGetRecord()
            begin
                Log.Add('A:Tail row');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(BaseOption; BaseOptionValue)
                {
                    ApplicationArea = All;
                    Caption = 'Base option';
                }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('A:rp open');
        end;

        trigger OnClosePage()
        begin
            Log.Add('A:rp close');
        end;
    }

    labels
    {
        BaseLabel = 'Base';
    }

    trigger OnInitReport()
    begin
        Log.Add('A:init');
    end;

    trigger OnPreReport()
    begin
        Log.Add('A:pre');
    end;

    trigger OnPostReport()
    begin
        Log.Add('A:post');
    end;

    var
        Log: Codeunit "RPT XA Indep Log";
        BaseOptionValue: Boolean;
        HeadTextValue: Text;
}
