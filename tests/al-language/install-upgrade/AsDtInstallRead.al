// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datatransfer/datatransfer-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), AsDtInstallTables.al (tables 79932-79937), AsDtInstaller.al (install codeunit 79938)
// Facts: what DataTransfer did when it ran in OnInstallAppPerCompany: the outcome of each call and the destination rows afterwards.
//   CopyRows with a source filter, mapped fields and a constant; CopyFields joined on the key with a source filter; CopyFields within one table;
//   CopyFields with a destination filter (BC 28+). Source rows: A(10, alpha, 1.5, kind 1), B(20, beta, 2.5, kind 2), C(30, gamma, 3.5, kind 1),
//   D(0, delta, 0, kind 2).
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced (27.5, 28.5, 29.0: identical).
// BC versions: 27.5+ (S4 28+)

codeunit 79939 "LT AS DT Install Read"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ObsText(ObsCode: Code[20]): Text
    var
        Obs: Record "LT AS DT Obs";
    begin
        if Obs.Get(ObsCode) then
            exit(Obs.Outcome);
        exit('<missing>');
    end;

    local procedure SrcRows(): Text
    var
        Src: Record "LT AS DT Src";
        Result: Text;
    begin
        if Src.FindSet() then
            repeat
                Result += StrSubstNo('%1|%2|%3|%4|%5;', Src."Code", Src.Amount, Src.Name, Format(Src.Qty, 0, 9), Src.Kind);
            until Src.Next() = 0;
        exit(Result);
    end;

    local procedure RowsRows(): Text
    var
        Dst: Record "LT AS DT Rows";
        Result: Text;
    begin
        if Dst.FindSet() then
            repeat
                Result += StrSubstNo('%1|%2|%3|%4|%5;', Dst."Code", Dst.Amount, Dst.Name, Dst.Note, Format(Dst.Qty, 0, 9));
            until Dst.Next() = 0;
        exit(Result);
    end;

    local procedure FieldsRows(): Text
    var
        Dst: Record "LT AS DT Fields";
        Result: Text;
    begin
        if Dst.FindSet() then
            repeat
                Result += StrSubstNo('%1|%2|%3|%4;', Dst."Code", Dst.Name, Dst.Amount, Dst.Note);
            until Dst.Next() = 0;
        exit(Result);
    end;

    local procedure SelfRows(): Text
    var
        Dst: Record "LT AS DT Self";
        Result: Text;
    begin
        if Dst.FindSet() then
            repeat
                Result += StrSubstNo('%1|%2|%3|%4;', Dst."Code", Dst.Amount, Dst."Copy", Dst.Note);
            until Dst.Next() = 0;
        exit(Result);
    end;

    local procedure DestFRows(): Text
    var
        Dst: Record "LT AS DT DestF";
        Result: Text;
    begin
        if Dst.FindSet() then
            repeat
                Result += StrSubstNo('%1|%2|%3;', Dst."Code", Dst.Name, Dst.Kind);
            until Dst.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure Install_ContextAndSourceUnchanged()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('ctx', ObsText('CTX'));
        Observer.Observe('done', ObsText('DONE'));
        Observer.Observe('src', SrcRows());
        Observer.Expect('ctx', 'Install');
        Observer.Expect('done', 'ok');
        Observer.Expect('src', 'A|10|alpha|1.5|1;B|20|beta|2.5|2;C|30|gamma|3.5|1;D|0|delta|0|2;');
        Observer.Verify();
    end;

    [Test]
    procedure Install_CopyRows_SourceFilter_FieldsAndConstant()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('outcome', ObsText('S1'));
        Observer.Observe('rows', RowsRows());
        Observer.Expect('outcome', 'ok');
        Observer.Expect('rows', 'B|20|beta|copied|0;C|30|gamma|copied|0;');
        Observer.Verify();
    end;

    [Test]
    procedure Install_CopyFields_Join_SourceFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('outcome', ObsText('S2'));
        Observer.Observe('rows', FieldsRows());
        Observer.Expect('outcome', 'ok');
        Observer.Expect('rows', 'A|alpha|10|joined;B|old|-1|seed;E|old|-1|seed;');
        Observer.Verify();
    end;

    [Test]
    procedure Install_CopyFields_SameTable_SourceFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('outcome', ObsText('S3'));
        Observer.Observe('rows', SelfRows());
        Observer.Expect('outcome', 'ok');
        Observer.Expect('rows', 'X|5|-1|seed;Y|15|15|self;Z|25|25|self;');
        Observer.Verify();
    end;

#if BC28PLUS
    [Test]
    procedure Install_CopyFields_Join_DestinationFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('outcome', ObsText('S4'));
        Observer.Observe('rows', DestFRows());
        Observer.Expect('outcome', 'ok');
        Observer.Expect('rows', 'A|alpha|1;B|old|2;C|gamma|1;');
        Observer.Verify();
    end;
#endif

    // Writer P6924 (al-runtime-rs triage of issue 6924, row 1f): Clear of a DataTransfer variable in install code (scenarios C1-C3 of
    // codeunit 79938, tables DtClearTables.al). Each row is Code|Amount|Name|Note.
    local procedure DumpRows(TableNo: Integer): Text
    var
        RR: RecordRef;
        Result: Text;
    begin
        RR.Open(TableNo);
        if RR.FindSet() then
            repeat
                Result += StrSubstNo('%1|%2|%3|%4;', RR.Field(1).Value, RR.Field(2).Value, RR.Field(3).Value, RR.Field(4).Value);
            until RR.Next() = 0;
        RR.Close();
        exit(Result);
    end;

    [Test]
    procedure Install_Clear_BetweenSetTables_CopyRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('outcome', ObsText('C1'));
        Observer.Observe('first target rows', DumpRows(Database::"INS DT Clear First"));
        Observer.Observe('second target rows', DumpRows(Database::"INS DT Clear Second"));
        // Observed on BC 27.5, 28.5 and 29.0: Clear drops the source filter, the field mappings and the constant staged before it; only the
        // calls after the second SetTables count (all four source rows, Amount and Note not copied). Nothing goes to the first target.
        Observer.Expect('outcome', 'ok');
        Observer.Expect('first target rows', '');
        Observer.Expect('second target rows', 'A|0|alpha|;B|0|beta|;C|0|gamma|;D|0|delta|;');
        Observer.Verify();
    end;

    [Test]
    procedure Install_SetTablesTwice_NoClear_CopyRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('outcome', ObsText('C2'));
        Observer.Observe('first target rows', DumpRows(Database::"INS DT Twice First"));
        Observer.Observe('second target rows', DumpRows(Database::"INS DT Twice Second"));
        // Observed on BC 27.5, 28.5 and 29.0: without Clear, a second SetTables keeps the field mappings of the first one: mapping Code
        // again raises (the text is BC's, with its spelling), and nothing is copied.
        Observer.Expect('outcome', 'Not possible to add the same field as destionation field twice.|DB:Ok');
        Observer.Expect('first target rows', '');
        Observer.Expect('second target rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure Install_Clear_ThenCopyRowsWithoutSetTables()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('outcome', ObsText('C3'));
        Observer.Observe('target rows', DumpRows(Database::"INS DT Clear Only"));
        // Observed on BC 27.5, 28.5 and 29.0: after Clear, CopyRows asks for SetTables, also in install code.
        Observer.Expect('outcome', 'SetTables must first be called before calling other methods on DataTransfer.|DB:Ok');
        Observer.Expect('target rows', '');
        Observer.Verify();
    end;
}
