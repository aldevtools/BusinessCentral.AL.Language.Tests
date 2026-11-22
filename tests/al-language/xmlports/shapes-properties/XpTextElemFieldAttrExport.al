// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/xmlport/devenv-onbeforepassvariable-xmlport-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (System Application); own table 77720, xmlports 77721-77727, test codeunit 77728.
// local object: the text element's fieldattribute, its own text and its OnBeforePassVariable trigger are what is under test.
// Probe: al-runner issue 7865. An Xml export of Root > temporary table element Line > text element MinValue (MaxOccurs = Once) with a
//   fieldattribute from a field of Line. Ports:
//     Attr Trigger       fieldattribute (Boolean field) and the element's own OnBeforePassVariable sets or clears the text; MinOccurs = Zero
//                        (the reporter's shape)
//     Attr Only          fieldattribute; the table element's OnAfterGetRecord sets or clears the text
//     Trigger Only       OnBeforePassVariable, no attribute (control)
//     Attr Trigger Once  as Attr Trigger, MinOccurs not set
//     Attr Trigger Flip  as Attr Trigger; the trigger also flips the attribute's field (is the attribute written before or after it)
//     Text Attr Trigger  as Attr Trigger with the attribute on a Text field that is blank in some rows
//     Attr Never         fieldattribute; the text element is never assigned
//   Each test exports one line with value 5, one line with value 0 (the text cleared) and three lines (5, 0, 7.5) and records the text.
//   Y67XpTextAttrSkip.al pins text attributes on a text element outside a table element.
// Facts: with a fieldattribute the element is always written: <MinValue equalsValid="true">5</MinValue> with text, <MinValue equalsValid="true" />
//   when the text is cleared or never assigned, also with MinOccurs = Zero and with a blank Text attribute (note=""). It makes no difference
//   whether OnBeforePassVariable or the table element's OnAfterGetRecord sets the text, or whether MinOccurs is Zero or not set. The
//   attribute value is read after the element's OnBeforePassVariable (a change of its field there is written). Without an attribute a cleared
//   text is written as <MinValue />.
// BC versions: 27, 28, 29 (values observed on local BC 27.5, 28.5 and 29.0, identical; the corpus CI run checks all three)

table 77720 "XP TEA Line"
{
    // local object: the exported lines.
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Default Min. Value"; Decimal) { }
        field(3; "Min. Value Equals Valid"; Boolean) { }
        field(4; Note; Text[30]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

xmlport 77721 "XP TEA Attr Trigger"
{
    // local object: fieldattribute and its own OnBeforePassVariable (the reporter's shape).
    Direction = Export;
    Format = Xml;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            MaxOccurs = Once;
            MinOccurs = Once;
            tableelement(Line; "XP TEA Line")
            {
                MinOccurs = Zero;
                UseTemporary = true;
                fieldelement(EntryNo; Line."Entry No.") { }
                textelement(MinValue)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    fieldattribute(equalsValid; Line."Min. Value Equals Valid") { }

                    trigger OnBeforePassVariable()
                    begin
                        if Line."Default Min. Value" <> 0 then
                            MinValue := Format(Line."Default Min. Value", 0, 2)
                        else
                            Clear(MinValue);
                    end;
                }
            }
        }
    }

    procedure SetLines(var TempLine: Record "XP TEA Line" temporary)
    begin
        if TempLine.FindSet() then
            repeat
                Line := TempLine;
                Line.Insert();
            until TempLine.Next() = 0;
    end;
}

xmlport 77722 "XP TEA Attr Only"
{
    // local object: fieldattribute, the text set in the table element's OnAfterGetRecord.
    Direction = Export;
    Format = Xml;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            MaxOccurs = Once;
            MinOccurs = Once;
            tableelement(Line; "XP TEA Line")
            {
                MinOccurs = Zero;
                UseTemporary = true;
                fieldelement(EntryNo; Line."Entry No.") { }
                textelement(MinValue)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    fieldattribute(equalsValid; Line."Min. Value Equals Valid") { }
                }

                trigger OnAfterGetRecord()
                begin
                    if Line."Default Min. Value" <> 0 then
                        MinValue := Format(Line."Default Min. Value", 0, 2)
                    else
                        Clear(MinValue);
                end;
            }
        }
    }

    procedure SetLines(var TempLine: Record "XP TEA Line" temporary)
    begin
        if TempLine.FindSet() then
            repeat
                Line := TempLine;
                Line.Insert();
            until TempLine.Next() = 0;
    end;
}

xmlport 77723 "XP TEA Trigger Only"
{
    // local object: own OnBeforePassVariable, no attribute (control).
    Direction = Export;
    Format = Xml;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            MaxOccurs = Once;
            MinOccurs = Once;
            tableelement(Line; "XP TEA Line")
            {
                MinOccurs = Zero;
                UseTemporary = true;
                fieldelement(EntryNo; Line."Entry No.") { }
                textelement(MinValue)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;

                    trigger OnBeforePassVariable()
                    begin
                        if Line."Default Min. Value" <> 0 then
                            MinValue := Format(Line."Default Min. Value", 0, 2)
                        else
                            Clear(MinValue);
                    end;
                }
            }
        }
    }

    procedure SetLines(var TempLine: Record "XP TEA Line" temporary)
    begin
        if TempLine.FindSet() then
            repeat
                Line := TempLine;
                Line.Insert();
            until TempLine.Next() = 0;
    end;
}

xmlport 77724 "XP TEA Attr Trigger Once"
{
    // local object: fieldattribute and OnBeforePassVariable, MinOccurs not set.
    Direction = Export;
    Format = Xml;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            MaxOccurs = Once;
            MinOccurs = Once;
            tableelement(Line; "XP TEA Line")
            {
                MinOccurs = Zero;
                UseTemporary = true;
                fieldelement(EntryNo; Line."Entry No.") { }
                textelement(MinValue)
                {
                    MaxOccurs = Once;
                    fieldattribute(equalsValid; Line."Min. Value Equals Valid") { }

                    trigger OnBeforePassVariable()
                    begin
                        if Line."Default Min. Value" <> 0 then
                            MinValue := Format(Line."Default Min. Value", 0, 2)
                        else
                            Clear(MinValue);
                    end;
                }
            }
        }
    }

    procedure SetLines(var TempLine: Record "XP TEA Line" temporary)
    begin
        if TempLine.FindSet() then
            repeat
                Line := TempLine;
                Line.Insert();
            until TempLine.Next() = 0;
    end;
}

xmlport 77725 "XP TEA Attr Trigger Flip"
{
    // local object: fieldattribute and OnBeforePassVariable that also flips the attribute's field.
    Direction = Export;
    Format = Xml;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            MaxOccurs = Once;
            MinOccurs = Once;
            tableelement(Line; "XP TEA Line")
            {
                MinOccurs = Zero;
                UseTemporary = true;
                fieldelement(EntryNo; Line."Entry No.") { }
                textelement(MinValue)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    fieldattribute(equalsValid; Line."Min. Value Equals Valid") { }

                    trigger OnBeforePassVariable()
                    begin
                        if Line."Default Min. Value" <> 0 then
                            MinValue := Format(Line."Default Min. Value", 0, 2)
                        else
                            Clear(MinValue);
                        Line."Min. Value Equals Valid" := not Line."Min. Value Equals Valid";
                    end;
                }
            }
        }
    }

    procedure SetLines(var TempLine: Record "XP TEA Line" temporary)
    begin
        if TempLine.FindSet() then
            repeat
                Line := TempLine;
                Line.Insert();
            until TempLine.Next() = 0;
    end;
}

xmlport 77726 "XP TEA Text Attr Trigger"
{
    // local object: fieldattribute on a Text field and OnBeforePassVariable.
    Direction = Export;
    Format = Xml;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            MaxOccurs = Once;
            MinOccurs = Once;
            tableelement(Line; "XP TEA Line")
            {
                MinOccurs = Zero;
                UseTemporary = true;
                fieldelement(EntryNo; Line."Entry No.") { }
                textelement(MinValue)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    fieldattribute(note; Line.Note) { }

                    trigger OnBeforePassVariable()
                    begin
                        if Line."Default Min. Value" <> 0 then
                            MinValue := Format(Line."Default Min. Value", 0, 2)
                        else
                            Clear(MinValue);
                    end;
                }
            }
        }
    }

    procedure SetLines(var TempLine: Record "XP TEA Line" temporary)
    begin
        if TempLine.FindSet() then
            repeat
                Line := TempLine;
                Line.Insert();
            until TempLine.Next() = 0;
    end;
}

xmlport 77727 "XP TEA Attr Never"
{
    // local object: fieldattribute, the text element never assigned.
    Direction = Export;
    Format = Xml;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            MaxOccurs = Once;
            MinOccurs = Once;
            tableelement(Line; "XP TEA Line")
            {
                MinOccurs = Zero;
                UseTemporary = true;
                fieldelement(EntryNo; Line."Entry No.") { }
                textelement(MinValue)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    fieldattribute(equalsValid; Line."Min. Value Equals Valid") { }
                }
            }
        }
    }

    procedure SetLines(var TempLine: Record "XP TEA Line" temporary)
    begin
        if TempLine.FindSet() then
            repeat
                Line := TempLine;
                Line.Insert();
            until TempLine.Next() = 0;
    end;
}

codeunit 77728 "XP TEA Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure AddLine(var TempLine: Record "XP TEA Line" temporary; EntryNo: Integer; MinValue: Decimal; EqualsValid: Boolean; Note: Text[30])
    begin
        TempLine.Init();
        TempLine."Entry No." := EntryNo;
        TempLine."Default Min. Value" := MinValue;
        TempLine."Min. Value Equals Valid" := EqualsValid;
        TempLine.Note := Note;
        TempLine.Insert();
    end;

    local procedure ExportText(XmlPortId: Integer; var TempLine: Record "XP TEA Line" temporary): Text
    var
        TempBlob: Codeunit "Temp Blob";
        AttrTrigger: XmlPort "XP TEA Attr Trigger";
        AttrOnly: XmlPort "XP TEA Attr Only";
        TriggerOnly: XmlPort "XP TEA Trigger Only";
        AttrTriggerOnce: XmlPort "XP TEA Attr Trigger Once";
        AttrTriggerFlip: XmlPort "XP TEA Attr Trigger Flip";
        TextAttrTrigger: XmlPort "XP TEA Text Attr Trigger";
        AttrNever: XmlPort "XP TEA Attr Never";
        OutS: OutStream;
        InS: InStream;
        Part: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        case XmlPortId of
            Xmlport::"XP TEA Attr Trigger":
                begin
                    AttrTrigger.SetLines(TempLine);
                    AttrTrigger.SetDestination(OutS);
                    AttrTrigger.Export();
                end;
            Xmlport::"XP TEA Attr Only":
                begin
                    AttrOnly.SetLines(TempLine);
                    AttrOnly.SetDestination(OutS);
                    AttrOnly.Export();
                end;
            Xmlport::"XP TEA Trigger Only":
                begin
                    TriggerOnly.SetLines(TempLine);
                    TriggerOnly.SetDestination(OutS);
                    TriggerOnly.Export();
                end;
            Xmlport::"XP TEA Attr Trigger Once":
                begin
                    AttrTriggerOnce.SetLines(TempLine);
                    AttrTriggerOnce.SetDestination(OutS);
                    AttrTriggerOnce.Export();
                end;
            Xmlport::"XP TEA Attr Trigger Flip":
                begin
                    AttrTriggerFlip.SetLines(TempLine);
                    AttrTriggerFlip.SetDestination(OutS);
                    AttrTriggerFlip.Export();
                end;
            Xmlport::"XP TEA Text Attr Trigger":
                begin
                    TextAttrTrigger.SetLines(TempLine);
                    TextAttrTrigger.SetDestination(OutS);
                    TextAttrTrigger.Export();
                end;
            Xmlport::"XP TEA Attr Never":
                begin
                    AttrNever.SetLines(TempLine);
                    AttrNever.SetDestination(OutS);
                    AttrNever.Export();
                end;
        end;
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        while not InS.EOS() do begin
            InS.ReadText(Part);
            if Result <> '' then
                Result += '|';
            Result += Part;
        end;
        exit(Result);
    end;

    local procedure Measure(XmlPortId: Integer)
    var
        TempLine: Record "XP TEA Line" temporary;
    begin
        AddLine(TempLine, 1, 5, true, '');
        Observer.Observe('value 5', ExportText(XmlPortId, TempLine));
        TempLine.DeleteAll();
        AddLine(TempLine, 1, 0, true, '');
        Observer.Observe('value cleared', ExportText(XmlPortId, TempLine));
        TempLine.DeleteAll();
        AddLine(TempLine, 1, 5, true, '');
        AddLine(TempLine, 2, 0, true, '');
        AddLine(TempLine, 3, 7.5, false, 'n3');
        Observer.Observe('three lines', ExportText(XmlPortId, TempLine));
    end;

    [Test]
    procedure TEA_AttrTrigger_Export()
    begin
        Measure(Xmlport::"XP TEA Attr Trigger");
        Observer.Expect('value 5', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue equalsValid="true">5</MinValue>|  </Line>|</Root>');
        Observer.Expect('value cleared', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue equalsValid="true" />|  </Line>|</Root>');
        Observer.Expect('three lines', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue equalsValid="true">5</MinValue>|  </Line>|  <Line>|    <EntryNo>2</EntryNo>|    <MinValue equalsValid="true" />|  </Line>|  <Line>|    <EntryNo>3</EntryNo>|    <MinValue equalsValid="false">7.5</MinValue>|  </Line>|</Root>');
        Observer.Verify();
    end;

    [Test]
    procedure TEA_AttrOnly_Export()
    begin
        Measure(Xmlport::"XP TEA Attr Only");
        Observer.Expect('value 5', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue equalsValid="true">5</MinValue>|  </Line>|</Root>');
        Observer.Expect('value cleared', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue equalsValid="true" />|  </Line>|</Root>');
        Observer.Expect('three lines', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue equalsValid="true">5</MinValue>|  </Line>|  <Line>|    <EntryNo>2</EntryNo>|    <MinValue equalsValid="true" />|  </Line>|  <Line>|    <EntryNo>3</EntryNo>|    <MinValue equalsValid="false">7.5</MinValue>|  </Line>|</Root>');
        Observer.Verify();
    end;

    [Test]
    procedure TEA_TriggerOnly_Export()
    begin
        Measure(Xmlport::"XP TEA Trigger Only");
        Observer.Expect('value 5', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue>5</MinValue>|  </Line>|</Root>');
        Observer.Expect('value cleared', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue />|  </Line>|</Root>');
        Observer.Expect('three lines', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue>5</MinValue>|  </Line>|  <Line>|    <EntryNo>2</EntryNo>|    <MinValue />|  </Line>|  <Line>|    <EntryNo>3</EntryNo>|    <MinValue>7.5</MinValue>|  </Line>|</Root>');
        Observer.Verify();
    end;

    [Test]
    procedure TEA_AttrTriggerOnce_Export()
    begin
        Measure(Xmlport::"XP TEA Attr Trigger Once");
        Observer.Expect('value 5', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue equalsValid="true">5</MinValue>|  </Line>|</Root>');
        Observer.Expect('value cleared', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue equalsValid="true" />|  </Line>|</Root>');
        Observer.Expect('three lines', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue equalsValid="true">5</MinValue>|  </Line>|  <Line>|    <EntryNo>2</EntryNo>|    <MinValue equalsValid="true" />|  </Line>|  <Line>|    <EntryNo>3</EntryNo>|    <MinValue equalsValid="false">7.5</MinValue>|  </Line>|</Root>');
        Observer.Verify();
    end;

    [Test]
    procedure TEA_AttrTriggerFlip_Export()
    begin
        Measure(Xmlport::"XP TEA Attr Trigger Flip");
        Observer.Expect('value 5', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue equalsValid="false">5</MinValue>|  </Line>|</Root>');
        Observer.Expect('value cleared', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue equalsValid="false" />|  </Line>|</Root>');
        Observer.Expect('three lines', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue equalsValid="false">5</MinValue>|  </Line>|  <Line>|    <EntryNo>2</EntryNo>|    <MinValue equalsValid="false" />|  </Line>|  <Line>|    <EntryNo>3</EntryNo>|    <MinValue equalsValid="true">7.5</MinValue>|  </Line>|</Root>');
        Observer.Verify();
    end;

    [Test]
    procedure TEA_TextAttrTrigger_Export()
    begin
        Measure(Xmlport::"XP TEA Text Attr Trigger");
        Observer.Expect('value 5', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue note="">5</MinValue>|  </Line>|</Root>');
        Observer.Expect('value cleared', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue note="" />|  </Line>|</Root>');
        Observer.Expect('three lines', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue note="">5</MinValue>|  </Line>|  <Line>|    <EntryNo>2</EntryNo>|    <MinValue note="" />|  </Line>|  <Line>|    <EntryNo>3</EntryNo>|    <MinValue note="n3">7.5</MinValue>|  </Line>|</Root>');
        Observer.Verify();
    end;

    [Test]
    procedure TEA_AttrNever_Export()
    begin
        Measure(Xmlport::"XP TEA Attr Never");
        Observer.Expect('value 5', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue equalsValid="true" />|  </Line>|</Root>');
        Observer.Expect('value cleared', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue equalsValid="true" />|  </Line>|</Root>');
        Observer.Expect('three lines', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line>|    <EntryNo>1</EntryNo>|    <MinValue equalsValid="true" />|  </Line>|  <Line>|    <EntryNo>2</EntryNo>|    <MinValue equalsValid="true" />|  </Line>|  <Line>|    <EntryNo>3</EntryNo>|    <MinValue equalsValid="false" />|  </Line>|</Root>');
        Observer.Verify();
    end;
}
