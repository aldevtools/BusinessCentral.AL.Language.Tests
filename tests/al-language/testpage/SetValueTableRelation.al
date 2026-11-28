// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-setvalue-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 73390, 73391, 73396 and 73397, pages 73390..73398, report 73396, test codeunits
//   73395 and 73396
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
//   - A variable related to the key takes the related row's stored key. Text[10]: 'ABC' and 'abc' give ABC, the prefixes 'MN' and
//     'mn' give MNO, and the prefix 'AB' of two keys gives ABC, also when ABD was inserted first (key order, not insertion order).
//     Code[10]: 'ABC', 'abc' and 'AB' give ABC, 'mn' gives MNO. OnValidate runs once.
//   - No row ('ZZZ'): SetValue fails with "Validation error for Field: BookCtl,  Message = 'The LT TSV Book does not exist.
//     Identification fields and values: Code='ZZZ''" (TestValidation, two spaces after the comma); the control reads empty and
//     OnValidate does not run.
//   - With the filter Active = true: 'MNO' (inside) gives MNO; 'XYZ' (an exact key outside the filter) is taken too, XYZ; the
//     prefix 'XY' of a row outside the filter fails with the does-not-exist error for Code='XY'.
//   - Related to the non-key field Name: each of the five values typed fails with "Validation error for Field: BookCtl,  Message = 'The
//     following field must be included into the table's primary key: Field: Name Table: LT TSV Book'" (TestValidation).
//   - A table field related to the key behaves like the variable (ABC, ABC, MNO; the table's OnValidate runs once; the record
//     stores the value after Close), but no row fails with "Validation error for Field: BookCtl,  Message = 'The field Book Code
//     of table LT TSV Host contains a value (ZZZ) that cannot be found in the related table (LT TSV Book). (Select Refresh to
//     discard errors)'" (TestValidation), and the record keeps an empty Book Code.
//   Codeunit 73396 (the cells the review of corpus pull request 1646 asks for; BC 29.0.54011.57673; BC 27.5 gave the same
//   readings in every cell in this pull request's CI observe run 46134940373, both 27.5 legs alike, so one set of assertions holds
//   on every version):
//   - Only a key prefix completes: 'BC' (inside a key) and 'Unique' (the start of a Name) fail with the does-not-exist error; the
//     text shows the Code-converted value: Code='BC', Code='UNIQUE', and 'zzz' gives Code='ZZZ'.
//   - SetValue('ABC') then SetValue('ZZZ'): the second fails and the control keeps ABC (OnValidate ran once). SetValue('') is
//     taken on the Text[10] variable and on the host field (empty, OnValidate runs once); on the Name variable it fails with the
//     primary-key text.
//   - Filtered variable: 'xyz' (an exact key outside the filter, other case) is taken as typed, 'xyz', not as the stored XYZ.
//     A prefix 'XY' whose first key XYA is outside the filter and a later key XYB inside gives XYB.
//   - A table field with the filter Active = true rejects both 'XYZ' and 'XY' with 'The field Active Book Code of table LT TSV Host
//     contains a value (<v>) that cannot be found in the related table (LT TSV Book). (Select Refresh to discard errors)': the
//     filter applies to a table field, unlike the variable. 'AB' on the plain host field gives ABC.
//   - A report request page variable behaves like the page variable: 'abc' gives ABC, 'MN' gives MNO, 'ZZZ' fails with the
//     does-not-exist text.
//   - Captions: with a captioned table and key field, the variable's text is 'The Captioned Book does not exist. Identification
//     fields and values: Book No.='ZZZ'' and the field's text 'The field Captioned Book No. of table Captioned Host contains a
//     value (ZZZ) that cannot be found in the related table (Captioned Book). ...': both use the captions.
//   - A relation that names the key field ("LT TSV Book"."Code") behaves like the table relation: 'abc' gives ABC, 'mn' gives MNO.
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
        field(4; "Active Book Code"; Code[10])
        {
            TableRelation = "LT TSV Book" where(Active = const(true));

            trigger OnValidate()
            begin
                ValidateCount += 1;
            end;
        }
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
            field(ActiveBookCtl; Rec."Active Book Code") { ApplicationArea = All; }
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

// Review additions (the cells the review of corpus pull request 1646 asks for).
table 73396 "LT TSV Cap Book"
{
    Caption = 'Captioned Book';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { Caption = 'Book No.'; }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 73397 "LT TSV Cap Host"
{
    Caption = 'Captioned Host';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Cap Code"; Code[10]) { Caption = 'Captioned Book No.'; TableRelation = "LT TSV Cap Book"; }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 73396 "LT TSV Cap Var"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(BookCtl; BookCode) { ApplicationArea = All; Caption = 'Captioned Book Code'; TableRelation = "LT TSV Cap Book"; }
        }
    }

    var
        BookCode: Text[10];
}

page 73397 "LT TSV Cap Host Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT TSV Cap Host";

    layout
    {
        area(Content)
        {
            field(BookCtl; Rec."Cap Code") { ApplicationArea = All; }
        }
    }
}

page 73398 "LT TSV KeyField Var"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(BookCtl; BookCode) { ApplicationArea = All; Caption = 'Book Code'; TableRelation = "LT TSV Book"."Code"; }
        }
    }

    var
        BookCode: Text[10];
}

report 73396 "LT TSV Request"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Int; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
    }

    requestpage
    {
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
    }

    var
        BookCode: Text[10];
        Validated: Integer;
}

codeunit 73396 "LT TSV SetValue More Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        RequestTyped: Text;
        RequestReading: Text;

    // The rows of the first codeunit; AbdFirst inserts ABD before ABC; Extra adds XYA (not Active) and XYB (Active).
    local procedure Seed(AbdFirst: Boolean; Extra: Boolean)
    var
        Book: Record "LT TSV Book";
        Host: Record "LT TSV Host";
        CapBook: Record "LT TSV Cap Book";
        CapHost: Record "LT TSV Cap Host";
    begin
        Book.DeleteAll();
        Host.DeleteAll();
        CapBook.DeleteAll();
        CapHost.DeleteAll();
        if AbdFirst then begin
            AddBook('ABD', 'Shared', true);
            AddBook('ABC', 'Shared', true);
        end else begin
            AddBook('ABC', 'Shared', true);
            AddBook('ABD', 'Shared', true);
        end;
        AddBook('MNO', 'Unique Name', true);
        AddBook('XYZ', 'Hidden', false);
        if Extra then begin
            AddBook('XYA', 'Extra A', false);
            AddBook('XYB', 'Extra B', true);
        end;
        Host.Init();
        Host.Id := 1;
        Host.Insert();
        CapBook.Init();
        CapBook."Code" := 'CB1';
        CapBook.Insert();
        CapHost.Init();
        CapHost.Id := 1;
        CapHost.Insert();
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

    [TryFunction]
    local procedure TrySetHostActive(var TP: TestPage "LT TSV Host Card"; Typed: Text)
    begin
        TP.ActiveBookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetCap(var TP: TestPage "LT TSV Cap Var"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetCapHost(var TP: TestPage "LT TSV Cap Host Card"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetKeyField(var TP: TestPage "LT TSV KeyField Var"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetRequest(var RP: TestRequestPage "LT TSV Request"; Typed: Text)
    begin
        RP.BookCtl.SetValue(Typed);
    end;

    local procedure TextVar(var Observer: Codeunit "Probe Observer"; Typed: Text; AbdFirst: Boolean)
    var
        TP: TestPage "LT TSV Text Var";
    begin
        Seed(AbdFirst, false);
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
        Seed(false, false);
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetCode(TP, Typed)));
        Observer.Observe('value', TP.BookCtl.Value());
        Observer.Observe('validated', TP.ValidatedCtl.Value());
        TP.Close();
    end;

    local procedure FilteredVar(var Observer: Codeunit "Probe Observer"; Typed: Text; Extra: Boolean)
    var
        TP: TestPage "LT TSV Filtered Var";
    begin
        Seed(false, Extra);
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetFiltered(TP, Typed)));
        Observer.Observe('value', TP.BookCtl.Value());
        Observer.Observe('validated', TP.ValidatedCtl.Value());
        TP.Close();
    end;

    local procedure HostField(var Observer: Codeunit "Probe Observer"; Typed: Text; Active: Boolean)
    var
        Host: Record "LT TSV Host";
        TP: TestPage "LT TSV Host Card";
        Ok: Boolean;
    begin
        Seed(false, false);
        Host.Get(1);
        TP.OpenEdit();
        TP.GoToRecord(Host);
        ClearLastError();
        if Active then begin
            Ok := TrySetHostActive(TP, Typed);
            Observer.Observe('set', Outcome(Ok));
            Observer.Observe('value', TP.ActiveBookCtl.Value());
        end else begin
            Ok := TrySetHost(TP, Typed);
            Observer.Observe('set', Outcome(Ok));
            Observer.Observe('value', TP.BookCtl.Value());
        end;
        Observer.Observe('validated', TP.ValidatedCtl.Value());
        TP.Close();
        Host.Get(1);
        Observer.Observe('stored', StrSubstNo('Book Code=%1 Active Book Code=%2 validated=%3', Host."Book Code", Host."Active Book Code", Host.ValidateCount));
    end;

    // 1. Code[10] variable: the exact key, and a prefix of two keys.
    [Test]
    procedure CodeVar_Exact()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CodeVar(Observer, 'ABC');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'ABC');
        Observer.Expect('validated', '1');
        Observer.Verify();
    end;

    [Test]
    procedure CodeVar_PrefixTwoKeys()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CodeVar(Observer, 'AB');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'ABC');
        Observer.Expect('validated', '1');
        Observer.Verify();
    end;

    // 2. Text[10] variable: a lower-case prefix of one key.
    [Test]
    procedure TextVar_LowerPrefix()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TextVar(Observer, 'mn', false);
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'MNO');
        Observer.Expect('validated', '1');
        Observer.Verify();
    end;

    // 3. Filtered variable: an exact key outside the filter, in lower case.
    [Test]
    procedure Filtered_OutsideLowerCase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilteredVar(Observer, 'xyz', false);
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'xyz');
        Observer.Expect('validated', '1');
        Observer.Verify();
    end;

    // 4. Text[10] variable: no row, in lower case.
    [Test]
    procedure TextVar_NoRowLower()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TextVar(Observer, 'zzz', false);
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The LT TSV Book does not exist. Identification fields and values: Code=''ZZZ'''' | TestValidation');
        Observer.Expect('value', '');
        Observer.Expect('validated', '0');
        Observer.Verify();
    end;

    // 5. Text[10] variable: a prefix of two keys with ABD inserted before ABC.
    [Test]
    procedure TextVar_PrefixTwoKeysAbdFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TextVar(Observer, 'AB', true);
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'ABC');
        Observer.Expect('validated', '1');
        Observer.Verify();
    end;

    // 6. Text[10] variable: 'BC' (inside a key, not at its start) and 'Unique' (the start of MNO's Name, no key).
    [Test]
    procedure TextVar_InsideKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TextVar(Observer, 'BC', false);
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The LT TSV Book does not exist. Identification fields and values: Code=''BC'''' | TestValidation');
        Observer.Expect('value', '');
        Observer.Expect('validated', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TextVar_NameStart()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TextVar(Observer, 'Unique', false);
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The LT TSV Book does not exist. Identification fields and values: Code=''UNIQUE'''' | TestValidation');
        Observer.Expect('value', '');
        Observer.Expect('validated', '0');
        Observer.Verify();
    end;

    // 7. Text[10] variable: SetValue('ABC'), then SetValue('ZZZ'); the readings after the second call.
    [Test]
    procedure TextVar_ValueThenNoRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT TSV Text Var";
    begin
        Seed(false, false);
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('first', Outcome(TrySetText(TP, 'ABC')));
        Observer.Observe('second', Outcome(TrySetText(TP, 'ZZZ')));
        Observer.Observe('value', TP.BookCtl.Value());
        Observer.Observe('validated', TP.ValidatedCtl.Value());
        TP.Close();
        Observer.Expect('first', 'ok');
        Observer.Expect('second', 'E: Validation error for Field: BookCtl,  Message = ''The LT TSV Book does not exist. Identification fields and values: Code=''ZZZ'''' | TestValidation');
        Observer.Expect('value', 'ABC');
        Observer.Expect('validated', '1');
        Observer.Verify();
    end;

    // 7. SetValue('') on the Text[10] page, the Name page and the host card.
    [Test]
    procedure TextVar_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TextVar(Observer, '', false);
        Observer.Expect('set', 'ok');
        Observer.Expect('value', '');
        Observer.Expect('validated', '1');
        Observer.Verify();
    end;

    [Test]
    procedure NameVar_Blank()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT TSV Name Var";
    begin
        Seed(false, false);
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetName(TP, '')));
        Observer.Observe('value', TP.BookCtl.Value());
        Observer.Observe('validated', TP.ValidatedCtl.Value());
        TP.Close();
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The following field must be included into the table''s primary key: Field: Name Table: LT TSV Book'' | TestValidation');
        Observer.Expect('value', '');
        Observer.Expect('validated', '0');
        Observer.Verify();
    end;

    [Test]
    procedure HostField_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HostField(Observer, '', false);
        Observer.Expect('set', 'ok');
        Observer.Expect('value', '');
        Observer.Expect('validated', '1');
        Observer.Expect('stored', 'Book Code= Active Book Code= validated=1');
        Observer.Verify();
    end;

    // 8. A report request page: a Text[10] variable related to the table, set in a RequestPageHandler.
    [RequestPageHandler]
    procedure RequestHandler(var RP: TestRequestPage "LT TSV Request")
    var
        SetText: Text;
    begin
        ClearLastError();
        SetText := Outcome(TrySetRequest(RP, RequestTyped));
        RequestReading := StrSubstNo('set=%1 value=%2 validated=%3', SetText, RP.BookCtl.Value(), RP.ValidatedCtl.Value());
        RP.Cancel().Invoke();
    end;

    local procedure RequestCell(var Observer: Codeunit "Probe Observer"; Typed: Text)
    begin
        Seed(false, false);
        RequestTyped := Typed;
        RequestReading := '';
        Commit();
        Report.RunModal(Report::"LT TSV Request", true);
        Observer.Observe('request', RequestReading);
    end;

    [Test]
    [HandlerFunctions('RequestHandler')]
    procedure RequestPage_LowerCase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RequestCell(Observer, 'abc');
        Observer.Expect('request', 'set=ok value=ABC validated=1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RequestHandler')]
    procedure RequestPage_Prefix()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RequestCell(Observer, 'MN');
        Observer.Expect('request', 'set=ok value=MNO validated=1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RequestHandler')]
    procedure RequestPage_NoRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RequestCell(Observer, 'ZZZ');
        Observer.Expect('request', 'set=E: Validation error for Field: BookCtl,  Message = ''The LT TSV Book does not exist. Identification fields and values: Code=''ZZZ'''' | TestValidation value= validated=0');
        Observer.Verify();
    end;

    // 8. A table field with a filter (Active = true): an exact key outside the filter, a prefix of it; 'AB' on the plain field.
    [Test]
    procedure HostActive_OutsideExact()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HostField(Observer, 'XYZ', true);
        Observer.Expect('set', 'E: Validation error for Field: ActiveBookCtl,  Message = ''The field Active Book Code of table LT TSV Host contains a value (XYZ) that cannot be found in the related table (LT TSV Book). (Select Refresh to discard errors)'' | TestValidation');
        Observer.Expect('value', '');
        Observer.Expect('validated', '0');
        Observer.Expect('stored', 'Book Code= Active Book Code= validated=0');
        Observer.Verify();
    end;

    [Test]
    procedure HostActive_OutsidePrefix()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HostField(Observer, 'XY', true);
        Observer.Expect('set', 'E: Validation error for Field: ActiveBookCtl,  Message = ''The field Active Book Code of table LT TSV Host contains a value (XY) that cannot be found in the related table (LT TSV Book). (Select Refresh to discard errors)'' | TestValidation');
        Observer.Expect('value', '');
        Observer.Expect('validated', '0');
        Observer.Expect('stored', 'Book Code= Active Book Code= validated=0');
        Observer.Verify();
    end;

    [Test]
    procedure HostField_PrefixTwoKeys()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HostField(Observer, 'AB', false);
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'ABC');
        Observer.Expect('validated', '1');
        Observer.Expect('stored', 'Book Code=ABC Active Book Code= validated=1');
        Observer.Verify();
    end;

    // 8. Captions: no row on a variable and on a table field related to a table whose caption and key caption differ.
    [Test]
    procedure CapVar_NoRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT TSV Cap Var";
    begin
        Seed(false, false);
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetCap(TP, 'ZZZ')));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The Captioned Book does not exist. Identification fields and values: Book No.=''ZZZ'''' | TestValidation');
        Observer.Expect('value', '');
        Observer.Verify();
    end;

    [Test]
    procedure CapHost_NoRow()
    var
        Observer: Codeunit "Probe Observer";
        CapHost: Record "LT TSV Cap Host";
        TP: TestPage "LT TSV Cap Host Card";
    begin
        Seed(false, false);
        CapHost.Get(1);
        TP.OpenEdit();
        TP.GoToRecord(CapHost);
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetCapHost(TP, 'ZZZ')));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The field Captioned Book No. of table Captioned Host contains a value (ZZZ) that cannot be found in the related table (Captioned Book). (Select Refresh to discard errors)'' | TestValidation');
        Observer.Expect('value', '');
        Observer.Verify();
    end;

    // Optional: a relation that names the key field, and a filtered prefix whose first match is outside the filter.
    [Test]
    procedure KeyFieldVar_LowerPrefix()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT TSV KeyField Var";
    begin
        Seed(false, false);
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set_abc', Outcome(TrySetKeyField(TP, 'abc')));
        Observer.Observe('value_abc', TP.BookCtl.Value());
        Observer.Observe('set_mn', Outcome(TrySetKeyField(TP, 'mn')));
        Observer.Observe('value_mn', TP.BookCtl.Value());
        TP.Close();
        Observer.Expect('set_abc', 'ok');
        Observer.Expect('value_abc', 'ABC');
        Observer.Expect('set_mn', 'ok');
        Observer.Expect('value_mn', 'MNO');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_PrefixFirstOutside()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilteredVar(Observer, 'XY', true);
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'XYB');
        Observer.Expect('validated', '1');
        Observer.Verify();
    end;
}
