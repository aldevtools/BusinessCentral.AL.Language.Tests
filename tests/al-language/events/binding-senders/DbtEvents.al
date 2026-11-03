// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: self-contained tables 70516, 70517, SingleInstance log codeunit 70516 (used only by test codeunit 70518), static subscriber codeunit 70517
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: database events (Before/After Insert, Modify, Delete, Rename, Validate) of an own table, their arguments (Rec, xRec, RunTrigger, CurrFieldNo), their order relative to the table triggers, effect of RunTrigger, ModifyAll/DeleteAll, errors raised in subscribers.
// BC versions: 29 (27 and 28 by CI)

table 70516 "LT DbT Ev"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT DbT Log";
            begin
                Log.Add('TV(' + Name + ')');
                Log.Check('TVName');
            end;
        }
        field(3; Amount; Decimal)
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT DbT Log";
            begin
                Log.Add('TVAmt');
            end;
        }
        field(4; Qty; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT DbT Log";
    begin
        Log.Add('TI' + Format(Id) + '(' + Name + ')');
        Log.Check('TI');
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT DbT Log";
    begin
        Log.Add('TM' + Format(Id) + '(' + Name + '<' + xRec.Name + ')');
        Log.Check('TM');
    end;

    trigger OnDelete()
    var
        Log: Codeunit "LT DbT Log";
    begin
        Log.Add('TD' + Format(Id));
        Log.Check('TD');
    end;

    trigger OnRename()
    var
        Log: Codeunit "LT DbT Log";
    begin
        Log.Add('TR' + Format(xRec.Id) + '>' + Format(Id));
        Log.Check('TR');
    end;
}

table 70517 "LT DbT Ev Plain"
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

codeunit 70516 "LT DbT Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        FailAt: Text;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ',';
        Entries += Entry;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    procedure SetFail(Point: Text)
    begin
        FailAt := Point;
    end;

    procedure Check(Point: Text)
    begin
        if (FailAt <> '') and (FailAt = Point) then
            Error('forced failure at %1', Point);
    end;
}

codeunit 70517 "LT DbT Subs"
{
    [EventSubscriber(ObjectType::Table, Database::"LT DbT Ev", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BeforeInsert(var Rec: Record "LT DbT Ev"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT DbT Log";
    begin
        Log.Add('BI' + Format(Rec.Id) + '(' + Rec.Name + ')/' + Format(RunTrigger));
        Log.Check('BI');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT DbT Ev", 'OnAfterInsertEvent', '', false, false)]
    local procedure AfterInsert(var Rec: Record "LT DbT Ev"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT DbT Log";
    begin
        Log.Add('AI' + Format(Rec.Id) + '(' + Rec.Name + ')/' + Format(RunTrigger));
        Log.Check('AI');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT DbT Ev", 'OnBeforeModifyEvent', '', false, false)]
    local procedure BeforeModify(var Rec: Record "LT DbT Ev"; var xRec: Record "LT DbT Ev"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT DbT Log";
    begin
        Log.Add('BM' + Format(Rec.Id) + '(' + Rec.Name + '<' + xRec.Name + ')/' + Format(RunTrigger));
        Log.Check('BM');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT DbT Ev", 'OnAfterModifyEvent', '', false, false)]
    local procedure AfterModify(var Rec: Record "LT DbT Ev"; var xRec: Record "LT DbT Ev"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT DbT Log";
    begin
        Log.Add('AM' + Format(Rec.Id) + '(' + Rec.Name + '<' + xRec.Name + ')/' + Format(RunTrigger));
        Log.Check('AM');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT DbT Ev", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure BeforeDelete(var Rec: Record "LT DbT Ev"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT DbT Log";
    begin
        Log.Add('BD' + Format(Rec.Id) + '/' + Format(RunTrigger));
        Log.Check('BD');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT DbT Ev", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDelete(var Rec: Record "LT DbT Ev"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT DbT Log";
    begin
        Log.Add('AD' + Format(Rec.Id) + '/' + Format(RunTrigger));
        Log.Check('AD');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT DbT Ev", 'OnBeforeRenameEvent', '', false, false)]
    local procedure BeforeRename(var Rec: Record "LT DbT Ev"; var xRec: Record "LT DbT Ev"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT DbT Log";
    begin
        Log.Add('BR' + Format(xRec.Id) + '>' + Format(Rec.Id) + '/' + Format(RunTrigger));
        Log.Check('BR');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT DbT Ev", 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRename(var Rec: Record "LT DbT Ev"; var xRec: Record "LT DbT Ev"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT DbT Log";
    begin
        Log.Add('AR' + Format(xRec.Id) + '>' + Format(Rec.Id) + '/' + Format(RunTrigger));
        Log.Check('AR');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT DbT Ev", 'OnBeforeValidateEvent', 'Name', false, false)]
    local procedure BeforeValidateName(var Rec: Record "LT DbT Ev"; var xRec: Record "LT DbT Ev"; CurrFieldNo: Integer)
    var
        Log: Codeunit "LT DbT Log";
    begin
        Log.Add('BVN(' + Rec.Name + '<' + xRec.Name + ')/' + Format(CurrFieldNo));
        Log.Check('BVN');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT DbT Ev", 'OnAfterValidateEvent', 'Name', false, false)]
    local procedure AfterValidateName(var Rec: Record "LT DbT Ev"; var xRec: Record "LT DbT Ev"; CurrFieldNo: Integer)
    var
        Log: Codeunit "LT DbT Log";
    begin
        Log.Add('AVN(' + Rec.Name + '<' + xRec.Name + ')/' + Format(CurrFieldNo));
        Log.Check('AVN');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT DbT Ev", 'OnBeforeValidateEvent', 'Amount', false, false)]
    local procedure BeforeValidateAmount(var Rec: Record "LT DbT Ev"; var xRec: Record "LT DbT Ev"; CurrFieldNo: Integer)
    var
        Log: Codeunit "LT DbT Log";
    begin
        Log.Add('BVA(' + Format(Rec.Amount) + '<' + Format(xRec.Amount) + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT DbT Ev", 'OnAfterValidateEvent', 'Amount', false, false)]
    local procedure AfterValidateAmount(var Rec: Record "LT DbT Ev"; var xRec: Record "LT DbT Ev"; CurrFieldNo: Integer)
    var
        Log: Codeunit "LT DbT Log";
    begin
        Log.Add('AVA(' + Format(Rec.Amount) + '<' + Format(xRec.Amount) + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT DbT Ev Plain", 'OnAfterInsertEvent', '', false, false)]
    local procedure PlainAfterInsert(var Rec: Record "LT DbT Ev Plain"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT DbT Log";
    begin
        Log.Add('PI' + Format(Rec.Id) + '/' + Format(RunTrigger));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT DbT Ev Plain", 'OnAfterModifyEvent', '', false, false)]
    local procedure PlainAfterModify(var Rec: Record "LT DbT Ev Plain"; var xRec: Record "LT DbT Ev Plain"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT DbT Log";
    begin
        Log.Add('PM' + Format(Rec.Id) + '(' + Rec.Name + '<' + xRec.Name + ')/' + Format(RunTrigger));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT DbT Ev Plain", 'OnAfterDeleteEvent', '', false, false)]
    local procedure PlainAfterDelete(var Rec: Record "LT DbT Ev Plain"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT DbT Log";
    begin
        Log.Add('PD' + Format(Rec.Id) + '/' + Format(RunTrigger));
    end;
}

codeunit 70518 "LT DbT Events"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Prep()
    var
        Rec: Record "LT DbT Ev";
        Plain: Record "LT DbT Ev Plain";
        Log: Codeunit "LT DbT Log";
    begin
        Rec.DeleteAll(false);
        Plain.DeleteAll(false);
        Log.SetFail('');
        Log.Take();
    end;

    local procedure Seed(Count: Integer)
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        i: Integer;
    begin
        for i := 1 to Count do begin
            Rec.Init();
            Rec.Id := i;
            Rec.Name := 'n' + Format(i);
            Rec.Amount := i * 10;
            Rec.Qty := i;
            Rec.Insert(false);
        end;
        Log.Take();
    end;

    [Test]
    procedure Insert_Order()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Rec.Id := 1;
        Rec.Name := 'a';
        Rec.Insert(true);
        Observer.Observe('insert true', Log.Take());
        Rec.Id := 2;
        Rec.Insert(false);
        Observer.Observe('insert false', Log.Take());
        Rec.Id := 3;
        Rec.Insert();
        Observer.Observe('insert default', Log.Take());
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Expect('insert true', 'BI1(a)/Yes,TI1(a),AI1(a)/Yes');
        Observer.Expect('insert false', 'BI2(a)/No,AI2(a)/No');
        Observer.Expect('insert default', 'BI3(a)/No,AI3(a)/No');
        Observer.Expect('count', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_RecValuesInTrigger()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Rec.Id := 10;
        Rec.Name := 'first';
        Rec.Amount := 5;
        Rec.Insert(true);
        Observer.Observe('insert named', Log.Take());
        Rec.Init();
        Rec.Id := 11;
        Rec.Insert(true);
        Observer.Observe('insert init', Log.Take());
        Observer.Observe('name after', Rec.Name);
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Expect('insert named', 'BI10(first)/Yes,TI10(first),AI10(first)/Yes');
        Observer.Expect('insert init', 'BI11()/Yes,TI11(),AI11()/Yes');
        Observer.Expect('name after', '');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_DuplicateKey()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Prep();
        Seed(1);
        Rec.Id := 1;
        Rec.Name := 'dup';
        Rec.Insert(true);
        Observer.Observe('dup insert true', 'no error');
        Observer.Observe('log after dup true', Log.Take());
        Rec.Id := 1;
        Rec.Name := 'dup2';
        Ok := Rec.Insert(true);
        Observer.Observe('dup insert returns', Format(Ok));
        Observer.Observe('log after dup returns', Log.Take());
        Observer.Expect('dup insert true', 'no error');
        Observer.Expect('log after dup true', 'BI1(dup)/Yes,TI1(dup),AI1(dup)/Yes');
        Observer.Expect('dup insert returns', 'No');
        Observer.Expect('log after dup returns', 'BI1(dup2)/Yes,TI1(dup2)');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_Order()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Seed(2);
        Rec.Get(1);
        Rec.Name := 'new1';
        Rec.Modify(true);
        Observer.Observe('modify true', Log.Take());
        Rec.Name := 'new2';
        Rec.Modify(false);
        Observer.Observe('modify false', Log.Take());
        Rec.Name := 'new3';
        Rec.Modify();
        Observer.Observe('modify default', Log.Take());
        Rec.Get(1);
        Observer.Observe('stored name', Rec.Name);
        Observer.Expect('modify true', 'BM1(new1<new1)/Yes,TM1(new1<new1),AM1(new1<new1)/Yes');
        Observer.Expect('modify false', 'BM1(new2<new2)/No,AM1(new2<new2)/No');
        Observer.Expect('modify default', 'BM1(new3<new3)/No,AM1(new3<new3)/No');
        Observer.Expect('stored name', 'new3');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_XRecIsDatabaseValue()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Seed(1);
        Rec.Get(1);
        Rec.Name := 'x1';
        Rec.Modify(true);
        Observer.Observe('first modify', Log.Take());
        Rec.Name := 'x2';
        Rec.Modify(true);
        Observer.Observe('second modify', Log.Take());
        Rec.Name := 'x3';
        Rec.Modify(false);
        Rec.Name := 'x4';
        Rec.Modify(true);
        Observer.Observe('after silent modify', Log.Take());
        Observer.Observe('xRec of variable', Rec.Name);
        Observer.Expect('first modify', 'BM1(x1<x1)/Yes,TM1(x1<x1),AM1(x1<x1)/Yes');
        Observer.Expect('second modify', 'BM1(x2<x2)/Yes,TM1(x2<x2),AM1(x2<x2)/Yes');
        Observer.Expect('after silent modify', 'BM1(x3<x3)/No,AM1(x3<x3)/No,BM1(x4<x4)/Yes,TM1(x4<x4),AM1(x4<x4)/Yes');
        Observer.Expect('xRec of variable', 'x4');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_Unchanged()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Prep();
        Seed(1);
        Rec.Get(1);
        Rec.Modify(true);
        Observer.Observe('unchanged modify true', Log.Take());
        Ok := Rec.Modify(true);
        Observer.Observe('unchanged returns', Format(Ok));
        Rec.Modify(false);
        Observer.Observe('unchanged modify false', Log.Take());
        Observer.Expect('unchanged modify true', 'BM1(n1<n1)/Yes,TM1(n1<n1),AM1(n1<n1)/Yes');
        Observer.Expect('unchanged returns', 'Yes');
        Observer.Expect('unchanged modify false', 'BM1(n1<n1)/Yes,TM1(n1<n1),AM1(n1<n1)/Yes,BM1(n1<n1)/No,AM1(n1<n1)/No');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_NotFound()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Prep();
        Rec.Id := 99;
        Rec.Name := 'ghost';
        asserterror Rec.Modify(true);
        Observer.ObserveError('modify missing');
        Observer.Observe('log after error', Log.Take());
        Ok := Rec.Modify(true);
        Observer.Observe('modify missing returns', Format(Ok));
        Observer.Observe('log after returns', Log.Take());
        Observer.Expect('modify missing|text', 'The LT DbT Ev does not exist. Identification fields and values: Id=''99''');
        Observer.Expect('modify missing|code', 'DB:RecordNotFound');
        Observer.Expect('log after error', 'BM99(ghost<ghost)/Yes,TM99(ghost<ghost)');
        Observer.Expect('modify missing returns', 'No');
        Observer.Expect('log after returns', 'BM99(ghost<ghost)/Yes,TM99(ghost<ghost)');
        Observer.Verify();
    end;

    [Test]
    procedure Delete_Order()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Seed(3);
        Rec.Get(1);
        Rec.Delete(true);
        Observer.Observe('delete true', Log.Take());
        Rec.Get(2);
        Rec.Delete(false);
        Observer.Observe('delete false', Log.Take());
        Rec.Get(3);
        Rec.Delete();
        Observer.Observe('delete default', Log.Take());
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Expect('delete true', 'BD1/Yes,TD1,AD1/Yes');
        Observer.Expect('delete false', 'BD2/No,AD2/No');
        Observer.Expect('delete default', 'BD3/No,AD3/No');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Delete_NotFound()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Prep();
        Rec.Id := 77;
        asserterror Rec.Delete(true);
        Observer.ObserveError('delete missing');
        Observer.Observe('log after error', Log.Take());
        Ok := Rec.Delete(true);
        Observer.Observe('delete missing returns', Format(Ok));
        Observer.Observe('log after returns', Log.Take());
        Observer.Expect('delete missing|text', 'The LT DbT Ev does not exist. Identification fields and values: Id=''77''');
        Observer.Expect('delete missing|code', 'DB:RecordNotFound');
        Observer.Expect('log after error', 'BD77/Yes,TD77');
        Observer.Expect('delete missing returns', 'No');
        Observer.Expect('log after returns', 'BD77/Yes,TD77');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_Order()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Seed(2);
        Rec.Get(1);
        Rec.Rename(11);
        Observer.Observe('rename default', Log.Take());
        Observer.Observe('id after', Format(Rec.Id));
        Rec.Get(11);
        Rec.Name := 'renamed';
        Rec.Rename(12);
        Observer.Observe('rename with name change', Log.Take());
        Rec.Get(12);
        Observer.Observe('name stored', Rec.Name);
        Observer.Expect('rename default', 'BR1>11/Yes,TR1>11,AR1>11/Yes');
        Observer.Expect('id after', '11');
        Observer.Expect('rename with name change', 'BR11>12/Yes,TR11>12,AR11>12/Yes');
        Observer.Expect('name stored', 'renamed');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_SameKey()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Seed(1);
        Rec.Get(1);
        Rec.Rename(1);
        Observer.Observe('rename to same key', Log.Take());
        Observer.Expect('rename to same key', 'BR1>1/Yes,TR1>1,AR1>1/Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Events()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Rec.Id := 1;
        Rec.Name := 'old';
        Rec.Validate(Name, 'new');
        Observer.Observe('validate name', Log.Take());
        Rec.Validate(Name);
        Observer.Observe('validate no value', Log.Take());
        Rec.Name := 'assigned';
        Observer.Observe('assignment only', Log.Take());
        Rec.Validate(Amount, 5);
        Observer.Observe('validate amount', Log.Take());
        Rec.Validate(Qty, 3);
        Observer.Observe('validate field without subscriber', Log.Take());
        Rec.Validate(Name, '');
        Observer.Observe('validate blank', Log.Take());
        Observer.Expect('validate name', 'BVN(new<old)/0,TV(new),AVN(new<old)/0');
        Observer.Expect('validate no value', 'BVN(new<new)/0,TV(new),AVN(new<new)/0');
        Observer.Expect('assignment only', '');
        Observer.Expect('validate amount', 'BVA(5<0),TVAmt,AVA(5<0)');
        Observer.Expect('validate field without subscriber', '');
        Observer.Expect('validate blank', 'BVN(<assigned)/0,TV(),AVN(<assigned)/0');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_XRecAfterModify()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Seed(1);
        Rec.Get(1);
        Rec.Validate(Name, 'v1');
        Observer.Observe('before modify', Log.Take());
        Rec.Modify(true);
        Log.Take();
        Rec.Validate(Name, 'v2');
        Observer.Observe('after modify', Log.Take());
        Observer.Expect('before modify', 'BVN(v1<n1)/0,TV(v1),AVN(v1<n1)/0');
        Observer.Expect('after modify', 'BVN(v2<v1)/0,TV(v2),AVN(v2<v1)/0');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_ErrorInSubscriber()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Rec.Id := 1;
        Rec.Name := 'keep';
        Log.SetFail('BVN');
        asserterror Rec.Validate(Name, 'changed');
        Observer.ObserveError('fail before validate');
        Observer.Observe('log', Log.Take());
        Observer.Observe('name', Rec.Name);
        Log.SetFail('TVName');
        asserterror Rec.Validate(Name, 'changed2');
        Observer.ObserveError('fail in field trigger');
        Observer.Observe('log2', Log.Take());
        Observer.Observe('name2', Rec.Name);
        Log.SetFail('AVN');
        asserterror Rec.Validate(Name, 'changed3');
        Observer.ObserveError('fail after validate');
        Observer.Observe('log3', Log.Take());
        Observer.Observe('name3', Rec.Name);
        Log.SetFail('');
        Observer.Expect('fail before validate|text', 'forced failure at BVN');
        Observer.Expect('fail before validate|code', 'Dialog');
        Observer.Expect('log', 'BVN(changed<keep)/0');
        Observer.Expect('name', 'keep');
        Observer.Expect('fail in field trigger|text', 'forced failure at TVName');
        Observer.Expect('fail in field trigger|code', 'Dialog');
        Observer.Expect('log2', 'BVN(changed2<keep)/0,TV(changed2)');
        Observer.Expect('name2', 'keep');
        Observer.Expect('fail after validate|text', 'forced failure at AVN');
        Observer.Expect('fail after validate|code', 'Dialog');
        Observer.Expect('log3', 'BVN(changed3<keep)/0,TV(changed3),AVN(changed3<keep)/0');
        Observer.Expect('name3', 'keep');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyAll_Events()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Seed(3);
        Rec.ModifyAll(Qty, 100, true);
        Observer.Observe('modifyall true', Log.Take());
        Rec.ModifyAll(Qty, 200, false);
        Observer.Observe('modifyall false', Log.Take());
        Rec.ModifyAll(Qty, 300);
        Observer.Observe('modifyall default', Log.Take());
        Rec.FindSet();
        Observer.Observe('qty first', Format(Rec.Qty));
        Observer.Expect('modifyall true', 'BM1(n1<n1)/Yes,TM1(n1<n1),AM1(n1<n1)/Yes,BM2(n2<n2)/Yes,TM2(n2<n2),AM2(n2<n2)/Yes,BM3(n3<n3)/Yes,TM3(n3<n3),AM3(n3<n3)/Yes');
        Observer.Expect('modifyall false', 'BM1(n1<n1)/No,AM1(n1<n1)/No,BM2(n2<n2)/No,AM2(n2<n2)/No,BM3(n3<n3)/No,AM3(n3<n3)/No');
        Observer.Expect('modifyall default', 'BM1(n1<n1)/No,AM1(n1<n1)/No,BM2(n2<n2)/No,AM2(n2<n2)/No,BM3(n3<n3)/No,AM3(n3<n3)/No');
        Observer.Expect('qty first', '300');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyAll_NameAndFilter()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Seed(3);
        Rec.SetRange(Id, 2, 3);
        Rec.ModifyAll(Name, 'mm', true);
        Observer.Observe('modifyall name true', Log.Take());
        Rec.ModifyAll(Name, 'nn', false);
        Observer.Observe('modifyall name false', Log.Take());
        Rec.SetRange(Id, 50);
        Rec.ModifyAll(Name, 'zz', true);
        Observer.Observe('modifyall empty set', Log.Take());
        Observer.Expect('modifyall name true', 'BM2(mm<mm)/Yes,TM2(mm<mm),AM2(mm<mm)/Yes,BM3(mm<mm)/Yes,TM3(mm<mm),AM3(mm<mm)/Yes');
        Observer.Expect('modifyall name false', 'BM2(nn<nn)/No,AM2(nn<nn)/No,BM3(nn<nn)/No,AM3(nn<nn)/No');
        Observer.Expect('modifyall empty set', '');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyAll_ErrorRollback()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Seed(3);
        Commit();
        Log.SetFail('TM');
        asserterror Rec.ModifyAll(Qty, 100, true);
        Observer.ObserveError('modifyall fails in trigger');
        Log.SetFail('');
        Observer.Observe('log', Log.Take());
        Rec.SetRange(Qty, 100);
        Observer.Observe('rows with 100', Format(Rec.Count()));
        Observer.Expect('modifyall fails in trigger|text', 'forced failure at TM');
        Observer.Expect('modifyall fails in trigger|code', 'Dialog');
        Observer.Expect('log', 'BM1(n1<n1)/Yes,TM1(n1<n1)');
        Observer.Expect('rows with 100', '0');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAll_Events()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Seed(2);
        Rec.DeleteAll(true);
        Observer.Observe('deleteall true', Log.Take());
        Seed(2);
        Rec.DeleteAll(false);
        Observer.Observe('deleteall false', Log.Take());
        Seed(2);
        Rec.DeleteAll();
        Observer.Observe('deleteall default', Log.Take());
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Expect('deleteall true', 'BD1/Yes,TD1,AD1/Yes,BD2/Yes,TD2,AD2/Yes');
        Observer.Expect('deleteall false', 'BD1/No,AD1/No,BD2/No,AD2/No');
        Observer.Expect('deleteall default', 'BD1/No,AD1/No,BD2/No,AD2/No');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAll_Filtered()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Seed(4);
        Rec.SetFilter(Id, '>=3');
        Rec.DeleteAll(true);
        Observer.Observe('deleteall filtered', Log.Take());
        Rec.Reset();
        Observer.Observe('count', Format(Rec.Count()));
        Rec.DeleteAll(true);
        Rec.DeleteAll(true);
        Observer.Observe('deleteall empty', Log.Take());
        Observer.Expect('deleteall filtered', 'BD3/Yes,TD3,AD3/Yes,BD4/Yes,TD4,AD4/Yes');
        Observer.Expect('count', '2');
        Observer.Expect('deleteall empty', 'BD1/Yes,TD1,AD1/Yes,BD2/Yes,TD2,AD2/Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Plain_Events()
    var
        Plain: Record "LT DbT Ev Plain";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Plain.Id := 1;
        Plain.Name := 'p';
        Plain.Insert(true);
        Observer.Observe('insert true', Log.Take());
        Plain.Id := 2;
        Plain.Insert(false);
        Observer.Observe('insert false', Log.Take());
        Plain.Name := 'q';
        Plain.Modify(true);
        Observer.Observe('modify true', Log.Take());
        Plain.Name := 'r';
        Plain.Modify(false);
        Observer.Observe('modify false', Log.Take());
        Plain.Delete(true);
        Observer.Observe('delete true', Log.Take());
        Plain.Get(1);
        Plain.Delete(false);
        Observer.Observe('delete false', Log.Take());
        Observer.Expect('insert true', 'PI1/Yes');
        Observer.Expect('insert false', 'PI2/No');
        Observer.Expect('modify true', 'PM2(q<q)/Yes');
        Observer.Expect('modify false', 'PM2(r<r)/No');
        Observer.Expect('delete true', 'PD2/Yes');
        Observer.Expect('delete false', 'PD1/No');
        Observer.Verify();
    end;

    [Test]
    procedure Plain_ModifyAllDeleteAll()
    var
        Plain: Record "LT DbT Ev Plain";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        Prep();
        for i := 1 to 3 do begin
            Plain.Id := i;
            Plain.Name := 'p' + Format(i);
            Plain.Insert(false);
        end;
        Log.Take();
        Plain.ModifyAll(Name, 'z', true);
        Observer.Observe('modifyall true', Log.Take());
        Plain.ModifyAll(Name, 'y', false);
        Observer.Observe('modifyall false', Log.Take());
        Plain.DeleteAll(true);
        Observer.Observe('deleteall true', Log.Take());
        Observer.Expect('modifyall true', 'PM1(z<z)/Yes,PM2(z<z)/Yes,PM3(z<z)/Yes');
        Observer.Expect('modifyall false', 'PM1(y<y)/No,PM2(y<y)/No,PM3(y<y)/No');
        Observer.Expect('deleteall true', 'PD1/Yes,PD2/Yes,PD3/Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Error_BeforeInsert()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Commit();
        Log.SetFail('BI');
        Rec.Id := 1;
        Rec.Name := 'e';
        asserterror Rec.Insert(true);
        Observer.ObserveError('before insert fails');
        Log.SetFail('');
        Observer.Observe('log', Log.Take());
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Expect('before insert fails|text', 'forced failure at BI');
        Observer.Expect('before insert fails|code', 'Dialog');
        Observer.Expect('log', 'BI1(e)/Yes');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Error_TableTriggerInsert()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Commit();
        Log.SetFail('TI');
        Rec.Id := 1;
        Rec.Name := 'e';
        asserterror Rec.Insert(true);
        Observer.ObserveError('table trigger fails');
        Observer.Observe('log', Log.Take());
        Observer.Observe('count', Format(Rec.Count()));
        Rec.Id := 2;
        Rec.Insert(false);
        Observer.Observe('insert false does not fail', Log.Take());
        Log.SetFail('');
        Observer.Expect('table trigger fails|text', 'forced failure at TI');
        Observer.Expect('table trigger fails|code', 'Dialog');
        Observer.Expect('log', 'BI1(e)/Yes,TI1(e)');
        Observer.Expect('count', '0');
        Observer.Expect('insert false does not fail', 'BI2(e)/No,AI2(e)/No');
        Observer.Verify();
    end;

    [Test]
    procedure Error_AfterInsert()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Commit();
        Log.SetFail('AI');
        Rec.Id := 1;
        Rec.Name := 'e';
        asserterror Rec.Insert(true);
        Observer.ObserveError('after insert fails');
        Log.SetFail('');
        Observer.Observe('log', Log.Take());
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Expect('after insert fails|text', 'forced failure at AI');
        Observer.Expect('after insert fails|code', 'Dialog');
        Observer.Expect('log', 'BI1(e)/Yes,TI1(e),AI1(e)/Yes');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Error_ModifyPoints()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Seed(1);
        Commit();
        Rec.Get(1);
        Rec.Name := 'changed';
        Log.SetFail('BM');
        asserterror Rec.Modify(true);
        Observer.ObserveError('before modify fails');
        Observer.Observe('log BM', Log.Take());
        Log.SetFail('TM');
        asserterror Rec.Modify(true);
        Observer.ObserveError('table trigger modify fails');
        Observer.Observe('log TM', Log.Take());
        Log.SetFail('AM');
        asserterror Rec.Modify(true);
        Observer.ObserveError('after modify fails');
        Observer.Observe('log AM', Log.Take());
        Log.SetFail('');
        Rec.Get(1);
        Observer.Observe('stored name', Rec.Name);
        Observer.Expect('before modify fails|text', 'forced failure at BM');
        Observer.Expect('before modify fails|code', 'Dialog');
        Observer.Expect('log BM', 'BM1(changed<changed)/Yes');
        Observer.Expect('table trigger modify fails|text', 'forced failure at TM');
        Observer.Expect('table trigger modify fails|code', 'Dialog');
        Observer.Expect('log TM', 'BM1(changed<changed)/Yes,TM1(changed<changed)');
        Observer.Expect('after modify fails|text', 'forced failure at AM');
        Observer.Expect('after modify fails|code', 'Dialog');
        Observer.Expect('log AM', 'BM1(changed<changed)/Yes,TM1(changed<changed),AM1(changed<changed)/Yes');
        Observer.Expect('stored name', 'n1');
        Observer.Verify();
    end;

    [Test]
    procedure Error_DeletePoints()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Seed(1);
        Commit();
        Rec.Get(1);
        Log.SetFail('BD');
        asserterror Rec.Delete(true);
        Observer.ObserveError('before delete fails');
        Observer.Observe('log BD', Log.Take());
        Log.SetFail('TD');
        asserterror Rec.Delete(true);
        Observer.ObserveError('table trigger delete fails');
        Observer.Observe('log TD', Log.Take());
        Log.SetFail('AD');
        asserterror Rec.Delete(true);
        Observer.ObserveError('after delete fails');
        Observer.Observe('log AD', Log.Take());
        Log.SetFail('');
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Expect('before delete fails|text', 'forced failure at BD');
        Observer.Expect('before delete fails|code', 'Dialog');
        Observer.Expect('log BD', 'BD1/Yes');
        Observer.Expect('table trigger delete fails|text', 'forced failure at TD');
        Observer.Expect('table trigger delete fails|code', 'Dialog');
        Observer.Expect('log TD', 'BD1/Yes,TD1');
        Observer.Expect('after delete fails|text', 'forced failure at AD');
        Observer.Expect('after delete fails|code', 'Dialog');
        Observer.Expect('log AD', 'BD1/Yes,TD1,AD1/Yes');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Error_RenamePoints()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Seed(1);
        Commit();
        Rec.Get(1);
        Log.SetFail('BR');
        asserterror Rec.Rename(5);
        Observer.ObserveError('before rename fails');
        Observer.Observe('log BR', Log.Take());
        Log.SetFail('TR');
        asserterror Rec.Rename(5);
        Observer.ObserveError('table trigger rename fails');
        Observer.Observe('log TR', Log.Take());
        Log.SetFail('AR');
        asserterror Rec.Rename(5);
        Observer.ObserveError('after rename fails');
        Observer.Observe('log AR', Log.Take());
        Log.SetFail('');
        Observer.Observe('exists 1', Format(Rec.Get(1)));
        Observer.Observe('exists 5', Format(Rec.Get(5)));
        Observer.Expect('before rename fails|text', 'forced failure at BR');
        Observer.Expect('before rename fails|code', 'Dialog');
        Observer.Expect('log BR', 'BR1>5/Yes');
        Observer.Expect('table trigger rename fails|text', 'forced failure at TR');
        Observer.Expect('table trigger rename fails|code', 'Dialog');
        Observer.Expect('log TR', 'BR5>5/Yes,TR5>5');
        Observer.Expect('after rename fails|text', 'The LT DbT Ev does not exist. Identification fields and values: Id=''5''');
        Observer.Expect('after rename fails|code', 'DB:RecordNotFound');
        Observer.Expect('log AR', 'BR5>5/Yes,TR5>5');
        Observer.Expect('exists 1', 'Yes');
        Observer.Expect('exists 5', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Error_RollsBackEarlierUncommitted()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Seed(2);
        Observer.Observe('count before', Format(Rec.Count()));
        Log.SetFail('BI');
        Rec.Id := 9;
        asserterror Rec.Insert(true);
        Observer.ObserveError('insert fails');
        Log.SetFail('');
        Observer.Observe('count after', Format(Rec.Count()));
        Observer.Expect('count before', '2');
        Observer.Expect('insert fails|text', 'forced failure at BI');
        Observer.Expect('insert fails|code', 'Dialog');
        Observer.Expect('count after', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Error_ErrorInsideLoopStopsLoop()
    var
        Rec: Record "LT DbT Ev";
        Log: Codeunit "LT DbT Log";
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        Prep();
        Commit();
        Log.SetFail('AI');
        for i := 1 to 3 do begin
            Rec.Id := i;
            asserterror Rec.Insert(true);
            Observer.ObserveError('loop insert ' + Format(i));
        end;
        Log.SetFail('');
        Observer.Observe('log', Log.Take());
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Expect('loop insert 1|text', 'forced failure at AI');
        Observer.Expect('loop insert 1|code', 'Dialog');
        Observer.Expect('loop insert 2|text', 'forced failure at AI');
        Observer.Expect('loop insert 2|code', 'Dialog');
        Observer.Expect('loop insert 3|text', 'forced failure at AI');
        Observer.Expect('loop insert 3|code', 'Dialog');
        Observer.Expect('log', 'BI1()/Yes,TI1(),AI1()/Yes,BI2()/Yes,TI2(),AI2()/Yes,BI3()/Yes,TI3(),AI3()/Yes');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;
}
