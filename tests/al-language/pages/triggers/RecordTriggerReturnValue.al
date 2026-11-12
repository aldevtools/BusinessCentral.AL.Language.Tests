// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-oninsertrecord-page-trigger
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onmodifyrecord-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 75350, card pages 75351 75352 75353, log codeunit 75354, test codeunit 75355
// Probe (al-runner 7628): what the client reads from a Boolean page trigger (OnInsertRecord, OnModifyRecord, OnDeleteRecord) that does not
//   end with exit(value): (Cond) `if Blocked then exit(false);` with Blocked = false, so the trigger ends without exit; (False) a named
//   return value Ok assigned false without exit; (True) the same assigned true. Driven through a TestPage: OpenNew + SetValue + Close or
//   Next (insert), OpenEdit + GoToKey + SetValue + Next or Close (modify). OnDeleteRecord is declared on each page but a TestPage has no
//   delete, so it is not reached.
// Observed (the CEM form): 'returned' when the steps came back (the trigger log and the stored rows); 'end' the error text and code
//   (CEM_NO_ERROR when no step raised); 'log' I/M/D = the page's OnInsertRecord / OnModifyRecord / OnDeleteRecord, T-ins / T-mod the
//   table's OnInsert / OnModify; 'rows' the stored rows afterwards.
// local object: the pages are the trigger shapes under test
// BC versions: 27, 28, 29

table 75350 "PG6 RT Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { DataClassification = SystemMetadata; }
        field(2; Name; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "PG6 RT Log";
    begin
        Log.Add('T-ins ' + Rec."Code" + ' ' + Rec.Name);
    end;

    trigger OnModify()
    var
        Log: Codeunit "PG6 RT Log";
    begin
        Log.Add('T-mod ' + Rec."Code" + ' ' + Rec.Name);
    end;
}

page 75351 "PG6 RT Cond Card"
{
    PageType = Card;
    SourceTable = "PG6 RT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "PG6 RT Log";
        Blocked: Boolean;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('I ' + Rec."Code" + ' ' + Rec.Name);
        if Blocked then
            exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('M ' + Rec."Code" + ' ' + Rec.Name);
        if Blocked then
            exit(false);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Log.Add('D ' + Rec."Code");
        if Blocked then
            exit(false);
    end;
}

page 75352 "PG6 RT False Card"
{
    PageType = Card;
    SourceTable = "PG6 RT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "PG6 RT Log";
        Blocked: Boolean;

    trigger OnInsertRecord(BelowxRec: Boolean) Ok: Boolean
    begin
        Log.Add('I ' + Rec."Code" + ' ' + Rec.Name);
        Ok := false;
    end;

    trigger OnModifyRecord() Ok: Boolean
    begin
        Log.Add('M ' + Rec."Code" + ' ' + Rec.Name);
        Ok := false;
    end;

    trigger OnDeleteRecord() Ok: Boolean
    begin
        Log.Add('D ' + Rec."Code");
        Ok := false;
    end;
}

page 75353 "PG6 RT True Card"
{
    PageType = Card;
    SourceTable = "PG6 RT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "PG6 RT Log";
        Blocked: Boolean;

    trigger OnInsertRecord(BelowxRec: Boolean) Ok: Boolean
    begin
        Log.Add('I ' + Rec."Code" + ' ' + Rec.Name);
        Ok := true;
    end;

    trigger OnModifyRecord() Ok: Boolean
    begin
        Log.Add('M ' + Rec."Code" + ' ' + Rec.Name);
        Ok := true;
    end;

    trigger OnDeleteRecord() Ok: Boolean
    begin
        Log.Add('D ' + Rec."Code");
        Ok := true;
    end;
}

codeunit 75354 "PG6 RT Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Reset()
    begin
        Lines := '';
    end;

    procedure Add(Line: Text)
    begin
        Lines += Line + '; ';
    end;

    procedure Peek(): Text
    begin
        exit(Lines);
    end;

    procedure Take() Result: Text
    begin
        Result := Lines;
        Lines := '';
    end;
}

codeunit 75355 "PG6 RT Trigger Return"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "PG6 RT Log";

    local procedure Setup()
    var
        Row: Record "PG6 RT Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."Code" := 'R1';
        Row.Name := 'start';
        Row.Insert();
        Row.Init();
        Row."Code" := 'R2';
        Row.Name := 'second';
        Row.Insert();
        Commit();
        Log.Reset();
        ClearLastError();
    end;

    local procedure Names() Result: Text
    var
        Row: Record "PG6 RT Row";
    begin
        if Row.FindSet() then
            repeat
                Result += Row."Code" + '=' + Row.Name + ' ';
            until Row.Next() = 0;
        Result += '(' + Format(Row.Count()) + ' rows)';
    end;

    local procedure ObserveEnd(var O: Codeunit "Probe Observer")
    begin
        O.ObserveError('end');
        O.Observe('log', Log.Take());
        O.Observe('rows', Names());
    end;

    [Test]
    procedure Cond_Insert_OpenNewSetValueClose()
    var
        O: Codeunit "Probe Observer";
        P: TestPage "PG6 RT Cond Card";
    begin
        Setup();
        asserterror begin
            P.OpenNew();
            P."Code".SetValue('N1');
            P.Name.SetValue('new');
            P.Close();
            O.Observe('returned', Log.Peek() + '| ' + Names());
            Error('CEM_NO_ERROR');
        end;
        ObserveEnd(O);
        O.Expect('returned', 'I N1 ; T-ins N1 ; M N1 new; T-mod N1 new; | N1=new R1=start R2=second (3 rows)');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'I N1 ; T-ins N1 ; M N1 new; T-mod N1 new; ');
        O.Expect('rows', 'R1=start R2=second (2 rows)');
        O.Verify();
    end;

    [Test]
    procedure Cond_Insert_OpenNewSetValueNext()
    var
        O: Codeunit "Probe Observer";
        P: TestPage "PG6 RT Cond Card";
    begin
        Setup();
        asserterror begin
            P.OpenNew();
            P."Code".SetValue('N1');
            P.Name.SetValue('new');
            P.Next();
            P.Close();
            O.Observe('returned', Log.Peek() + '| ' + Names());
            Error('CEM_NO_ERROR');
        end;
        ObserveEnd(O);
        O.Expect('returned', 'I N1 ; T-ins N1 ; M N1 new; T-mod N1 new; | N1=new R1=start R2=second (3 rows)');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'I N1 ; T-ins N1 ; M N1 new; T-mod N1 new; ');
        O.Expect('rows', 'R1=start R2=second (2 rows)');
        O.Verify();
    end;

    [Test]
    procedure Cond_Modify_SetValueNext()
    var
        O: Codeunit "Probe Observer";
        P: TestPage "PG6 RT Cond Card";
    begin
        Setup();
        asserterror begin
            P.OpenEdit();
            P.GoToKey('R1');
            P.Name.SetValue('edited');
            P.Next();
            P.Close();
            O.Observe('returned', Log.Peek() + '| ' + Names());
            Error('CEM_NO_ERROR');
        end;
        ObserveEnd(O);
        O.Expect('returned', 'M R1 edited; T-mod R1 edited; | R1=edited R2=second (2 rows)');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M R1 edited; T-mod R1 edited; ');
        O.Expect('rows', 'R1=start R2=second (2 rows)');
        O.Verify();
    end;

    [Test]
    procedure Cond_Modify_SetValueClose()
    var
        O: Codeunit "Probe Observer";
        P: TestPage "PG6 RT Cond Card";
    begin
        Setup();
        asserterror begin
            P.OpenEdit();
            P.GoToKey('R1');
            P.Name.SetValue('edited');
            P.Close();
            O.Observe('returned', Log.Peek() + '| ' + Names());
            Error('CEM_NO_ERROR');
        end;
        ObserveEnd(O);
        O.Expect('returned', 'M R1 edited; T-mod R1 edited; | R1=edited R2=second (2 rows)');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M R1 edited; T-mod R1 edited; ');
        O.Expect('rows', 'R1=start R2=second (2 rows)');
        O.Verify();
    end;

    [Test]
    procedure False_Insert_OpenNewSetValueClose()
    var
        O: Codeunit "Probe Observer";
        P: TestPage "PG6 RT False Card";
    begin
        Setup();
        asserterror begin
            P.OpenNew();
            P."Code".SetValue('N1');
            P.Name.SetValue('new');
            P.Close();
            O.Observe('returned', Log.Peek() + '| ' + Names());
            Error('CEM_NO_ERROR');
        end;
        ObserveEnd(O);
        O.Expect('end|text', 'Validation error for Field: ,  Message = ''The view is filtered, and the entry is outside the filter. Some actions may not work.''');
        O.Expect('end|code', 'TestValidation');
        O.Expect('log', 'I N1 ; ');
        O.Expect('rows', 'R1=start R2=second (2 rows)');
        O.Verify();
    end;

    [Test]
    procedure False_Insert_OpenNewSetValueNext()
    var
        O: Codeunit "Probe Observer";
        P: TestPage "PG6 RT False Card";
    begin
        Setup();
        asserterror begin
            P.OpenNew();
            P."Code".SetValue('N1');
            P.Name.SetValue('new');
            P.Next();
            P.Close();
            O.Observe('returned', Log.Peek() + '| ' + Names());
            Error('CEM_NO_ERROR');
        end;
        ObserveEnd(O);
        O.Expect('end|text', 'Validation error for Field: ,  Message = ''The view is filtered, and the entry is outside the filter. Some actions may not work.''');
        O.Expect('end|code', 'TestValidation');
        O.Expect('log', 'I N1 ; ');
        O.Expect('rows', 'R1=start R2=second (2 rows)');
        O.Verify();
    end;

    [Test]
    procedure False_Modify_SetValueNext()
    var
        O: Codeunit "Probe Observer";
        P: TestPage "PG6 RT False Card";
    begin
        Setup();
        asserterror begin
            P.OpenEdit();
            P.GoToKey('R1');
            P.Name.SetValue('edited');
            P.Next();
            P.Close();
            O.Observe('returned', Log.Peek() + '| ' + Names());
            Error('CEM_NO_ERROR');
        end;
        ObserveEnd(O);
        O.Expect('returned', 'M R1 edited; | R1=start R2=second (2 rows)');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M R1 edited; ');
        O.Expect('rows', 'R1=start R2=second (2 rows)');
        O.Verify();
    end;

    [Test]
    procedure False_Modify_SetValueClose()
    var
        O: Codeunit "Probe Observer";
        P: TestPage "PG6 RT False Card";
    begin
        Setup();
        asserterror begin
            P.OpenEdit();
            P.GoToKey('R1');
            P.Name.SetValue('edited');
            P.Close();
            O.Observe('returned', Log.Peek() + '| ' + Names());
            Error('CEM_NO_ERROR');
        end;
        ObserveEnd(O);
        O.Expect('returned', 'M R1 edited; | R1=start R2=second (2 rows)');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M R1 edited; ');
        O.Expect('rows', 'R1=start R2=second (2 rows)');
        O.Verify();
    end;

    [Test]
    procedure True_Insert_OpenNewSetValueClose()
    var
        O: Codeunit "Probe Observer";
        P: TestPage "PG6 RT True Card";
    begin
        Setup();
        asserterror begin
            P.OpenNew();
            P."Code".SetValue('N1');
            P.Name.SetValue('new');
            P.Close();
            O.Observe('returned', Log.Peek() + '| ' + Names());
            Error('CEM_NO_ERROR');
        end;
        ObserveEnd(O);
        O.Expect('returned', 'I N1 ; T-ins N1 ; M N1 new; T-mod N1 new; | N1=new R1=start R2=second (3 rows)');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'I N1 ; T-ins N1 ; M N1 new; T-mod N1 new; ');
        O.Expect('rows', 'R1=start R2=second (2 rows)');
        O.Verify();
    end;

    [Test]
    procedure True_Insert_OpenNewSetValueNext()
    var
        O: Codeunit "Probe Observer";
        P: TestPage "PG6 RT True Card";
    begin
        Setup();
        asserterror begin
            P.OpenNew();
            P."Code".SetValue('N1');
            P.Name.SetValue('new');
            P.Next();
            P.Close();
            O.Observe('returned', Log.Peek() + '| ' + Names());
            Error('CEM_NO_ERROR');
        end;
        ObserveEnd(O);
        O.Expect('returned', 'I N1 ; T-ins N1 ; M N1 new; T-mod N1 new; | N1=new R1=start R2=second (3 rows)');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'I N1 ; T-ins N1 ; M N1 new; T-mod N1 new; ');
        O.Expect('rows', 'R1=start R2=second (2 rows)');
        O.Verify();
    end;

    [Test]
    procedure True_Modify_SetValueNext()
    var
        O: Codeunit "Probe Observer";
        P: TestPage "PG6 RT True Card";
    begin
        Setup();
        asserterror begin
            P.OpenEdit();
            P.GoToKey('R1');
            P.Name.SetValue('edited');
            P.Next();
            P.Close();
            O.Observe('returned', Log.Peek() + '| ' + Names());
            Error('CEM_NO_ERROR');
        end;
        ObserveEnd(O);
        O.Expect('returned', 'M R1 edited; T-mod R1 edited; | R1=edited R2=second (2 rows)');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M R1 edited; T-mod R1 edited; ');
        O.Expect('rows', 'R1=start R2=second (2 rows)');
        O.Verify();
    end;

    [Test]
    procedure True_Modify_SetValueClose()
    var
        O: Codeunit "Probe Observer";
        P: TestPage "PG6 RT True Card";
    begin
        Setup();
        asserterror begin
            P.OpenEdit();
            P.GoToKey('R1');
            P.Name.SetValue('edited');
            P.Close();
            O.Observe('returned', Log.Peek() + '| ' + Names());
            Error('CEM_NO_ERROR');
        end;
        ObserveEnd(O);
        O.Expect('returned', 'M R1 edited; T-mod R1 edited; | R1=edited R2=second (2 rows)');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M R1 edited; T-mod R1 edited; ');
        O.Expect('rows', 'R1=start R2=second (2 rows)');
        O.Verify();
    end;
}
