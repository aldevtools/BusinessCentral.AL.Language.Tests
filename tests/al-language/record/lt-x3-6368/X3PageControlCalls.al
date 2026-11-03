// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 90801, codeunit 90802, pages 90803 and 90804, test codeunit 90805.
// Probe: al-runner issue 6368 (writer X3), follow-up to issue 6284 (record/lt-wb-6284/WbPageControlBuiltIn.al) and record/PageControlFieldSourceFormsSM.al:
//   the "Page Control Field" (2000000192) row of controls bound to a procedure call: a method of the source table (Rec.DisplayCode()), a method of a
//   codeunit variable with an argument (Names.NameOf(Rec."No.")) and without one (Names.Fixed()), next to a field (Rec."No.") and a built-in call
//   (Format(Rec.Kind)), on an API page and on a Card page. Columns read: TableNo, FieldNo, Enabled, Editable, Visible, SourceExpression, OptionString,
//   Sequence (ControlId is a generated id and is not read).
// Measured (BC 29): every call-bound control has FieldNo 0, TableNo the source table, Editable 'False', Enabled and Visible 'true', OptionString empty,
//   and SourceExpression the call as written WITH 'Rec.' (Rec.DisplayCode(), Names.NameOf(Rec."No."), Names.Fixed()); the field control's
//   SourceExpression drops 'Rec.' (No.). Sequence is the layout position. API page and Card page give the same rows.
// BC versions: 27, 28, 29

table 90801 "LT X3 PX Entry"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Kind; Option) { OptionMembers = Sale,Purchase; }
    }
    keys { key(PK; "No.") { Clustered = true; } }

    procedure DisplayCode(): Code[20]
    begin
        exit("No.");
    end;
}

codeunit 90802 "LT X3 PX Names"
{
    procedure NameOf(No: Code[20]): Text
    begin
        exit('Name ' + No);
    end;

    procedure Fixed(): Text
    begin
        exit('Fixed');
    end;
}

page 90803 "LT X3 PX Entries API"
{
    PageType = API;
    APIPublisher = 'ltxthree';
    APIGroup = 'ltxthree';
    APIVersion = 'v1.0';
    EntityName = 'xthreeEntry';
    EntitySetName = 'xthreeEntries';
    SourceTable = "LT X3 PX Entry";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(number; Rec."No.") { }
                field(kindText; Format(Rec.Kind)) { }
                field(displayCode; Rec.DisplayCode()) { }
                field(name; Names.NameOf(Rec."No.")) { }
                field(fixedName; Names.Fixed()) { }
            }
        }
    }

    var
        Names: Codeunit "LT X3 PX Names";
}

page 90804 "LT X3 PX Entry Card"
{
    PageType = Card;
    SourceTable = "LT X3 PX Entry";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(KindText; Format(Rec.Kind)) { ApplicationArea = All; Caption = 'Kind Text'; }
                field(DisplayCode; Rec.DisplayCode()) { ApplicationArea = All; Caption = 'Display Code'; }
                field(Name; Names.NameOf(Rec."No.")) { ApplicationArea = All; Caption = 'Name'; }
                field(FixedName; Names.Fixed()) { ApplicationArea = All; Caption = 'Fixed Name'; }
            }
        }
    }

    var
        Names: Codeunit "LT X3 PX Names";
}

codeunit 90805 "LT X3 PCF Call Controls"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Row(PageNo: Integer; ControlName: Text): Text
    var
        PageControlField: Record "Page Control Field";
    begin
        PageControlField.SetRange(PageNo, PageNo);
        PageControlField.SetRange(ControlName, ControlName);
        if not PageControlField.FindFirst() then
            exit('no row');
        exit(StrSubstNo('TableNo=%1 FieldNo=%2 Enabled=[%3] Editable=[%4] Visible=[%5] SourceExpression=[%6] OptionString=[%7] Sequence=%8',
            PageControlField.TableNo, PageControlField.FieldNo, PageControlField.Enabled, PageControlField.Editable,
            PageControlField.Visible, PageControlField.SourceExpression, PageControlField.OptionString, PageControlField.Sequence));
    end;

    local procedure Counts(PageNo: Integer): Text
    var
        PageControlField: Record "Page Control Field";
        Rows: Integer;
        Bound: Integer;
    begin
        PageControlField.SetRange(PageNo, PageNo);
        if PageControlField.FindSet() then
            repeat
                Rows += 1;
                if PageControlField.FieldNo <> 0 then
                    Bound += 1;
            until PageControlField.Next() = 0;
        exit(StrSubstNo('rows=%1 bound=%2', Rows, Bound));
    end;

    [Test]
    procedure ApiPage_CallControlRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('number', Row(Page::"LT X3 PX Entries API", 'number'));
        Observer.Observe('kindText', Row(Page::"LT X3 PX Entries API", 'kindText'));
        Observer.Observe('displayCode', Row(Page::"LT X3 PX Entries API", 'displayCode'));
        Observer.Observe('name', Row(Page::"LT X3 PX Entries API", 'name'));
        Observer.Observe('fixedName', Row(Page::"LT X3 PX Entries API", 'fixedName'));
        Observer.Observe('counts', Counts(Page::"LT X3 PX Entries API"));
        Observer.Expect('number', 'TableNo=90801 FieldNo=1 Enabled=[true] Editable=[True] Visible=[true] SourceExpression=[No.] OptionString=[] Sequence=0');
        Observer.Expect('kindText', 'TableNo=90801 FieldNo=0 Enabled=[true] Editable=[False] Visible=[true] SourceExpression=[Format(Rec.Kind)] OptionString=[] Sequence=1');
        Observer.Expect('displayCode', 'TableNo=90801 FieldNo=0 Enabled=[true] Editable=[False] Visible=[true] SourceExpression=[Rec.DisplayCode()] OptionString=[] Sequence=2');
        Observer.Expect('name', 'TableNo=90801 FieldNo=0 Enabled=[true] Editable=[False] Visible=[true] SourceExpression=[Names.NameOf(Rec."No.")] OptionString=[] Sequence=3');
        Observer.Expect('fixedName', 'TableNo=90801 FieldNo=0 Enabled=[true] Editable=[False] Visible=[true] SourceExpression=[Names.Fixed()] OptionString=[] Sequence=4');
        Observer.Expect('counts', 'rows=5 bound=1');
        Observer.Verify();
    end;

    [Test]
    procedure CardPage_CallControlRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('No.', Row(Page::"LT X3 PX Entry Card", 'No.'));
        Observer.Observe('KindText', Row(Page::"LT X3 PX Entry Card", 'KindText'));
        Observer.Observe('DisplayCode', Row(Page::"LT X3 PX Entry Card", 'DisplayCode'));
        Observer.Observe('Name', Row(Page::"LT X3 PX Entry Card", 'Name'));
        Observer.Observe('FixedName', Row(Page::"LT X3 PX Entry Card", 'FixedName'));
        Observer.Observe('counts', Counts(Page::"LT X3 PX Entry Card"));
        Observer.Expect('No.', 'TableNo=90801 FieldNo=1 Enabled=[true] Editable=[True] Visible=[true] SourceExpression=[No.] OptionString=[] Sequence=0');
        Observer.Expect('KindText', 'TableNo=90801 FieldNo=0 Enabled=[true] Editable=[False] Visible=[true] SourceExpression=[Format(Rec.Kind)] OptionString=[] Sequence=1');
        Observer.Expect('DisplayCode', 'TableNo=90801 FieldNo=0 Enabled=[true] Editable=[False] Visible=[true] SourceExpression=[Rec.DisplayCode()] OptionString=[] Sequence=2');
        Observer.Expect('Name', 'TableNo=90801 FieldNo=0 Enabled=[true] Editable=[False] Visible=[true] SourceExpression=[Names.NameOf(Rec."No.")] OptionString=[] Sequence=3');
        Observer.Expect('FixedName', 'TableNo=90801 FieldNo=0 Enabled=[true] Editable=[False] Visible=[true] SourceExpression=[Names.Fixed()] OptionString=[] Sequence=4');
        Observer.Expect('counts', 'rows=5 bound=1');
        Observer.Verify();
    end;

    [Test]
    procedure ApiPage_FilterToTableBoundControls()
    var
        PageControlField: Record "Page Control Field";
        Observer: Codeunit "Probe Observer";
    begin
        PageControlField.SetRange(PageNo, Page::"LT X3 PX Entries API");
        PageControlField.SetFilter(FieldNo, '<>0');
        Observer.Observe('count FieldNo <> 0', Format(PageControlField.Count()));
        PageControlField.SetRange(FieldNo, 0);
        Observer.Observe('count FieldNo = 0', Format(PageControlField.Count()));
        Observer.Expect('count FieldNo <> 0', '1');
        Observer.Expect('count FieldNo = 0', '4');
        Observer.Verify();
    end;
}
