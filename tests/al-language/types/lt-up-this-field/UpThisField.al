// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-this-keyword
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 90490, codeunits 90491 (this in a codeunit) and 90492 (tests)
// Probe (writer UP, al-runner issue 6211): `this.` in front of a table field inside a table procedure: assignment (this.ETag := x), a method called
// on a Text field (this."Set Codes".Split('|')), Validate and TestField through this., reads, compound assignment, values stored after Modify; and
// `this.` on a global variable and a procedure of a codeunit. Already pinned elsewhere: this.Field assignment/read and this.Var in a table
// (misc/lt-probes-needed-6/PnF18ThisInTable.al), this in report/page/xmlport/query (types/PRThisMember.al); this file adds the method-call, Validate,
// TestField, Modify and codeunit forms.
// BC versions: 27-29

table 90490 "LT UP This Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; ETag; Text[50]) { }
        field(3; "Set Codes"; Text[250]) { }
        field(4; Qty; Decimal)
        {
            trigger OnValidate()
            begin
                Trail += 'Q(' + Format(Qty, 0, 9) + ';old=' + Format(xRec.Qty, 0, 9) + ')';
            end;
        }
        field(5; Trail; Text[250]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }

    procedure SetETag(NewETag: Text[50])
    begin
        if this.ETag = NewETag then
            exit;
        this.ETag := NewETag;
    end;

    procedure GetSetCodeList(): List of [Text]
    begin
        exit(this."Set Codes".Split('|'));
    end;

    procedure TextMethods(): Text
    begin
        exit(this.ETag.ToUpper() + '|' + Format(this.ETag.Contains('b')) + '|' + this.ETag.Replace('b', 'X') + '|' + this.ETag.Substring(2) + '|' + Format(this.ETag.EndsWith('c')) + '|' + Format(StrLen(this.ETag)));
    end;

    procedure ValidateQty(NewQty: Decimal)
    begin
        this.Validate(Qty, NewQty);
    end;

    procedure AssignAndValidateQty(NewQty: Decimal)
    begin
        this.Qty := NewQty;
        this.Validate(this.Qty);
    end;

    procedure TestETag(Expected: Text)
    begin
        this.TestField(ETag, Expected);
    end;

    procedure TestETagFilled()
    begin
        this.TestField(ETag);
    end;

    procedure AddQty(Delta: Decimal)
    begin
        this.Qty += Delta;
        this.Qty := this.Qty * 2;
    end;

    procedure StoreETag(NewETag: Text[50])
    begin
        this.ETag := NewETag;
        this.Modify();
    end;

    procedure InsertWithThis(NewNo: Code[20]; NewETag: Text[50])
    begin
        this.Init();
        this."No." := NewNo;
        this.ETag := NewETag;
        this.Insert();
    end;

    procedure SameAsRec(): Boolean
    begin
        exit((this.ETag = Rec.ETag) and (this.Qty = Qty));
    end;
}

codeunit 90491 "LT UP This Codeunit"
{
    var
        Counter: Integer;
        Tag: Text;

    procedure Bump(): Integer
    begin
        this.Counter += 1;
        this.Tag := 'bumped' + Format(this.Counter);
        exit(this.Counter);
    end;

    procedure ViaThisProc(): Text
    begin
        this.Bump();
        exit(this.Tag + '|' + Format(this.GetCounter()));
    end;

    procedure GetCounter(): Integer
    begin
        exit(this.Counter);
    end;

    procedure PassThis(var Other: Codeunit "LT UP This Codeunit")
    begin
        Other := this;
        Other.Bump();
    end;
}

codeunit 90492 "LT UP This Field Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure UP_This_FieldAssignAndRead()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT UP This Row";
    begin
        Row.SetETag('abc');
        Observer.Observe('after first', Row.ETag);
        Row.SetETag('abc');
        Observer.Observe('after same', Row.ETag);
        Row.SetETag('xyz');
        Observer.Observe('after change', Row.ETag);
        Observer.Observe('same as rec', Format(Row.SameAsRec()));
        Observer.Expect('after first', 'abc');
        Observer.Expect('after same', 'abc');
        Observer.Expect('after change', 'xyz');
        Observer.Expect('same as rec', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure UP_This_MethodOnTextField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT UP This Row";
        Codes: List of [Text];
    begin
        Row."Set Codes" := 'A|B|C';
        Codes := Row.GetSetCodeList();
        Observer.Observe('count', Format(Codes.Count()));
        Observer.Observe('second', Codes.Get(2));
        Row."Set Codes" := '';
        Observer.Observe('empty count', Format(Row.GetSetCodeList().Count()));
        Row.ETag := 'abc';
        Observer.Observe('text methods', Row.TextMethods());
        Observer.Expect('count', '3');
        Observer.Expect('second', 'B');
        Observer.Expect('empty count', '1');
        Observer.Expect('text methods', 'ABC|Yes|aXc|bc|Yes|3');
        Observer.Verify();
    end;

    [Test]
    procedure UP_This_ValidateTestFieldCompound()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT UP This Row";
    begin
        Row.Qty := 3;
        Row.ValidateQty(5);
        Observer.Observe('validate qty', Format(Row.Qty, 0, 9));
        Observer.Observe('validate trail', Row.Trail);
        Row.Trail := '';
        Row.AssignAndValidateQty(7);
        Observer.Observe('assign+validate trail', Row.Trail);
        Row.AddQty(1);
        Observer.Observe('compound qty', Format(Row.Qty, 0, 9));
        Row.ETag := '';
        asserterror Row.TestETagFilled();
        Observer.Observe('testfield empty', GetLastErrorText());
        Row.ETag := 'a';
        Row.TestETagFilled();
        asserterror Row.TestETag('b');
        Observer.Observe('testfield value', GetLastErrorText());
        Row.TestETag('a');
        Observer.Expect('validate qty', '5');
        Observer.Expect('validate trail', 'Q(5;old=3)');
        Observer.Expect('assign+validate trail', 'Q(7;old=5)');
        Observer.Expect('compound qty', '16');
        Observer.Expect('testfield empty', 'ETag must have a value in LT UP This Row: No.=. It cannot be zero or empty.');
        Observer.Expect('testfield value', 'ETag must be equal to ''b''  in LT UP This Row: No.=. The current value is ''a''.');
        Observer.Verify();
    end;

    [Test]
    procedure UP_This_ValueStoredAfterModify()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT UP This Row";
        Stored: Record "LT UP This Row";
    begin
        Row.DeleteAll();
        Row.InsertWithThis('A', 'first');
        Stored.Get('A');
        Observer.Observe('after insert', Stored.ETag);
        Row.StoreETag('second');
        Stored.Get('A');
        Observer.Observe('after modify', Stored.ETag);
        Observer.Observe('row in memory', Row.ETag);
        Row.DeleteAll();
        Observer.Expect('after insert', 'first');
        Observer.Expect('after modify', 'second');
        Observer.Expect('row in memory', 'second');
        Observer.Verify();
    end;

    [Test]
    procedure UP_This_InCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Lib: Codeunit "LT UP This Codeunit";
        Other: Codeunit "LT UP This Codeunit";
    begin
        Observer.Observe('bump', Format(Lib.Bump()));
        Observer.Observe('bump again', Format(Lib.Bump()));
        Observer.Observe('via this proc', Lib.ViaThisProc());
        Lib.PassThis(Other);
        Observer.Observe('other counter', Format(Other.GetCounter()));
        Observer.Observe('lib counter', Format(Lib.GetCounter()));
        Observer.Expect('bump', '1');
        Observer.Expect('bump again', '2');
        Observer.Expect('via this proc', 'bumped3|3');
        Observer.Expect('other counter', '4');
        Observer.Expect('lib counter', '4');
        Observer.Verify();
    end;
}
