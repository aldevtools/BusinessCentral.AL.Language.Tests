// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-wordxmlpart-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), W3 Row (67698)
// local object: the data items and columns of these reports are under test (enum 62350, reports 62351 to 62356).
// Area: the text of Report.WordXmlPart(Id) and Report.WordXmlPart(Id, true) for three shapes not pinned before.
//   1. A data item with no column and no nested data item (al-runner issue 7383, the Integer data item `Total` of the Base
//      Application service reports): alone in the report, after a data item with columns, before one, with and without a
//      DataItemTableView, nested, and a parent whose only content is an empty nested data item.
//   2. The order of column and label names that differ in a digit, an underscore and letter case (al-runner issue 7367:
//      ShipToAddress8 and ShipToAddress_Lbl of report 1305).
//   3. The DataType of a column bound to an array element (al-runner issue 7381: an element of `array[8] of Text`): arrays of
//      Text, Text[30], Code, Integer, Decimal, Boolean, Date, Time, DateTime, Option, Enum, Guid, BigInteger and Duration, a
//      two-dimensional array, an index held in a variable, a field of an element of an array of records, and expressions over
//      an element.
// Already pinned elsewhere: name legalizing, the DataType of fields, variables and literals, labels, one and two report
//   extensions, and the order of names that differ in case or in an underscore between letters (reports/WordXmlPartNames.al).
// The WordXmlPart of the Extended tests is observed, not asserted (Ignore), so they have no continuation tests.
// BC versions: 27-29
enum 62350 "RPT WXP2 Kind"
{
    Extensible = false;

    value(0; First) { }
    value(1; Second) { }
}

report 62351 "RPT WXP2 Empty Alone"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Total; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
        }
    }
}

// The reporter's shape: a data item with a column, then the empty one.
report 62352 "RPT WXP2 Empty After"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Head; "W3 Row")
        {
            column(No; Id) { }
        }
        dataitem(Total; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
        }
    }
}

report 62353 "RPT WXP2 Empty Mixed"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(PlainFirst; Integer)
        {
        }
        dataitem(Head; "W3 Row")
        {
            column(No; Id) { }
            dataitem(NestedEmpty; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
            }
            dataitem(NestedWithColumn; Integer)
            {
                column(NestedNo; Number) { }
            }
        }
        dataitem(OnlyEmptyChild; "W3 Row")
        {
            dataitem(ChildOfEmptyParent; Integer)
            {
            }
        }
        dataitem(OnlyChildWithColumn; "W3 Row")
        {
            dataitem(Deep; Integer)
            {
                column(DeepNo; Number) { }
            }
        }
        dataitem(PlainLast; Integer)
        {
        }
    }

    labels
    {
        OneLabel = 'One';
    }
}

// Declared in an order that is neither ordinal nor alphabetical.
report 62354 "RPT WXP2 Name Order"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Rows; "W3 Row")
        {
            column(ShipToAddress_Lbl; Name) { }
            column(ShipToAddress8; Name) { }
            column(shipToAddress9; Name) { }
            column(ShipToAddress; Name) { }
            column(ShipToAddress10; Name) { }
            column(ShipToAddress_; Name) { }
            column(ShipToAddress2; Name) { }
            column(ShipToAddressA; Name) { }
            column(ShipToAddress1; Name) { }
            column(SHIPTOADDRESS3; Name) { }
            column(ShipTo_Address; Name) { }
            column(ShipTo8Address; Name) { }
            column(A_; Id) { }
            column(A1; Id) { }
            column(AA; Id) { }
            column(aB; Id) { }
        }
    }

    labels
    {
        Lbl_Text = 'L1';
        Lbl8Text = 'L2';
        LblAText = 'L3';
        lbl9Text = 'L4';
    }
}

report 62355 "RPT WXP2 Arrays A"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Rows; "W3 Row")
        {
            column(Contact_AddrArray_1; TextArr[1]) { }
            column(Contact_AddrArray_8; TextArr[8]) { }
            column(Text30_1; Text30Arr[1]) { }
            column(Code_2; CodeArr[2]) { }
            column(Int_1; IntArr[1]) { }
            column(Dec_2; DecArr[2]) { }
            column(Bool_1; BoolArr[1]) { }
            column(Date_1; DateArr[1]) { }
            column(Time_1; TimeArr[1]) { }
            column(DateTime_1; DateTimeArr[1]) { }
        }
    }

    var
        TextArr: array[8] of Text;
        Text30Arr: array[2] of Text[30];
        CodeArr: array[2] of Code[20];
        IntArr: array[2] of Integer;
        DecArr: array[2] of Decimal;
        BoolArr: array[2] of Boolean;
        DateArr: array[2] of Date;
        TimeArr: array[2] of Time;
        DateTimeArr: array[2] of DateTime;
}

report 62356 "RPT WXP2 Arrays B"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Rows; "W3 Row")
        {
            column(Option_1; OptionArr[1]) { }
            column(Enum_1; EnumArr[1]) { }
            column(Guid_1; GuidArr[1]) { }
            column(BigInt_1; BigIntArr[1]) { }
            column(Duration_1; DurationArr[1]) { }
            column(TwoDim_1_2; TwoDimArr[1, 2]) { }
            column(VarIndex; TextArr[Index]) { }
            column(RecArr_Name; RecArr[1].Name) { }
            column(RecArr_Amount; RecArr[2].Amount) { }
            column(Concat; TextArr[1] + 'x') { }
            column(Formatted; Format(DecArr[1])) { }
            column(Sum; IntArr[1] + IntArr[2]) { }
        }
    }

    var
        TextArr: array[8] of Text;
        IntArr: array[2] of Integer;
        DecArr: array[2] of Decimal;
        OptionArr: array[2] of Option Alpha,Beta;
        EnumArr: array[2] of Enum "RPT WXP2 Kind";
        GuidArr: array[2] of Guid;
        BigIntArr: array[2] of BigInteger;
        DurationArr: array[2] of Duration;
        TwoDimArr: array[2, 3] of Text;
        RecArr: array[2] of Record "W3 Row";
        Index: Integer;
}

codeunit 62357 "RPT WXP2 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure WordXmlPart_EmptyDataItemAlone_Plain()
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"RPT WXP2 Empty Alone"));
        Observer.Ignore('part'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_EmptyDataItemAlone_Extended()
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"RPT WXP2 Empty Alone", true));
        Observer.Ignore('part'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_EmptyDataItemAfterOneWithColumns_Plain()
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"RPT WXP2 Empty After"));
        Observer.Ignore('part'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_EmptyDataItemAfterOneWithColumns_Extended()
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"RPT WXP2 Empty After", true));
        Observer.Ignore('part'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_EmptyDataItemsMixed_Plain()
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"RPT WXP2 Empty Mixed"));
        Observer.Ignore('part'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_EmptyDataItemsMixed_Extended()
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"RPT WXP2 Empty Mixed", true));
        Observer.Ignore('part'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_NameOrderDigitUnderscoreCase_Plain()
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"RPT WXP2 Name Order"));
        Observer.Ignore('part'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_NameOrderDigitUnderscoreCase_Extended()
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"RPT WXP2 Name Order", true));
        Observer.Ignore('part'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_ArrayElements_FirstTypes_Plain()
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"RPT WXP2 Arrays A"));
        Observer.Ignore('part'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_ArrayElements_FirstTypes_Extended()
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"RPT WXP2 Arrays A", true));
        Observer.Ignore('part'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_ArrayElements_OtherTypes_Plain()
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"RPT WXP2 Arrays B"));
        Observer.Ignore('part'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_ArrayElements_OtherTypes_Extended()
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"RPT WXP2 Arrays B", true));
        Observer.Ignore('part'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

}
