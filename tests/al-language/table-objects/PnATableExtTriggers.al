// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 70100/70101, extensions 70102-70104, log 70105
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Events: A table extension's triggers run only when the write runs triggers (and the xRec handle shared with the base trigger; two extensions declaring the same trigger)
// Facts: which base and extension triggers run for Insert/Modify/Delete/DeleteAll/Rename with RunTrigger false and true, order of base and extension triggers, xRec shared between them, two extensions with the same trigger
// BC versions: 29 (27 and 28 by CI)

codeunit 70105 "LT PnA TX Log"
{
    SingleInstance = true;

    var
        Txt: Text;

    procedure Add(Entry: Text)
    begin
        if Txt <> '' then
            Txt += ';';
        Txt += Entry;
    end;

    procedure Get(): Text
    begin
        exit(Txt);
    end;

    procedure Reset()
    begin
        Txt := '';
    end;
}

table 70100 "LT PnA TX"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Val; Integer) { }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT PnA TX Log";
    begin
        Log.Add('base-insert');
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT PnA TX Log";
    begin
        Log.Add('base-modify:' + Format(xRec.Val) + '>' + Format(Rec.Val));
        xRec.Val := 77;
    end;

    trigger OnDelete()
    var
        Log: Codeunit "LT PnA TX Log";
    begin
        Log.Add('base-delete');
    end;

    trigger OnRename()
    var
        Log: Codeunit "LT PnA TX Log";
    begin
        Log.Add('base-rename:' + xRec.Code + '>' + Rec.Code);
    end;
}

tableextension 70102 "LT PnA TX Ext" extends "LT PnA TX"
{
    fields
    {
        field(70100; Extra; Integer) { }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT PnA TX Log";
    begin
        Log.Add('ext-insert');
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT PnA TX Log";
    begin
        Log.Add('ext-modify:' + Format(xRec.Val) + '>' + Format(Rec.Val));
    end;

    trigger OnDelete()
    var
        Log: Codeunit "LT PnA TX Log";
    begin
        Log.Add('ext-delete');
    end;

    trigger OnRename()
    var
        Log: Codeunit "LT PnA TX Log";
    begin
        Log.Add('ext-rename:' + xRec.Code + '>' + Rec.Code);
    end;
}

table 70101 "LT PnA TX2"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Val; Integer) { }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT PnA TX Log";
    begin
        Log.Add('base2-insert');
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT PnA TX Log";
    begin
        Log.Add('base2-modify');
    end;
}

tableextension 70103 "LT PnA TX2 Ext A" extends "LT PnA TX2"
{
    trigger OnInsert()
    var
        Log: Codeunit "LT PnA TX Log";
    begin
        Log.Add('extA-insert');
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT PnA TX Log";
    begin
        Log.Add('extA-modify');
    end;
}

tableextension 70104 "LT PnA TX2 Ext B" extends "LT PnA TX2"
{
    trigger OnInsert()
    var
        Log: Codeunit "LT PnA TX Log";
    begin
        Log.Add('extB-insert');
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT PnA TX Log";
    begin
        Log.Add('extB-modify');
    end;
}

codeunit 70106 "LT PnA TX Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT PnA TX Log";

    [Test]
    procedure Insert_RunTrigger()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnA TX";
    begin
        R.DeleteAll(false);
        Log.Reset();
        R.Code := 'A';
        R.Insert(false);
        Observer.Observe('insert-false', Log.Get());
        Log.Reset();
        R.Code := 'B';
        R.Insert(true);
        Observer.Observe('insert-true', Log.Get());
        Log.Reset();
        R.Code := 'C';
        R.Insert();
        Observer.Observe('insert-default', Log.Get());
        Observer.Expect('insert-false', '');
        Observer.Expect('insert-true', 'base-insert;ext-insert');
        Observer.Expect('insert-default', '');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_RunTrigger_AndXRec()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnA TX";
    begin
        R.DeleteAll(false);
        R.Code := 'A';
        R.Val := 1;
        R.Insert(false);
        Log.Reset();
        R.Val := 2;
        R.Modify(false);
        Observer.Observe('modify-false', Log.Get());
        Log.Reset();
        R.Val := 3;
        R.Modify(true);
        Observer.Observe('modify-true', Log.Get());
        Log.Reset();
        R.Val := 4;
        R.Modify();
        Observer.Observe('modify-default', Log.Get());
        Log.Reset();
        R.Modify(true);
        Observer.Observe('modify-true-unchanged', Log.Get());
        Observer.Expect('modify-false', '');
        Observer.Expect('modify-true', 'base-modify:3>3;ext-modify:77>3');
        Observer.Expect('modify-default', '');
        Observer.Expect('modify-true-unchanged', 'base-modify:4>4;ext-modify:77>4');
        Observer.Verify();
    end;

    [Test]
    procedure Delete_And_DeleteAll_RunTrigger()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnA TX";
    begin
        R.DeleteAll(false);
        R.Code := 'A';
        R.Insert(false);
        R.Code := 'B';
        R.Insert(false);
        R.Code := 'C';
        R.Insert(false);
        R.Code := 'D';
        R.Insert(false);
        Log.Reset();
        R.Get('A');
        R.Delete(false);
        Observer.Observe('delete-false', Log.Get());
        Log.Reset();
        R.Get('B');
        R.Delete(true);
        Observer.Observe('delete-true', Log.Get());
        Log.Reset();
        R.DeleteAll(false);
        Observer.Observe('deleteall-false', Log.Get());
        Observer.Observe('left-after-deleteall-false', Format(R.Count()));
        R.Code := 'E';
        R.Insert(false);
        R.Code := 'F';
        R.Insert(false);
        Log.Reset();
        R.DeleteAll(true);
        Observer.Observe('deleteall-true', Log.Get());
        Observer.Expect('delete-false', '');
        Observer.Expect('delete-true', 'base-delete;ext-delete');
        Observer.Expect('deleteall-false', '');
        Observer.Expect('left-after-deleteall-false', '0');
        Observer.Expect('deleteall-true', 'base-delete;ext-delete;base-delete;ext-delete');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_AlwaysRunsTriggers()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnA TX";
    begin
        R.DeleteAll(false);
        R.Code := 'A';
        R.Insert(false);
        Log.Reset();
        R.Rename('B');
        Observer.Observe('rename', Log.Get());
        Observer.Expect('rename', 'base-rename:A>B;ext-rename:A>B');
        Observer.Verify();
    end;

    [Test]
    procedure TwoExtensions_SameTrigger()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnA TX2";
    begin
        R.DeleteAll(false);
        Log.Reset();
        R.Code := 'A';
        R.Insert(true);
        Observer.Observe('insert-true', Log.Get());
        Log.Reset();
        R.Code := 'B';
        R.Insert(false);
        Observer.Observe('insert-false', Log.Get());
        Log.Reset();
        R.Val := 1;
        R.Modify(true);
        Observer.Observe('modify-true', Log.Get());
        Log.Reset();
        R.Val := 2;
        R.Modify(false);
        Observer.Observe('modify-false', Log.Get());
        Observer.Expect('insert-true', 'base2-insert;extA-insert;extB-insert');
        Observer.Expect('insert-false', '');
        Observer.Expect('modify-true', 'base2-modify;extA-modify;extB-modify');
        Observer.Expect('modify-false', '');
        Observer.Verify();
    end;
}
