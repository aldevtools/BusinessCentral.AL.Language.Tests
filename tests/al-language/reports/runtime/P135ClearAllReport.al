// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 74250, codeunit 74251 (log), report 74252, codeunit 74253
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles (issue 135, reason 12): "ClearAll in a report (not pinned)".
// Facts: ClearAll() called in OnInitReport, OnPreReport, a data item's OnPreDataItem and OnPostReport of a report: what happens to the report's global variables (Integer, Text, Boolean, List, Record, the Mode variable itself), to the data item record, and to the rest of the run (rows still read, triggers still run).
// BC versions: 29 (27 and 28 by CI)

table 74250 "LT P135 CA Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74251 "LT P135 CA Log"
{
    SingleInstance = true;

    var
        Buffer: Text;

    procedure Add(Entry: Text)
    begin
        Buffer += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Buffer;
        Buffer := '';
        exit(Result);
    end;
}

report 74252 "LT P135 ClearAll Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P135 CA Row")
        {
            trigger OnPreDataItem()
            var
                Log: Codeunit "LT P135 CA Log";
            begin
                Log.Add('predi-before ' + State());
                if Mode = 3 then begin
                    ClearAll();
                    Log.Add('predi-after ' + State());
                end;
            end;

            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT P135 CA Log";
            begin
                Log.Add('row ' + Format(Row.Id) + ' ' + State());
            end;

            trigger OnPostDataItem()
            var
                Log: Codeunit "LT P135 CA Log";
            begin
                Log.Add('postdi ' + State());
            end;
        }
    }

    var
        Mode: Integer;
        Counter: Integer;
        Caption2: Text[30];
        Flag: Boolean;
        Items: List of [Text];
        Extra: Record "LT P135 CA Row";

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    local procedure State(): Text
    begin
        exit('M=' + Format(Mode) + ' C=' + Format(Counter) + ' T=' + Caption2 + ' F=' + Format(Flag) + ' L=' + Format(Items.Count()) + ' X=' + Format(Extra.Id) + ' R=' + Format(Row.Count()));
    end;

    trigger OnInitReport()
    var
        Log: Codeunit "LT P135 CA Log";
    begin
        Counter := 5;
        Caption2 := 'init';
        Flag := true;
        Items.Add('a');
        Extra.Id := 9;
        Log.Add('init-before ' + State());
        if Mode = 1 then begin
            ClearAll();
            Log.Add('init-after ' + State());
        end;
    end;

    trigger OnPreReport()
    var
        Log: Codeunit "LT P135 CA Log";
    begin
        Log.Add('pre-before ' + State());
        if Mode = 2 then begin
            ClearAll();
            Log.Add('pre-after ' + State());
        end;
    end;

    trigger OnPostReport()
    var
        Log: Codeunit "LT P135 CA Log";
    begin
        Log.Add('post-before ' + State());
        if Mode = 4 then begin
            ClearAll();
            Log.Add('post-after ' + State());
        end;
    end;
}

codeunit 74253 "LT P135 ClearAll Report Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P135 CA Row";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Name := 'one';
        R.Insert();
        R.Id := 2;
        R.Name := 'two';
        R.Insert();
    end;

    local procedure RunMode(M: Integer): Text
    var
        Rpt: Report "LT P135 ClearAll Report";
        Log: Codeunit "LT P135 CA Log";
    begin
        Log.Take();
        Rpt.SetMode(M);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        exit(Log.Take());
    end;

    [Test]
    procedure P135_NoClearAll_Baseline()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('log', RunMode(0));
        Observer.Expect('log', 'init-before M=0 C=5 T=init F=Yes L=1 X=9 R=2;pre-before M=0 C=5 T=init F=Yes L=1 X=9 R=2;predi-before M=0 C=5 T=init F=Yes L=1 X=9 R=2;row 1 M=0 C=5 T=init F=Yes L=1 X=9 R=2;row 2 M=0 C=5 T=init F=Yes L=1 X=9 R=2;postdi M=0 C=5 T=init F=Yes L=1 X=9 R=2;post-before M=0 C=5 T=init F=Yes L=1 X=9 R=2;');
        Observer.Verify();
    end;

    [Test]
    procedure P135_ClearAll_In_OnInitReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('log', RunMode(1));
        Observer.Expect('log', 'init-before M=0 C=5 T=init F=Yes L=1 X=9 R=2;pre-before M=1 C=5 T=init F=Yes L=1 X=9 R=2;predi-before M=1 C=5 T=init F=Yes L=1 X=9 R=2;row 1 M=1 C=5 T=init F=Yes L=1 X=9 R=2;row 2 M=1 C=5 T=init F=Yes L=1 X=9 R=2;postdi M=1 C=5 T=init F=Yes L=1 X=9 R=2;post-before M=1 C=5 T=init F=Yes L=1 X=9 R=2;');
        Observer.Verify();
    end;

    [Test]
    procedure P135_ClearAll_In_OnPreReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('log', RunMode(2));
        Observer.Expect('log', 'init-before M=0 C=5 T=init F=Yes L=1 X=9 R=2;pre-before M=2 C=5 T=init F=Yes L=1 X=9 R=2;pre-after M=0 C=0 T= F=No L=0 X=0 R=2;predi-before M=0 C=0 T= F=No L=0 X=0 R=2;row 1 M=0 C=0 T= F=No L=0 X=0 R=2;row 2 M=0 C=0 T= F=No L=0 X=0 R=2;postdi M=0 C=0 T= F=No L=0 X=0 R=2;post-before M=0 C=0 T= F=No L=0 X=0 R=2;');
        Observer.Verify();
    end;

    [Test]
    procedure P135_ClearAll_In_OnPreDataItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('log', RunMode(3));
        Observer.Expect('log', 'init-before M=0 C=5 T=init F=Yes L=1 X=9 R=2;pre-before M=3 C=5 T=init F=Yes L=1 X=9 R=2;predi-before M=3 C=5 T=init F=Yes L=1 X=9 R=2;predi-after M=0 C=0 T= F=No L=0 X=0 R=2;row 1 M=0 C=0 T= F=No L=0 X=0 R=2;row 2 M=0 C=0 T= F=No L=0 X=0 R=2;postdi M=0 C=0 T= F=No L=0 X=0 R=2;post-before M=0 C=0 T= F=No L=0 X=0 R=2;');
        Observer.Verify();
    end;

    [Test]
    procedure P135_ClearAll_In_OnPostReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('log', RunMode(4));
        Observer.Expect('log', 'init-before M=0 C=5 T=init F=Yes L=1 X=9 R=2;pre-before M=4 C=5 T=init F=Yes L=1 X=9 R=2;predi-before M=4 C=5 T=init F=Yes L=1 X=9 R=2;row 1 M=4 C=5 T=init F=Yes L=1 X=9 R=2;row 2 M=4 C=5 T=init F=Yes L=1 X=9 R=2;postdi M=4 C=5 T=init F=Yes L=1 X=9 R=2;post-before M=4 C=5 T=init F=Yes L=1 X=9 R=2;post-after M=0 C=0 T= F=No L=0 X=0 R=2;');
        Observer.Verify();
    end;
}
