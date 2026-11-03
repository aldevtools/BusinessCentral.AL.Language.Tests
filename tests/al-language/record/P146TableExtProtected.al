// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 74990, tableextension 74991
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a tableextension procedure and triggers reading and writing a `protected var` of its base table: is the global per record variable, what Copy, TransferFields, Clear, Init, Reset, a by-value parameter and a temporary record do with it, base and extension trigger order
// BC versions: 29 (27 and 28 by CI)

table 74990 "LT P146 Base"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    protected var
        Marker: Text;
        Counter: Integer;

    procedure BaseMarker(): Text
    begin
        exit(Marker);
    end;

    procedure BaseCounter(): Integer
    begin
        exit(Counter);
    end;

    procedure BaseSet(NewMarker: Text; NewCounter: Integer)
    begin
        Marker := NewMarker;
        Counter := NewCounter;
    end;

    trigger OnInsert()
    begin
        Marker += '|base-insert';
        Counter += 1;
    end;

    trigger OnModify()
    begin
        Marker += '|base-modify';
        Counter += 10;
    end;
}

tableextension 74991 "LT P146 Base Ext" extends "LT P146 Base"
{
    fields
    {
        field(74991; ExtNote; Text[30]) { }
    }

    procedure ExtMarker(): Text
    begin
        exit(Marker);
    end;

    procedure ExtCounter(): Integer
    begin
        exit(Counter);
    end;

    procedure ExtSet(NewMarker: Text; NewCounter: Integer)
    begin
        Marker := NewMarker;
        Counter := NewCounter;
    end;

    procedure ExtAppend(Suffix: Text)
    begin
        Marker := Marker + Suffix;
        Counter += 1000;
    end;

    trigger OnInsert()
    begin
        Marker += '|ext-insert';
        Counter += 100;
    end;

    trigger OnModify()
    begin
        Marker += '|ext-modify';
        Counter += 2000;
    end;
}

codeunit 74992 "LT P146 TableExt Protected"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ByValue(R: Record "LT P146 Base"): Text
    begin
        exit(R.ExtMarker() + '#' + Format(R.ExtCounter()));
    end;

    local procedure ByVar(var R: Record "LT P146 Base")
    begin
        R.ExtAppend('|byvar');
    end;

    [Test]
    procedure P146_ReadWrite_ExtensionProcedure()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT P146 Base";
        R2: Record "LT P146 Base";
    begin
        R1.DeleteAll();
        Observer.Observe('initial ext marker', R1.ExtMarker());
        Observer.Observe('initial ext counter', Format(R1.ExtCounter()));
        R1.ExtSet('one', 1);
        Observer.Observe('r1 ext marker', R1.ExtMarker());
        Observer.Observe('r1 ext counter', Format(R1.ExtCounter()));
        Observer.Observe('r1 base marker', R1.BaseMarker());
        Observer.Observe('r1 base counter', Format(R1.BaseCounter()));
        Observer.Observe('r2 ext marker', R2.ExtMarker());
        Observer.Observe('r2 ext counter', Format(R2.ExtCounter()));
        R2.ExtSet('two', 2);
        Observer.Observe('r2 after set ext marker', R2.ExtMarker());
        Observer.Observe('r1 after r2 set ext marker', R1.ExtMarker());
        R1.BaseSet('base-one', 11);
        Observer.Observe('r1 after base set ext marker', R1.ExtMarker());
        Observer.Observe('r1 after base set ext counter', Format(R1.ExtCounter()));
        Observer.Observe('r2 after r1 base set', R2.ExtMarker());
        R1.ExtAppend('+x');
        Observer.Observe('r1 after append', R1.BaseMarker());
        Observer.Observe('r1 after append counter', Format(R1.BaseCounter()));
        Observer.Expect('initial ext marker', '');
        Observer.Expect('initial ext counter', '0');
        Observer.Expect('r1 ext marker', 'one');
        Observer.Expect('r1 ext counter', '1');
        Observer.Expect('r1 base marker', 'one');
        Observer.Expect('r1 base counter', '1');
        Observer.Expect('r2 ext marker', '');
        Observer.Expect('r2 ext counter', '0');
        Observer.Expect('r2 after set ext marker', 'two');
        Observer.Expect('r1 after r2 set ext marker', 'one');
        Observer.Expect('r1 after base set ext marker', 'base-one');
        Observer.Expect('r1 after base set ext counter', '11');
        Observer.Expect('r2 after r1 base set', 'two');
        Observer.Expect('r1 after append', 'base-one+x');
        Observer.Expect('r1 after append counter', '1011');
        Observer.Verify();
    end;

    [Test]
    procedure P146_Triggers_BaseThenExtension()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT P146 Base";
        R2: Record "LT P146 Base";
    begin
        R1.DeleteAll();
        R1.Code := 'A';
        R1.Insert(true);
        Observer.Observe('after insert marker', R1.ExtMarker());
        Observer.Observe('after insert counter', Format(R1.ExtCounter()));
        R1.Name := 'x';
        R1.Modify(true);
        Observer.Observe('after modify marker', R1.ExtMarker());
        Observer.Observe('after modify counter', Format(R1.ExtCounter()));
        R1.Insert(false);
        Observer.Observe('insert without trigger marker', R1.BaseMarker());
        R2.Code := 'B';
        R2.Insert(true);
        Observer.Observe('r2 marker after own insert', R2.ExtMarker());
        Observer.Observe('r1 marker after r2 insert', R1.ExtMarker());
        asserterror R2.Modify(false);
        Observer.ObserveError('af165');
        Observer.Observe('r2 modify without trigger', R2.ExtMarker());
        R1.DeleteAll();
        Observer.Expect('after insert marker', '|base-insert|ext-insert');
        Observer.Expect('after insert counter', '101');
        Observer.Expect('after modify marker', '|base-insert|ext-insert|base-modify|ext-modify');
        Observer.Expect('after modify counter', '2111');
        Observer.Expect('insert without trigger marker', '|base-insert|ext-insert|base-modify|ext-modify');
        Observer.Expect('r2 marker after own insert', '|base-insert|ext-insert');
        Observer.Expect('r1 marker after r2 insert', '|base-insert|ext-insert|base-modify|ext-modify');
        Observer.Expect('af165|text', 'The record in table LT P146 Base already exists. Identification fields and values: Code=''A''');
        Observer.Expect('af165|code', 'DB:RecordExists');
        Observer.Expect('r2 modify without trigger', '|base-insert|ext-insert');
        Observer.Verify();
    end;

    [Test]
    procedure P146_Triggers_FailedInsertKeepsGlobal()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT P146 Base";
        R2: Record "LT P146 Base";
    begin
        R1.DeleteAll();
        R1.Code := 'A';
        R1.Insert(true);
        R2.Code := 'A';
        R2.Insert(true);
        Observer.Observe('duplicate insert', 'no error');
        Observer.Observe('r2 marker after failed insert', R2.ExtMarker());
        Observer.Observe('r2 counter after failed insert', Format(R2.ExtCounter()));
        asserterror R1.DeleteAll();
        Observer.ObserveError('af187');
        Observer.Expect('duplicate insert', 'no error');
        Observer.Expect('r2 marker after failed insert', '|base-insert|ext-insert');
        Observer.Expect('r2 counter after failed insert', '101');
        Observer.Expect('af187|text', 'The record in table LT P146 Base already exists. Identification fields and values: Code=''A''');
        Observer.Expect('af187|code', 'DB:RecordExists');
        Observer.Verify();
    end;

    [Test]
    procedure P146_Copy_TransferFields()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT P146 Base";
        R2: Record "LT P146 Base";
        R3: Record "LT P146 Base";
        R4: Record "LT P146 Base";
    begin
        R1.DeleteAll();
        R1.Code := 'C1';
        R1.Name := 'copy';
        R1.ExtSet('src', 7);
        R2.ExtSet('dst', 8);
        R2.Copy(R1);
        Observer.Observe('copy dst code', R2.Code);
        Observer.Observe('copy dst marker', R2.ExtMarker());
        Observer.Observe('copy dst counter', Format(R2.ExtCounter()));
        Observer.Observe('copy src marker', R1.ExtMarker());
        R3.ExtSet('dst3', 9);
        R3.TransferFields(R1);
        Observer.Observe('transfer dst code', R3.Code);
        Observer.Observe('transfer dst marker', R3.ExtMarker());
        Observer.Observe('transfer dst counter', Format(R3.ExtCounter()));
        R4 := R1;
        Observer.Observe('assign dst marker', R4.ExtMarker());
        Observer.Observe('assign dst counter', Format(R4.ExtCounter()));
        Observer.Expect('copy dst code', 'C1');
        Observer.Expect('copy dst marker', 'dst');
        Observer.Expect('copy dst counter', '8');
        Observer.Expect('copy src marker', 'src');
        Observer.Expect('transfer dst code', 'C1');
        Observer.Expect('transfer dst marker', 'dst3');
        Observer.Expect('transfer dst counter', '9');
        Observer.Expect('assign dst marker', '');
        Observer.Expect('assign dst counter', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P146_Clear_Init_Reset()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT P146 Base";
    begin
        R1.DeleteAll();
        R1.ExtSet('keep', 5);
        R1.Init();
        Observer.Observe('after init marker', R1.ExtMarker());
        Observer.Observe('after init counter', Format(R1.ExtCounter()));
        R1.Reset();
        Observer.Observe('after reset marker', R1.ExtMarker());
        R1.SetRange(Code, 'A');
        R1.SetRange(Code);
        Observer.Observe('after setrange marker', R1.ExtMarker());
        Clear(R1);
        Observer.Observe('after clear marker', R1.ExtMarker());
        Observer.Observe('after clear counter', Format(R1.ExtCounter()));
        Observer.Expect('after init marker', 'keep');
        Observer.Expect('after init counter', '5');
        Observer.Expect('after reset marker', '');
        Observer.Expect('after setrange marker', '');
        Observer.Expect('after clear marker', '');
        Observer.Expect('after clear counter', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P146_Parameters_ByValue_ByVar()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT P146 Base";
    begin
        R1.DeleteAll();
        R1.ExtSet('param', 3);
        Observer.Observe('by value inside', ByValue(R1));
        ByVar(R1);
        Observer.Observe('after by var marker', R1.ExtMarker());
        Observer.Observe('after by var counter', Format(R1.ExtCounter()));
        Observer.Expect('by value inside', '#0');
        Observer.Expect('after by var marker', 'param|byvar');
        Observer.Expect('after by var counter', '1003');
        Observer.Verify();
    end;

    [Test]
    procedure P146_Find_ReadsRowKeepsGlobal()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT P146 Base";
        R2: Record "LT P146 Base";
    begin
        R1.DeleteAll();
        R1.Code := 'F1';
        R1.Insert(false);
        R2.ExtSet('before find', 4);
        Observer.Observe('find ok', Format(R2.Get('F1')));
        Observer.Observe('after get marker', R2.ExtMarker());
        Observer.Observe('after get counter', Format(R2.ExtCounter()));
        R2.FindFirst();
        Observer.Observe('after findfirst marker', R2.ExtMarker());
        R2.FindSet();
        Observer.Observe('after findset marker', R2.ExtMarker());
        R2.Modify(true);
        Observer.Observe('after modify marker', R2.ExtMarker());
        Observer.Observe('after modify counter', Format(R2.ExtCounter()));
        R1.DeleteAll();
        Observer.Expect('find ok', 'Yes');
        Observer.Expect('after get marker', 'before find');
        Observer.Expect('after get counter', '4');
        Observer.Expect('after findfirst marker', 'before find');
        Observer.Expect('after findset marker', 'before find');
        Observer.Expect('after modify marker', 'before find|base-modify|ext-modify');
        Observer.Expect('after modify counter', '2014');
        Observer.Verify();
    end;

    [Test]
    procedure P146_Temporary_Record()
    var
        Observer: Codeunit "Probe Observer";
        T1: Record "LT P146 Base" temporary;
        T2: Record "LT P146 Base" temporary;
        R1: Record "LT P146 Base";
    begin
        R1.DeleteAll();
        T1.ExtSet('temp', 6);
        Observer.Observe('temp marker', T1.ExtMarker());
        Observer.Observe('temp counter', Format(T1.ExtCounter()));
        T1.Code := 'T';
        T1.Insert(true);
        Observer.Observe('temp after insert marker', T1.ExtMarker());
        Observer.Observe('temp after insert counter', Format(T1.ExtCounter()));
        T1.Modify(true);
        Observer.Observe('temp after modify marker', T1.ExtMarker());
        Observer.Observe('temp after modify counter', Format(T1.ExtCounter()));
        Observer.Observe('second temp marker', T2.ExtMarker());
        T2.Copy(T1, true);
        Observer.Observe('copy sharetable marker', T2.ExtMarker());
        Observer.Observe('copy sharetable find', Format(T2.FindFirst()));
        Observer.Observe('copy sharetable marker after find', T2.ExtMarker());
        Observer.Expect('temp marker', 'temp');
        Observer.Expect('temp counter', '6');
        Observer.Expect('temp after insert marker', 'temp|base-insert|ext-insert');
        Observer.Expect('temp after insert counter', '107');
        Observer.Expect('temp after modify marker', 'temp|base-insert|ext-insert|base-modify|ext-modify');
        Observer.Expect('temp after modify counter', '2117');
        Observer.Expect('second temp marker', '');
        Observer.Expect('copy sharetable marker', '');
        Observer.Expect('copy sharetable find', 'Yes');
        Observer.Expect('copy sharetable marker after find', '');
        Observer.Verify();
    end;
}
