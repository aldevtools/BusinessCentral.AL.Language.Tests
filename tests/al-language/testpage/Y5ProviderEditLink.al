// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-provider-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 90980 - 90982 (writer Y5)
// Probe: written against SaaS BC 29 and the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: al-runner issue 6377. A Document page with a ListPart "Lines" (SubPageLink on the header) and two FactBoxes over one
//   ListPart page, both with Provider = Lines: ToBin links on the line's "To Bin Code" (a plain field), FromBin on its
//   "From Bin Code" (whose OnValidate calls CurrPage.Update()). The tests stand on line 10000, type a new value into one of
//   those fields, stay on the line and read the FactBox. Contrast: the provider moves to its next row
//   (testpart/TestPartProvider.al ProviderLinkedPart_FollowsTheProviderWhenItMoves pins the move).
// Result: the FactBox re-reads its SubPageLink as soon as the linked field is typed on the provider's current row (B2 at once,
//   before the line is stored for a plain field; also after CurrPage.Update in OnValidate); a blank value shows no row.
// Source: al-runner issue 6377 (the reporter's repro passed on a real BC 29 container).
// BC versions: 27, 28, 29

table 90980 "LT Y5 PL Header"
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

table 90981 "LT Y5 PL Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Document No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; "To Bin Code"; Code[20]) { }
        field(4; "From Bin Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "Document No.", "Line No.") { Clustered = true; }
    }
}

table 90982 "LT Y5 PL Bin"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 90980 "LT Y5 PL Document"
{
    PageType = Document;
    SourceTable = "LT Y5 PL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "LT Y5 PL Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
        area(FactBoxes)
        {
            part(ToBin; "LT Y5 PL Bin FactBox")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Code" = field("To Bin Code");
            }
            part(FromBin; "LT Y5 PL Bin FactBox")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Code" = field("From Bin Code");
            }
        }
    }
}

page 90981 "LT Y5 PL Lines Part"
{
    PageType = ListPart;
    SourceTable = "LT Y5 PL Line";
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
                field("To Bin Code"; Rec."To Bin Code") { ApplicationArea = All; }
                field("From Bin Code"; Rec."From Bin Code")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
            }
        }
    }
}

page 90982 "LT Y5 PL Bin FactBox"
{
    PageType = ListPart;
    SourceTable = "LT Y5 PL Bin";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
            }
        }
    }
}

codeunit 90980 "LT Y5 PL Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Y5_ProviderLink_PlainFieldTypedOnTheCurrentRow()
    var
        Line: Record "LT Y5 PL Line";
        Document: TestPage "LT Y5 PL Document";
        Observer: Codeunit "Probe Observer";
    begin
        InsertDocument();
        Document.OpenEdit();
        Document.GoToKey('D1');
        Observer.Observe('before first', Format(Document.ToBin.First()));
        Observer.Observe('before code', Document.ToBin."Code".Value());

        Document.Lines."To Bin Code".SetValue('B2');

        Observer.Observe('provider line', Document.Lines."Line No.".Value());
        Observer.Observe('provider to bin', Document.Lines."To Bin Code".Value());
        Line.Get('D1', 10000);
        Observer.Observe('stored to bin', Line."To Bin Code");
        Observer.Observe('after first', Format(Document.ToBin.First()));
        Observer.Observe('after code', Document.ToBin."Code".Value());
        Observer.Observe('after next', Format(Document.ToBin.Next()));
        Observer.Observe('other factbox code', Document.FromBin."Code".Value());
        Document.Close();
        Observer.Expect('before first', 'Yes');
        Observer.Expect('before code', 'B1');
        Observer.Expect('provider line', '10000');
        Observer.Expect('provider to bin', 'B2');
        Observer.Expect('stored to bin', 'B1');
        Observer.Expect('after first', 'Yes');
        Observer.Expect('after code', 'B2');
        Observer.Expect('after next', 'No');
        Observer.Expect('other factbox code', 'B1');
        Observer.Verify();
    end;

    [Test]
    procedure Y5_ProviderLink_FieldWhoseOnValidateCallsCurrPageUpdate()
    var
        Line: Record "LT Y5 PL Line";
        Document: TestPage "LT Y5 PL Document";
        Observer: Codeunit "Probe Observer";
    begin
        InsertDocument();
        Document.OpenEdit();
        Document.GoToKey('D1');
        Observer.Observe('before first', Format(Document.FromBin.First()));
        Observer.Observe('before code', Document.FromBin."Code".Value());

        Document.Lines."From Bin Code".SetValue('B2');

        Line.Get('D1', 10000);
        Observer.Observe('stored from bin', Line."From Bin Code");
        Observer.Observe('provider line', Document.Lines."Line No.".Value());
        Observer.Observe('after first', Format(Document.FromBin.First()));
        Observer.Observe('after code', Document.FromBin."Code".Value());
        Observer.Observe('other factbox code', Document.ToBin."Code".Value());
        Document.Close();
        Observer.Expect('before first', 'Yes');
        Observer.Expect('before code', 'B1');
        Observer.Expect('stored from bin', 'B2');
        Observer.Expect('provider line', '10000');
        Observer.Expect('after first', 'Yes');
        Observer.Expect('after code', 'B2');
        Observer.Expect('other factbox code', 'B1');
        Observer.Verify();
    end;

    [Test]
    procedure Y5_ProviderLink_ReadWithoutFirstAfterTheEdit()
    var
        Document: TestPage "LT Y5 PL Document";
        Observer: Codeunit "Probe Observer";
    begin
        // The same edit as the plain-field test, but the FactBox is read without First() after it.
        InsertDocument();
        Document.OpenEdit();
        Document.GoToKey('D1');
        Observer.Observe('before code', Document.ToBin."Code".Value());

        Document.Lines."To Bin Code".SetValue('B2');

        Observer.Observe('after code', Document.ToBin."Code".Value());
        Document.Close();
        Observer.Expect('before code', 'B1');
        Observer.Expect('after code', 'B2');
        Observer.Verify();
    end;

    [Test]
    procedure Y5_ProviderLink_PlainFieldTypedBlank()
    var
        Document: TestPage "LT Y5 PL Document";
        Observer: Codeunit "Probe Observer";
    begin
        InsertDocument();
        Document.OpenEdit();
        Document.GoToKey('D1');
        Observer.Observe('before code', Document.ToBin."Code".Value());

        Document.Lines."To Bin Code".SetValue('');

        Observer.Observe('provider line', Document.Lines."Line No.".Value());
        Observer.Observe('after first', Format(Document.ToBin.First()));
        Observer.Observe('after code', Document.ToBin."Code".Value());
        Document.Close();
        Observer.Expect('before code', 'B1');
        Observer.Expect('provider line', '10000');
        Observer.Expect('after first', 'No');
        Observer.Expect('after code', '');
        Observer.Verify();
    end;

    [Test]
    procedure Y5_ProviderLink_EditThenMoveAndBack()
    var
        Document: TestPage "LT Y5 PL Document";
        Observer: Codeunit "Probe Observer";
    begin
        // Line 10000 gets B2 typed, the provider moves to line 20000 (B1 typed there) and back.
        InsertDocument();
        Document.OpenEdit();
        Document.GoToKey('D1');
        Document.Lines."To Bin Code".SetValue('B2');
        Observer.Observe('next', Format(Document.Lines.Next()));
        Observer.Observe('line after next', Document.Lines."Line No.".Value());
        Observer.Observe('code on 20000', Document.ToBin."Code".Value());
        Document.Lines."To Bin Code".SetValue('B1');
        Observer.Observe('code on 20000 after edit', Document.ToBin."Code".Value());
        Observer.Observe('previous', Format(Document.Lines.Previous()));
        Observer.Observe('line after previous', Document.Lines."Line No.".Value());
        Observer.Observe('provider to bin on 10000', Document.Lines."To Bin Code".Value());
        Observer.Observe('code on 10000', Document.ToBin."Code".Value());
        Document.Close();
        Observer.Expect('next', 'Yes');
        Observer.Expect('line after next', '20000');
        Observer.Expect('code on 20000', 'B2');
        Observer.Expect('code on 20000 after edit', 'B1');
        Observer.Expect('previous', 'Yes');
        Observer.Expect('line after previous', '10000');
        Observer.Expect('provider to bin on 10000', 'B2');
        Observer.Expect('code on 10000', 'B2');
        Observer.Verify();
    end;

    [Test]
    procedure Y5_ProviderLink_MoveToTheNextRow()
    var
        Document: TestPage "LT Y5 PL Document";
        Observer: Codeunit "Probe Observer";
    begin
        InsertDocument();
        Document.OpenEdit();
        Document.GoToKey('D1');
        Observer.Observe('before code', Document.ToBin."Code".Value());
        Observer.Observe('next', Format(Document.Lines.Next()));
        Observer.Observe('provider line', Document.Lines."Line No.".Value());
        Observer.Observe('after first', Format(Document.ToBin.First()));
        Observer.Observe('after code', Document.ToBin."Code".Value());
        Document.Close();
        Observer.Expect('before code', 'B1');
        Observer.Expect('next', 'Yes');
        Observer.Expect('provider line', '20000');
        Observer.Expect('after first', 'Yes');
        Observer.Expect('after code', 'B2');
        Observer.Verify();
    end;

    local procedure InsertDocument()
    var
        Header: Record "LT Y5 PL Header";
        Line: Record "LT Y5 PL Line";
        Bin: Record "LT Y5 PL Bin";
    begin
        Header.DeleteAll();
        Line.DeleteAll();
        Bin.DeleteAll();
        Bin."Code" := 'B1';
        Bin.Insert();
        Bin."Code" := 'B2';
        Bin.Insert();
        Header."No." := 'D1';
        Header.Insert();
        Line."Document No." := 'D1';
        Line."Line No." := 10000;
        Line."To Bin Code" := 'B1';
        Line."From Bin Code" := 'B1';
        Line.Insert();
        Line."Line No." := 20000;
        Line."To Bin Code" := 'B2';
        Line."From Bin Code" := 'B2';
        Line.Insert();
    end;
}
