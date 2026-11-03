// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-this-keyword
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73903, codeunit 73904
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "this.Member in a report, page, xmlport or query" (Must-not-compile checks; the table half of its probe)
// Facts: this.Proc(), this.GlobalVar, this.Field and a passed on this in a table: procedure, trigger and event style callers
// BC versions: 29 (27 and 28 by CI)

table 73903 "LT PnF This Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    var
        Counter: Integer;
        Tag: Text[20];

    trigger OnInsert()
    begin
        this.Counter += 1;
        this.Tag := 'inserted';
    end;

    procedure Helper(): Text
    begin
        exit('helper');
    end;

    procedure ViaThisProc(): Text
    begin
        exit(this.Helper());
    end;

    procedure ViaThisVar(): Text
    begin
        this.Counter := 41;
        this.Counter += 1;
        exit(Format(this.Counter));
    end;

    procedure ViaThisField(): Text
    begin
        this.Name := 'set via this';
        exit(this.Name + '|' + Name + '|' + this.Name);
    end;

    procedure ReadCounter(): Integer
    begin
        exit(this.Counter);
    end;

    procedure ReadTag(): Text
    begin
        exit(this.Tag);
    end;

    procedure PassThis(var Other: Record "LT PnF This Row")
    begin
        Other.CopyFrom(this);
    end;

    procedure CopyFrom(Source: Record "LT PnF This Row")
    begin
        Rec := Source;
    end;
}

codeunit 73904 "LT PnF This In Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure This_Table_Proc_Var_Field()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF This Row";
    begin
        Row.DeleteAll();
        Observer.Observe('proc', Row.ViaThisProc());
        Observer.Observe('var', Row.ViaThisVar());
        Observer.Observe('field', Row.ViaThisField());
        Observer.Observe('field_after', Row.Name);
        Observer.Expect('proc', 'helper');
        Observer.Expect('var', '42');
        Observer.Expect('field', 'set via this|set via this|set via this');
        Observer.Expect('field_after', 'set via this');
        Observer.Verify();
    end;

    [Test]
    procedure This_Table_InsertTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF This Row";
    begin
        Row.DeleteAll();
        Observer.Observe('counter_before', Format(Row.ReadCounter()));
        Row.Id := 1;
        Row.Insert(true);
        Observer.Observe('counter_after_trigger', Format(Row.ReadCounter()));
        Observer.Observe('tag', Row.ReadTag());
        Row.Id := 2;
        Row.Insert(false);
        Observer.Observe('counter_after_no_trigger', Format(Row.ReadCounter()));
        Row.Id := 3;
        Row.Insert(true);
        Observer.Observe('counter_after_second_trigger', Format(Row.ReadCounter()));
        Observer.Expect('counter_before', '0');
        Observer.Expect('counter_after_trigger', '1');
        Observer.Expect('tag', 'inserted');
        Observer.Expect('counter_after_no_trigger', '1');
        Observer.Expect('counter_after_second_trigger', '2');
        Observer.Verify();
    end;

    [Test]
    procedure This_Table_PassedOn()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF This Row";
        Other: Record "LT PnF This Row";
    begin
        Row.DeleteAll();
        Row.Id := 9;
        Row.Name := 'nine';
        Row.PassThis(Other);
        Observer.Observe('id', Format(Other.Id));
        Observer.Observe('name', Other.Name);
        Observer.Expect('id', '9');
        Observer.Expect('name', 'nine');
        Observer.Verify();
    end;
}
