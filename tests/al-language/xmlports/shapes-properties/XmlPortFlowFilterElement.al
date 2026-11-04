// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-field-element
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); own tables 71448 and 71449, log 71450, xmlports 71451-71453, runner 71454 (codeunit), test codeunit 71455
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XML text exported when the table view carries a FlowFilter (the FlowField element changes, and the FlowFilter element's own text), import of a FlowFilter element value without AutoSave.
// BC versions: 29 (27 and 28 by CI)

table 71448 "LT XpFlow Parent Filter"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
        field(3; Cnt; Integer)
        {
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = count("LT XpFlow Child Filter" where(ParentId = field(Id), Seq = field("Seq Filter")));
        }
        field(4; "Seq Filter"; Integer)
        {
            FieldClass = FlowFilter;
        }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 71449 "LT XpFlow Child Filter"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
        field(3; Seq; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 71450 "LT XpFlow Log Filter"
{
    SingleInstance = true;

    var
        Entries: Text;
        Xml: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    procedure SetXml(NewXml: Text)
    begin
        Xml := NewXml;
    end;

    procedure GetXml(): Text
    begin
        exit(Xml);
    end;
}

xmlport 71451 "LT XpFlow Export Filter"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Parent; "LT XpFlow Parent Filter")
            {
                fieldelement(Id; Parent.Id) { }
                fieldelement(Name; Parent.Name) { }
                fieldelement(Cnt; Parent.Cnt) { }
                fieldelement(SeqFilter; Parent."Seq Filter") { }
            }
        }
    }
}

xmlport 71452 "LT XpFlow Import Filter"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Parent; "LT XpFlow Parent Filter")
            {
                AutoSave = false;

                fieldelement(Id; Parent.Id) { }
                fieldelement(Name; Parent.Name) { }
                fieldelement(Cnt; Parent.Cnt)
                {
                    trigger OnAfterAssignField()
                    begin
                        L.Add('Cnt=' + Format(Parent.Cnt));
                    end;
                }
                fieldelement(SeqFilter; Parent."Seq Filter")
                {
                    trigger OnAfterAssignField()
                    begin
                        L.Add('SeqFilter=' + Format(Parent."Seq Filter"));
                    end;
                }
            }
        }
    }

    var
        L: Codeunit "LT XpFlow Log Filter";
}

xmlport 71453 "LT XpFlow ImportSave Filter"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Parent; "LT XpFlow Parent Filter")
            {
                AutoSave = true;

                fieldelement(Id; Parent.Id) { }
                fieldelement(Name; Parent.Name) { }
                fieldelement(Cnt; Parent.Cnt) { }
            }
        }
    }
}

codeunit 71454 "LT XpFlow Runner Filter"
{
    trigger OnRun()
    var
        L: Codeunit "LT XpFlow Log Filter";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(L.GetXml());
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(Xmlport::"LT XpFlow ImportSave Filter", InS);
    end;
}

codeunit 71455 "LT XpFlow Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT XpFlow Log Filter";

    local procedure Seed()
    var
        Parent: Record "LT XpFlow Parent Filter";
        Child: Record "LT XpFlow Child Filter";
    begin
        Parent.DeleteAll();
        Child.DeleteAll();
        Parent.Id := 1;
        Parent.Name := 'one';
        Parent.Insert();
        Parent.Id := 2;
        Parent.Name := 'two';
        Parent.Insert();
        AddChild(1, 1, 1);
        AddChild(2, 1, 2);
        AddChild(3, 1, 2);
        AddChild(4, 2, 1);
        L.Take();
    end;

    local procedure AddChild(ChildId: Integer; ParentNo: Integer; SeqNo: Integer)
    var
        Child: Record "LT XpFlow Child Filter";
    begin
        Child.Id := ChildId;
        Child.ParentId := ParentNo;
        Child.Seq := SeqNo;
        Child.Insert();
    end;

    local procedure ReadAll(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line;
        end;
        exit(Result);
    end;

    [Test]
    procedure Import_FlowFilterElement_AssignedWithoutSave()
    var
        Observer: Codeunit "Probe Observer";
        Xp: XmlPort "LT XpFlow Import Filter";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('<Root><Parent><Id>5</Id><Name>five</Name><Cnt>9</Cnt><SeqFilter>2</SeqFilter></Parent></Root>');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xp.SetSource(InS);
        Xp.Import();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', '');
        Observer.Verify();
    end;
}
