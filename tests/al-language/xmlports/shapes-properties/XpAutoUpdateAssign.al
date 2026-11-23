// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoupdate-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); own tables 72915-72921, xmlports 72922-72929 and 72932, log 72930, test codeunit 72931
// Probe: observe probe; every literal asserted below is what the corpus CI service tiers produced.
// Facts: an XmlPort import into a row that already exists, where triggers assign fields of the row:
//   - AutoUpdate = true, an OnAfterAssignField of the key field, of a carried field, an OnAfterAssignVariable of a text element, and an
//     OnAfterInitRecord, each assigning a field: which value the stored row ends with, for a field the document carries or not;
//     what Rec holds inside the trigger (the fresh or the stored values) and inside OnBeforeModifyRecord (the merged row or not);
//   - AutoUpdate = true on a parent with a linked child table element (the parent is stored again after its child rows);
//   - no AutoUpdate or AutoReplace: a parent stored before its linked child rows and stored again after them, when a child trigger
//     changed the parent's record variable, or the child table's OnInsert changed the stored parent row;
//   - the shape of an import of a suite with an OnAfterAssignField on its key attribute that looks the row up, skips it, deletes it or
//     raises, and assigns two other fields; a text attribute that assigns a field; linked child and grandchild table elements
//     with Skip in OnAfterInitRecord and a line number set in OnBeforeInsertRecord; a linked child with a SourceTableView.
// BC versions: 29 (27 and 28 by CI)

table 72915 "LT XAU Par"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Stamp; Text[30]) { }
        field(4; Extra; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 72916 "LT XAU Chi"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
        field(3; Note; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

// A child table whose OnInsert changes the stored parent row through a record variable of its own.
table 72917 "LT XAU ChiW"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    var
        P: Record "LT XAU Par";
    begin
        if P.Get(ParentId) then begin
            P.Stamp := 'db';
            P.Modify();
        end;
    end;
}

table 72918 "LT XAU Suite"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Description; Text[50]) { }
        field(3; AppId; Text[30]) { }
        field(4; Hash; Text[30]) { }
        field(5; Validation; Boolean) { }
        field(6; Runner; Integer) { }
    }

    keys { key(PK; Code) { Clustered = true; } }

    trigger OnInsert()
    begin
        if Runner = 0 then
            Runner := 7;
    end;
}

table 72919 "LT XAU Lang"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; SuiteCode; Code[20]) { }
        field(2; Tag; Text[10]) { }
        field(3; Validation; Boolean) { }
    }

    keys { key(PK; SuiteCode, Tag) { Clustered = true; } }
}

table 72920 "LT XAU Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; SuiteCode; Code[20]) { }
        field(2; LineNo; Integer) { }
        field(3; Cu; Integer) { }
    }

    keys { key(PK; SuiteCode, LineNo) { Clustered = true; } }
}

table 72921 "LT XAU Eval"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; SuiteCode; Code[20]) { }
        field(2; LineNo; Integer) { }
        field(3; Name; Text[30]) { }
    }

    keys { key(PK; SuiteCode, LineNo, Name) { Clustered = true; } }
}

codeunit 72930 "LT XAU Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Row(P: Record "LT XAU Par"): Text
    begin
        exit(Format(P.Id) + '/' + P.Name + '/' + P.Stamp + '/' + P.Extra);
    end;

    procedure SuiteRow(S: Record "LT XAU Suite"): Text
    begin
        exit(S.Code + '/' + S.Description + '/' + S.AppId + '/' + S.Hash + '/' + Format(S.Validation) + '/' + Format(S.Runner));
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

// AutoUpdate, OnAfterAssignField of the key field assigns a field the document never carries.
xmlport 72922 "LT XAU KeyTrig"
{
    Direction = Import;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Par; "LT XAU Par")
            {
                XmlName = 'P';
                AutoUpdate = true;

                fieldelement(Id; Par.Id)
                {
                    trigger OnAfterAssignField()
                    begin
                        L.Add('tr:' + L.Row(Par));
                        Par.Stamp := 'trig';
                    end;
                }
                fieldelement(Name; Par.Name) { MinOccurs = Zero; }

                trigger OnBeforeInsertRecord()
                begin
                    L.Add('bi:' + L.Row(Par));
                end;

                trigger OnBeforeModifyRecord()
                begin
                    L.Add('bm:' + L.Row(Par));
                end;

                trigger OnAfterModifyRecord()
                begin
                    L.Add('am:' + L.Row(Par));
                end;
            }
        }
    }

    var
        L: Codeunit "LT XAU Log";
}

// AutoUpdate, OnAfterAssignField of a carried field assigns that field and a field the document never carries.
xmlport 72923 "LT XAU FieldTrig"
{
    Direction = Import;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Par; "LT XAU Par")
            {
                XmlName = 'P';
                AutoUpdate = true;

                fieldelement(Id; Par.Id) { }
                fieldelement(Name; Par.Name)
                {
                    trigger OnAfterAssignField()
                    begin
                        L.Add('tr:' + L.Row(Par));
                        Par.Name := Par.Name + '!';
                        Par.Stamp := 'trig';
                    end;
                }

                trigger OnBeforeModifyRecord()
                begin
                    L.Add('bm:' + L.Row(Par));
                end;
            }
        }
    }

    var
        L: Codeunit "LT XAU Log";
}

// AutoUpdate, OnAfterAssignVariable of a text element assigns a field.
xmlport 72924 "LT XAU TextTrig"
{
    Direction = Import;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Par; "LT XAU Par")
            {
                XmlName = 'P';
                AutoUpdate = true;

                fieldelement(Id; Par.Id) { }
                textelement(Flg)
                {
                    MinOccurs = Zero;

                    trigger OnAfterAssignVariable()
                    begin
                        L.Add('tr:' + L.Row(Par));
                        Par.Stamp := Flg;
                    end;
                }

                trigger OnBeforeModifyRecord()
                begin
                    L.Add('bm:' + L.Row(Par));
                end;
            }
        }
    }

    var
        L: Codeunit "LT XAU Log";
}

// AutoUpdate, OnAfterInitRecord assigns a field the document never carries.
xmlport 72925 "LT XAU InitTrig"
{
    Direction = Import;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Par; "LT XAU Par")
            {
                XmlName = 'P';
                AutoUpdate = true;

                fieldelement(Id; Par.Id) { }
                fieldelement(Name; Par.Name) { MinOccurs = Zero; }

                trigger OnAfterInitRecord()
                begin
                    L.Add('init:' + L.Row(Par));
                    Par.Extra := 'init';
                end;

                trigger OnBeforeModifyRecord()
                begin
                    L.Add('bm:' + L.Row(Par));
                end;
            }
        }
    }

    var
        L: Codeunit "LT XAU Log";
}

// AutoUpdate on a parent with an OnAfterAssignField of the key and a linked child table element.
xmlport 72926 "LT XAU NestUpd"
{
    Direction = Import;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Par; "LT XAU Par")
            {
                XmlName = 'P';
                AutoUpdate = true;

                fieldelement(Id; Par.Id)
                {
                    trigger OnAfterAssignField()
                    begin
                        Par.Stamp := 'trig';
                    end;
                }
                fieldelement(Name; Par.Name) { MinOccurs = Zero; }
                tableelement(Chi; "LT XAU Chi")
                {
                    XmlName = 'C';
                    LinkTable = Par;
                    LinkFields = ParentId = field(Id);
                    MinOccurs = Zero;

                    fieldelement(CId; Chi.Id) { }
                    fieldelement(Note; Chi.Note) { }
                }

                trigger OnBeforeInsertRecord()
                begin
                    L.Add('bi:' + L.Row(Par));
                end;

                trigger OnBeforeModifyRecord()
                begin
                    L.Add('bm:' + L.Row(Par));
                end;
            }
        }
    }

    var
        L: Codeunit "LT XAU Log";
}

// No AutoUpdate or AutoReplace: OnAfterAssignField of the key field assigns a field; the parent is stored before its linked
// child rows and again after them.
xmlport 72932 "LT XAU Again"
{
    Direction = Import;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Par; "LT XAU Par")
            {
                XmlName = 'P';

                fieldelement(Id; Par.Id)
                {
                    trigger OnAfterAssignField()
                    begin
                        L.Add('tr:' + L.Row(Par));
                        Par.Stamp := 'trig';
                    end;
                }
                fieldelement(Name; Par.Name) { }
                tableelement(Chi; "LT XAU Chi")
                {
                    XmlName = 'C';
                    LinkTable = Par;
                    LinkFields = ParentId = field(Id);
                    MinOccurs = Zero;

                    fieldelement(CId; Chi.Id) { }
                    fieldelement(Note; Chi.Note) { }
                }

                trigger OnBeforeInsertRecord()
                begin
                    L.Add('bi:' + L.Row(Par));
                end;

                trigger OnBeforeModifyRecord()
                begin
                    L.Add('bm:' + L.Row(Par));
                end;

                trigger OnAfterModifyRecord()
                begin
                    L.Add('am:' + L.Row(Par));
                end;
            }
        }
    }

    var
        L: Codeunit "LT XAU Log";
}

// No AutoUpdate or AutoReplace: a child trigger changes the parent's record variable between its two saves.
xmlport 72927 "LT XAU Stale"
{
    Direction = Import;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Par; "LT XAU Par")
            {
                XmlName = 'P';

                fieldelement(Id; Par.Id)
                {
                    trigger OnAfterAssignField()
                    begin
                        Par.Stamp := 'trig';
                    end;
                }
                fieldelement(Name; Par.Name) { }
                tableelement(Chi; "LT XAU Chi")
                {
                    XmlName = 'C';
                    LinkTable = Par;
                    LinkFields = ParentId = field(Id);
                    MinOccurs = Zero;

                    fieldelement(CId; Chi.Id) { }

                    trigger OnAfterInitRecord()
                    begin
                        Par.Extra := 'child';
                    end;
                }

                trigger OnBeforeModifyRecord()
                begin
                    L.Add('bm:' + L.Row(Par));
                end;
            }
        }
    }

    var
        L: Codeunit "LT XAU Log";
}

// No AutoUpdate or AutoReplace: the child table's OnInsert changes the stored parent row between its two saves.
xmlport 72928 "LT XAU StaleDb"
{
    Direction = Import;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Par; "LT XAU Par")
            {
                XmlName = 'P';

                fieldelement(Id; Par.Id)
                {
                    trigger OnAfterAssignField()
                    begin
                        Par.Extra := 'trig';
                    end;
                }
                fieldelement(Name; Par.Name) { }
                tableelement(Chi; "LT XAU ChiW")
                {
                    XmlName = 'C';
                    LinkTable = Par;
                    LinkFields = ParentId = field(Id);
                    MinOccurs = Zero;

                    fieldelement(CId; Chi.Id) { }
                }

                trigger OnBeforeModifyRecord()
                begin
                    L.Add('bm:' + L.Row(Par));
                end;
            }
        }
    }

    var
        L: Codeunit "LT XAU Log";
}

// A suite import: the key attribute's OnAfterAssignField looks the row up, skips it, deletes it or raises, and assigns two fields.
xmlport 72929 "LT XAU Suite"
{
    Direction = Import;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Suite; "LT XAU Suite")
            {
                MaxOccurs = Unbounded;
                XmlName = 'Suite';

                fieldattribute(Code; Suite.Code)
                {
                    Occurrence = Required;

                    trigger OnAfterAssignField()
                    var
                        Other: Record "LT XAU Suite";
                    begin
                        L.Add('code:' + L.SuiteRow(Suite));
                        Other.SetRange(Code, Suite.Code);
                        if Other.FindFirst() then
                            if Other.AppId = CallerApp then
                                if Other.Hash = CallerHash then begin
                                    Skipped.Add(Suite.Code);
                                    currXMLport.Skip();
                                end else
                                    Other.Delete()
                            else
                                Error('Suite %1 belongs to another app.', Suite.Code);
                        Suite.AppId := CallerApp;
                        Suite.Hash := CallerHash;
                    end;
                }
                fieldattribute(Description; Suite.Description) { Occurrence = Optional; }
                textattribute(SuiteValidation)
                {
                    XmlName = 'Validation';
                    Occurrence = Optional;

                    trigger OnAfterAssignVariable()
                    begin
                        Suite.Validation := UpperCase(SuiteValidation) = 'TRUE';
                    end;
                }
                tableelement(Lang; "LT XAU Lang")
                {
                    LinkTable = Suite;
                    LinkFields = SuiteCode = field(Code);
                    MinOccurs = Zero;
                    XmlName = 'Language';

                    textattribute(LangTag)
                    {
                        XmlName = 'Tag';
                        Occurrence = Required;

                        trigger OnAfterAssignVariable()
                        begin
                            Lang.Tag := LangTag;
                        end;
                    }
                    textattribute(LangValidation)
                    {
                        XmlName = 'Validation';
                        Occurrence = Optional;

                        trigger OnAfterAssignVariable()
                        begin
                            Lang.Validation := UpperCase(LangValidation) = 'TRUE';
                        end;
                    }

                    trigger OnAfterInitRecord()
                    begin
                        if Skipped.Contains(Suite.Code) then
                            currXMLport.Skip();
                    end;
                }
                tableelement(SuiteEval; "LT XAU Eval")
                {
                    LinkTable = Suite;
                    LinkFields = SuiteCode = field(Code);
                    MinOccurs = Zero;
                    XmlName = 'Evaluator';
                    SourceTableView = where(LineNo = const(0));

                    fieldattribute(Name; SuiteEval.Name) { Occurrence = Required; }

                    trigger OnAfterInitRecord()
                    begin
                        if Skipped.Contains(Suite.Code) then
                            currXMLport.Skip();
                    end;
                }
                tableelement(Line; "LT XAU Line")
                {
                    LinkTable = Suite;
                    LinkFields = SuiteCode = field(Code);
                    MinOccurs = Zero;
                    XmlName = 'Line';

                    fieldattribute(Cu; Line.Cu) { Occurrence = Required; }
                    tableelement(LineEval; "LT XAU Eval")
                    {
                        LinkTable = Line;
                        LinkFields = SuiteCode = field(SuiteCode), LineNo = field(LineNo);
                        MinOccurs = Zero;
                        XmlName = 'Evaluator';

                        fieldattribute(Name; LineEval.Name) { Occurrence = Required; }

                        trigger OnAfterInitRecord()
                        begin
                            if Skipped.Contains(Suite.Code) then
                                currXMLport.Skip();
                        end;

                        trigger OnBeforeInsertRecord()
                        begin
                            LineEval.LineNo := Line.LineNo;
                        end;
                    }

                    trigger OnAfterInitRecord()
                    begin
                        if Skipped.Contains(Suite.Code) then
                            currXMLport.Skip();
                    end;

                    trigger OnBeforeInsertRecord()
                    var
                        Last: Record "LT XAU Line";
                    begin
                        Last.SetRange(SuiteCode, Suite.Code);
                        if Last.FindLast() then;
                        Line.LineNo := Last.LineNo + 10000;
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    L.Add('bi:' + L.SuiteRow(Suite));
                    if Skipped.Contains(Suite.Code) then
                        currXMLport.Skip();
                end;

                trigger OnBeforeModifyRecord()
                begin
                    L.Add('bm:' + L.SuiteRow(Suite));
                end;

                trigger OnAfterModifyRecord()
                begin
                    L.Add('am:' + L.SuiteRow(Suite));
                end;
            }
        }
    }

    procedure SetCaller(App: Text[30]; HashValue: Text[30])
    begin
        CallerApp := App;
        CallerHash := HashValue;
    end;

    var
        L: Codeunit "LT XAU Log";
        Skipped: List of [Code[20]];
        CallerApp: Text[30];
        CallerHash: Text[30];
}

codeunit 72931 "LT XmlPort AutoUpdate Assign"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedPar()
    var
        Par: Record "LT XAU Par";
        Chi: Record "LT XAU Chi";
        ChiW: Record "LT XAU ChiW";
        Log: Codeunit "LT XAU Log";
    begin
        Par.DeleteAll();
        Chi.DeleteAll();
        ChiW.DeleteAll();
        Par.Id := 1;
        Par.Name := 'old';
        Par.Stamp := 's0';
        Par.Extra := 'e0';
        Par.Insert();
        Log.Take();
    end;

    local procedure Source(Xml: Text; var TempBlob: Codeunit "Temp Blob"; var InS: InStream)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Xml);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
    end;

    local procedure RunPort(XmlportId: Integer; Xml: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        Source(Xml, TempBlob, InS);
        Xmlport.Import(XmlportId, InS);
    end;

    local procedure ParRows(): Text
    var
        Par: Record "LT XAU Par";
        Chi: Record "LT XAU Chi";
        ChiW: Record "LT XAU ChiW";
        Log: Codeunit "LT XAU Log";
        Txt: Text;
    begin
        if Par.FindSet() then
            repeat
                Txt += 'P' + Log.Row(Par) + ';';
            until Par.Next() = 0;
        if Chi.FindSet() then
            repeat
                Txt += 'C' + Format(Chi.Id) + '/' + Format(Chi.ParentId) + '/' + Chi.Note + ';';
            until Chi.Next() = 0;
        if ChiW.FindSet() then
            repeat
                Txt += 'W' + Format(ChiW.Id) + '/' + Format(ChiW.ParentId) + ';';
            until ChiW.Next() = 0;
        exit(Txt);
    end;

    local procedure WipeSuites()
    var
        Suite: Record "LT XAU Suite";
        Lang: Record "LT XAU Lang";
        Line: Record "LT XAU Line";
        Eval: Record "LT XAU Eval";
        Log: Codeunit "LT XAU Log";
    begin
        Suite.DeleteAll();
        Lang.DeleteAll();
        Line.DeleteAll();
        Eval.DeleteAll();
        Log.Take();
    end;

    local procedure RunSuite(App: Text[30]; HashValue: Text[30]; Xml: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        Imp: XmlPort "LT XAU Suite";
        InS: InStream;
    begin
        Source(Xml, TempBlob, InS);
        Imp.SetCaller(App, HashValue);
        Imp.SetSource(InS);
        Imp.Import();
    end;

    local procedure SuiteRows(): Text
    var
        Suite: Record "LT XAU Suite";
        Lang: Record "LT XAU Lang";
        Line: Record "LT XAU Line";
        Eval: Record "LT XAU Eval";
        Log: Codeunit "LT XAU Log";
        Txt: Text;
    begin
        if Suite.FindSet() then
            repeat
                Txt += 'S' + Log.SuiteRow(Suite) + ';';
            until Suite.Next() = 0;
        if Lang.FindSet() then
            repeat
                Txt += 'L' + Lang.SuiteCode + '/' + Lang.Tag + '/' + Format(Lang.Validation) + ';';
            until Lang.Next() = 0;
        if Line.FindSet() then
            repeat
                Txt += 'N' + Line.SuiteCode + '/' + Format(Line.LineNo) + '/' + Format(Line.Cu) + ';';
            until Line.Next() = 0;
        if Eval.FindSet() then
            repeat
                Txt += 'E' + Eval.SuiteCode + '/' + Format(Eval.LineNo) + '/' + Eval.Name + ';';
            until Eval.Next() = 0;
        exit(Txt);
    end;

    [Test]
    procedure KeyTrig_Existing_NameCarried()
    var
        Log: Codeunit "LT XAU Log";
        Observer: Codeunit "Probe Observer";
    begin
        SeedPar();
        RunPort(Xmlport::"LT XAU KeyTrig", '<Root><P><Id>1</Id><Name>new</Name></P></Root>');
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', ParRows());
        Observer.Finish();
    end;

    [Test]
    procedure KeyTrig_Existing_NameAbsent()
    var
        Log: Codeunit "LT XAU Log";
        Observer: Codeunit "Probe Observer";
    begin
        SeedPar();
        RunPort(Xmlport::"LT XAU KeyTrig", '<Root><P><Id>1</Id></P></Root>');
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', ParRows());
        Observer.Finish();
    end;

    [Test]
    procedure KeyTrig_NewRow()
    var
        Log: Codeunit "LT XAU Log";
        Observer: Codeunit "Probe Observer";
    begin
        SeedPar();
        RunPort(Xmlport::"LT XAU KeyTrig", '<Root><P><Id>2</Id><Name>new</Name></P></Root>');
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', ParRows());
        Observer.Finish();
    end;

    [Test]
    procedure FieldTrig_Existing()
    var
        Log: Codeunit "LT XAU Log";
        Observer: Codeunit "Probe Observer";
    begin
        SeedPar();
        RunPort(Xmlport::"LT XAU FieldTrig", '<Root><P><Id>1</Id><Name>new</Name></P></Root>');
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', ParRows());
        Observer.Finish();
    end;

    [Test]
    procedure TextTrig_Existing()
    var
        Log: Codeunit "LT XAU Log";
        Observer: Codeunit "Probe Observer";
    begin
        SeedPar();
        RunPort(Xmlport::"LT XAU TextTrig", '<Root><P><Id>1</Id><Flg>f</Flg></P></Root>');
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', ParRows());
        Observer.Finish();
    end;

    [Test]
    procedure InitTrig_Existing_NameCarried()
    var
        Log: Codeunit "LT XAU Log";
        Observer: Codeunit "Probe Observer";
    begin
        SeedPar();
        RunPort(Xmlport::"LT XAU InitTrig", '<Root><P><Id>1</Id><Name>new</Name></P></Root>');
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', ParRows());
        Observer.Finish();
    end;

    [Test]
    procedure InitTrig_Existing_NameAbsent()
    var
        Log: Codeunit "LT XAU Log";
        Observer: Codeunit "Probe Observer";
    begin
        SeedPar();
        RunPort(Xmlport::"LT XAU InitTrig", '<Root><P><Id>1</Id></P></Root>');
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', ParRows());
        Observer.Finish();
    end;

    [Test]
    procedure NestUpd_Existing_WithChild()
    var
        Log: Codeunit "LT XAU Log";
        Observer: Codeunit "Probe Observer";
    begin
        SeedPar();
        RunPort(Xmlport::"LT XAU NestUpd", '<Root><P><Id>1</Id><Name>new</Name><C><CId>10</CId><Note>a</Note></C></P></Root>');
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', ParRows());
        Observer.Finish();
    end;

    [Test]
    procedure NestUpd_NewRow_WithChild()
    var
        Log: Codeunit "LT XAU Log";
        Observer: Codeunit "Probe Observer";
    begin
        SeedPar();
        RunPort(Xmlport::"LT XAU NestUpd", '<Root><P><Id>2</Id><Name>new</Name><C><CId>10</CId><Note>a</Note></C></P></Root>');
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', ParRows());
        Observer.Finish();
    end;

    [Test]
    procedure Again_FieldElementTrigger()
    var
        Log: Codeunit "LT XAU Log";
        Observer: Codeunit "Probe Observer";
    begin
        SeedPar();
        RunPort(Xmlport::"LT XAU Again", '<Root><P><Id>2</Id><Name>two</Name><C><CId>10</CId><Note>a</Note></C><C><CId>11</CId><Note>b</Note></C></P><P><Id>3</Id><Name>three</Name></P></Root>');
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', ParRows());
        Observer.Finish();
    end;

    [Test]
    procedure Stale_ChildTriggerSetsParentVariable()
    var
        Log: Codeunit "LT XAU Log";
        Observer: Codeunit "Probe Observer";
    begin
        SeedPar();
        RunPort(Xmlport::"LT XAU Stale", '<Root><P><Id>2</Id><Name>two</Name><C><CId>10</CId></C></P></Root>');
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', ParRows());
        Observer.Finish();
    end;

    [Test]
    procedure StaleDb_ChildOnInsertChangesStoredParent()
    var
        Log: Codeunit "LT XAU Log";
        Observer: Codeunit "Probe Observer";
    begin
        SeedPar();
        Commit();
        asserterror begin
            RunPort(Xmlport::"LT XAU StaleDb", '<Root><P><Id>2</Id><Name>two</Name><C><CId>10</CId></C></P></Root>');
            Observer.Observe('trace', Log.Take());
            Observer.Observe('rows', ParRows());
            Error('');
        end;
        Observer.ObserveError('error');
        Observer.Observe('trace_after', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Suite_Fresh()
    var
        Log: Codeunit "LT XAU Log";
        Observer: Codeunit "Probe Observer";
    begin
        WipeSuites();
        RunSuite('app1', 'h1', '<Root><Suite Code="A" Description="da" Validation="true"><Language Tag="en" Validation="true"/><Line Cu="5"><Evaluator Name="e1"/></Line><Line Cu="6"/></Suite><Suite Code="B"><Line Cu="7"/></Suite></Root>');
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', SuiteRows());
        Observer.Finish();
    end;

    [Test]
    procedure Suite_Fresh_SuiteEvaluator()
    var
        Log: Codeunit "LT XAU Log";
        Observer: Codeunit "Probe Observer";
    begin
        WipeSuites();
        RunSuite('app1', 'h1', '<Root><Suite Code="A"><Evaluator Name="e0"/><Line Cu="5"/></Suite></Root>');
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', SuiteRows());
        Observer.Finish();
    end;

    [Test]
    procedure Suite_SameAppSameHash_Skips()
    var
        Log: Codeunit "LT XAU Log";
        Observer: Codeunit "Probe Observer";
    begin
        WipeSuites();
        RunSuite('app1', 'h1', '<Root><Suite Code="A" Description="da"><Line Cu="5"/></Suite></Root>');
        Log.Take();
        RunSuite('app1', 'h1', '<Root><Suite Code="A" Description="db" Validation="true"><Language Tag="en"/><Line Cu="6"><Evaluator Name="e1"/></Line></Suite><Suite Code="B"><Line Cu="7"/></Suite></Root>');
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', SuiteRows());
        Observer.Finish();
    end;

    [Test]
    procedure Suite_SameAppOtherHash_Replaces()
    var
        Log: Codeunit "LT XAU Log";
        Observer: Codeunit "Probe Observer";
    begin
        WipeSuites();
        RunSuite('app1', 'h1', '<Root><Suite Code="A" Description="da" Validation="true"><Line Cu="5"/></Suite></Root>');
        Log.Take();
        RunSuite('app1', 'h2', '<Root><Suite Code="A" Description="db"><Line Cu="6"/></Suite></Root>');
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', SuiteRows());
        Observer.Finish();
    end;

    [Test]
    procedure Suite_OtherApp_Errors()
    var
        Log: Codeunit "LT XAU Log";
        Observer: Codeunit "Probe Observer";
    begin
        WipeSuites();
        RunSuite('app1', 'h1', '<Root><Suite Code="A" Description="da"><Line Cu="5"/></Suite></Root>');
        Commit();
        Log.Take();
        asserterror RunSuite('app2', 'h1', '<Root><Suite Code="A" Description="db"><Line Cu="6"/></Suite></Root>');
        Observer.ObserveError('error');
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', SuiteRows());
        Observer.Finish();
    end;
}
