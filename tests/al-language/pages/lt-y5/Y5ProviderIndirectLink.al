// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-provider-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 90988 - 90990 (writer Y5)
// Probe: written against SaaS BC 29 and the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: al-runner issue 6377, second part. A Document page with a ListPart "Lines" and a FactBox with Provider = Lines whose
//   SubPageLink is on the line's "Qty. (Base)". That field is never typed: typing Quantity sets it in the TABLE field's
//   OnValidate (Quantity * 2); typing "Page Qty" sets it in the PAGE control's OnValidate (Page Qty * 3). The test stays on
//   the line and reads the FactBox. Bucket rows carry a label per quantity, so the FactBox row is read as text.
// Result: the FactBox follows at once when another field's OnValidate (of the table or of the page control) changes the
//   linked field on the provider's current row, before the row is stored; a value with no matching row shows no row.
// Source: al-runner issue 6377 (the reporter's real-world shape: Quantity changes the linked Qty. (Base)).
// BC versions: 27, 28, 29

table 90988 "LT Y5 IL Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 90989 "LT Y5 IL Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Document No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Quantity; Decimal)
        {
            trigger OnValidate()
            begin
                "Qty. (Base)" := Quantity * 2;
            end;
        }
        field(4; "Qty. (Base)"; Decimal) { }
        field(5; "Page Qty"; Decimal) { }
    }

    keys
    {
        key(PK; "Document No.", "Line No.") { Clustered = true; }
    }
}

table 90990 "LT Y5 IL Bucket"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Qty; Decimal) { }
        field(2; Label; Text[30]) { }
    }

    keys
    {
        key(PK; Qty) { Clustered = true; }
    }
}

page 90988 "LT Y5 IL Document"
{
    PageType = Document;
    SourceTable = "LT Y5 IL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "LT Y5 IL Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
        area(FactBoxes)
        {
            part(Bucket; "LT Y5 IL Bucket FactBox")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = Qty = field("Qty. (Base)");
            }
        }
    }
}

page 90989 "LT Y5 IL Lines Part"
{
    PageType = ListPart;
    SourceTable = "LT Y5 IL Line";
    InsertAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
                field("Page Qty"; Rec."Page Qty")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Rec."Qty. (Base)" := Rec."Page Qty" * 3;
                    end;
                }
                field("Qty. (Base)"; Rec."Qty. (Base)") { ApplicationArea = All; Editable = false; }
            }
        }
    }
}

page 90990 "LT Y5 IL Bucket FactBox"
{
    PageType = ListPart;
    SourceTable = "LT Y5 IL Bucket";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Label; Rec.Label) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 90988 "LT Y5 IL Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Y5_IndirectLink_TableOnValidateSetsTheLinkedField()
    var
        Line: Record "LT Y5 IL Line";
        Document: TestPage "LT Y5 IL Document";
        Observer: Codeunit "Probe Observer";
    begin
        InsertDocument();
        Document.OpenEdit();
        Document.GoToKey('D1');
        Observer.Observe('before first', Format(Document.Bucket.First()));
        Observer.Observe('before label', Document.Bucket.Label.Value());

        Document.Lines.Quantity.SetValue(2);

        Observer.Observe('provider line', Document.Lines."Line No.".Value());
        Observer.Observe('provider qty base', Document.Lines."Qty. (Base)".Value());
        Line.Get('D1', 10000);
        Observer.Observe('stored qty base', Format(Line."Qty. (Base)"));
        Observer.Observe('after label', Document.Bucket.Label.Value());
        Observer.Observe('after first', Format(Document.Bucket.First()));
        Observer.Observe('after first label', Document.Bucket.Label.Value());
        Document.Close();
        Observer.Expect('before first', 'Yes');
        Observer.Expect('before label', 'base 2');
        Observer.Expect('provider line', '10000');
        Observer.Expect('provider qty base', '4.00');
        Observer.Expect('stored qty base', '2');
        Observer.Expect('after label', 'base 4');
        Observer.Expect('after first', 'Yes');
        Observer.Expect('after first label', 'base 4');
        Observer.Verify();
    end;

    [Test]
    procedure Y5_IndirectLink_PageOnValidateSetsTheLinkedField()
    var
        Line: Record "LT Y5 IL Line";
        Document: TestPage "LT Y5 IL Document";
        Observer: Codeunit "Probe Observer";
    begin
        InsertDocument();
        Document.OpenEdit();
        Document.GoToKey('D1');
        Observer.Observe('before label', Document.Bucket.Label.Value());

        Document.Lines."Page Qty".SetValue(3);

        Observer.Observe('provider qty base', Document.Lines."Qty. (Base)".Value());
        Line.Get('D1', 10000);
        Observer.Observe('stored qty base', Format(Line."Qty. (Base)"));
        Observer.Observe('after label', Document.Bucket.Label.Value());
        Observer.Observe('after first', Format(Document.Bucket.First()));
        Observer.Observe('after first label', Document.Bucket.Label.Value());
        Document.Close();
        Observer.Expect('before label', 'base 2');
        Observer.Expect('provider qty base', '9.00');
        Observer.Expect('stored qty base', '2');
        Observer.Expect('after label', 'base 9');
        Observer.Expect('after first', 'Yes');
        Observer.Expect('after first label', 'base 9');
        Observer.Verify();
    end;

    [Test]
    procedure Y5_IndirectLink_QuantityToAValueWithoutBucket()
    var
        Document: TestPage "LT Y5 IL Document";
        Observer: Codeunit "Probe Observer";
    begin
        // Quantity 5 makes Qty. (Base) 10; no bucket row has Qty 10.
        InsertDocument();
        Document.OpenEdit();
        Document.GoToKey('D1');
        Document.Lines.Quantity.SetValue(5);
        Observer.Observe('provider qty base', Document.Lines."Qty. (Base)".Value());
        Observer.Observe('after first', Format(Document.Bucket.First()));
        Observer.Observe('after label', Document.Bucket.Label.Value());
        Document.Close();
        Observer.Expect('provider qty base', '10.00');
        Observer.Expect('after first', 'No');
        Observer.Expect('after label', '');
        Observer.Verify();
    end;

    local procedure InsertDocument()
    var
        Header: Record "LT Y5 IL Header";
        Line: Record "LT Y5 IL Line";
        Bucket: Record "LT Y5 IL Bucket";
    begin
        Header.DeleteAll();
        Line.DeleteAll();
        Bucket.DeleteAll();
        InsertBucket(2, 'base 2');
        InsertBucket(4, 'base 4');
        InsertBucket(9, 'base 9');
        Header."No." := 'D1';
        Header.Insert();
        Line."Document No." := 'D1';
        Line."Line No." := 10000;
        Line.Quantity := 1;
        Line."Qty. (Base)" := 2;
        Line.Insert();
    end;

    local procedure InsertBucket(Qty: Decimal; Label: Text[30])
    var
        Bucket: Record "LT Y5 IL Bucket";
    begin
        Bucket.Qty := Qty;
        Bucket.Label := Label;
        Bucket.Insert();
    end;
}
