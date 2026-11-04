// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-minoccurs-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 91675-91676, xmlport 91677, codeunits 91678-91679
// Probe: observe probe (writer Y14, 2026-10-31, runtime asks from partner-app triage); every literal asserted below is what the BC service tier produced.
// Facts: XmlPort export where a table element is LINKED to its parent table element (LinkTable and LinkFields) with MinOccurs = Zero and MaxOccurs = Once:
//   the XML for a parent with no, one and two child rows (the parent keys are inserted out of order, the child rows of the last parent too), which child row is
//   written, and the order of the child's OnPreXmlItem and OnAfterGetRecord. Related pins: misc/lt-np4-probes/Np4XmlPort.al (linked Once/Once,
//   unlinked Zero/Once) and xmlport/lt-xmlport-linktable/XmlPortLinkTableNoLinkFields.al.
// BC versions: 27, 28, 29

table 91675 "LT Y14 XP Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; No; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys { key(PK; No) { Clustered = true; } }
}

table 91676 "LT Y14 XP Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; ParentNo; Integer) { }
        field(2; Seq; Integer) { }
        field(3; Txt; Text[30]) { }
    }
    keys { key(PK; ParentNo, Seq) { Clustered = true; } }
}

codeunit 91678 "LT Y14 XP Log"
{
    SingleInstance = true;

    var
        Text: Text;

    procedure Add(Entry: Text)
    begin
        Text += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Text;
        Text := '';
        exit(Result);
    end;
}

xmlport 91677 "LT Y14 XP Linked Zero Once"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(Par; "LT Y14 XP Parent")
            {
                XmlName = 'Parent';
                MinOccurs = Zero;
                MaxOccurs = Unbounded;

                fieldattribute(No; Par.No) { }

                tableelement(Chi; "LT Y14 XP Child")
                {
                    XmlName = 'Child';
                    LinkTable = Par;
                    LinkFields = ParentNo = field(No);
                    MinOccurs = Zero;
                    MaxOccurs = Once;

                    fieldelement(Seq; Chi.Seq) { }
                    fieldelement(Txt; Chi.Txt) { }

                    trigger OnPreXmlItem()
                    begin
                        Log.Add('pre(' + Format(Par.No) + ')');
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        Log.Add('agr(' + Format(Chi.ParentNo) + '/' + Format(Chi.Seq) + ')');
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('parent(' + Format(Par.No) + ')');
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y14 XP Log";
}

codeunit 91679 "LT Y14 XP Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Export(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        Port: XmlPort "LT Y14 XP Linked Zero Once";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Port.Export();
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    [Test]
    procedure LinkedZeroOnce_ZeroOneTwoChildren()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y14 XP Log";
        P: Record "LT Y14 XP Parent";
        C: Record "LT Y14 XP Child";
    begin
        P.DeleteAll();
        C.DeleteAll();
        Log.Take();
        // parents inserted out of key order; parent 3 gets two children, inserted out of key order
        P.No := 3;
        P.Insert();
        P.No := 1;
        P.Insert();
        P.No := 2;
        P.Insert();
        C.ParentNo := 2;
        C.Seq := 10;
        C.Txt := 'p2c10';
        C.Insert();
        C.ParentNo := 3;
        C.Seq := 20;
        C.Txt := 'p3c20';
        C.Insert();
        C.ParentNo := 3;
        C.Seq := 10;
        C.Txt := 'p3c10';
        C.Insert();
        Observer.Observe('export', Export());
        Observer.Observe('log', Log.Take());
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Parent No="1" />|  <Parent No="2">|    <Child>|      <Seq>10</Seq>|      <Txt>p2c10</Txt>|    </Child>|  </Parent>|  <Parent No="3">|    <Child>|      <Seq>10</Seq>|      <Txt>p3c10</Txt>|    </Child>|  </Parent>|</Root>|');
        Observer.Expect('log', 'parent(1);pre(1);parent(2);pre(2);agr(2/10);parent(3);pre(3);agr(3/10);');
        Observer.Verify();
    end;
}
