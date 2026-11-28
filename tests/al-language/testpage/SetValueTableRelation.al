// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-setvalue-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 73390 and 73391, pages 73390..73394, test codeunit 73395
// Probe (AL Runner issue 9336): TestPage <control>.SetValue(Text) on a page control with a TableRelation. Related table
//   "LT TSV Book" (key Code[10]): ABC (Name Shared, Active), ABD (Name Shared, Active), MNO (Name Unique Name, Active) and
//   XYZ (Name Hidden, not Active).
//   Pages: 73390 a Text[10] page variable related to the table (the issue's shape); 73391 a Code[10] page variable; 73392 a Text[10]
//   variable related with a filter (WHERE Active = true); 73393 a Text[30] variable related to the non-key field Name; 73394 a
//   Card on "LT TSV Host" whose Code[10] field "Book Code" is related to the table (a table field, with an OnValidate trigger).
//   Each variable control has an OnValidate trigger that counts its runs into a second control (Validated); the host table
//   counts into a field.
//   Each cell opens the page with OpenEdit, calls SetValue inside a TryFunction and records: set = "ok" or "E: <GetLastErrorText> |
//   <GetLastErrorCode>"; value = the control's Value() afterwards; validated = the trigger count. The host cells also record the
//   stored record after TestPage.Close(): stored = "<Book Code> validated=<count>".
//   Measured on a local BC 29.0.54011.57673 service tier (Linux, W1, en-US session) on 2026-11-28 with an invented app holding
//   these objects (AL 18.0.43.1464, run by al runtests of AL tool 18.1.43.24897); the values are those readings, turned into
//   Expect and Verify by convert.py verbatim. This pull request's CI checks them on 27.5, 28.5 and 29.0; a version difference
//   gets a version guard.
//   Facts (BC 29.0.54011.57673):
//   - A variable related to the key (Text[10] and Code[10] alike) takes the related row's stored key: 'ABC' and 'abc' give ABC,
//     the prefix 'MN' gives MNO, and the prefix 'AB' of two keys gives the first, ABC. OnValidate runs once.
//   - No row ('ZZZ'): SetValue fails with "Validation error for Field: BookCtl,  Message = 'The LT TSV Book does not exist.
//     Identification fields and values: Code='ZZZ''" (TestValidation, two spaces after the comma); the control reads empty and
//     OnValidate does not run.
//   - With the filter Active = true: 'MNO' (inside) gives MNO; 'XYZ' (an exact key outside the filter) is taken too, XYZ; the
//     prefix 'XY' of a row outside the filter fails with the does-not-exist error for Code='XY'.
//   - Related to the non-key field Name: every SetValue fails with "Validation error for Field: BookCtl,  Message = 'The
//     following field must be included into the table's primary key: Field: Name Table: LT TSV Book'" (TestValidation).
//   - A table field related to the key behaves like the variable (ABC, ABC, MNO; the table's OnValidate runs once; the record
//     stores the value after Close), but no row fails with "Validation error for Field: BookCtl,  Message = 'The field Book Code
//     of table LT TSV Host contains a value (ZZZ) that cannot be found in the related table (LT TSV Book). (Select Refresh to
//     discard errors)'" (TestValidation), and the record keeps an empty Book Code.
// BC versions: 27, 28, 29 by CI
table 73390 "LT TSV Book"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Active; Boolean) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 73391 "LT TSV Host"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Book Code"; Code[10])
        {
            TableRelation = "LT TSV Book";

            trigger OnValidate()
            begin
                ValidateCount += 1;
            end;
        }
        field(3; ValidateCount; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 73390 "LT TSV Text Var"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(BookCtl; BookCode)
            {
                ApplicationArea = All;
                Caption = 'Book Code';
                TableRelation = "LT TSV Book";

                trigger OnValidate()
                begin
                    Validated += 1;
                end;
            }
            field(ValidatedCtl; Validated) { ApplicationArea = All; Editable = false; }
        }
    }

    var
        BookCode: Text[10];
        Validated: Integer;
}

page 73391 "LT TSV Code Var"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(BookCtl; BookCode)
            {
                ApplicationArea = All;
                Caption = 'Book Code';
                TableRelation = "LT TSV Book";

                trigger OnValidate()
                begin
                    Validated += 1;
                end;
            }
            field(ValidatedCtl; Validated) { ApplicationArea = All; Editable = false; }
        }
    }

    var
        BookCode: Code[10];
        Validated: Integer;
}

page 73392 "LT TSV Filtered Var"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(BookCtl; BookCode)
            {
                ApplicationArea = All;
                Caption = 'Active Book Code';
                TableRelation = "LT TSV Book" where(Active = const(true));

                trigger OnValidate()
                begin
                    Validated += 1;
                end;
            }
            field(ValidatedCtl; Validated) { ApplicationArea = All; Editable = false; }
        }
    }

    var
        BookCode: Text[10];
        Validated: Integer;
}

page 73393 "LT TSV Name Var"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(BookCtl; BookName)
            {
                ApplicationArea = All;
                Caption = 'Book Name';
                TableRelation = "LT TSV Book".Name;

                trigger OnValidate()
                begin
                    Validated += 1;
                end;
            }
            field(ValidatedCtl; Validated) { ApplicationArea = All; Editable = false; }
        }
    }

    var
        BookName: Text[30];
        Validated: Integer;
}

page 73394 "LT TSV Host Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT TSV Host";

    layout
    {
        area(Content)
        {
            field(BookCtl; Rec."Book Code") { ApplicationArea = All; }
            field(ValidatedCtl; Rec.ValidateCount) { ApplicationArea = All; Editable = false; }
        }
    }
}

codeunit 73395 "LT TSV SetValue Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Book: Record "LT TSV Book";
        Host: Record "LT TSV Host";
    begin
        Book.DeleteAll();
        Host.DeleteAll();
        AddBook('ABC', 'Shared', true);
        AddBook('ABD', 'Shared', true);
        AddBook('MNO', 'Unique Name', true);
        AddBook('XYZ', 'Hidden', false);
        Host.Init();
        Host.Id := 1;
        Host.Insert();
    end;

    local procedure AddBook(C: Code[10]; N: Text[30]; A: Boolean)
    var
        Book: Record "LT TSV Book";
    begin
        Book.Init();
        Book."Code" := C;
        Book.Name := N;
        Book.Active := A;
        Book.Insert();
    end;

    local procedure Outcome(Ok: Boolean): Text
    var
        T: Text;
    begin
        if Ok then
            exit('ok');
        T := 'E: ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        ClearLastError();
        exit(T);
    end;

    [TryFunction]
    local procedure TrySetText(var TP: TestPage "LT TSV Text Var"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetCode(var TP: TestPage "LT TSV Code Var"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetFiltered(var TP: TestPage "LT TSV Filtered Var"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetName(var TP: TestPage "LT TSV Name Var"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetHost(var TP: TestPage "LT TSV Host Card"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    local procedure TextVar(var Observer: Codeunit "Probe Observer"; Typed: Text)
    var
        TP: TestPage "LT TSV Text Var";
    begin
        Seed();
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetText(TP, Typed)));
        Observer.Observe('value', TP.BookCtl.Value());
        Observer.Observe('validated', TP.ValidatedCtl.Value());
        TP.Close();
    end;

    local procedure CodeVar(var Observer: Codeunit "Probe Observer"; Typed: Text)
    var
        TP: TestPage "LT TSV Code Var";
    begin
        Seed();
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetCode(TP, Typed)));
        Observer.Observe('value', TP.BookCtl.Value());
        Observer.Observe('validated', TP.ValidatedCtl.Value());
        TP.Close();
    end;

    local procedure FilteredVar(var Observer: Codeunit "Probe Observer"; Typed: Text)
    var
        TP: TestPage "LT TSV Filtered Var";
    begin
        Seed();
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetFiltered(TP, Typed)));
        Observer.Observe('value', TP.BookCtl.Value());
        Observer.Observe('validated', TP.ValidatedCtl.Value());
        TP.Close();
    end;

    local procedure NameVar(var Observer: Codeunit "Probe Observer"; Typed: Text)
    var
        TP: TestPage "LT TSV Name Var";
    begin
        Seed();
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetName(TP, Typed)));
        Observer.Observe('value', TP.BookCtl.Value());
        Observer.Observe('validated', TP.ValidatedCtl.Value());
        TP.Close();
    end;

    local procedure HostField(var Observer: Codeunit "Probe Observer"; Typed: Text)
    var
        Host: Record "LT TSV Host";
        TP: TestPage "LT TSV Host Card";
    begin
        Seed();
        Host.Get(1);
        TP.OpenEdit();
        TP.GoToRecord(Host);
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetHost(TP, Typed)));
        Observer.Observe('value', TP.BookCtl.Value());
        Observer.Observe('validated', TP.ValidatedCtl.Value());
        TP.Close();
        Host.Get(1);
        Observer.Observe('stored', StrSubstNo('%1 validated=%2', Host."Book Code", Host.ValidateCount));
    end;

    // Text[10] variable related to the key: the issue's four cells and a prefix of two keys.
    [Test]
    procedure TextVar_Exact()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TextVar(Observer, 'ABC');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'ABC');
        Observer.Expect('validated', '1');
        Observer.Verify();
    end;

    [Test]
    procedure TextVar_LowerCase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TextVar(Observer, 'abc');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'ABC');
        Observer.Expect('validated', '1');
        Observer.Verify();
    end;

    [Test]
    procedure TextVar_PrefixOneKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TextVar(Observer, 'MN');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'MNO');
        Observer.Expect('validated', '1');
        Observer.Verify();
    end;

    [Test]
    procedure TextVar_PrefixTwoKeys()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TextVar(Observer, 'AB');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'ABC');
        Observer.Expect('validated', '1');
        Observer.Verify();
    end;

    [Test]
    procedure TextVar_NoRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TextVar(Observer, 'ZZZ');
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The LT TSV Book does not exist. Identification fields and values: Code=''ZZZ'''' | TestValidation');
        Observer.Expect('value', '');
        Observer.Expect('validated', '0');
        Observer.Verify();
    end;

    // Code[10] variable related to the key.
    [Test]
    procedure CodeVar_LowerCase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CodeVar(Observer, 'abc');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'ABC');
        Observer.Expect('validated', '1');
        Observer.Verify();
    end;

    [Test]
    procedure CodeVar_PrefixOneKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CodeVar(Observer, 'mn');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'MNO');
        Observer.Expect('validated', '1');
        Observer.Verify();
    end;

    [Test]
    procedure CodeVar_NoRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CodeVar(Observer, 'ZZZ');
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The LT TSV Book does not exist. Identification fields and values: Code=''ZZZ'''' | TestValidation');
        Observer.Expect('value', '');
        Observer.Expect('validated', '0');
        Observer.Verify();
    end;

    // Text[10] variable related with a filter (Active = true): a row inside, a row outside, a prefix of a row outside.
    [Test]
    procedure Filtered_Inside()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilteredVar(Observer, 'MNO');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'MNO');
        Observer.Expect('validated', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_Outside()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilteredVar(Observer, 'XYZ');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'XYZ');
        Observer.Expect('validated', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_PrefixOutside()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilteredVar(Observer, 'XY');
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The LT TSV Book does not exist. Identification fields and values: Code=''XY'''' | TestValidation');
        Observer.Expect('value', '');
        Observer.Expect('validated', '0');
        Observer.Verify();
    end;

    // Text[30] variable related to the non-key field Name: exact, other case, prefix, a value of two rows, no row.
    [Test]
    procedure NameVar_Exact()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NameVar(Observer, 'Unique Name');
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The following field must be included into the table''s primary key: Field: Name Table: LT TSV Book'' | TestValidation');
        Observer.Expect('value', '');
        Observer.Expect('validated', '0');
        Observer.Verify();
    end;

    [Test]
    procedure NameVar_LowerCase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NameVar(Observer, 'unique name');
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The following field must be included into the table''s primary key: Field: Name Table: LT TSV Book'' | TestValidation');
        Observer.Expect('value', '');
        Observer.Expect('validated', '0');
        Observer.Verify();
    end;

    [Test]
    procedure NameVar_Prefix()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NameVar(Observer, 'Uni');
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The following field must be included into the table''s primary key: Field: Name Table: LT TSV Book'' | TestValidation');
        Observer.Expect('value', '');
        Observer.Expect('validated', '0');
        Observer.Verify();
    end;

    [Test]
    procedure NameVar_TwoRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NameVar(Observer, 'Shared');
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The following field must be included into the table''s primary key: Field: Name Table: LT TSV Book'' | TestValidation');
        Observer.Expect('value', '');
        Observer.Expect('validated', '0');
        Observer.Verify();
    end;

    [Test]
    procedure NameVar_NoRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NameVar(Observer, 'Nope');
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The following field must be included into the table''s primary key: Field: Name Table: LT TSV Book'' | TestValidation');
        Observer.Expect('value', '');
        Observer.Expect('validated', '0');
        Observer.Verify();
    end;

    // A Code[10] table field related to the key, on a Card over the host record.
    [Test]
    procedure HostField_Exact()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HostField(Observer, 'ABC');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'ABC');
        Observer.Expect('validated', '1');
        Observer.Expect('stored', 'ABC validated=1');
        Observer.Verify();
    end;

    [Test]
    procedure HostField_LowerCase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HostField(Observer, 'abc');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'ABC');
        Observer.Expect('validated', '1');
        Observer.Expect('stored', 'ABC validated=1');
        Observer.Verify();
    end;

    [Test]
    procedure HostField_PrefixOneKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HostField(Observer, 'MN');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'MNO');
        Observer.Expect('validated', '1');
        Observer.Expect('stored', 'MNO validated=1');
        Observer.Verify();
    end;

    [Test]
    procedure HostField_NoRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HostField(Observer, 'ZZZ');
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The field Book Code of table LT TSV Host contains a value (ZZZ) that cannot be found in the related table (LT TSV Book). (Select Refresh to discard errors)'' | TestValidation');
        Observer.Expect('value', '');
        Observer.Expect('validated', '0');
        Observer.Expect('stored', ' validated=0');
        Observer.Verify();
    end;
}
