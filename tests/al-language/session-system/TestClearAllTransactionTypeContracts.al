// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-function
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-currenttransactiontype-method
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68430, codeunits 68431..68434 and 68436,
//                page 68435
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins:
//  - ClearAll() resets the global variables of the running object (codeunit with TableNo, SingleInstance
//    codeunit, table, page) and leaves the object's own record (Rec) as it is.
//  - CurrentTransactionType: members and ordinals (Format(x, 0, 2)) UpdateNoLocks 0, Update 1, Snapshot 2,
//    Browse 3, Report 4; at the start of a test the current type is UpdateNoLocks, NOT Update;
//    a set before any database access takes effect; once the transaction has written, the type reads
//    Update and a set to another type is ignored without an error.
// BC versions: 27.5

table 68430 "Probe ClearAll Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    var
        TableGlobal: Integer;

    procedure ClearInTable(): Text
    begin
        TableGlobal := 7;
        Id := 3;
        Txt := 'tbl';
        ClearAll();
        exit('global=' + Format(TableGlobal) + ' Id=' + Format(Id) + ' Txt=[' + Txt + ']');
    end;
}

codeunit 68431 "Probe ClearAll Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

codeunit 68432 "Probe ClearAll Table No"
{
    TableNo = "Probe ClearAll Table";

    var
        Glob: Integer;
        Glob2: Text;

    trigger OnRun()
    var
        ClearLog: Codeunit "Probe ClearAll Log";
    begin
        Glob := 5;
        Glob2 := 'g';
        Rec.Txt := 'before';
        ClearAll();
        ClearLog.Add('glob=' + Format(Glob) + ' glob2=[' + Glob2 + '] Rec.Id=' + Format(Rec.Id) + ' Rec.Txt=[' + Rec.Txt + ']');
    end;
}

codeunit 68433 "Probe ClearAll Single"
{
    SingleInstance = true;

    var
        Count: Integer;

    procedure Bump()
    begin
        Count += 1;
    end;

    procedure Reset()
    begin
        ClearAll();
    end;

    procedure Current(): Integer
    begin
        exit(Count);
    end;
}

page 68435 "Probe ClearAll Page"
{
    PageType = Card;
    SourceTable = "Probe ClearAll Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Txt; Rec.Txt) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ClearIt)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    ClearLog: Codeunit "Probe ClearAll Log";
                begin
                    PageGlobal := 9;
                    ClearAll();
                    ClearLog.Add('glob=' + Format(PageGlobal) + ' Rec.Id=' + Format(Rec.Id) + ' Rec.Txt=[' + Rec.Txt + ']');
                end;
            }
        }
    }

    var
        PageGlobal: Integer;
}

// Corpus issue 670 (writer CY): a plain codeunit that holds the SingleInstance codeunit above in a global and calls ClearAll().
codeunit 85540 "LT CY ClearAll Holder"
{
    var
        Single: Codeunit "Probe ClearAll Single";
        Own: Integer;

    procedure BumpSingle()
    begin
        Single.Bump();
    end;

    procedure SetOwn(Value: Integer)
    begin
        Own := Value;
    end;

    procedure ClearAllHere()
    begin
        ClearAll();
    end;

    procedure ReadSingle(): Integer
    begin
        exit(Single.Current());
    end;

    procedure ReadOwn(): Integer
    begin
        exit(Own);
    end;
}

codeunit 68436 "Probe ClearAll TxType"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        ClearLog: Codeunit "Probe ClearAll Log";

    [Test]
    procedure ClearAll_InACodeunitWithTableNo_ResetsGlobalsAndKeepsRec()
    var
        ClearRec: Record "Probe ClearAll Table";
        TableNoCodeunit: Codeunit "Probe ClearAll Table No";
    begin
        ClearRec.DeleteAll();
        ClearRec.Id := 1;
        ClearRec.Txt := 'a';
        ClearRec.Insert();
        Commit();
        ClearLog.Take();
        ClearRec.Get(1);

        TableNoCodeunit.Run(ClearRec);

        Assert.AreEqual('glob=0 glob2=[] Rec.Id=1 Rec.Txt=[before];', ClearLog.Take(), 'log');
        Assert.AreEqual('before', ClearRec.Txt, 'the caller sees the change made before ClearAll');
    end;

    [Test]
    procedure ClearAll_InASingleInstanceCodeunit_ResetsItsGlobals()
    var
        Single: Codeunit "Probe ClearAll Single";
    begin
        Single.Reset();
        Single.Bump();
        Single.Bump();
        Assert.AreEqual(2, Single.Current(), 'before');

        Single.Reset();

        Assert.AreEqual(0, Single.Current(), 'after');
    end;

    [Test]
    procedure ClearAll_InATable_ResetsGlobalsAndKeepsTheFields()
    var
        ClearRec: Record "Probe ClearAll Table";
    begin
        Assert.AreEqual('global=0 Id=3 Txt=[tbl]', ClearRec.ClearInTable(), 'table');
    end;

    [Test]
    procedure ClearAll_InAPage_ResetsGlobalsAndKeepsRec()
    var
        ClearRec: Record "Probe ClearAll Table";
        ClearPage: TestPage "Probe ClearAll Page";
    begin
        ClearRec.DeleteAll();
        ClearRec.Id := 1;
        ClearRec.Txt := 'a';
        ClearRec.Insert();
        Commit();
        ClearLog.Take();

        ClearPage.OpenView();
        ClearPage.ClearIt.Invoke();

        Assert.AreEqual('glob=0 Rec.Id=1 Rec.Txt=[a];', ClearLog.Take(), 'page');
        ClearPage.Close();
    end;

    [Test]
    procedure CurrentTransactionType_StartsAsUpdateNoLocks_WithTheDocumentedMembers()
    var
        Members: Text;
    begin
        Assert.AreEqual('UpdateNoLocks', Format(CurrentTransactionType()), 'default name');
        Assert.AreEqual('0', Format(CurrentTransactionType(), 0, 2), 'default ordinal');

        Members := Format(TransactionType::UpdateNoLocks, 0, 2) + Format(TransactionType::Update, 0, 2) + Format(TransactionType::Snapshot, 0, 2) + Format(TransactionType::Browse, 0, 2) + Format(TransactionType::Report, 0, 2);
        Assert.AreEqual('01234', Members, 'ordinals');

        CurrentTransactionType(TransactionType::Browse);
        Assert.AreEqual('Browse', Format(CurrentTransactionType()), 'a set before any database access');
        CurrentTransactionType(TransactionType::Update);
        Assert.AreEqual('Update', Format(CurrentTransactionType()), 'and another');
    end;

    [Test]
    procedure CurrentTransactionType_AfterAWrite_IsUpdate_AndASetIsIgnored()
    var
        ClearRec: Record "Probe ClearAll Table";
    begin
        Commit();
        ClearRec.DeleteAll();

        Assert.AreEqual('Update', Format(CurrentTransactionType()), 'after a write');

        CurrentTransactionType(TransactionType::Snapshot);

        Assert.AreEqual('Update', Format(CurrentTransactionType()), 'a set after a write changes nothing and raises nothing');
    end;

    // Corpus issue 670: docs say ClearAll does not change the variables of single-instance codeunits. Object A (a plain codeunit)
    // holds single-instance codeunit B in a global, B has state, A calls ClearAll(): what A's own global, A's B variable and
    // a second B variable read afterwards; and ClearAll() in the test procedure while a local B variable holds state.
    [Test]
    procedure CY_ClearAll_InOtherObject_SingleInstanceStateKept()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT CY ClearAll Holder";
        Single: Codeunit "Probe ClearAll Single";
        Second: Codeunit "Probe ClearAll Single";
    begin
        Single.Reset();
        Holder.BumpSingle();
        Holder.BumpSingle();
        Holder.SetOwn(7);
        Observer.Observe('before holder single', Format(Holder.ReadSingle()));
        Observer.Observe('before second', Format(Second.Current()));
        Holder.ClearAllHere();
        Observer.Observe('after holder own', Format(Holder.ReadOwn()));
        Observer.Observe('after holder single', Format(Holder.ReadSingle()));
        Observer.Observe('after second', Format(Second.Current()));
        Single.Bump();
        Observer.Observe('local bump', Format(Single.Current()));
        ClearAll();
        Observer.Observe('after test clearall local', Format(Single.Current()));
        Observer.Observe('after test clearall second', Format(Second.Current()));
        Single.Reset();
        Observer.Expect('before holder single', '2');
        Observer.Expect('before second', '2');
        Observer.Expect('after holder own', '0');
        Observer.Expect('after holder single', '2');
        Observer.Expect('after second', '2');
        Observer.Expect('local bump', '3');
        Observer.Expect('after test clearall local', '3');
        Observer.Expect('after test clearall second', '3');
        Observer.Verify();
    end;
}
