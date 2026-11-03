// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-transferfields-method
// Scope: in-scope
// Fixtures used: self-contained tables 72007 to 72011, test codeunit 72005
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.TransferFields(From) and (From, InitPrimaryKeyFields) between the same table and tables with the same, different, extra and missing fields (matched by field number), with
// type differences (Integer to Decimal, Text to Code, Text length, Option to Integer, Code to Text), the primary key, triggers (none), and the errors for incompatible field types.
// BC versions: 29 (27 and 28 by CI)

table 72007 "LT RcB Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Dec; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B,C; }
        field(5; Cod; Code[10]) { }
        field(6; Dt; Date) { }
        field(7; OnlySrc; Integer) { }
        field(8; Flag; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 72008 "LT RcB Dst Same"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Dec; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B,C; }
        field(5; Cod; Code[10]) { }
        field(6; Dt; Date) { }
        field(7; OnlyDst; Integer) { InitValue = 9; }
        field(8; Flag; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 72009 "LT RcB Dst Types"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[5]) { }
        field(3; Dec; Integer) { }
        field(4; Opt; Integer) { }
        field(5; Cod; Text[20]) { }
        field(6; Dt; Date) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 72010 "LT RcB Dst Wide"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[100]) { }
        field(3; Dec; BigInteger) { }
        field(4; Opt; Option) { OptionMembers = A,B,C,D; }
        field(5; Cod; Code[3]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 72011 "LT RcB Dst Otherkey"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Other; Code[10]) { }
        field(2; Txt; Text[30]) { }
        field(3; Dec; Decimal) { }
    }

    keys
    {
        key(PK; Other) { Clustered = true; }
    }
}

codeunit 72005 "LT RcB Transfer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Fill(var Src: Record "LT RcB Src")
    begin
        Src.Init();
        Src.Id := 5;
        Src.Txt := 'text';
        Src.Dec := 12.5;
        Src.Opt := Src.Opt::C;
        Src.Cod := 'CODE';
        Src.Dt := 20250301D;
        Src.OnlySrc := 77;
        Src.Flag := true;
    end;

    [Test]
    procedure Transfer_SameLayout_WithKey()
    var
        Src: Record "LT RcB Src";
        Dst: Record "LT RcB Dst Same";
        Observer: Codeunit "Probe Observer";
    begin
        Fill(Src);
        Dst.TransferFields(Src);
        Observer.Observe('Id', Format(Dst.Id));
        Observer.Observe('Txt', Dst.Txt);
        Observer.Observe('Dec', Format(Dst.Dec));
        Observer.Observe('Opt', Format(Dst.Opt));
        Observer.Observe('Cod', Dst.Cod);
        Observer.Observe('Dt', Format(Dst.Dt, 0, 9));
        Observer.Observe('Flag', Format(Dst.Flag));
        Observer.Observe('OnlyDst', Format(Dst.OnlyDst));
        Observer.Expect('Id', '5');
        Observer.Expect('Txt', 'text');
        Observer.Expect('Dec', '12.5');
        Observer.Expect('Opt', 'C');
        Observer.Expect('Cod', 'CODE');
        Observer.Expect('Dt', '2025-03-01');
        Observer.Expect('Flag', 'Yes');
        Observer.Expect('OnlyDst', '77');
        Observer.Verify();
    end;

    [Test]
    procedure Transfer_WithoutKey()
    var
        Src: Record "LT RcB Src";
        Dst: Record "LT RcB Dst Same";
        Observer: Codeunit "Probe Observer";
    begin
        Fill(Src);
        Dst.Id := 99;
        Dst.TransferFields(Src, false);
        Observer.Observe('Id kept', Format(Dst.Id));
        Observer.Observe('Txt', Dst.Txt);
        Observer.Observe('Dec', Format(Dst.Dec));
        Dst.Init();
        Dst.TransferFields(Src, false);
        Observer.Observe('Id after init', Format(Dst.Id));
        Observer.Expect('Id kept', '99');
        Observer.Expect('Txt', 'text');
        Observer.Expect('Dec', '12.5');
        Observer.Expect('Id after init', '99');
        Observer.Verify();
    end;

    [Test]
    procedure Transfer_WithKeyExplicitTrue()
    var
        Src: Record "LT RcB Src";
        Dst: Record "LT RcB Dst Same";
        Observer: Codeunit "Probe Observer";
    begin
        Fill(Src);
        Dst.Id := 99;
        Dst.TransferFields(Src, true);
        Observer.Observe('Id', Format(Dst.Id));
        Observer.Expect('Id', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Transfer_OtherFieldsOfDst()
    var
        Src: Record "LT RcB Src";
        Dst: Record "LT RcB Dst Same";
        Observer: Codeunit "Probe Observer";
    begin
        Fill(Src);
        Dst.OnlyDst := 55;
        Dst.TransferFields(Src);
        Observer.Observe('OnlyDst after transfer', Format(Dst.OnlyDst));
        Dst.Init();
        Dst.OnlyDst := 55;
        Dst.TransferFields(Src, false);
        Observer.Observe('OnlyDst after transfer no key', Format(Dst.OnlyDst));
        Observer.Expect('OnlyDst after transfer', '77');
        Observer.Expect('OnlyDst after transfer no key', '77');
        Observer.Verify();
    end;

    [Test]
    procedure Transfer_SameTable()
    var
        A: Record "LT RcB Src";
        B: Record "LT RcB Src";
        Observer: Codeunit "Probe Observer";
    begin
        Fill(A);
        B.Id := 1;
        B.OnlySrc := 3;
        B.TransferFields(A);
        Observer.Observe('Id', Format(B.Id));
        Observer.Observe('OnlySrc', Format(B.OnlySrc));
        B.Id := 2;
        B.Txt := 'changed';
        B.TransferFields(A, false);
        Observer.Observe('Id no key', Format(B.Id));
        Observer.Observe('Txt', B.Txt);
        Observer.Expect('Id', '5');
        Observer.Expect('OnlySrc', '77');
        Observer.Expect('Id no key', '2');
        Observer.Expect('Txt', 'text');
        Observer.Verify();
    end;

    [Test]
    procedure Transfer_InsertAfter()
    var
        Src: Record "LT RcB Src";
        Dst: Record "LT RcB Dst Same";
        Observer: Codeunit "Probe Observer";
    begin
        Dst.DeleteAll();
        Fill(Src);
        Dst.TransferFields(Src);
        Dst.Insert();
        Dst.Get(5);
        Observer.Observe('inserted', Dst.Txt);
        Src.Id := 6;
        Dst.TransferFields(Src, false);
        Observer.Observe('id after no key', Format(Dst.Id));
        Dst.Modify();
        Observer.Observe('count', Format(Dst.Count()));
        Dst.Get(5);
        Observer.Observe('row 5 txt', Dst.Txt);
        Observer.Expect('inserted', 'text');
        Observer.Expect('id after no key', '5');
        Observer.Expect('count', '1');
        Observer.Expect('row 5 txt', 'text');
        Observer.Verify();
    end;

    [Test]
    procedure Transfer_TypeDifferences_Narrowing()
    var
        Src: Record "LT RcB Src";
        Dst: Record "LT RcB Dst Types";
        Observer: Codeunit "Probe Observer";
    begin
        Fill(Src);
        Src.Dec := 7;
        Src.Txt := 'toolong';
        asserterror Dst.TransferFields(Src);
        Observer.ObserveError('text too long');
        Src.Txt := 'abcde';
        asserterror Dst.TransferFields(Src);
        Observer.ObserveError('af255');
        Observer.Observe('Txt fits', Dst.Txt);
        Observer.Observe('Dec to Integer', Format(Dst.Dec));
        Observer.Observe('Opt to Integer', Format(Dst.Opt));
        Observer.Observe('Cod to Text', Dst.Cod);
        Observer.Expect('text too long|text', 'The contents of the Txt field cannot be copied to the Txt field because the size of the Txt field is too small.\\Type: Text5 <-- Text30\Field: Txt <-- Txt\Table: LT RcB Dst Types <-- LT RcB Src');
        Observer.Expect('text too long|code', 'DB:TypeMisMatch');
        Observer.Expect('af255|text', 'The following fields must have the same type:\\Field: Dec <-- Dec\Table: LT RcB Dst Types <-- LT RcB Src\Type: Integer <-- Decimal');
        Observer.Expect('af255|code', 'DB:TypeMisMatch');
        Observer.Expect('Txt fits', 'abcde');
        Observer.Expect('Dec to Integer', '0');
        Observer.Expect('Opt to Integer', '0');
        Observer.Expect('Cod to Text', '');
        Observer.Verify();
    end;

    [Test]
    procedure Transfer_TypeDifferences_DecimalFraction()
    var
        Src: Record "LT RcB Src";
        Dst: Record "LT RcB Dst Types";
        Observer: Codeunit "Probe Observer";
    begin
        Fill(Src);
        Src.Txt := 'ab';
        asserterror Dst.TransferFields(Src);
        Observer.ObserveError('fraction to integer');
        Src.Dec := -3;
        asserterror Dst.TransferFields(Src);
        Observer.ObserveError('af276');
        Observer.Observe('negative', Format(Dst.Dec));
        Src.Dec := 2147483648.0;
        asserterror Dst.TransferFields(Src);
        Observer.ObserveError('overflow');
        Observer.Expect('fraction to integer|text', 'The following fields must have the same type:\\Field: Dec <-- Dec\Table: LT RcB Dst Types <-- LT RcB Src\Type: Integer <-- Decimal');
        Observer.Expect('fraction to integer|code', 'DB:TypeMisMatch');
        Observer.Expect('af276|text', 'The following fields must have the same type:\\Field: Dec <-- Dec\Table: LT RcB Dst Types <-- LT RcB Src\Type: Integer <-- Decimal');
        Observer.Expect('af276|code', 'DB:TypeMisMatch');
        Observer.Expect('negative', '0');
        Observer.Expect('overflow|text', 'The following fields must have the same type:\\Field: Dec <-- Dec\Table: LT RcB Dst Types <-- LT RcB Src\Type: Integer <-- Decimal');
        Observer.Expect('overflow|code', 'DB:TypeMisMatch');
        Observer.Verify();
    end;

    [Test]
    procedure Transfer_TypeDifferences_Widening()
    var
        Src: Record "LT RcB Src";
        Dst: Record "LT RcB Dst Wide";
        Observer: Codeunit "Probe Observer";
    begin
        Fill(Src);
        Src.Dec := 8;
        Src.Cod := 'ABC';
        asserterror Dst.TransferFields(Src);
        Observer.ObserveError('af295');
        Observer.Observe('Txt', Dst.Txt);
        Observer.Observe('Dec', Format(Dst.Dec));
        Observer.Observe('Opt', Format(Dst.Opt));
        Observer.Observe('Cod', Dst.Cod);
        Src.Cod := 'ABCD';
        asserterror Dst.TransferFields(Src);
        Observer.ObserveError('code too long');
        Observer.Expect('af295|text', 'The following fields must have the same type:\\Field: Dec <-- Dec\Table: LT RcB Dst Wide <-- LT RcB Src\Type: BigInteger <-- Decimal');
        Observer.Expect('af295|code', 'DB:TypeMisMatch');
        Observer.Expect('Txt', 'text');
        Observer.Expect('Dec', '0');
        Observer.Expect('Opt', 'A');
        Observer.Expect('Cod', '');
        Observer.Expect('code too long|text', 'The following fields must have the same type:\\Field: Dec <-- Dec\Table: LT RcB Dst Wide <-- LT RcB Src\Type: BigInteger <-- Decimal');
        Observer.Expect('code too long|code', 'DB:TypeMisMatch');
        Observer.Verify();
    end;

    [Test]
    procedure Transfer_DifferentPrimaryKey()
    var
        Src: Record "LT RcB Src";
        Dst: Record "LT RcB Dst Otherkey";
        Observer: Codeunit "Probe Observer";
    begin
        Fill(Src);
        Dst.Other := 'KEEP';
        asserterror Dst.TransferFields(Src);
        Observer.ObserveError('af316');
        Observer.Observe('other', Dst.Other);
        Observer.Observe('Txt', Dst.Txt);
        Observer.Observe('Dec', Format(Dst.Dec));
        Dst.Other := 'KEEP2';
        Dst.TransferFields(Src, false);
        Observer.Observe('other no key', Dst.Other);
        Observer.Observe('Txt no key', Dst.Txt);
        Observer.Expect('af316|text', 'The following fields must have the same type:\\Field: Other <-- Id\Table: LT RcB Dst Otherkey <-- LT RcB Src\Type: Code <-- Integer');
        Observer.Expect('af316|code', 'DB:TypeMisMatch');
        Observer.Expect('other', 'KEEP');
        Observer.Expect('Txt', '');
        Observer.Expect('Dec', '0');
        Observer.Expect('other no key', 'KEEP2');
        Observer.Expect('Txt no key', 'text');
        Observer.Verify();
    end;

    [Test]
    procedure Transfer_Fields_Count_Are_Set()
    var
        Src: Record "LT RcB Src";
        Dst: Record "LT RcB Dst Same";
        Observer: Codeunit "Probe Observer";
    begin
        Src.Init();
        Dst.Id := 4;
        Dst.Txt := 'before';
        Dst.TransferFields(Src);
        Observer.Observe('Id from init', Format(Dst.Id));
        Observer.Observe('Txt blanked', '[' + Dst.Txt + ']');
        Observer.Expect('Id from init', '0');
        Observer.Expect('Txt blanked', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Transfer_IgnoresFiltersAndTriggers()
    var
        Src: Record "LT RcB Src";
        Dst: Record "LT RcB Dst Same";
        Observer: Codeunit "Probe Observer";
    begin
        Fill(Src);
        Dst.SetRange(Id, 1000);
        Dst.TransferFields(Src);
        Observer.Observe('Id', Format(Dst.Id));
        Observer.Observe('filter kept', Dst.GetFilter(Id));
        Src.SetRange(Id, 1);
        Dst.TransferFields(Src);
        Observer.Observe('src filter', Format(Dst.Id));
        Observer.Expect('Id', '5');
        Observer.Expect('filter kept', '1000');
        Observer.Expect('src filter', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Transfer_TemporaryTarget()
    var
        Src: Record "LT RcB Src";
        Dst: Record "LT RcB Dst Same" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        Fill(Src);
        Dst.TransferFields(Src);
        Dst.Insert();
        Observer.Observe('temp count', Format(Dst.Count()));
        Observer.Observe('temp txt', Dst.Txt);
        Observer.Expect('temp count', '1');
        Observer.Expect('temp txt', 'text');
        Observer.Verify();
    end;

    // Corpus issue 668 items 21 and 31 (writer BQ). Fixtures: record/lt-bq-odd-leads/BqObjects.al.
    local procedure BqBlobText(var Dst: Record "LT BQ Blob Dst"): Text
    var
        InS: InStream;
        Value: Text;
    begin
        if not Dst.Data.HasValue() then
            exit('empty');
        Dst.Data.CreateInStream(InS);
        InS.ReadText(Value);
        exit('[' + Value + ']');
    end;

    local procedure BqStoredBlob(Id: Integer): Text
    var
        Dst: Record "LT BQ Blob Dst";
    begin
        Dst.Get(Id);
        Dst.CalcFields(Data);
        exit(BqBlobText(Dst));
    end;

    // TransferFields with a Blob field, with and without CalcFields on the source (microsoft/AL issue 5550), and a plain assignment.
    [Test]
    procedure Transfer_Blob_Field_BQ()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BQ Blob Src";
        Read: Record "LT BQ Blob Src";
        Copied: Record "LT BQ Blob Src";
        Dst: Record "LT BQ Blob Dst";
        OutS: OutStream;
    begin
        Src.DeleteAll();
        Dst.DeleteAll();
        Src.Init();
        Src.Id := 1;
        Src.Txt := 'src';
        Src.Data.CreateOutStream(OutS);
        OutS.WriteText('payload');
        Src.Insert();

        Dst.Init();
        Dst.TransferFields(Src);
        Observer.Observe('fromInsertedVariable', BqBlobText(Dst));
        Dst.Id := 1;
        Dst.Insert();
        Observer.Observe('fromInsertedVariableStored', BqStoredBlob(1));

        Read.Get(1);
        Observer.Observe('readHasValue', Format(Read.Data.HasValue()));
        Dst.Init();
        Dst.TransferFields(Read);
        Observer.Observe('withoutCalcFields', BqBlobText(Dst));
        Dst.Id := 2;
        Dst.Insert();
        Observer.Observe('withoutCalcFieldsStored', BqStoredBlob(2));

        Read.Get(1);
        Read.CalcFields(Data);
        Dst.Init();
        Dst.TransferFields(Read);
        Observer.Observe('withCalcFields', BqBlobText(Dst));
        Dst.Id := 3;
        Dst.Insert();
        Observer.Observe('withCalcFieldsStored', BqStoredBlob(3));

        Read.Get(1);
        Copied := Read;
        Observer.Observe('assignmentHasValue', Format(Copied.Data.HasValue()));
        Copied.CalcFields(Data);
        Observer.Observe('assignmentAfterCalcFields', Format(Copied.Data.HasValue()));
        Observer.Expect('fromInsertedVariable', '[payload]');
        Observer.Expect('fromInsertedVariableStored', '[payload]');
        Observer.Expect('readHasValue', 'Yes');
        Observer.Expect('withoutCalcFields', 'empty');
        Observer.Expect('withoutCalcFieldsStored', 'empty');
        Observer.Expect('withCalcFields', '[payload]');
        Observer.Expect('withCalcFieldsStored', '[payload]');
        Observer.Expect('assignmentHasValue', 'Yes');
        Observer.Expect('assignmentAfterCalcFields', 'Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure BqTryTransferCustomer(var Dst: Record "LT BQ Cust Dst"; var Customer: Record Customer; Skip: Boolean)
    begin
        if Skip then
            Dst.TransferFields(Customer, true, true)
        else
            Dst.TransferFields(Customer);
    end;

    local procedure BqCustomerOutcome(Address: Text[100]; Skip: Boolean): Text
    var
        Customer: Record Customer;
        Dst: Record "LT BQ Cust Dst";
        Result: Text;
    begin
        Customer.Init();
        Customer."No." := 'BQ1';
        Customer.Name := 'Bq Name';
        Customer."Search Name" := 'BQ SEARCH';
        Customer.Address := Address;
        Dst.Init();
        if BqTryTransferCustomer(Dst, Customer, Skip) then
            exit('ok no=' + Dst."No." + ' name=' + Format(Dst.Name) + ' search=' + Dst."Search Name" + ' address=' + Dst.Address);
        Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    // TransferFields from a Base Application table (Customer) into an own table whose fields of the same numbers have other types: field 2
    // Integer against Text[100], field 3 Text[100] against Code[100], field 5 Text[10] against Text[100] (docs: a type mismatch between
    // fields of different apps).
    [Test]
    procedure Transfer_From_Another_Apps_Table_Type_Mismatch_BQ()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('default', BqCustomerOutcome('Short', false));
        Observer.Observe('skipNotMatching', BqCustomerOutcome('Short', true));
        Observer.Observe('longAddressSkip', BqCustomerOutcome('An address longer than ten', true));
        Observer.Expect('default', 'ok no=BQ1 name=0 search=BQ SEARCH address=Short');
        Observer.Expect('skipNotMatching', 'ok no=BQ1 name=0 search=BQ SEARCH address=Short');
        Observer.Expect('longAddressSkip', 'ok no=BQ1 name=0 search=BQ SEARCH address=');
        Observer.Verify();
    end;
}
