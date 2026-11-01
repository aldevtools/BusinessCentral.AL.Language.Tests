// Cross-app fixtures of writer Y64 (al-runner issues 6653 and 6644), app A.
// 6653: report 61352 with a report extension in this app (61353), in B (61355), in C (61360) and in the AL Language Coverage Tests app (93326).
//   Every trigger of the report and of each extension appends '<app>:<trigger>' to the run log table 61350 (per company). Tests:
//   tests/al-language/reportext/lt-y64-xapp-run-order/Y64XappRunOrder.al.
// 6644: hub 61351 (SingleInstance) that install code of B and D arms with its app tag, an integration event the install code raises, and a
//   telemetry call; the subscribers in B and D (no dependency path between them) note in DataPerCompany = false table 61354 which app's install
//   they ran in. A subscriber does nothing while the hub is not armed, so it is inert outside these install triggers. Install code must never
//   fail: the only write is `if Insert() then;`. Tests: tests/al-language/install/lt-y64-install-subscribers/Y64InstallSubscribers.al.

table 61350 "LT Y64 XA Run Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Txt; Text[250]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 61351 "LT Y64 XA Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 61350 "LT Y64 XA Log"
{
    procedure Add(Entry: Text)
    var
        L: Record "LT Y64 XA Run Log";
    begin
        L.Init();
        L.Txt := CopyStr(Entry, 1, MaxStrLen(L.Txt));
        L.Insert();
    end;

    procedure Take(): Text
    var
        L: Record "LT Y64 XA Run Log";
        Result: Text;
    begin
        if L.FindSet() then
            repeat
                Result += L.Txt + ';';
            until L.Next() = 0;
        L.DeleteAll();
        exit(Result);
    end;
}

report 61352 "LT Y64 XA Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT Y64 XA Row")
        {
            trigger OnPreDataItem()
            begin
                Log.Add('A-base:predataitem');
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('A-base:aftergetrecord ' + Format(Row.Id));
            end;

            trigger OnPostDataItem()
            begin
                Log.Add('A-base:postdataitem');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(MyOption; MyOptionValue)
                {
                    Caption = 'My option';
                }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('A-base:rp open');
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            Log.Add('A-base:rp queryclose');
            exit(true);
        end;

        trigger OnClosePage()
        begin
            Log.Add('A-base:rp close');
        end;
    }

    trigger OnInitReport()
    begin
        Log.Add('A-base:initreport');
    end;

    trigger OnPreReport()
    begin
        Log.Add('A-base:prereport');
    end;

    trigger OnPostReport()
    begin
        Log.Add('A-base:postreport');
    end;

    var
        Log: Codeunit "LT Y64 XA Log";
        MyOptionValue: Boolean;

    procedure SetMyOption(Value: Boolean)
    begin
        MyOptionValue := Value;
    end;
}

reportextension 61353 "LT Y64 XA Report Ext A" extends "LT Y64 XA Report"
{
    dataset
    {
        modify(Row)
        {
            trigger OnBeforePreDataItem()
            begin
                ExtLog.Add('A-ext:beforepredataitem');
            end;

            trigger OnAfterPreDataItem()
            begin
                ExtLog.Add('A-ext:afterpredataitem');
            end;

            trigger OnBeforeAfterGetRecord()
            begin
                ExtLog.Add('A-ext:beforeaftergetrecord');
            end;

            trigger OnAfterAfterGetRecord()
            begin
                ExtLog.Add('A-ext:afteraftergetrecord');
            end;

            trigger OnBeforePostDataItem()
            begin
                ExtLog.Add('A-ext:beforepostdataitem');
            end;

            trigger OnAfterPostDataItem()
            begin
                ExtLog.Add('A-ext:afterpostdataitem');
            end;
        }
    }

    requestpage
    {
        layout
        {
            addafter(MyOption)
            {
                field(MyFieldA; MyVarA)
                {
                    Caption = 'My field A';
                }
            }
        }

        trigger OnOpenPage()
        begin
            MyInitA();
            ExtLog.Add('A-ext:rp open');
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            ExtLog.Add('A-ext:rp queryclose');
            exit(true);
        end;

        trigger OnClosePage()
        begin
            ExtLog.Add('A-ext:rp close');
        end;
    }

    trigger OnPreReport()
    begin
        ExtLog.Add('A-ext:prereport');
    end;

    trigger OnPostReport()
    begin
        ExtLog.Add('A-ext:postreport');
    end;

    var
        ExtLog: Codeunit "LT Y64 XA Log";
        MyVarA: Boolean;

    local procedure MyInitA()
    begin
        MyVarA := false;
    end;
}

table 61354 "LT Y64 XA Install Subs"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Tag; Text[100]) { }
    }

    keys { key(PK; Tag) { Clustered = true; } }
}

codeunit 61351 "LT Y64 XA Install Hub"
{
    SingleInstance = true;

    var
        ArmedApp: Text;

    procedure Arm(App: Text)
    begin
        ArmedApp := App;
    end;

    procedure Disarm()
    begin
        ArmedApp := '';
    end;

    procedure Armed(): Text
    begin
        exit(ArmedApp);
    end;

    procedure Note(Tag: Text)
    var
        Row: Record "LT Y64 XA Install Subs";
    begin
        Row.Tag := CopyStr(Tag, 1, MaxStrLen(Row.Tag));
        if Row.Insert() then;
    end;

    procedure Probe(App: Text; Phase: Text)
    var
        Telemetry: Codeunit Telemetry;
    begin
        Arm(App + '|' + Phase);
        Note('installed|' + App + '|' + Phase);
        OnY64InstallProbe(App + '|' + Phase);
        Telemetry.LogMessage('0000Y64', 'LT Y64 install probe', Verbosity::Normal, DataClassification::SystemMetadata);
        Disarm();
    end;

    [IntegrationEvent(false, false)]
    procedure OnY64InstallProbe(InstallingApp: Text)
    begin
    end;
}
