// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sqldatatype-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), objects in Y82Objects.al
// Probe (runner issues 6796 and 6797): Code primary key with SQLDataType Varchar, Integer, BigInteger, Variant and none: order, filters, rename, metadata, typed record.
// BC versions: 27.5, 28.5, 29.0
codeunit 94310 "LT Y82 Pk Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        H: Codeunit "LT Y82 Helper";

    [Test]
    procedure PkVar_NumericOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94300, 1, '10,9,2,1,100,20'));
        Observer.Observe('asc', H.Dump(94300, 1, 1, true));
        Observer.Observe('desc', H.Dump(94300, 1, 1, false));
        Observer.Observe('count', H.CountFilter(94300, 1, ''));
        Observer.Observe('find 9', H.FindKey(94300, '9'));
        Observer.Observe('find 100', H.FindKey(94300, '100'));
        Observer.Observe('find 3', H.FindKey(94300, '3'));
        Observer.Observe('range 2..10', H.DumpRange(94300, 1, 1, 1, '2', '10'));
        Observer.Observe('filter <10', H.DumpFilter(94300, 1, 1, 1, '<10'));
        Observer.Observe('filter >=9', H.DumpFilter(94300, 1, 1, 1, '>=9'));
        Observer.Observe('filter 1|9|100', H.DumpFilter(94300, 1, 1, 1, '1|9|100'));
        Observer.Observe('filter 2..10', H.DumpFilter(94300, 1, 1, 1, '2..10'));
        Observer.Observe('filter 1..', H.DumpFilter(94300, 1, 1, 1, '1..'));
        Observer.Observe('filter ..9', H.DumpFilter(94300, 1, 1, 1, '..9'));
        Observer.Observe('filter <>10', H.DumpFilter(94300, 1, 1, 1, '<>10'));
        Observer.Observe('filter 1*', H.DumpFilter(94300, 1, 1, 1, '1*'));
        Observer.Finish();
    end;

    [Test]
    procedure PkVar_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94300, 1, ',1,2'));
        Observer.Observe('asc', H.Dump(94300, 1, 1, true));
        Observer.Observe('desc', H.Dump(94300, 1, 1, false));
        Observer.Observe('find blank', H.FindKey(94300, ''));
        Observer.Observe('filter =''''', H.DumpFilter(94300, 1, 1, 1, ''''''));
        Observer.Observe('filter <>''''', H.DumpFilter(94300, 1, 1, 1, '<>'''''));
        Observer.Finish();
    end;

    [Test]
    procedure PkVar_LeadingZeros()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94300, 1, '007,7,07'));
        Observer.Observe('asc', H.Dump(94300, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkVar_Mixed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94300, 1, 'A,B,1A,A1,10,9,a,'));
        Observer.Observe('asc', H.Dump(94300, 1, 1, true));
        Observer.Observe('desc', H.Dump(94300, 1, 1, false));
        Observer.Finish();
    end;

    [Test]
    procedure PkVar_Lowercase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94300, 1, 'abc,Abd'));
        Observer.Observe('asc', H.Dump(94300, 1, 1, true));
        Observer.Observe('find abc', H.FindKey(94300, 'abc'));
        Observer.Observe('filter abc', H.DumpFilter(94300, 1, 1, 1, 'abc'));
        Observer.Observe('range a..b', H.DumpRange(94300, 1, 1, 1, 'a', 'b'));
        Observer.Finish();
    end;

    [Test]
    procedure PkVar_FilterLetters_Range()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94300, 1, '1,2,10'));
        Observer.Observe('range A..B', H.DumpRange(94300, 1, 1, 1, 'A', 'B'));
        Observer.Finish();
    end;

    [Test]
    procedure PkVar_FilterLetters_Text()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94300, 1, '1,2,10'));
        Observer.Observe('filter A..B', H.DumpFilter(94300, 1, 1, 1, 'A..B'));
        Observer.Finish();
    end;

    [Test]
    procedure PkVar_FilterLetters_Mixed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94300, 1, '1,2,10'));
        Observer.Observe('filter 1A', H.DumpFilter(94300, 1, 1, 1, '1A'));
        Observer.Finish();
    end;

    [Test]
    procedure PkVar_FilterLetters_Count()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94300, 1, '1,2,10'));
        Observer.Observe('count filter A*', H.CountFilter(94300, 1, 'A*'));
        Observer.Finish();
    end;

    [Test]
    procedure PkVar_Rename()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94300, 1, '10,9'));
        Observer.Observe('rename 9 to 11', H.RenameKey(94300, '9', '11'));
        Observer.Observe('asc', H.Dump(94300, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkVar_Rename_ToAbc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94300, 1, '10,9'));
        Observer.Observe('rename 9 to ABC', H.RenameKey(94300, '9', 'ABC'));
        Observer.Observe('asc', H.Dump(94300, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkVar_Meta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('field', H.FieldInfo(94300, 1));
        Observer.Observe('keys', H.KeyInfo(94300));
        Observer.Finish();
    end;

    [Test]
    procedure PkVar_Typed()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT Y82 PkVar";
    begin
        H.Wipe();
        Observer.Observe('seed', TypedSeed(Rec));
        Observer.Observe('asc', TypedDump(Rec, true));
        Observer.Observe('desc', TypedDump(Rec, false));
        Observer.Observe('get 9', TypedGet(Rec, '9'));
        Observer.Observe('get 3', TypedGet(Rec, '3'));
        Observer.Observe('range 2..10', TypedRange(Rec, '2', '10'));
        Observer.Observe('filter >9', TypedFilter(Rec, '>%1', '9'));
        Observer.Observe('firstlast', TypedFirstLast(Rec));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_NumericOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94301, 1, '10,9,2,1,100,20'));
        Observer.Observe('asc', H.Dump(94301, 1, 1, true));
        Observer.Observe('desc', H.Dump(94301, 1, 1, false));
        Observer.Observe('count', H.CountFilter(94301, 1, ''));
        Observer.Observe('find 9', H.FindKey(94301, '9'));
        Observer.Observe('find 100', H.FindKey(94301, '100'));
        Observer.Observe('find 3', H.FindKey(94301, '3'));
        Observer.Observe('range 2..10', H.DumpRange(94301, 1, 1, 1, '2', '10'));
        Observer.Observe('filter <10', H.DumpFilter(94301, 1, 1, 1, '<10'));
        Observer.Observe('filter >=9', H.DumpFilter(94301, 1, 1, 1, '>=9'));
        Observer.Observe('filter 1|9|100', H.DumpFilter(94301, 1, 1, 1, '1|9|100'));
        Observer.Observe('filter 2..10', H.DumpFilter(94301, 1, 1, 1, '2..10'));
        Observer.Observe('filter 1..', H.DumpFilter(94301, 1, 1, 1, '1..'));
        Observer.Observe('filter ..9', H.DumpFilter(94301, 1, 1, 1, '..9'));
        Observer.Observe('filter <>10', H.DumpFilter(94301, 1, 1, 1, '<>10'));
        Observer.Observe('filter 1*', H.DumpFilter(94301, 1, 1, 1, '1*'));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94301, 1, ',1,2'));
        Observer.Observe('asc', H.Dump(94301, 1, 1, true));
        Observer.Observe('desc', H.Dump(94301, 1, 1, false));
        Observer.Observe('find blank', H.FindKey(94301, ''));
        Observer.Observe('filter =''''', H.DumpFilter(94301, 1, 1, 1, ''''''));
        Observer.Observe('filter <>''''', H.DumpFilter(94301, 1, 1, 1, '<>'''''));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_LeadingZeros()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94301, 1, '007,7,07'));
        Observer.Observe('asc', H.Dump(94301, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_Mixed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94301, 1, 'A,B,1A,A1,10,9,a,'));
        Observer.Observe('asc', H.Dump(94301, 1, 1, true));
        Observer.Observe('desc', H.Dump(94301, 1, 1, false));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_Lowercase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94301, 1, 'abc,Abd'));
        Observer.Observe('asc', H.Dump(94301, 1, 1, true));
        Observer.Observe('find abc', H.FindKey(94301, 'abc'));
        Observer.Observe('filter abc', H.DumpFilter(94301, 1, 1, 1, 'abc'));
        Observer.Observe('range a..b', H.DumpRange(94301, 1, 1, 1, 'a', 'b'));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_FilterLetters_Range()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94301, 1, '1,2,10'));
        Observer.Observe('range A..B', H.DumpRange(94301, 1, 1, 1, 'A', 'B'));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_FilterLetters_Text()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94301, 1, '1,2,10'));
        Observer.Observe('filter A..B', H.DumpFilter(94301, 1, 1, 1, 'A..B'));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_FilterLetters_Mixed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94301, 1, '1,2,10'));
        Observer.Observe('filter 1A', H.DumpFilter(94301, 1, 1, 1, '1A'));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_FilterLetters_Count()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94301, 1, '1,2,10'));
        Observer.Observe('count filter A*', H.CountFilter(94301, 1, 'A*'));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_Rename()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94301, 1, '10,9'));
        Observer.Observe('rename 9 to 11', H.RenameKey(94301, '9', '11'));
        Observer.Observe('asc', H.Dump(94301, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_Rename_ToAbc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94301, 1, '10,9'));
        Observer.Observe('rename 9 to ABC', H.RenameKey(94301, '9', 'ABC'));
        Observer.Observe('asc', H.Dump(94301, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_Meta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('field', H.FieldInfo(94301, 1));
        Observer.Observe('keys', H.KeyInfo(94301));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_Typed()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT Y82 PkInt";
    begin
        H.Wipe();
        Observer.Observe('seed', TypedSeed(Rec));
        Observer.Observe('asc', TypedDump(Rec, true));
        Observer.Observe('desc', TypedDump(Rec, false));
        Observer.Observe('get 9', TypedGet(Rec, '9'));
        Observer.Observe('get 3', TypedGet(Rec, '3'));
        Observer.Observe('range 2..10', TypedRange(Rec, '2', '10'));
        Observer.Observe('filter >9', TypedFilter(Rec, '>%1', '9'));
        Observer.Observe('firstlast', TypedFirstLast(Rec));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_NumericOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94302, 1, '10,9,2,1,100,20'));
        Observer.Observe('asc', H.Dump(94302, 1, 1, true));
        Observer.Observe('desc', H.Dump(94302, 1, 1, false));
        Observer.Observe('count', H.CountFilter(94302, 1, ''));
        Observer.Observe('find 9', H.FindKey(94302, '9'));
        Observer.Observe('find 100', H.FindKey(94302, '100'));
        Observer.Observe('find 3', H.FindKey(94302, '3'));
        Observer.Observe('range 2..10', H.DumpRange(94302, 1, 1, 1, '2', '10'));
        Observer.Observe('filter <10', H.DumpFilter(94302, 1, 1, 1, '<10'));
        Observer.Observe('filter >=9', H.DumpFilter(94302, 1, 1, 1, '>=9'));
        Observer.Observe('filter 1|9|100', H.DumpFilter(94302, 1, 1, 1, '1|9|100'));
        Observer.Observe('filter 2..10', H.DumpFilter(94302, 1, 1, 1, '2..10'));
        Observer.Observe('filter 1..', H.DumpFilter(94302, 1, 1, 1, '1..'));
        Observer.Observe('filter ..9', H.DumpFilter(94302, 1, 1, 1, '..9'));
        Observer.Observe('filter <>10', H.DumpFilter(94302, 1, 1, 1, '<>10'));
        Observer.Observe('filter 1*', H.DumpFilter(94302, 1, 1, 1, '1*'));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94302, 1, ',1,2'));
        Observer.Observe('asc', H.Dump(94302, 1, 1, true));
        Observer.Observe('desc', H.Dump(94302, 1, 1, false));
        Observer.Observe('find blank', H.FindKey(94302, ''));
        Observer.Observe('filter =''''', H.DumpFilter(94302, 1, 1, 1, ''''''));
        Observer.Observe('filter <>''''', H.DumpFilter(94302, 1, 1, 1, '<>'''''));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_LeadingZeros()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94302, 1, '007,7,07'));
        Observer.Observe('asc', H.Dump(94302, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_Mixed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94302, 1, 'A,B,1A,A1,10,9,a,'));
        Observer.Observe('asc', H.Dump(94302, 1, 1, true));
        Observer.Observe('desc', H.Dump(94302, 1, 1, false));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_Lowercase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94302, 1, 'abc,Abd'));
        Observer.Observe('asc', H.Dump(94302, 1, 1, true));
        Observer.Observe('find abc', H.FindKey(94302, 'abc'));
        Observer.Observe('filter abc', H.DumpFilter(94302, 1, 1, 1, 'abc'));
        Observer.Observe('range a..b', H.DumpRange(94302, 1, 1, 1, 'a', 'b'));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_FilterLetters_Range()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94302, 1, '1,2,10'));
        Observer.Observe('range A..B', H.DumpRange(94302, 1, 1, 1, 'A', 'B'));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_FilterLetters_Text()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94302, 1, '1,2,10'));
        Observer.Observe('filter A..B', H.DumpFilter(94302, 1, 1, 1, 'A..B'));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_FilterLetters_Mixed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94302, 1, '1,2,10'));
        Observer.Observe('filter 1A', H.DumpFilter(94302, 1, 1, 1, '1A'));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_FilterLetters_Count()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94302, 1, '1,2,10'));
        Observer.Observe('count filter A*', H.CountFilter(94302, 1, 'A*'));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_Rename()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94302, 1, '10,9'));
        Observer.Observe('rename 9 to 11', H.RenameKey(94302, '9', '11'));
        Observer.Observe('asc', H.Dump(94302, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_Rename_ToAbc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94302, 1, '10,9'));
        Observer.Observe('rename 9 to ABC', H.RenameKey(94302, '9', 'ABC'));
        Observer.Observe('asc', H.Dump(94302, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_Meta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('field', H.FieldInfo(94302, 1));
        Observer.Observe('keys', H.KeyInfo(94302));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_Typed()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT Y82 PkBig";
    begin
        H.Wipe();
        Observer.Observe('seed', TypedSeed(Rec));
        Observer.Observe('asc', TypedDump(Rec, true));
        Observer.Observe('desc', TypedDump(Rec, false));
        Observer.Observe('get 9', TypedGet(Rec, '9'));
        Observer.Observe('get 3', TypedGet(Rec, '3'));
        Observer.Observe('range 2..10', TypedRange(Rec, '2', '10'));
        Observer.Observe('filter >9', TypedFilter(Rec, '>%1', '9'));
        Observer.Observe('firstlast', TypedFirstLast(Rec));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_NumericOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94303, 1, '10,9,2,1,100,20'));
        Observer.Observe('asc', H.Dump(94303, 1, 1, true));
        Observer.Observe('desc', H.Dump(94303, 1, 1, false));
        Observer.Observe('count', H.CountFilter(94303, 1, ''));
        Observer.Observe('find 9', H.FindKey(94303, '9'));
        Observer.Observe('find 100', H.FindKey(94303, '100'));
        Observer.Observe('find 3', H.FindKey(94303, '3'));
        Observer.Observe('range 2..10', H.DumpRange(94303, 1, 1, 1, '2', '10'));
        Observer.Observe('filter <10', H.DumpFilter(94303, 1, 1, 1, '<10'));
        Observer.Observe('filter >=9', H.DumpFilter(94303, 1, 1, 1, '>=9'));
        Observer.Observe('filter 1|9|100', H.DumpFilter(94303, 1, 1, 1, '1|9|100'));
        Observer.Observe('filter 2..10', H.DumpFilter(94303, 1, 1, 1, '2..10'));
        Observer.Observe('filter 1..', H.DumpFilter(94303, 1, 1, 1, '1..'));
        Observer.Observe('filter ..9', H.DumpFilter(94303, 1, 1, 1, '..9'));
        Observer.Observe('filter <>10', H.DumpFilter(94303, 1, 1, 1, '<>10'));
        Observer.Observe('filter 1*', H.DumpFilter(94303, 1, 1, 1, '1*'));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94303, 1, ',1,2'));
        Observer.Observe('asc', H.Dump(94303, 1, 1, true));
        Observer.Observe('desc', H.Dump(94303, 1, 1, false));
        Observer.Observe('find blank', H.FindKey(94303, ''));
        Observer.Observe('filter =''''', H.DumpFilter(94303, 1, 1, 1, ''''''));
        Observer.Observe('filter <>''''', H.DumpFilter(94303, 1, 1, 1, '<>'''''));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_LeadingZeros()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94303, 1, '007,7,07'));
        Observer.Observe('asc', H.Dump(94303, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_Mixed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94303, 1, 'A,B,1A,A1,10,9,a,'));
        Observer.Observe('asc', H.Dump(94303, 1, 1, true));
        Observer.Observe('desc', H.Dump(94303, 1, 1, false));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_Lowercase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94303, 1, 'abc,Abd'));
        Observer.Observe('asc', H.Dump(94303, 1, 1, true));
        Observer.Observe('find abc', H.FindKey(94303, 'abc'));
        Observer.Observe('filter abc', H.DumpFilter(94303, 1, 1, 1, 'abc'));
        Observer.Observe('range a..b', H.DumpRange(94303, 1, 1, 1, 'a', 'b'));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_FilterLetters_Range()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94303, 1, '1,2,10'));
        Observer.Observe('range A..B', H.DumpRange(94303, 1, 1, 1, 'A', 'B'));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_FilterLetters_Text()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94303, 1, '1,2,10'));
        Observer.Observe('filter A..B', H.DumpFilter(94303, 1, 1, 1, 'A..B'));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_FilterLetters_Mixed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94303, 1, '1,2,10'));
        Observer.Observe('filter 1A', H.DumpFilter(94303, 1, 1, 1, '1A'));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_FilterLetters_Count()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94303, 1, '1,2,10'));
        Observer.Observe('count filter A*', H.CountFilter(94303, 1, 'A*'));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_Rename()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94303, 1, '10,9'));
        Observer.Observe('rename 9 to 11', H.RenameKey(94303, '9', '11'));
        Observer.Observe('asc', H.Dump(94303, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_Rename_ToAbc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94303, 1, '10,9'));
        Observer.Observe('rename 9 to ABC', H.RenameKey(94303, '9', 'ABC'));
        Observer.Observe('asc', H.Dump(94303, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_Meta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('field', H.FieldInfo(94303, 1));
        Observer.Observe('keys', H.KeyInfo(94303));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_Typed()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT Y82 PkVnt";
    begin
        H.Wipe();
        Observer.Observe('seed', TypedSeed(Rec));
        Observer.Observe('asc', TypedDump(Rec, true));
        Observer.Observe('desc', TypedDump(Rec, false));
        Observer.Observe('get 9', TypedGet(Rec, '9'));
        Observer.Observe('get 3', TypedGet(Rec, '3'));
        Observer.Observe('range 2..10', TypedRange(Rec, '2', '10'));
        Observer.Observe('filter >9', TypedFilter(Rec, '>%1', '9'));
        Observer.Observe('firstlast', TypedFirstLast(Rec));
        Observer.Finish();
    end;

    [Test]
    procedure PkDef_NumericOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94304, 1, '10,9,2,1,100,20'));
        Observer.Observe('asc', H.Dump(94304, 1, 1, true));
        Observer.Observe('desc', H.Dump(94304, 1, 1, false));
        Observer.Observe('count', H.CountFilter(94304, 1, ''));
        Observer.Observe('find 9', H.FindKey(94304, '9'));
        Observer.Observe('find 100', H.FindKey(94304, '100'));
        Observer.Observe('find 3', H.FindKey(94304, '3'));
        Observer.Observe('range 2..10', H.DumpRange(94304, 1, 1, 1, '2', '10'));
        Observer.Observe('filter <10', H.DumpFilter(94304, 1, 1, 1, '<10'));
        Observer.Observe('filter >=9', H.DumpFilter(94304, 1, 1, 1, '>=9'));
        Observer.Observe('filter 1|9|100', H.DumpFilter(94304, 1, 1, 1, '1|9|100'));
        Observer.Observe('filter 2..10', H.DumpFilter(94304, 1, 1, 1, '2..10'));
        Observer.Observe('filter 1..', H.DumpFilter(94304, 1, 1, 1, '1..'));
        Observer.Observe('filter ..9', H.DumpFilter(94304, 1, 1, 1, '..9'));
        Observer.Observe('filter <>10', H.DumpFilter(94304, 1, 1, 1, '<>10'));
        Observer.Observe('filter 1*', H.DumpFilter(94304, 1, 1, 1, '1*'));
        Observer.Finish();
    end;

    [Test]
    procedure PkDef_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94304, 1, ',1,2'));
        Observer.Observe('asc', H.Dump(94304, 1, 1, true));
        Observer.Observe('desc', H.Dump(94304, 1, 1, false));
        Observer.Observe('find blank', H.FindKey(94304, ''));
        Observer.Observe('filter =''''', H.DumpFilter(94304, 1, 1, 1, ''''''));
        Observer.Observe('filter <>''''', H.DumpFilter(94304, 1, 1, 1, '<>'''''));
        Observer.Finish();
    end;

    [Test]
    procedure PkDef_LeadingZeros()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94304, 1, '007,7,07'));
        Observer.Observe('asc', H.Dump(94304, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkDef_Mixed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94304, 1, 'A,B,1A,A1,10,9,a,'));
        Observer.Observe('asc', H.Dump(94304, 1, 1, true));
        Observer.Observe('desc', H.Dump(94304, 1, 1, false));
        Observer.Finish();
    end;

    [Test]
    procedure PkDef_Lowercase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94304, 1, 'abc,Abd'));
        Observer.Observe('asc', H.Dump(94304, 1, 1, true));
        Observer.Observe('find abc', H.FindKey(94304, 'abc'));
        Observer.Observe('filter abc', H.DumpFilter(94304, 1, 1, 1, 'abc'));
        Observer.Observe('range a..b', H.DumpRange(94304, 1, 1, 1, 'a', 'b'));
        Observer.Finish();
    end;

    [Test]
    procedure PkDef_FilterLetters_Range()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94304, 1, '1,2,10'));
        Observer.Observe('range A..B', H.DumpRange(94304, 1, 1, 1, 'A', 'B'));
        Observer.Finish();
    end;

    [Test]
    procedure PkDef_FilterLetters_Text()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94304, 1, '1,2,10'));
        Observer.Observe('filter A..B', H.DumpFilter(94304, 1, 1, 1, 'A..B'));
        Observer.Finish();
    end;

    [Test]
    procedure PkDef_FilterLetters_Mixed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94304, 1, '1,2,10'));
        Observer.Observe('filter 1A', H.DumpFilter(94304, 1, 1, 1, '1A'));
        Observer.Finish();
    end;

    [Test]
    procedure PkDef_FilterLetters_Count()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94304, 1, '1,2,10'));
        Observer.Observe('count filter A*', H.CountFilter(94304, 1, 'A*'));
        Observer.Finish();
    end;

    [Test]
    procedure PkDef_Rename()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94304, 1, '10,9'));
        Observer.Observe('rename 9 to 11', H.RenameKey(94304, '9', '11'));
        Observer.Observe('asc', H.Dump(94304, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkDef_Rename_ToAbc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('seed', H.Seed(94304, 1, '10,9'));
        Observer.Observe('rename 9 to ABC', H.RenameKey(94304, '9', 'ABC'));
        Observer.Observe('asc', H.Dump(94304, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkDef_Meta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('field', H.FieldInfo(94304, 1));
        Observer.Observe('keys', H.KeyInfo(94304));
        Observer.Finish();
    end;

    [Test]
    procedure PkDef_Typed()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT Y82 PkDef";
    begin
        H.Wipe();
        Observer.Observe('seed', TypedSeed(Rec));
        Observer.Observe('asc', TypedDump(Rec, true));
        Observer.Observe('desc', TypedDump(Rec, false));
        Observer.Observe('get 9', TypedGet(Rec, '9'));
        Observer.Observe('get 3', TypedGet(Rec, '3'));
        Observer.Observe('range 2..10', TypedRange(Rec, '2', '10'));
        Observer.Observe('filter >9', TypedFilter(Rec, '>%1', '9'));
        Observer.Observe('firstlast', TypedFirstLast(Rec));
        Observer.Finish();
    end;


    local procedure TypedSeed(var Rec: Record "LT Y82 PkVar"): Text
    var
        Values: List of [Text];
        Value: Text;
        Results: Text;
        Sep: Text;
    begin
        Values := '10,9,2,1,100,20'.Split(',');
        foreach Value in Values do begin
            Rec.Init();
            Rec.K := CopyStr(Value, 1, 10);
            Rec.Insert();
            Results += Sep + 'ok';
            Sep := ' | ';
        end;
        exit(Results);
    end;

    local procedure TypedDump(var Rec: Record "LT Y82 PkVar"; Ascending: Boolean): Text
    var
        Result: Text;
        Sep: Text;
    begin
        Rec.Reset();
        Rec.SetCurrentKey(K);
        Rec.SetAscending(K, Ascending);
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.K);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Result);
    end;

    local procedure TypedGet(var Rec: Record "LT Y82 PkVar"; Value: Text): Text
    begin
        Rec.Reset();
        if Rec.Get(Value) then
            exit('found ' + Format(Rec.K));
        exit('not found');
    end;

    local procedure TypedRange(var Rec: Record "LT Y82 PkVar"; FromValue: Text; ToValue: Text): Text
    var
        Result: Text;
        Sep: Text;
    begin
        Rec.Reset();
        Rec.SetRange(K, CopyStr(FromValue, 1, 10), CopyStr(ToValue, 1, 10));
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.K);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Format(Rec.Count()) + ': ' + Result);
    end;

    local procedure TypedFilter(var Rec: Record "LT Y82 PkVar"; Expression: Text; Value: Text): Text
    var
        Result: Text;
        Sep: Text;
    begin
        Rec.Reset();
        Rec.SetFilter(K, Expression, CopyStr(Value, 1, 10));
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.K);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Format(Rec.Count()) + ': ' + Result + ' | filter=' + Rec.GetFilter(K));
    end;

    local procedure TypedFirstLast(var Rec: Record "LT Y82 PkVar"): Text
    var
        First: Text;
        Last: Text;
    begin
        Rec.Reset();
        Rec.FindFirst();
        First := Rec.K;
        Rec.FindLast();
        Last := Rec.K;
        exit(First + ' .. ' + Last);
    end;


    local procedure TypedSeed(var Rec: Record "LT Y82 PkInt"): Text
    var
        Values: List of [Text];
        Value: Text;
        Results: Text;
        Sep: Text;
    begin
        Values := '10,9,2,1,100,20'.Split(',');
        foreach Value in Values do begin
            Rec.Init();
            Rec.K := CopyStr(Value, 1, 10);
            Rec.Insert();
            Results += Sep + 'ok';
            Sep := ' | ';
        end;
        exit(Results);
    end;

    local procedure TypedDump(var Rec: Record "LT Y82 PkInt"; Ascending: Boolean): Text
    var
        Result: Text;
        Sep: Text;
    begin
        Rec.Reset();
        Rec.SetCurrentKey(K);
        Rec.SetAscending(K, Ascending);
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.K);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Result);
    end;

    local procedure TypedGet(var Rec: Record "LT Y82 PkInt"; Value: Text): Text
    begin
        Rec.Reset();
        if Rec.Get(Value) then
            exit('found ' + Format(Rec.K));
        exit('not found');
    end;

    local procedure TypedRange(var Rec: Record "LT Y82 PkInt"; FromValue: Text; ToValue: Text): Text
    var
        Result: Text;
        Sep: Text;
    begin
        Rec.Reset();
        Rec.SetRange(K, CopyStr(FromValue, 1, 10), CopyStr(ToValue, 1, 10));
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.K);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Format(Rec.Count()) + ': ' + Result);
    end;

    local procedure TypedFilter(var Rec: Record "LT Y82 PkInt"; Expression: Text; Value: Text): Text
    var
        Result: Text;
        Sep: Text;
    begin
        Rec.Reset();
        Rec.SetFilter(K, Expression, CopyStr(Value, 1, 10));
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.K);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Format(Rec.Count()) + ': ' + Result + ' | filter=' + Rec.GetFilter(K));
    end;

    local procedure TypedFirstLast(var Rec: Record "LT Y82 PkInt"): Text
    var
        First: Text;
        Last: Text;
    begin
        Rec.Reset();
        Rec.FindFirst();
        First := Rec.K;
        Rec.FindLast();
        Last := Rec.K;
        exit(First + ' .. ' + Last);
    end;


    local procedure TypedSeed(var Rec: Record "LT Y82 PkBig"): Text
    var
        Values: List of [Text];
        Value: Text;
        Results: Text;
        Sep: Text;
    begin
        Values := '10,9,2,1,100,20'.Split(',');
        foreach Value in Values do begin
            Rec.Init();
            Rec.K := CopyStr(Value, 1, 10);
            Rec.Insert();
            Results += Sep + 'ok';
            Sep := ' | ';
        end;
        exit(Results);
    end;

    local procedure TypedDump(var Rec: Record "LT Y82 PkBig"; Ascending: Boolean): Text
    var
        Result: Text;
        Sep: Text;
    begin
        Rec.Reset();
        Rec.SetCurrentKey(K);
        Rec.SetAscending(K, Ascending);
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.K);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Result);
    end;

    local procedure TypedGet(var Rec: Record "LT Y82 PkBig"; Value: Text): Text
    begin
        Rec.Reset();
        if Rec.Get(Value) then
            exit('found ' + Format(Rec.K));
        exit('not found');
    end;

    local procedure TypedRange(var Rec: Record "LT Y82 PkBig"; FromValue: Text; ToValue: Text): Text
    var
        Result: Text;
        Sep: Text;
    begin
        Rec.Reset();
        Rec.SetRange(K, CopyStr(FromValue, 1, 10), CopyStr(ToValue, 1, 10));
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.K);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Format(Rec.Count()) + ': ' + Result);
    end;

    local procedure TypedFilter(var Rec: Record "LT Y82 PkBig"; Expression: Text; Value: Text): Text
    var
        Result: Text;
        Sep: Text;
    begin
        Rec.Reset();
        Rec.SetFilter(K, Expression, CopyStr(Value, 1, 10));
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.K);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Format(Rec.Count()) + ': ' + Result + ' | filter=' + Rec.GetFilter(K));
    end;

    local procedure TypedFirstLast(var Rec: Record "LT Y82 PkBig"): Text
    var
        First: Text;
        Last: Text;
    begin
        Rec.Reset();
        Rec.FindFirst();
        First := Rec.K;
        Rec.FindLast();
        Last := Rec.K;
        exit(First + ' .. ' + Last);
    end;


    local procedure TypedSeed(var Rec: Record "LT Y82 PkVnt"): Text
    var
        Values: List of [Text];
        Value: Text;
        Results: Text;
        Sep: Text;
    begin
        Values := '10,9,2,1,100,20'.Split(',');
        foreach Value in Values do begin
            Rec.Init();
            Rec.K := CopyStr(Value, 1, 10);
            Rec.Insert();
            Results += Sep + 'ok';
            Sep := ' | ';
        end;
        exit(Results);
    end;

    local procedure TypedDump(var Rec: Record "LT Y82 PkVnt"; Ascending: Boolean): Text
    var
        Result: Text;
        Sep: Text;
    begin
        Rec.Reset();
        Rec.SetCurrentKey(K);
        Rec.SetAscending(K, Ascending);
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.K);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Result);
    end;

    local procedure TypedGet(var Rec: Record "LT Y82 PkVnt"; Value: Text): Text
    begin
        Rec.Reset();
        if Rec.Get(Value) then
            exit('found ' + Format(Rec.K));
        exit('not found');
    end;

    local procedure TypedRange(var Rec: Record "LT Y82 PkVnt"; FromValue: Text; ToValue: Text): Text
    var
        Result: Text;
        Sep: Text;
    begin
        Rec.Reset();
        Rec.SetRange(K, CopyStr(FromValue, 1, 10), CopyStr(ToValue, 1, 10));
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.K);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Format(Rec.Count()) + ': ' + Result);
    end;

    local procedure TypedFilter(var Rec: Record "LT Y82 PkVnt"; Expression: Text; Value: Text): Text
    var
        Result: Text;
        Sep: Text;
    begin
        Rec.Reset();
        Rec.SetFilter(K, Expression, CopyStr(Value, 1, 10));
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.K);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Format(Rec.Count()) + ': ' + Result + ' | filter=' + Rec.GetFilter(K));
    end;

    local procedure TypedFirstLast(var Rec: Record "LT Y82 PkVnt"): Text
    var
        First: Text;
        Last: Text;
    begin
        Rec.Reset();
        Rec.FindFirst();
        First := Rec.K;
        Rec.FindLast();
        Last := Rec.K;
        exit(First + ' .. ' + Last);
    end;


    local procedure TypedSeed(var Rec: Record "LT Y82 PkDef"): Text
    var
        Values: List of [Text];
        Value: Text;
        Results: Text;
        Sep: Text;
    begin
        Values := '10,9,2,1,100,20'.Split(',');
        foreach Value in Values do begin
            Rec.Init();
            Rec.K := CopyStr(Value, 1, 10);
            Rec.Insert();
            Results += Sep + 'ok';
            Sep := ' | ';
        end;
        exit(Results);
    end;

    local procedure TypedDump(var Rec: Record "LT Y82 PkDef"; Ascending: Boolean): Text
    var
        Result: Text;
        Sep: Text;
    begin
        Rec.Reset();
        Rec.SetCurrentKey(K);
        Rec.SetAscending(K, Ascending);
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.K);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Result);
    end;

    local procedure TypedGet(var Rec: Record "LT Y82 PkDef"; Value: Text): Text
    begin
        Rec.Reset();
        if Rec.Get(Value) then
            exit('found ' + Format(Rec.K));
        exit('not found');
    end;

    local procedure TypedRange(var Rec: Record "LT Y82 PkDef"; FromValue: Text; ToValue: Text): Text
    var
        Result: Text;
        Sep: Text;
    begin
        Rec.Reset();
        Rec.SetRange(K, CopyStr(FromValue, 1, 10), CopyStr(ToValue, 1, 10));
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.K);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Format(Rec.Count()) + ': ' + Result);
    end;

    local procedure TypedFilter(var Rec: Record "LT Y82 PkDef"; Expression: Text; Value: Text): Text
    var
        Result: Text;
        Sep: Text;
    begin
        Rec.Reset();
        Rec.SetFilter(K, Expression, CopyStr(Value, 1, 10));
        if Rec.FindSet() then
            repeat
                Result += Sep + Format(Rec.K);
                Sep := ',';
            until Rec.Next() = 0;
        exit(Format(Rec.Count()) + ': ' + Result + ' | filter=' + Rec.GetFilter(K));
    end;

    local procedure TypedFirstLast(var Rec: Record "LT Y82 PkDef"): Text
    var
        First: Text;
        Last: Text;
    begin
        Rec.Reset();
        Rec.FindFirst();
        First := Rec.K;
        Rec.FindLast();
        Last := Rec.K;
        exit(First + ' .. ' + Last);
    end;

}
