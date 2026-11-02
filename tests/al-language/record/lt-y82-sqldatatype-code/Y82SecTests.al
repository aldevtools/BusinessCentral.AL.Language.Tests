// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sqldatatype-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), objects in Y82Objects.al
// Probe (runner issues 6796 and 6797): Code fields with SQLDataType in secondary keys, in no key, in compound keys, in a table extension; FlowFields; Format and Evaluate; metadata.
// BC versions: 27.5, 28.5, 29.0
codeunit 94312 "LT Y82 Sec Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        H: Codeunit "LT Y82 Helper";

    [Test]
    procedure SecFVar_NumericOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 2, '10,9,2,1,100,'));
        Observer.Observe('asc', H.Dump(94305, 2, 1, true));
        Observer.Observe('desc', H.Dump(94305, 2, 1, false));
        Observer.Observe('range 2..10', H.DumpRange(94305, 2, 1, 2, '2', '10'));
        Observer.Observe('filter <10', H.DumpFilter(94305, 2, 1, 2, '<10'));
        Observer.Observe('filter >=9', H.DumpFilter(94305, 2, 1, 2, '>=9'));
        Observer.Observe('filter 2..10', H.DumpFilter(94305, 2, 1, 2, '2..10'));
        Observer.Observe('filter ..9', H.DumpFilter(94305, 2, 1, 2, '..9'));
        Observer.Observe('filter 1|9', H.DumpFilter(94305, 2, 1, 2, '1|9'));
        Observer.Observe('count blank', H.CountFilter(94305, 2, ''''''));
        Observer.Observe('count nonblank', H.CountFilter(94305, 2, '<>'''''));
        Observer.Finish();
    end;

    [Test]
    procedure SecFVar_Mixed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 2, 'A,B,1A,A1,10,9,007,a,'));
        Observer.Observe('asc', H.Dump(94305, 2, 1, true));
        Observer.Observe('desc', H.Dump(94305, 2, 1, false));
        Observer.Observe('range A..B', H.DumpRange(94305, 2, 1, 2, 'A', 'B'));
        Observer.Observe('range 1..10', H.DumpRange(94305, 2, 1, 2, '1', '10'));
        Observer.Observe('filter A*', H.DumpFilter(94305, 2, 1, 2, 'A*'));
        Observer.Finish();
    end;

    [Test]
    procedure SecFVar_Typed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', TypedSeedFVar());
        Observer.Observe('asc', TypedDumpFVar(true));
        Observer.Observe('desc', TypedDumpFVar(false));
        Observer.Observe('range 2..10', TypedRangeFVar('2', '10'));
        Observer.Observe('filter >9', TypedFilterFVar('>%1', '9'));
        Observer.Observe('firstlast', TypedFirstLastFVar());
        Observer.Finish();
    end;

    [Test]
    procedure SecFInt_NumericOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 3, '10,9,2,1,100,'));
        Observer.Observe('asc', H.Dump(94305, 3, 1, true));
        Observer.Observe('desc', H.Dump(94305, 3, 1, false));
        Observer.Observe('range 2..10', H.DumpRange(94305, 3, 1, 3, '2', '10'));
        Observer.Observe('filter <10', H.DumpFilter(94305, 3, 1, 3, '<10'));
        Observer.Observe('filter >=9', H.DumpFilter(94305, 3, 1, 3, '>=9'));
        Observer.Observe('filter 2..10', H.DumpFilter(94305, 3, 1, 3, '2..10'));
        Observer.Observe('filter ..9', H.DumpFilter(94305, 3, 1, 3, '..9'));
        Observer.Observe('filter 1|9', H.DumpFilter(94305, 3, 1, 3, '1|9'));
        Observer.Observe('count blank', H.CountFilter(94305, 3, ''''''));
        Observer.Observe('count nonblank', H.CountFilter(94305, 3, '<>'''''));
        Observer.Finish();
    end;

    [Test]
    procedure SecFInt_LeadingZeros()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 3, '007,7,07'));
        Observer.Observe('asc', H.Dump(94305, 3, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFInt_FilterLetters_Range()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 3, '1,2,10'));
        Observer.Observe('range A..B', H.DumpRange(94305, 3, 1, 3, 'A', 'B'));
        Observer.Finish();
    end;

    [Test]
    procedure SecFInt_FilterLetters_Text()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 3, '1,2,10'));
        Observer.Observe('filter A..B', H.DumpFilter(94305, 3, 1, 3, 'A..B'));
        Observer.Finish();
    end;

    [Test]
    procedure SecFInt_Typed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', TypedSeedFInt());
        Observer.Observe('asc', TypedDumpFInt(true));
        Observer.Observe('desc', TypedDumpFInt(false));
        Observer.Observe('range 2..10', TypedRangeFInt('2', '10'));
        Observer.Observe('filter >9', TypedFilterFInt('>%1', '9'));
        Observer.Observe('firstlast', TypedFirstLastFInt());
        Observer.Finish();
    end;

    [Test]
    procedure SecFBig_NumericOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 4, '10,9,2,1,100,'));
        Observer.Observe('asc', H.Dump(94305, 4, 1, true));
        Observer.Observe('desc', H.Dump(94305, 4, 1, false));
        Observer.Observe('range 2..10', H.DumpRange(94305, 4, 1, 4, '2', '10'));
        Observer.Observe('filter <10', H.DumpFilter(94305, 4, 1, 4, '<10'));
        Observer.Observe('filter >=9', H.DumpFilter(94305, 4, 1, 4, '>=9'));
        Observer.Observe('filter 2..10', H.DumpFilter(94305, 4, 1, 4, '2..10'));
        Observer.Observe('filter ..9', H.DumpFilter(94305, 4, 1, 4, '..9'));
        Observer.Observe('filter 1|9', H.DumpFilter(94305, 4, 1, 4, '1|9'));
        Observer.Observe('count blank', H.CountFilter(94305, 4, ''''''));
        Observer.Observe('count nonblank', H.CountFilter(94305, 4, '<>'''''));
        Observer.Finish();
    end;

    [Test]
    procedure SecFBig_LeadingZeros()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 4, '007,7,07'));
        Observer.Observe('asc', H.Dump(94305, 4, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFBig_FilterLetters_Range()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 4, '1,2,10'));
        Observer.Observe('range A..B', H.DumpRange(94305, 4, 1, 4, 'A', 'B'));
        Observer.Finish();
    end;

    [Test]
    procedure SecFBig_FilterLetters_Text()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 4, '1,2,10'));
        Observer.Observe('filter A..B', H.DumpFilter(94305, 4, 1, 4, 'A..B'));
        Observer.Finish();
    end;

    [Test]
    procedure SecFBig_Typed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', TypedSeedFBig());
        Observer.Observe('asc', TypedDumpFBig(true));
        Observer.Observe('desc', TypedDumpFBig(false));
        Observer.Observe('range 2..10', TypedRangeFBig('2', '10'));
        Observer.Observe('filter >9', TypedFilterFBig('>%1', '9'));
        Observer.Observe('firstlast', TypedFirstLastFBig());
        Observer.Finish();
    end;

    [Test]
    procedure SecFVnt_NumericOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 5, '10,9,2,1,100,'));
        Observer.Observe('asc', H.Dump(94305, 5, 1, true));
        Observer.Observe('desc', H.Dump(94305, 5, 1, false));
        Observer.Observe('range 2..10', H.DumpRange(94305, 5, 1, 5, '2', '10'));
        Observer.Observe('filter <10', H.DumpFilter(94305, 5, 1, 5, '<10'));
        Observer.Observe('filter >=9', H.DumpFilter(94305, 5, 1, 5, '>=9'));
        Observer.Observe('filter 2..10', H.DumpFilter(94305, 5, 1, 5, '2..10'));
        Observer.Observe('filter ..9', H.DumpFilter(94305, 5, 1, 5, '..9'));
        Observer.Observe('filter 1|9', H.DumpFilter(94305, 5, 1, 5, '1|9'));
        Observer.Observe('count blank', H.CountFilter(94305, 5, ''''''));
        Observer.Observe('count nonblank', H.CountFilter(94305, 5, '<>'''''));
        Observer.Finish();
    end;

    [Test]
    procedure SecFVnt_Mixed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 5, 'A,B,1A,A1,10,9,007,a,'));
        Observer.Observe('asc', H.Dump(94305, 5, 1, true));
        Observer.Observe('desc', H.Dump(94305, 5, 1, false));
        Observer.Observe('range A..B', H.DumpRange(94305, 5, 1, 5, 'A', 'B'));
        Observer.Observe('range 1..10', H.DumpRange(94305, 5, 1, 5, '1', '10'));
        Observer.Observe('filter A*', H.DumpFilter(94305, 5, 1, 5, 'A*'));
        Observer.Finish();
    end;

    [Test]
    procedure SecFVnt_Typed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', TypedSeedFVnt());
        Observer.Observe('asc', TypedDumpFVnt(true));
        Observer.Observe('desc', TypedDumpFVnt(false));
        Observer.Observe('range 2..10', TypedRangeFVnt('2', '10'));
        Observer.Observe('filter >9', TypedFilterFVnt('>%1', '9'));
        Observer.Observe('firstlast', TypedFirstLastFVnt());
        Observer.Finish();
    end;

    [Test]
    procedure SecFDef_NumericOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 6, '10,9,2,1,100,'));
        Observer.Observe('asc', H.Dump(94305, 6, 1, true));
        Observer.Observe('desc', H.Dump(94305, 6, 1, false));
        Observer.Observe('range 2..10', H.DumpRange(94305, 6, 1, 6, '2', '10'));
        Observer.Observe('filter <10', H.DumpFilter(94305, 6, 1, 6, '<10'));
        Observer.Observe('filter >=9', H.DumpFilter(94305, 6, 1, 6, '>=9'));
        Observer.Observe('filter 2..10', H.DumpFilter(94305, 6, 1, 6, '2..10'));
        Observer.Observe('filter ..9', H.DumpFilter(94305, 6, 1, 6, '..9'));
        Observer.Observe('filter 1|9', H.DumpFilter(94305, 6, 1, 6, '1|9'));
        Observer.Observe('count blank', H.CountFilter(94305, 6, ''''''));
        Observer.Observe('count nonblank', H.CountFilter(94305, 6, '<>'''''));
        Observer.Finish();
    end;

    [Test]
    procedure SecFDef_Mixed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 6, 'A,B,1A,A1,10,9,007,a,'));
        Observer.Observe('asc', H.Dump(94305, 6, 1, true));
        Observer.Observe('desc', H.Dump(94305, 6, 1, false));
        Observer.Observe('range A..B', H.DumpRange(94305, 6, 1, 6, 'A', 'B'));
        Observer.Observe('range 1..10', H.DumpRange(94305, 6, 1, 6, '1', '10'));
        Observer.Observe('filter A*', H.DumpFilter(94305, 6, 1, 6, 'A*'));
        Observer.Finish();
    end;

    [Test]
    procedure SecFDef_Typed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', TypedSeedFDef());
        Observer.Observe('asc', TypedDumpFDef(true));
        Observer.Observe('desc', TypedDumpFDef(false));
        Observer.Observe('range 2..10', TypedRangeFDef('2', '10'));
        Observer.Observe('filter >9', TypedFilterFDef('>%1', '9'));
        Observer.Observe('firstlast', TypedFirstLastFDef());
        Observer.Finish();
    end;

    [Test]
    procedure NoKeyNoKInt_Values()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 7, '10,9,2,100,'));
        Observer.Observe('by id', H.Dump(94305, 1, 1, true));
        Observer.Observe('range 2..10', H.DumpRange(94305, 1, 1, 7, '2', '10'));
        Observer.Observe('filter <10', H.DumpFilter(94305, 1, 1, 7, '<10'));
        Observer.Observe('filter >=9', H.DumpFilter(94305, 1, 1, 7, '>=9'));
        Observer.Observe('filter 1|9', H.DumpFilter(94305, 1, 1, 7, '1|9'));
        Observer.Observe('count blank', H.CountFilter(94305, 7, ''''''));
        Observer.Finish();
    end;

    [Test]
    procedure NoKeyNoKInt_Mixed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 7, 'A,1'));
        Observer.Observe('by id', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure NoKeyNoKInt_Alpha_Filter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 7, '1,2'));
        Observer.Observe('filter A*', H.CountFilter(94305, 7, 'A*'));
        Observer.Finish();
    end;

    [Test]
    procedure NoKeyNoKInt_Alpha_Range()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 7, '1,2'));
        Observer.Observe('range A..B', H.CountRange(94305, 7, 'A', 'B'));
        Observer.Finish();
    end;

    [Test]
    procedure NoKeyNoKVnt_Values()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 8, '10,9,2,100,'));
        Observer.Observe('by id', H.Dump(94305, 1, 1, true));
        Observer.Observe('range 2..10', H.DumpRange(94305, 1, 1, 8, '2', '10'));
        Observer.Observe('filter <10', H.DumpFilter(94305, 1, 1, 8, '<10'));
        Observer.Observe('filter >=9', H.DumpFilter(94305, 1, 1, 8, '>=9'));
        Observer.Observe('filter 1|9', H.DumpFilter(94305, 1, 1, 8, '1|9'));
        Observer.Observe('count blank', H.CountFilter(94305, 8, ''''''));
        Observer.Finish();
    end;

    [Test]
    procedure NoKeyNoKVnt_Mixed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 8, 'A,1'));
        Observer.Observe('by id', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure NoKeyNoKVnt_Alpha_Filter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 8, '1,2'));
        Observer.Observe('filter A*', H.CountFilter(94305, 8, 'A*'));
        Observer.Finish();
    end;

    [Test]
    procedure NoKeyNoKVnt_Alpha_Range()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 8, '1,2'));
        Observer.Observe('range A..B', H.CountRange(94305, 8, 'A', 'B'));
        Observer.Finish();
    end;

    [Test]
    procedure NoKeyNoKBig_Values()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 9, '10,9,2,100,'));
        Observer.Observe('by id', H.Dump(94305, 1, 1, true));
        Observer.Observe('range 2..10', H.DumpRange(94305, 1, 1, 9, '2', '10'));
        Observer.Observe('filter <10', H.DumpFilter(94305, 1, 1, 9, '<10'));
        Observer.Observe('filter >=9', H.DumpFilter(94305, 1, 1, 9, '>=9'));
        Observer.Observe('filter 1|9', H.DumpFilter(94305, 1, 1, 9, '1|9'));
        Observer.Observe('count blank', H.CountFilter(94305, 9, ''''''));
        Observer.Finish();
    end;

    [Test]
    procedure NoKeyNoKBig_Mixed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 9, 'A,1'));
        Observer.Observe('by id', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure NoKeyNoKBig_Alpha_Filter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 9, '1,2'));
        Observer.Observe('filter A*', H.CountFilter(94305, 9, 'A*'));
        Observer.Finish();
    end;

    [Test]
    procedure NoKeyNoKBig_Alpha_Range()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 9, '1,2'));
        Observer.Observe('range A..B', H.CountRange(94305, 9, 'A', 'B'));
        Observer.Finish();
    end;

    [Test]
    procedure NoKeyNoKVar_Values()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 10, '10,9,2,100,'));
        Observer.Observe('by id', H.Dump(94305, 1, 1, true));
        Observer.Observe('range 2..10', H.DumpRange(94305, 1, 1, 10, '2', '10'));
        Observer.Observe('filter <10', H.DumpFilter(94305, 1, 1, 10, '<10'));
        Observer.Observe('filter >=9', H.DumpFilter(94305, 1, 1, 10, '>=9'));
        Observer.Observe('filter 1|9', H.DumpFilter(94305, 1, 1, 10, '1|9'));
        Observer.Observe('count blank', H.CountFilter(94305, 10, ''''''));
        Observer.Finish();
    end;

    [Test]
    procedure NoKeyNoKVar_Mixed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 10, 'A,1'));
        Observer.Observe('by id', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure NoKeyNoKVar_Alpha_Filter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 10, '1,2'));
        Observer.Observe('filter A*', H.CountFilter(94305, 10, 'A*'));
        Observer.Finish();
    end;

    [Test]
    procedure NoKeyNoKVar_Alpha_Range()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 10, '1,2'));
        Observer.Observe('range A..B', H.CountRange(94305, 10, 'A', 'B'));
        Observer.Finish();
    end;

    [Test]
    procedure SecExtExtInt_Order()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 94300, '10,9,2,1,100,'));
        Observer.Observe('asc', H.Dump(94305, 94300, 1, true));
        Observer.Observe('desc', H.Dump(94305, 94300, 1, false));
        Observer.Observe('range 2..10', H.DumpRange(94305, 94300, 1, 94300, '2', '10'));
        Observer.Finish();
    end;

    [Test]
    procedure SecExtExtInt_Alpha()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('insert', H.Ins(94305, 94300, 1, 'ABC'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecExtExtVnt_Order()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('seed', H.Seed(94305, 94301, '10,9,2,1,100,'));
        Observer.Observe('asc', H.Dump(94305, 94301, 1, true));
        Observer.Observe('desc', H.Dump(94305, 94301, 1, false));
        Observer.Observe('range 2..10', H.DumpRange(94305, 94301, 1, 94301, '2', '10'));
        Observer.Finish();
    end;

    [Test]
    procedure SecExtExtVnt_Alpha()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('insert', H.Ins(94305, 94301, 1, 'ABC'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecCompound_DefVnt()
    var
        Observer: Codeunit "Probe Observer";
        RecA: Record "LT Y82 Sec";
    begin
        Observer.Observe('typed', TypedCompoundVnt(RecA));
        Observer.Finish();
    end;

    [Test]
    procedure SecCompound_Meta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('keys', H.KeyInfo(94305));
        Observer.Finish();
    end;

    [Test]
    procedure SecObsoleteVariant_Key()
    var
        Observer: Codeunit "Probe Observer";
        RecA: Record "LT Y82 Sec";
    begin
        Observer.Observe('typed', TypedObsolete(RecA));
        Observer.Finish();
    end;

    [Test]
    procedure SecCompound_Typed()
    var
        Observer: Codeunit "Probe Observer";
        RecA: Record "LT Y82 Sec";
    begin
        Observer.Observe('typed', TypedCompound(RecA));
        Observer.Finish();
    end;

    [Test]
    procedure Flow_RangeCounts()
    var
        Observer: Codeunit "Probe Observer";
        Flow: Record "LT Y82 Flow";
    begin
        Observer.Observe('seed var', H.Seed(94300, 1, '1,2,9,10,100'));
        Observer.Observe('seed int', H.Seed(94301, 1, '1,2,9,10,100'));
        Observer.Observe('seed big', H.Seed(94302, 1, '1,2,9,10,100'));
        Observer.Observe('seed vnt', H.Seed(94303, 1, '1,2,9,10,100'));
        Observer.Observe('seed def', H.Seed(94304, 1, '1,2,9,10,100'));
        Observer.Observe('counts', FlowRange(Flow));
        Observer.Finish();
    end;

    [Test]
    procedure Flow_ByField()
    var
        Observer: Codeunit "Probe Observer";
        Flow: Record "LT Y82 Flow";
    begin
        Observer.Observe('seed var', H.Seed(94300, 1, '1,2,9,10,100'));
        Observer.Observe('seed int', H.Seed(94301, 1, '1,2,9,10,100'));
        Observer.Observe('seed vnt', H.Seed(94303, 1, '1,2,9,10,100'));
        Observer.Observe('counts', FlowByField(Flow));
        Observer.Finish();
    end;

    [Test]
    procedure Format_Evaluate_IntCode()
    var
        Observer: Codeunit "Probe Observer";
        Sec: Record "LT Y82 Sec";
    begin
        Observer.Observe('fmt', FormatEvaluate(Sec));
        Observer.Finish();
    end;

    [Test]
    procedure FieldRef_Value_Types()
    var
        Observer: Codeunit "Probe Observer";
        Sec: Record "LT Y82 Sec";
    begin
        Observer.Observe('values', FieldRefValues(Sec));
        Observer.Finish();
    end;

    [Test]
    procedure Meta_Sec_FVar()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('field', H.FieldInfo(94305, 2));
        Observer.Finish();
    end;

    [Test]
    procedure Meta_Sec_FInt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('field', H.FieldInfo(94305, 3));
        Observer.Finish();
    end;

    [Test]
    procedure Meta_Sec_FBig()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('field', H.FieldInfo(94305, 4));
        Observer.Finish();
    end;

    [Test]
    procedure Meta_Sec_FVnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('field', H.FieldInfo(94305, 5));
        Observer.Finish();
    end;

    [Test]
    procedure Meta_Sec_FDef()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('field', H.FieldInfo(94305, 6));
        Observer.Finish();
    end;

    [Test]
    procedure Meta_Sec_NoKInt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('field', H.FieldInfo(94305, 7));
        Observer.Finish();
    end;

    [Test]
    procedure Meta_Sec_NoKVnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('field', H.FieldInfo(94305, 8));
        Observer.Finish();
    end;

    [Test]
    procedure Meta_Sec_NoKBig()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('field', H.FieldInfo(94305, 9));
        Observer.Finish();
    end;

    [Test]
    procedure Meta_Sec_NoKVar()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('field', H.FieldInfo(94305, 10));
        Observer.Finish();
    end;

    [Test]
    procedure Meta_Sec_FObs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('field', H.FieldInfo(94305, 11));
        Observer.Finish();
    end;

    [Test]
    procedure Meta_Sec_ExtInt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('field', H.FieldInfo(94305, 94300));
        Observer.Finish();
    end;

    [Test]
    procedure Meta_Sec_ExtVnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('field', H.FieldInfo(94305, 94301));
        Observer.Finish();
    end;







    local procedure TypedSeedFVar(): Text
    var
        Rec: Record "LT Y82 Sec";
        Values: List of [Text];
        Value: Text;
        Id: Integer;
    begin
        Values := '10,9,2,1,100,'.Split(',');
        foreach Value in Values do begin
            Id += 1;
            Rec.Init();
            Rec.Id := Id;
            Rec.FVar := CopyStr(Value, 1, 10);
            Rec.Insert();
        end;
        exit('ok');
    end;

    local procedure TypedDumpFVar(Ascending: Boolean): Text
    var
        Rec: Record "LT Y82 Sec";
        Result: Text;
        Sep: Text;
    begin
        Rec.SetCurrentKey(FVar);
        Rec.SetAscending(FVar, Ascending);
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.Id) + '=' + Format(Rec.FVar);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Result);
    end;

    local procedure TypedRangeFVar(FromValue: Text; ToValue: Text): Text
    var
        Rec: Record "LT Y82 Sec";
        Result: Text;
        Sep: Text;
    begin
        Rec.SetCurrentKey(FVar);
        Rec.SetRange(FVar, CopyStr(FromValue, 1, 10), CopyStr(ToValue, 1, 10));
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.Id);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Format(Rec.Count()) + ': ' + Result);
    end;

    local procedure TypedFilterFVar(Expression: Text; Value: Text): Text
    var
        Rec: Record "LT Y82 Sec";
        Result: Text;
        Sep: Text;
    begin
        Rec.SetCurrentKey(FVar);
        Rec.SetFilter(FVar, Expression, CopyStr(Value, 1, 10));
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.Id);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Format(Rec.Count()) + ': ' + Result + ' | filter=' + Rec.GetFilter(FVar));
    end;

    local procedure TypedFirstLastFVar(): Text
    var
        Rec: Record "LT Y82 Sec";
        First: Text;
        Last: Text;
    begin
        Rec.SetCurrentKey(FVar);
        Rec.FindFirst();
        First := Format(Rec.Id);
        Rec.FindLast();
        Last := Format(Rec.Id);
        exit(First + ' .. ' + Last);
    end;


    local procedure TypedSeedFInt(): Text
    var
        Rec: Record "LT Y82 Sec";
        Values: List of [Text];
        Value: Text;
        Id: Integer;
    begin
        Values := '10,9,2,1,100,'.Split(',');
        foreach Value in Values do begin
            Id += 1;
            Rec.Init();
            Rec.Id := Id;
            Rec.FInt := CopyStr(Value, 1, 10);
            Rec.Insert();
        end;
        exit('ok');
    end;

    local procedure TypedDumpFInt(Ascending: Boolean): Text
    var
        Rec: Record "LT Y82 Sec";
        Result: Text;
        Sep: Text;
    begin
        Rec.SetCurrentKey(FInt);
        Rec.SetAscending(FInt, Ascending);
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.Id) + '=' + Format(Rec.FInt);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Result);
    end;

    local procedure TypedRangeFInt(FromValue: Text; ToValue: Text): Text
    var
        Rec: Record "LT Y82 Sec";
        Result: Text;
        Sep: Text;
    begin
        Rec.SetCurrentKey(FInt);
        Rec.SetRange(FInt, CopyStr(FromValue, 1, 10), CopyStr(ToValue, 1, 10));
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.Id);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Format(Rec.Count()) + ': ' + Result);
    end;

    local procedure TypedFilterFInt(Expression: Text; Value: Text): Text
    var
        Rec: Record "LT Y82 Sec";
        Result: Text;
        Sep: Text;
    begin
        Rec.SetCurrentKey(FInt);
        Rec.SetFilter(FInt, Expression, CopyStr(Value, 1, 10));
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.Id);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Format(Rec.Count()) + ': ' + Result + ' | filter=' + Rec.GetFilter(FInt));
    end;

    local procedure TypedFirstLastFInt(): Text
    var
        Rec: Record "LT Y82 Sec";
        First: Text;
        Last: Text;
    begin
        Rec.SetCurrentKey(FInt);
        Rec.FindFirst();
        First := Format(Rec.Id);
        Rec.FindLast();
        Last := Format(Rec.Id);
        exit(First + ' .. ' + Last);
    end;


    local procedure TypedSeedFBig(): Text
    var
        Rec: Record "LT Y82 Sec";
        Values: List of [Text];
        Value: Text;
        Id: Integer;
    begin
        Values := '10,9,2,1,100,'.Split(',');
        foreach Value in Values do begin
            Id += 1;
            Rec.Init();
            Rec.Id := Id;
            Rec.FBig := CopyStr(Value, 1, 10);
            Rec.Insert();
        end;
        exit('ok');
    end;

    local procedure TypedDumpFBig(Ascending: Boolean): Text
    var
        Rec: Record "LT Y82 Sec";
        Result: Text;
        Sep: Text;
    begin
        Rec.SetCurrentKey(FBig);
        Rec.SetAscending(FBig, Ascending);
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.Id) + '=' + Format(Rec.FBig);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Result);
    end;

    local procedure TypedRangeFBig(FromValue: Text; ToValue: Text): Text
    var
        Rec: Record "LT Y82 Sec";
        Result: Text;
        Sep: Text;
    begin
        Rec.SetCurrentKey(FBig);
        Rec.SetRange(FBig, CopyStr(FromValue, 1, 10), CopyStr(ToValue, 1, 10));
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.Id);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Format(Rec.Count()) + ': ' + Result);
    end;

    local procedure TypedFilterFBig(Expression: Text; Value: Text): Text
    var
        Rec: Record "LT Y82 Sec";
        Result: Text;
        Sep: Text;
    begin
        Rec.SetCurrentKey(FBig);
        Rec.SetFilter(FBig, Expression, CopyStr(Value, 1, 10));
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.Id);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Format(Rec.Count()) + ': ' + Result + ' | filter=' + Rec.GetFilter(FBig));
    end;

    local procedure TypedFirstLastFBig(): Text
    var
        Rec: Record "LT Y82 Sec";
        First: Text;
        Last: Text;
    begin
        Rec.SetCurrentKey(FBig);
        Rec.FindFirst();
        First := Format(Rec.Id);
        Rec.FindLast();
        Last := Format(Rec.Id);
        exit(First + ' .. ' + Last);
    end;


    local procedure TypedSeedFVnt(): Text
    var
        Rec: Record "LT Y82 Sec";
        Values: List of [Text];
        Value: Text;
        Id: Integer;
    begin
        Values := '10,9,2,1,100,'.Split(',');
        foreach Value in Values do begin
            Id += 1;
            Rec.Init();
            Rec.Id := Id;
            Rec.FVnt := CopyStr(Value, 1, 10);
            Rec.Insert();
        end;
        exit('ok');
    end;

    local procedure TypedDumpFVnt(Ascending: Boolean): Text
    var
        Rec: Record "LT Y82 Sec";
        Result: Text;
        Sep: Text;
    begin
        Rec.SetCurrentKey(FVnt);
        Rec.SetAscending(FVnt, Ascending);
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.Id) + '=' + Format(Rec.FVnt);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Result);
    end;

    local procedure TypedRangeFVnt(FromValue: Text; ToValue: Text): Text
    var
        Rec: Record "LT Y82 Sec";
        Result: Text;
        Sep: Text;
    begin
        Rec.SetCurrentKey(FVnt);
        Rec.SetRange(FVnt, CopyStr(FromValue, 1, 10), CopyStr(ToValue, 1, 10));
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.Id);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Format(Rec.Count()) + ': ' + Result);
    end;

    local procedure TypedFilterFVnt(Expression: Text; Value: Text): Text
    var
        Rec: Record "LT Y82 Sec";
        Result: Text;
        Sep: Text;
    begin
        Rec.SetCurrentKey(FVnt);
        Rec.SetFilter(FVnt, Expression, CopyStr(Value, 1, 10));
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.Id);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Format(Rec.Count()) + ': ' + Result + ' | filter=' + Rec.GetFilter(FVnt));
    end;

    local procedure TypedFirstLastFVnt(): Text
    var
        Rec: Record "LT Y82 Sec";
        First: Text;
        Last: Text;
    begin
        Rec.SetCurrentKey(FVnt);
        Rec.FindFirst();
        First := Format(Rec.Id);
        Rec.FindLast();
        Last := Format(Rec.Id);
        exit(First + ' .. ' + Last);
    end;


    local procedure TypedSeedFDef(): Text
    var
        Rec: Record "LT Y82 Sec";
        Values: List of [Text];
        Value: Text;
        Id: Integer;
    begin
        Values := '10,9,2,1,100,'.Split(',');
        foreach Value in Values do begin
            Id += 1;
            Rec.Init();
            Rec.Id := Id;
            Rec.FDef := CopyStr(Value, 1, 10);
            Rec.Insert();
        end;
        exit('ok');
    end;

    local procedure TypedDumpFDef(Ascending: Boolean): Text
    var
        Rec: Record "LT Y82 Sec";
        Result: Text;
        Sep: Text;
    begin
        Rec.SetCurrentKey(FDef);
        Rec.SetAscending(FDef, Ascending);
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.Id) + '=' + Format(Rec.FDef);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Result);
    end;

    local procedure TypedRangeFDef(FromValue: Text; ToValue: Text): Text
    var
        Rec: Record "LT Y82 Sec";
        Result: Text;
        Sep: Text;
    begin
        Rec.SetCurrentKey(FDef);
        Rec.SetRange(FDef, CopyStr(FromValue, 1, 10), CopyStr(ToValue, 1, 10));
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.Id);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Format(Rec.Count()) + ': ' + Result);
    end;

    local procedure TypedFilterFDef(Expression: Text; Value: Text): Text
    var
        Rec: Record "LT Y82 Sec";
        Result: Text;
        Sep: Text;
    begin
        Rec.SetCurrentKey(FDef);
        Rec.SetFilter(FDef, Expression, CopyStr(Value, 1, 10));
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.Id);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Format(Rec.Count()) + ': ' + Result + ' | filter=' + Rec.GetFilter(FDef));
    end;

    local procedure TypedFirstLastFDef(): Text
    var
        Rec: Record "LT Y82 Sec";
        First: Text;
        Last: Text;
    begin
        Rec.SetCurrentKey(FDef);
        Rec.FindFirst();
        First := Format(Rec.Id);
        Rec.FindLast();
        Last := Format(Rec.Id);
        exit(First + ' .. ' + Last);
    end;

    local procedure SeedSecond(FieldNo: Integer; Values: Text): Text
    var
        Rec: Record "LT Y82 Sec";
        Parts: List of [Text];
        Part: Text;
        Id: Integer;
    begin
        Parts := Values.Split(',');
        foreach Part in Parts do begin
            Id += 1;
            Rec.Get(Id);
            Rec.FVnt := CopyStr(Part, 1, 10);
            Rec.Modify();
        end;
        exit('ok');
    end;

    local procedure TypedObsolete(var Rec: Record "LT Y82 Sec"): Text
    var
        Result: Text;
        Sep: Text;
    begin
        Rec.Init();
        Rec.Id := 1;
        Rec.FDef := 'A';
        Rec.FObs := 'X2';
        Rec.Insert();
        Rec.Init();
        Rec.Id := 2;
        Rec.FDef := 'A';
        Rec.FObs := 'X10';
        Rec.Insert();
        Rec.Init();
        Rec.Id := 3;
        Rec.FDef := 'A';
        Rec.Insert();
        Rec.Reset();
        Rec.SetCurrentKey(FDef, FObs);
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.Id);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Result + ' count=' + Format(Rec.Count()));
    end;

    local procedure TypedCompound(var Rec: Record "LT Y82 Sec"): Text
    var
        Result: Text;
        Sep: Text;
        I: Integer;
        Defs: List of [Text];
        Ints: List of [Text];
    begin
        Defs := 'A,A,B,A,A'.Split(',');
        Ints := '10,9,2,2,100'.Split(',');
        for I := 1 to 5 do begin
            Rec.Init();
            Rec.Id := I;
            Rec.FDef := CopyStr(Defs.Get(I), 1, 10);
            Rec.FInt := CopyStr(Ints.Get(I), 1, 10);
            Rec.Insert();
        end;
        Rec.SetCurrentKey(FDef, FInt);
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.Id);
                Sep := ',';
            until Rec.Next() = 0;
        Result += ' | desc ';
        Sep := '';
        Rec.SetAscending(FInt, false);
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.Id);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Result);
    end;

    local procedure TypedCompoundVnt(var Rec: Record "LT Y82 Sec"): Text
    var
        Result: Text;
        Sep: Text;
        I: Integer;
        Defs: List of [Text];
        Ints: List of [Text];
    begin
        Defs := 'A,A,B,A,A'.Split(',');
        Ints := '10,9,2,2,100'.Split(',');
        for I := 1 to 5 do begin
            Rec.Init();
            Rec.Id := I;
            Rec.FDef := CopyStr(Defs.Get(I), 1, 10);
            Rec.FVnt := CopyStr(Ints.Get(I), 1, 10);
            Rec.Insert();
        end;
        Rec.SetCurrentKey(FDef, FVnt);
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.Id);
                Sep := ',';
            until Rec.Next() = 0;
        Result += ' | desc ';
        Sep := '';
        Rec.SetAscending(FVnt, false);
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.Id);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Result);
    end;

    local procedure FlowRange(var Flow: Record "LT Y82 Flow"): Text
    begin
        Flow.Init();
        Flow.Id := 1;
        Flow.Insert();
        Flow.CalcFields(CntVarRange, CntIntRange, CntBigRange, CntVntRange, CntDefRange, CntIntLess, CntVarLess);
        exit(StrSubstNo('range 2..10: var %1 int %2 big %3 vnt %4 def %5 | less 10: int %6 var %7', Flow.CntVarRange, Flow.CntIntRange, Flow.CntBigRange, Flow.CntVntRange, Flow.CntDefRange, Flow.CntIntLess, Flow.CntVarLess));
    end;

    local procedure FlowByField(var Flow: Record "LT Y82 Flow"): Text
    begin
        Flow.Init();
        Flow.Id := 1;
        Flow.RefInt := '9';
        Flow.RefVar := '10';
        Flow.Insert();
        Flow.CalcFields(CntIntByRefInt, CntIntByRefVar, CntVarByRefInt, CntVntByRefVar);
        exit(StrSubstNo('int by refint %1 | int by refvar %2 | var by refint %3 | vnt by refvar %4', Flow.CntIntByRefInt, Flow.CntIntByRefVar, Flow.CntVarByRefInt, Flow.CntVntByRefVar));
    end;

    local procedure FormatEvaluate(var Sec: Record "LT Y82 Sec"): Text
    var
        Result: Text;
        Ok: Boolean;
    begin
        Sec.Init();
        Sec.FInt := 'abc';
        Result := 'assign abc: ' + Format(Sec.FInt);
        Sec.FInt := '007';
        Result += ' | 007: ' + Format(Sec.FInt);
        Ok := Evaluate(Sec.FInt, '12');
        Result += ' | eval 12: ' + Format(Ok) + ' ' + Format(Sec.FInt);
        Ok := Evaluate(Sec.FInt, 'xyz');
        Result += ' | eval xyz: ' + Format(Ok) + ' ' + Format(Sec.FInt);
        Ok := Evaluate(Sec.FVnt, 'xyz');
        Result += ' | eval vnt xyz: ' + Format(Ok) + ' ' + Format(Sec.FVnt);
        Result += ' | format len: ' + Format(StrLen(Format(Sec.FBig)));
        exit(Result);
    end;

    local procedure FieldRefValues(var Sec: Record "LT Y82 Sec"): Text
    var
        RR: RecordRef;
        FR: FieldRef;
        Result: Text;
    begin
        Sec.Init();
        Sec.Id := 1;
        Sec.FInt := '12';
        Sec.FVnt := '12';
        Sec.Insert();
        RR.GetTable(Sec);
        FR := RR.Field(3);
        Result := 'int: ' + Format(FR.Value) + ' ' + Format(FR.Length);
        FR := RR.Field(5);
        Result += ' | vnt: ' + Format(FR.Value) + ' ' + Format(FR.Length);
        FR := RR.Field(3);
        FR.Value := 'abc';
        Result += ' | after FieldRef.Value := abc: ' + Format(FR.Value);
        exit(Result);
    end;

}
