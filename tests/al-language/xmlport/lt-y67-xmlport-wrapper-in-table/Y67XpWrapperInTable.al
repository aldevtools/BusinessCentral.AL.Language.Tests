// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 93619-93621, codeunit 93622 (log), xmlports 93623-93624, codeunit 93625 (writer Y67)
// Probe: EXPORT of a text element with content inside a table element, in the shape of a SOAP-style response: a table element
//   (MinOccurs = Zero, MaxOccurs = Unbounded) that holds a text attribute, a text element with its own trigger, and a text element
//   (MaxOccurs = Once, MinOccurs = Zero) that holds field elements with text attributes, text elements with text attributes and
//   triggers, a text element that wraps a table element (field attributes and a text attribute with a trigger) and a table element
//   directly in the wrapper (field elements, one with a text attribute). Run with temporary table elements (filled through SetTables-style
//   procedure) and with real tables; with and without rows in the inner table elements; with no row in the outer table element; with Skip
//   in the wrapper's OnBeforePassVariable. Y60 (xmlport/lt-y60-xmlport-text-in-table/Y60XpTextInTable.al) pins other shapes of the same family.
// BC versions: 27, 28, 29

table 93619 "LT Y67 WT Hdr"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 93620 "LT Y67 WT Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Hdr No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Item; Text[30]) { }
    }

    keys
    {
        key(PK; "Hdr No.", "Line No.") { Clustered = true; }
    }
}

table 93621 "LT Y67 WT Det"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Det No."; Integer) { }
        field(2; Info; Text[30]) { }
    }

    keys
    {
        key(PK; "Det No.") { Clustered = true; }
    }
}

codeunit 93622 "LT Y67 WT Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Add(Line: Text)
    begin
        Lines += Line + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Lines;
        Lines := '';
        exit(Result);
    end;
}

xmlport 93623 "LT Y67 WT Member Temp Exp"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Resp; "LT Y67 WT Hdr")
            {
                MinOccurs = Zero;
                MaxOccurs = Unbounded;
                UseTemporary = true;
                textattribute(inst)
                {
                    trigger OnBeforePassVariable()
                    begin
                        Log.Add('inst');
                        inst := 'I1';
                    end;
                }
                textelement(status)
                {
                    MaxOccurs = Once;

                    trigger OnBeforePassVariable()
                    begin
                        Log.Add('status');
                        status := 'ok';
                    end;
                }
                textelement(membership)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    fieldelement(code; Resp."No.")
                    {
                        textattribute(codename)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                Log.Add('codename');
                                codename := 'N-' + Resp."No.";
                            end;
                        }
                    }
                    fieldelement(title; Resp.Name) { }
                    textelement(loyalty)
                    {
                        MaxOccurs = Once;
                        textattribute(loyname)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                Log.Add('loyname');
                                loyname := 'L';
                            end;
                        }

                        trigger OnBeforePassVariable()
                        begin
                            Log.Add('loyalty');
                            loyalty := 'lv';
                        end;
                    }
                    textelement(counts)
                    {
                        textattribute(named)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                named := '1';
                            end;
                        }
                        textattribute(anon)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                anon := '2';
                            end;
                        }

                        trigger OnBeforePassVariable()
                        begin
                            Log.Add('counts');
                            counts := '3';
                        end;
                    }
                    textelement(attributes)
                    {
                        MaxOccurs = Once;
                        MinOccurs = Zero;
                        tableelement(Attr; "LT Y67 WT Det")
                        {
                            MinOccurs = Zero;
                    UseTemporary = true;
                            fieldattribute(dno; Attr."Det No.") { }
                            textattribute(attrname)
                            {
                                trigger OnBeforePassVariable()
                                begin
                                    Log.Add('attrname');
                                    attrname := 'A' + Format(Attr."Det No.");
                                end;
                            }
                            fieldattribute(info; Attr.Info) { }

                            trigger OnAfterGetRecord()
                            begin
                                Log.Add('attr ' + Format(Attr."Det No."));
                            end;
                        }

                        trigger OnBeforePassVariable()
                        begin
                            Log.Add('attributes');
                        end;
                    }
                    tableelement(Entry; "LT Y67 WT Line")
                    {
                        MinOccurs = Zero;
                    UseTemporary = true;
                        fieldelement(line; Entry."Line No.") { }
                        fieldelement(item; Entry.Item)
                        {
                            textattribute(itemname)
                            {
                                trigger OnBeforePassVariable()
                                begin
                                    itemname := 'it';
                                end;
                            }
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Log.Add('entry ' + Format(Entry."Line No."));
                        end;
                    }

                    trigger OnBeforePassVariable()
                    begin
                        Log.Add('membership');
                        if Mode = 1 then
                            currXMLport.Skip();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('resp ' + Resp."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y67 WT Log";
        Mode: Integer;

    procedure SetData(var TempHdr: Record "LT Y67 WT Hdr" temporary; var TempLine: Record "LT Y67 WT Line" temporary; var TempDet: Record "LT Y67 WT Det" temporary; NewMode: Integer)
    begin
        Mode := NewMode;
        if TempHdr.FindSet() then
            repeat
                Resp := TempHdr;
                Resp.Insert();
            until TempHdr.Next() = 0;
        if TempLine.FindSet() then
            repeat
                Entry := TempLine;
                Entry.Insert();
            until TempLine.Next() = 0;
        if TempDet.FindSet() then
            repeat
                Attr := TempDet;
                Attr.Insert();
            until TempDet.Next() = 0;
    end;
}

xmlport 93624 "LT Y67 WT Member Real Exp"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Resp; "LT Y67 WT Hdr")
            {
                MinOccurs = Zero;
                MaxOccurs = Unbounded;
                textattribute(inst)
                {
                    trigger OnBeforePassVariable()
                    begin
                        Log.Add('inst');
                        inst := 'I1';
                    end;
                }
                textelement(status)
                {
                    MaxOccurs = Once;

                    trigger OnBeforePassVariable()
                    begin
                        Log.Add('status');
                        status := 'ok';
                    end;
                }
                textelement(membership)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    fieldelement(code; Resp."No.")
                    {
                        textattribute(codename)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                Log.Add('codename');
                                codename := 'N-' + Resp."No.";
                            end;
                        }
                    }
                    fieldelement(title; Resp.Name) { }
                    textelement(loyalty)
                    {
                        MaxOccurs = Once;
                        textattribute(loyname)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                Log.Add('loyname');
                                loyname := 'L';
                            end;
                        }

                        trigger OnBeforePassVariable()
                        begin
                            Log.Add('loyalty');
                            loyalty := 'lv';
                        end;
                    }
                    textelement(counts)
                    {
                        textattribute(named)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                named := '1';
                            end;
                        }
                        textattribute(anon)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                anon := '2';
                            end;
                        }

                        trigger OnBeforePassVariable()
                        begin
                            Log.Add('counts');
                            counts := '3';
                        end;
                    }
                    textelement(attributes)
                    {
                        MaxOccurs = Once;
                        MinOccurs = Zero;
                        tableelement(Attr; "LT Y67 WT Det")
                        {
                            MinOccurs = Zero;
                            fieldattribute(dno; Attr."Det No.") { }
                            textattribute(attrname)
                            {
                                trigger OnBeforePassVariable()
                                begin
                                    Log.Add('attrname');
                                    attrname := 'A' + Format(Attr."Det No.");
                                end;
                            }
                            fieldattribute(info; Attr.Info) { }

                            trigger OnAfterGetRecord()
                            begin
                                Log.Add('attr ' + Format(Attr."Det No."));
                            end;
                        }

                        trigger OnBeforePassVariable()
                        begin
                            Log.Add('attributes');
                        end;
                    }
                    tableelement(Entry; "LT Y67 WT Line")
                    {
                        MinOccurs = Zero;
                        fieldelement(line; Entry."Line No.") { }
                        fieldelement(item; Entry.Item)
                        {
                            textattribute(itemname)
                            {
                                trigger OnBeforePassVariable()
                                begin
                                    itemname := 'it';
                                end;
                            }
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Log.Add('entry ' + Format(Entry."Line No."));
                        end;
                    }

                    trigger OnBeforePassVariable()
                    begin
                        Log.Add('membership');
                        if Mode = 1 then
                            currXMLport.Skip();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('resp ' + Resp."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y67 WT Log";
        Mode: Integer;

    procedure SetData(NewMode: Integer)
    begin
        Mode := NewMode;
    end;
}

codeunit 93625 "LT Y67 WT Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y67 WT Log";

    local procedure Clean()
    var
        Hdr: Record "LT Y67 WT Hdr";
        Line: Record "LT Y67 WT Line";
        Det: Record "LT Y67 WT Det";
    begin
        Hdr.DeleteAll();
        Line.DeleteAll();
        Det.DeleteAll();
        Log.Take();
    end;

    local procedure Fill(var Hdr: Record "LT Y67 WT Hdr"; var Line: Record "LT Y67 WT Line"; var Det: Record "LT Y67 WT Det"; Rows: Integer; WithLines: Boolean; WithDets: Boolean)
    var
        i: Integer;
    begin
        for i := 1 to Rows do begin
            Hdr."No." := 'H' + Format(i);
            Hdr.Name := 'name' + Format(i);
            Hdr.Insert();
        end;
        if WithLines then begin
            Line."Hdr No." := 'H1';
            Line."Line No." := 10;
            Line.Item := 'x';
            Line.Insert();
            Line."Line No." := 20;
            Line.Item := 'y';
            Line.Insert();
        end;
        if WithDets then begin
            Det."Det No." := 1;
            Det.Info := 'i1';
            Det.Insert();
            Det."Det No." := 2;
            Det.Info := 'i2';
            Det.Insert();
        end;
    end;

    local procedure Text_(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    local procedure RunTemp(var Observer: Codeunit "Probe Observer"; Name: Text; Rows: Integer; WithLines: Boolean; WithDets: Boolean; Mode: Integer)
    var
        Hdr: Record "LT Y67 WT Hdr" temporary;
        Line: Record "LT Y67 WT Line" temporary;
        Det: Record "LT Y67 WT Det" temporary;
        Xp: XmlPort "LT Y67 WT Member Temp Exp";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Log.Take();
        Fill(Hdr, Line, Det, Rows, WithLines, WithDets);
        Xp.SetData(Hdr, Line, Det, Mode);
        TempBlob.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        Observer.Observe(Name + ' xml', Text_(TempBlob));
        Observer.Observe(Name + ' log', Log.Take());
    end;

    local procedure RunReal(var Observer: Codeunit "Probe Observer"; Name: Text; Rows: Integer; WithLines: Boolean; WithDets: Boolean; Mode: Integer)
    var
        Hdr: Record "LT Y67 WT Hdr";
        Line: Record "LT Y67 WT Line";
        Det: Record "LT Y67 WT Det";
        Xp: XmlPort "LT Y67 WT Member Real Exp";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Clean();
        Fill(Hdr, Line, Det, Rows, WithLines, WithDets);
        Xp.SetData(Mode);
        TempBlob.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        Observer.Observe(Name + ' xml', Text_(TempBlob));
        Observer.Observe(Name + ' log', Log.Take());
    end;

    [Test]
    procedure Temp_AllRows_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTemp(Observer, 'two resp', 2, true, true, 0);
        Observer.Finish();
    end;

    [Test]
    procedure Temp_MissingInnerRows_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTemp(Observer, 'no lines', 1, false, true, 0);
        RunTemp(Observer, 'no dets', 1, true, false, 0);
        RunTemp(Observer, 'neither', 1, false, false, 0);
        Observer.Finish();
    end;

    [Test]
    procedure Temp_NoOuterRow_And_SkipWrapper_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTemp(Observer, 'no resp', 0, true, true, 0);
        RunTemp(Observer, 'skip wrapper', 2, true, true, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Real_AllRows_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunReal(Observer, 'two resp', 2, true, true, 0);
        Observer.Finish();
    end;

    [Test]
    procedure Real_MissingInnerRows_And_Skip_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunReal(Observer, 'no lines', 1, false, true, 0);
        RunReal(Observer, 'neither', 1, false, false, 0);
        RunReal(Observer, 'no resp', 0, true, true, 0);
        RunReal(Observer, 'skip wrapper', 2, true, true, 1);
        Observer.Finish();
    end;
}
