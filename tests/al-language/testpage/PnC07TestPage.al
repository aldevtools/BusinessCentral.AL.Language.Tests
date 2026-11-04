// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT PnC Rec (71080), LT PnC Log (71071)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed rows: TestPage "OnInsertRecord and its event get BelowxRec = Yes ... a row added in the middle is not"; TestPage "An index past the last validation error in TestPage.GetValidationError"; TestPage.FindFirstField (fixes-7) "A miss with the result unused raises The row does not exist on the TestPage."
// BC versions: 29 (27 and 28 by CI)

codeunit 71143 "LT PnC Log 4"
{
    SingleInstance = true;

    var
        Items: List of [Text];

    procedure Add(Value: Text)
    begin
        Items.Add(Value);
    end;

    procedure Reset()
    begin
        Clear(Items);
    end;

    procedure Joined(): Text
    var
        Result: Text;
        Item: Text;
    begin
        foreach Item in Items do begin
            if Result <> '' then
                Result += '|';
            Result += Item;
        end;
        exit(Result);
    end;

    procedure Count(): Integer
    begin
        exit(Items.Count());
    end;
}

page 71086 "LT PnC List"
{
    PageType = List;
    SourceTable = "LT PnC Rec";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('Name.OnValidate');
                        if Rec.Name = 'bad' then
                            Error('bad name');
                    end;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('Amount.OnValidate');
                    end;
                }
                field(Other; Rec.Other)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    var
        Log: Codeunit "LT PnC Log 4";

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('OnNewRecord(below=' + Format(BelowxRec) + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('OnInsertRecord(below=' + Format(BelowxRec) + ')');
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('OnModifyRecord');
        exit(true);
    end;
}

codeunit 71108 "LT PnC TestPage Insert"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT PnC Rec";
        i: Integer;
    begin
        R.DeleteAll();
        for i := 1 to 3 do begin
            R.Init();
            R."No." := i * 10;
            R.Name := 'N' + Format(i);
            R.Insert();
        end;
    end;

    [Test]
    procedure New_AtTheEnd()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 4";
        List: TestPage "LT PnC List";
        R: Record "LT PnC Rec";
    begin
        Seed();
        Log.Reset();
        List.OpenEdit();
        List.Last();
        List.New();
        List."No.".SetValue(40);
        Observer.Observe('beforeClose', Log.Joined());
        List.Close();
        Observer.Observe('afterClose', Log.Joined());
        Observer.Observe('rows', Format(R.Count()));
        Observer.Expect('beforeClose', 'OnNewRecord(below=Yes)|OnNewRecord(below=Yes)');
        Observer.Expect('afterClose', 'OnNewRecord(below=Yes)|OnNewRecord(below=Yes)|OnInsertRecord(below=Yes)');
        Observer.Expect('rows', '4');
        Observer.Verify();
    end;

    [Test]
    procedure New_InTheMiddle()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 4";
        List: TestPage "LT PnC List";
        R: Record "LT PnC Rec";
    begin
        Seed();
        Log.Reset();
        List.OpenEdit();
        List.First();
        List.New();
        List."No.".SetValue(15);
        Observer.Observe('beforeClose', Log.Joined());
        List.Close();
        Observer.Observe('afterClose', Log.Joined());
        Observer.Observe('rows', Format(R.Count()));
        Observer.Expect('beforeClose', 'OnNewRecord(below=Yes)');
        Observer.Expect('afterClose', 'OnNewRecord(below=Yes)|OnInsertRecord(below=Yes)');
        Observer.Expect('rows', '4');
        Observer.Verify();
    end;

    [Test]
    procedure New_OnEmptyPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 4";
        List: TestPage "LT PnC List";
        R: Record "LT PnC Rec";
    begin
        R.DeleteAll();
        Log.Reset();
        List.OpenEdit();
        List.New();
        List."No.".SetValue(1);
        List.Close();
        Observer.Observe('log', Log.Joined());
        Observer.Observe('rows', Format(R.Count()));
        Observer.Expect('log', 'OnNewRecord(below=Yes)|OnNewRecord(below=Yes)|OnNewRecord(below=Yes)|OnInsertRecord(below=Yes)');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure New_AfterMovingAwayFromNewRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 4";
        List: TestPage "LT PnC List";
    begin
        Seed();
        Log.Reset();
        List.OpenEdit();
        List.Last();
        List.New();
        List."No.".SetValue(40);
        List.Previous();
        Observer.Observe('afterPrevious', Log.Joined());
        List.Close();
        Observer.Expect('afterPrevious', 'OnNewRecord(below=Yes)|OnNewRecord(below=Yes)|OnInsertRecord(below=Yes)');
        Observer.Verify();
    end;
}

codeunit 71109 "LT PnC TestPage Validation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT PnC Rec";
        i: Integer;
    begin
        R.DeleteAll();
        for i := 1 to 3 do begin
            R.Init();
            R."No." := i * 10;
            R.Name := 'N' + Format(i);
            R.Insert();
        end;
    end;

    [Test]
    procedure GetValidationError_Indexes_NoErrors()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT PnC List";
        Txt: Text;
    begin
        Seed();
        List.OpenEdit();
        asserterror Txt := List.GetValidationError(0);
        Observer.ObserveError('index0');
        asserterror Txt := List.GetValidationError(1);
        Observer.ObserveError('index1');
        asserterror Txt := List.GetValidationError(2);
        Observer.ObserveError('index2');
        asserterror Txt := List.GetValidationError(-1);
        Observer.ObserveError('indexMinus1');
        asserterror Txt := List.GetValidationError(100);
        Observer.ObserveError('index100');
        List.Close();
        Observer.Expect('index0|text', 'Index out of bounds.');
        Observer.Expect('index0|code', 'IndexOutOfBounds');
        Observer.Expect('index1|text', 'Index out of bounds.');
        Observer.Expect('index1|code', 'IndexOutOfBounds');
        Observer.Expect('index2|text', 'Index out of bounds.');
        Observer.Expect('index2|code', 'IndexOutOfBounds');
        Observer.Expect('indexMinus1|text', 'Index out of bounds.');
        Observer.Expect('indexMinus1|code', 'IndexOutOfBounds');
        Observer.Expect('index100|text', 'Index out of bounds.');
        Observer.Expect('index100|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure GetValidationError_AfterFailedValidation()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT PnC List";
        Txt: Text;
    begin
        Seed();
        List.OpenEdit();
        List.First();
        asserterror List.Name.SetValue('bad');
        Observer.ObserveError('setValue');
        asserterror Txt := List.GetValidationError(0);
        Observer.ObserveError('index0');
        Txt := List.GetValidationError(1);
        Observer.Observe('index1', 'no error');
        asserterror Txt := List.GetValidationError(2);
        Observer.ObserveError('index2');
        asserterror Txt := List.GetValidationError(5);
        Observer.ObserveError('index5');
        Observer.Expect('setValue|text', 'Validation error for Field: Name,  Message = ''bad name''');
        Observer.Expect('setValue|code', 'TestValidation');
        Observer.Expect('index0|text', 'Index out of bounds.');
        Observer.Expect('index0|code', 'IndexOutOfBounds');
        Observer.Expect('index1', 'no error');
        Observer.Expect('index2|text', 'Index out of bounds.');
        Observer.Expect('index2|code', 'IndexOutOfBounds');
        Observer.Expect('index5|text', 'Index out of bounds.');
        Observer.Expect('index5|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure FindFirstField_Hit_And_Miss()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT PnC List";
        Found: Boolean;
    begin
        Seed();
        List.OpenView();
        Found := List.FindFirstField(List."No.", 20);
        Observer.Observe('first.hit', Format(Found));
        Observer.Observe('first.hit.row', List."No.".Value());
        Found := List.FindFirstField(List."No.", 99);
        Observer.Observe('first.miss', Format(Found));
        Found := List.FindNextField(List."No.", 30);
        Observer.Observe('next.afterMiss', Format(Found));
        List.First();
        Found := List.FindNextField(List."No.", 30);
        Observer.Observe('next.hit', Format(Found));
        Found := List.FindNextField(List."No.", 99);
        Observer.Observe('next.miss', Format(Found));
        Found := List.FindPreviousField(List."No.", 10);
        Observer.Observe('previous.hit', Format(Found));
        Found := List.FindPreviousField(List."No.", 99);
        Observer.Observe('previous.miss', Format(Found));
        Found := List.FindFirstField(List.Name, 'N2');
        Observer.Observe('text.hit', Format(Found));
        Observer.Observe('text.hit.row', List."No.".Value());
        List.Close();
        Observer.Expect('first.hit', 'Yes');
        Observer.Expect('first.hit.row', '20');
        Observer.Expect('first.miss', 'No');
        Observer.Expect('next.afterMiss', 'Yes');
        Observer.Expect('next.hit', 'Yes');
        Observer.Expect('next.miss', 'No');
        Observer.Expect('previous.hit', 'Yes');
        Observer.Expect('previous.miss', 'No');
        Observer.Expect('text.hit', 'Yes');
        Observer.Expect('text.hit.row', '20');
        Observer.Verify();
    end;

    [Test]
    procedure FindField_MissWithUnusedResult()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT PnC List";
    begin
        Seed();
        List.OpenView();
        asserterror List.FindFirstField(List."No.", 99);
        Observer.ObserveError('first');
        asserterror List.FindNextField(List."No.", 99);
        Observer.ObserveError('next');
        List.FindPreviousField(List."No.", 99);
        Observer.Observe('previous', 'no error');
        List.FindFirstField(List."No.", 20);
        Observer.Observe('firstHit', 'no error');
        Observer.Observe('stillOpen', List."No.".Value());
        List.Close();
        Observer.Expect('first|text', 'The row does not exist on the TestPage.');
        Observer.Expect('first|code', 'TestRowNotFound');
        Observer.Expect('next|text', 'The row does not exist on the TestPage.');
        Observer.Expect('next|code', 'TestRowNotFound');
        Observer.Expect('previous', 'no error');
        Observer.Expect('firstHit', 'no error');
        Observer.Expect('stillOpen', '20');
        Observer.Verify();
    end;
}
