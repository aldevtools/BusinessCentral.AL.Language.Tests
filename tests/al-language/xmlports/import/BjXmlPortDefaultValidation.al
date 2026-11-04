// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-defaultfieldsvalidation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 81670 and 81671, log codeunit 81672, xmlports 81673 to 81675, test codeunit 81676
// Probe: corpus issue 601 item 14. XmlPort DefaultFieldsValidation = true (set explicitly), = false and not set, on an import: which OnValidate
//   triggers run for a field element without FieldValidate, with FieldValidate = Yes and with FieldValidate = No, in which order, and what a
//   value that is not in the related table does under each setting.
// Facts (CI): DefaultFieldsValidation = true and the property left out behave the same: every field element without FieldValidate is
//   validated (OnValidate runs, xRec already holds the new value, a TableRelation is checked: DB:PrimRecordNotFound and no row), FieldValidate = No
//   is not validated, FieldValidate = Yes is. With false only FieldValidate = Yes is validated and an unrelated value is stored. Validation runs
//   per field in document order, before OnInsert. Elements out of schema order fail the import after the rows before them were inserted.
//   Writer RG: table 87927, xmlports 87928 to 87931, test procedures RG_* (TableRelation on a fieldattribute and a fieldelement, FieldValidate
//   left out / No / Yes, DefaultFieldsValidation true / false, AutoSave on / off; existing, missing and blank related value).
//   Facts (CI, writer RG): the TableRelation is checked only when the node is validated (FieldValidate = Yes, or left out under
//   DefaultFieldsValidation = true), at assignment, before OnValidate and before OnBeforeInsertRecord: DB:PrimRecordNotFound, no row; AutoSave
//   off gives the same error. A node that is not validated stores the missing value; Insert never checks it. A blank value never fails; a blank
//   fieldelement still runs OnValidate, a blank fieldattribute runs no OnValidate even with FieldValidate = Yes.
// BC versions: 27, 28, 29

table 81670 "LT BJ Xv Rel"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 81671 "LT BJ Xv Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Plain; Text[20])
        {
            trigger OnValidate()
            var
                XvLog: Codeunit "LT BJ Xv Log";
            begin
                XvLog.Add('val Plain=' + Plain + ' xRec=' + xRec.Plain);
            end;
        }
        field(3; Forced; Text[20])
        {
            trigger OnValidate()
            var
                XvLog: Codeunit "LT BJ Xv Log";
            begin
                XvLog.Add('val Forced=' + Forced);
            end;
        }
        field(4; Skipped; Text[20])
        {
            trigger OnValidate()
            var
                XvLog: Codeunit "LT BJ Xv Log";
            begin
                XvLog.Add('val Skipped=' + Skipped);
            end;
        }
        field(5; Rel; Code[10])
        {
            TableRelation = "LT BJ Xv Rel".Code;

            trigger OnValidate()
            var
                XvLog: Codeunit "LT BJ Xv Log";
            begin
                XvLog.Add('val Rel=' + Rel);
            end;
        }
        field(6; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    var
        XvLog: Codeunit "LT BJ Xv Log";
    begin
        XvLog.Add('insert ' + Format(Id));
    end;
}

codeunit 81672 "LT BJ Xv Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

xmlport 81673 "LT BJ Xv True"
{
    Direction = Import;
    Format = Xml;
    DefaultFieldsValidation = true;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT BJ Xv Row")
            {
                fieldattribute(Id; Row.Id) { }
                fieldelement(Plain; Row.Plain) { MinOccurs = Zero; }
                fieldelement(Forced; Row.Forced) { MinOccurs = Zero; FieldValidate = Yes; }
                fieldelement(Skipped; Row.Skipped) { MinOccurs = Zero; FieldValidate = No; }
                fieldelement(Rel; Row.Rel) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 81674 "LT BJ Xv False"
{
    Direction = Import;
    Format = Xml;
    DefaultFieldsValidation = false;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT BJ Xv Row")
            {
                fieldattribute(Id; Row.Id) { }
                fieldelement(Plain; Row.Plain) { MinOccurs = Zero; }
                fieldelement(Forced; Row.Forced) { MinOccurs = Zero; FieldValidate = Yes; }
                fieldelement(Skipped; Row.Skipped) { MinOccurs = Zero; FieldValidate = No; }
                fieldelement(Rel; Row.Rel) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 81675 "LT BJ Xv Unset"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT BJ Xv Row")
            {
                fieldattribute(Id; Row.Id) { }
                fieldelement(Plain; Row.Plain) { MinOccurs = Zero; }
                fieldelement(Forced; Row.Forced) { MinOccurs = Zero; FieldValidate = Yes; }
                fieldelement(Skipped; Row.Skipped) { MinOccurs = Zero; FieldValidate = No; }
                fieldelement(Rel; Row.Rel) { MinOccurs = Zero; }
            }
        }
    }
}

// Writer RG (Microsoft's DemoTool imports into fields with a TableRelation): a fieldattribute and a fieldelement whose field relates to
// table 81670, with FieldValidate left out, = No and = Yes, under DefaultFieldsValidation true and false and with the table element's
// AutoSave on and off; each import carries one node with a value that exists in the related table, one that does not, or a blank value.
table 87927 "LT RG Xv Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; AttrDef; Code[10])
        {
            TableRelation = "LT BJ Xv Rel".Code;

            trigger OnValidate()
            var
                XvLog: Codeunit "LT BJ Xv Log";
            begin
                XvLog.Add('val AttrDef=' + AttrDef);
            end;
        }
        field(3; AttrNo; Code[10])
        {
            TableRelation = "LT BJ Xv Rel".Code;

            trigger OnValidate()
            var
                XvLog: Codeunit "LT BJ Xv Log";
            begin
                XvLog.Add('val AttrNo=' + AttrNo);
            end;
        }
        field(4; AttrYes; Code[10])
        {
            TableRelation = "LT BJ Xv Rel".Code;

            trigger OnValidate()
            var
                XvLog: Codeunit "LT BJ Xv Log";
            begin
                XvLog.Add('val AttrYes=' + AttrYes);
            end;
        }
        field(5; ElDef; Code[10])
        {
            TableRelation = "LT BJ Xv Rel".Code;

            trigger OnValidate()
            var
                XvLog: Codeunit "LT BJ Xv Log";
            begin
                XvLog.Add('val ElDef=' + ElDef);
            end;
        }
        field(6; ElNo; Code[10])
        {
            TableRelation = "LT BJ Xv Rel".Code;

            trigger OnValidate()
            var
                XvLog: Codeunit "LT BJ Xv Log";
            begin
                XvLog.Add('val ElNo=' + ElNo);
            end;
        }
        field(7; ElYes; Code[10])
        {
            TableRelation = "LT BJ Xv Rel".Code;

            trigger OnValidate()
            var
                XvLog: Codeunit "LT BJ Xv Log";
            begin
                XvLog.Add('val ElYes=' + ElYes);
            end;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    var
        XvLog: Codeunit "LT BJ Xv Log";
    begin
        XvLog.Add('insert ' + Format(Id));
    end;
}

xmlport 87928 "LT RG Xv True Save"
{
    Direction = Import;
    Format = Xml;
    DefaultFieldsValidation = true;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT RG Xv Row")
            {
                fieldattribute(Id; Row.Id) { }
                fieldattribute(AttrDef; Row.AttrDef) { Occurrence = Optional; }
                fieldattribute(AttrNo; Row.AttrNo) { Occurrence = Optional; FieldValidate = No; }
                fieldattribute(AttrYes; Row.AttrYes) { Occurrence = Optional; FieldValidate = Yes; }
                fieldelement(ElDef; Row.ElDef) { MinOccurs = Zero; }
                fieldelement(ElNo; Row.ElNo) { MinOccurs = Zero; FieldValidate = No; }
                fieldelement(ElYes; Row.ElYes) { MinOccurs = Zero; FieldValidate = Yes; }

                trigger OnBeforeInsertRecord()
                begin
                    XvLog.Add('before insert ' + Format(Row.Id) + ':' + Row.AttrDef + ':' + Row.AttrNo + ':' + Row.AttrYes + ':' + Row.ElDef + ':' + Row.ElNo + ':' + Row.ElYes);
                end;
            }
        }
    }

    var
        XvLog: Codeunit "LT BJ Xv Log";
}

xmlport 87929 "LT RG Xv False Save"
{
    Direction = Import;
    Format = Xml;
    DefaultFieldsValidation = false;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT RG Xv Row")
            {
                fieldattribute(Id; Row.Id) { }
                fieldattribute(AttrDef; Row.AttrDef) { Occurrence = Optional; }
                fieldattribute(AttrNo; Row.AttrNo) { Occurrence = Optional; FieldValidate = No; }
                fieldattribute(AttrYes; Row.AttrYes) { Occurrence = Optional; FieldValidate = Yes; }
                fieldelement(ElDef; Row.ElDef) { MinOccurs = Zero; }
                fieldelement(ElNo; Row.ElNo) { MinOccurs = Zero; FieldValidate = No; }
                fieldelement(ElYes; Row.ElYes) { MinOccurs = Zero; FieldValidate = Yes; }

                trigger OnBeforeInsertRecord()
                begin
                    XvLog.Add('before insert ' + Format(Row.Id) + ':' + Row.AttrDef + ':' + Row.AttrNo + ':' + Row.AttrYes + ':' + Row.ElDef + ':' + Row.ElNo + ':' + Row.ElYes);
                end;
            }
        }
    }

    var
        XvLog: Codeunit "LT BJ Xv Log";
}

xmlport 87930 "LT RG Xv True NoSave"
{
    Direction = Import;
    Format = Xml;
    DefaultFieldsValidation = true;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT RG Xv Row")
            {
                AutoSave = false;
                fieldattribute(Id; Row.Id) { }
                fieldattribute(AttrDef; Row.AttrDef) { Occurrence = Optional; }
                fieldattribute(AttrNo; Row.AttrNo) { Occurrence = Optional; FieldValidate = No; }
                fieldattribute(AttrYes; Row.AttrYes) { Occurrence = Optional; FieldValidate = Yes; }
                fieldelement(ElDef; Row.ElDef) { MinOccurs = Zero; }
                fieldelement(ElNo; Row.ElNo) { MinOccurs = Zero; FieldValidate = No; }
                fieldelement(ElYes; Row.ElYes) { MinOccurs = Zero; FieldValidate = Yes; }

                trigger OnBeforeInsertRecord()
                begin
                    XvLog.Add('before insert ' + Format(Row.Id) + ':' + Row.AttrDef + ':' + Row.AttrNo + ':' + Row.AttrYes + ':' + Row.ElDef + ':' + Row.ElNo + ':' + Row.ElYes);
                end;
            }
        }
    }

    var
        XvLog: Codeunit "LT BJ Xv Log";
}

xmlport 87931 "LT RG Xv False NoSave"
{
    Direction = Import;
    Format = Xml;
    DefaultFieldsValidation = false;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT RG Xv Row")
            {
                AutoSave = false;
                fieldattribute(Id; Row.Id) { }
                fieldattribute(AttrDef; Row.AttrDef) { Occurrence = Optional; }
                fieldattribute(AttrNo; Row.AttrNo) { Occurrence = Optional; FieldValidate = No; }
                fieldattribute(AttrYes; Row.AttrYes) { Occurrence = Optional; FieldValidate = Yes; }
                fieldelement(ElDef; Row.ElDef) { MinOccurs = Zero; }
                fieldelement(ElNo; Row.ElNo) { MinOccurs = Zero; FieldValidate = No; }
                fieldelement(ElYes; Row.ElYes) { MinOccurs = Zero; FieldValidate = Yes; }

                trigger OnBeforeInsertRecord()
                begin
                    XvLog.Add('before insert ' + Format(Row.Id) + ':' + Row.AttrDef + ':' + Row.AttrNo + ':' + Row.AttrYes + ':' + Row.ElDef + ':' + Row.ElNo + ':' + Row.ElYes);
                end;
            }
        }
    }

    var
        XvLog: Codeunit "LT BJ Xv Log";
}

codeunit 81676 "LT BJ Xv Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        XvLog: Codeunit "LT BJ Xv Log";
        OrderXml: Label '<?xml version="1.0" encoding="utf-8"?><Root><Row Id="1"><Plain>p1</Plain><Forced>f1</Forced><Skipped>s1</Skipped><Rel>R1</Rel></Row><Row Id="2"><Skipped>s2</Skipped><Plain>p2</Plain></Row></Root>', Locked = true;
        GoodXml: Label '<?xml version="1.0" encoding="utf-8"?><Root><Row Id="1"><Plain>p1</Plain><Forced>f1</Forced><Skipped>s1</Skipped><Rel>R1</Rel></Row><Row Id="2"><Plain>p2</Plain><Skipped>s2</Skipped></Row></Root>', Locked = true;
        BadRelXml: Label '<?xml version="1.0" encoding="utf-8"?><Root><Row Id="3"><Plain>p3</Plain><Rel>NOPE</Rel></Row></Root>', Locked = true;

    local procedure Seed()
    var
        Row: Record "LT BJ Xv Row";
        Rel: Record "LT BJ Xv Rel";
    begin
        Row.DeleteAll();
        Rel.DeleteAll();
        Rel.Code := 'R1';
        Rel.Insert();
        XvLog.Take();
    end;

    [TryFunction]
    local procedure TryImport(XmlPortId: Integer; Xml: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Xml);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(XmlPortId, InS);
    end;

    local procedure Rows(): Text
    var
        Row: Record "LT BJ Xv Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ':' + Row.Plain + ':' + Row.Forced + ':' + Row.Skipped + ':' + Row.Rel + ',';
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure Probe(Tag: Text; XmlPortId: Integer)
    begin
        Seed();
        ClearLastError();
        Observer.Observe(Tag + ' order ok', Format(TryImport(XmlPortId, OrderXml)));
        Observer.Observe(Tag + ' order error', GetLastErrorText());
        Observer.Observe(Tag + ' order log', XvLog.Take());
        Observer.Observe(Tag + ' order rows', Rows());
        Seed();
        ClearLastError();
        if TryImport(XmlPortId, BadRelXml) then
            Observer.Observe(Tag + ' bad rel', 'ok')
        else
            Observer.ObserveError(Tag + ' bad rel');
        Observer.Observe(Tag + ' bad rel log', XvLog.Take());
        Observer.Observe(Tag + ' bad rel rows', Rows());
    end;

    local procedure ProbeInOrder(Tag: Text; XmlPortId: Integer)
    begin
        Seed();
        ClearLastError();
        Observer.Observe(Tag + ' good ok', Format(TryImport(XmlPortId, GoodXml)));
        Observer.Observe(Tag + ' good error', GetLastErrorText());
        Observer.Observe(Tag + ' good log', XvLog.Take());
        Observer.Observe(Tag + ' good rows', Rows());
    end;

    [Test]
    procedure XmlPort_DefaultFieldsValidation_True()
    begin
        Probe('true', Xmlport::"LT BJ Xv True");
        Observer.Expect('true order ok', 'No');
        Observer.Expect('true order error', 'Imported XML cannot validate with the schema: The element ''Row'' has invalid child element ''Plain''. List of possible elements expected: ''Rel''.');
        Observer.Expect('true order log', 'val Plain=p1 xRec=p1;val Forced=f1;val Rel=R1;insert 1;');
        Observer.Expect('true order rows', '1:p1:f1:s1:R1,');
        Observer.Expect('true bad rel|text', 'The field Rel of table LT BJ Xv Row contains a value (NOPE) that cannot be found in the related table (LT BJ Xv Rel).');
        Observer.Expect('true bad rel|code', 'DB:PrimRecordNotFound');
        Observer.Expect('true bad rel log', 'val Plain=p3 xRec=p3;');
        Observer.Expect('true bad rel rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure XmlPort_DefaultFieldsValidation_False()
    begin
        Probe('false', Xmlport::"LT BJ Xv False");
        Observer.Expect('false order ok', 'No');
        Observer.Expect('false order error', 'Imported XML cannot validate with the schema: The element ''Row'' has invalid child element ''Plain''. List of possible elements expected: ''Rel''.');
        Observer.Expect('false order log', 'val Forced=f1;insert 1;');
        Observer.Expect('false order rows', '1:p1:f1:s1:R1,');
        Observer.Expect('false bad rel', 'ok');
        Observer.Expect('false bad rel log', 'insert 3;');
        Observer.Expect('false bad rel rows', '3:p3:::NOPE,');
        Observer.Verify();
    end;

    [Test]
    procedure XmlPort_DefaultFieldsValidation_Unset()
    begin
        Probe('unset', Xmlport::"LT BJ Xv Unset");
        Observer.Expect('unset order ok', 'No');
        Observer.Expect('unset order error', 'Imported XML cannot validate with the schema: The element ''Row'' has invalid child element ''Plain''. List of possible elements expected: ''Rel''.');
        Observer.Expect('unset order log', 'val Plain=p1 xRec=p1;val Forced=f1;val Rel=R1;insert 1;');
        Observer.Expect('unset order rows', '1:p1:f1:s1:R1,');
        Observer.Expect('unset bad rel|text', 'The field Rel of table LT BJ Xv Row contains a value (NOPE) that cannot be found in the related table (LT BJ Xv Rel).');
        Observer.Expect('unset bad rel|code', 'DB:PrimRecordNotFound');
        Observer.Expect('unset bad rel log', 'val Plain=p3 xRec=p3;');
        Observer.Expect('unset bad rel rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure XmlPort_DefaultFieldsValidation_True_InOrder()
    begin
        ProbeInOrder('true', Xmlport::"LT BJ Xv True");
        Observer.Expect('true good ok', 'Yes');
        Observer.Expect('true good error', '');
        Observer.Expect('true good log', 'val Plain=p1 xRec=p1;val Forced=f1;val Rel=R1;insert 1;val Plain=p2 xRec=p2;insert 2;');
        Observer.Expect('true good rows', '1:p1:f1:s1:R1,2:p2::s2:,');
        Observer.Verify();
    end;

    [Test]
    procedure XmlPort_DefaultFieldsValidation_False_InOrder()
    begin
        ProbeInOrder('false', Xmlport::"LT BJ Xv False");
        Observer.Expect('false good ok', 'Yes');
        Observer.Expect('false good error', '');
        Observer.Expect('false good log', 'val Forced=f1;insert 1;insert 2;');
        Observer.Expect('false good rows', '1:p1:f1:s1:R1,2:p2::s2:,');
        Observer.Verify();
    end;

    [Test]
    procedure XmlPort_DefaultFieldsValidation_Unset_InOrder()
    begin
        ProbeInOrder('unset', Xmlport::"LT BJ Xv Unset");
        Observer.Expect('unset good ok', 'Yes');
        Observer.Expect('unset good error', '');
        Observer.Expect('unset good log', 'val Plain=p1 xRec=p1;val Forced=f1;val Rel=R1;insert 1;val Plain=p2 xRec=p2;insert 2;');
        Observer.Expect('unset good rows', '1:p1:f1:s1:R1,2:p2::s2:,');
        Observer.Verify();
    end;

    // Writer RG: one import per node and value (R1 exists in table 81670, NOPE does not, blank); each observation is
    // import ok | last error text | last error code | log (OnValidate, OnBeforeInsertRecord, OnInsert) | rows of table 87927.
    local procedure RgSeed()
    var
        Row: Record "LT RG Xv Row";
        Rel: Record "LT BJ Xv Rel";
    begin
        Row.DeleteAll();
        Rel.DeleteAll();
        Rel.Code := 'R1';
        Rel.Insert();
        XvLog.Take();
    end;

    local procedure RgRows(): Text
    var
        Row: Record "LT RG Xv Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ':' + Row.AttrDef + ':' + Row.AttrNo + ':' + Row.AttrYes + ':' + Row.ElDef + ':' + Row.ElNo + ':' + Row.ElYes + ',';
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure RgCase(XmlPortId: Integer; Node: Text; Value: Text; IsAttribute: Boolean)
    var
        Xml: Text;
        Ok: Boolean;
    begin
        if IsAttribute then
            Xml := '<?xml version="1.0" encoding="utf-8"?><Root><Row Id="1" ' + Node + '="' + Value + '"/></Root>'
        else
            Xml := '<?xml version="1.0" encoding="utf-8"?><Root><Row Id="1"><' + Node + '>' + Value + '</' + Node + '></Row></Root>';
        RgSeed();
        ClearLastError();
        Ok := TryImport(XmlPortId, Xml);
        if Value = '' then
            Value := 'blank';
        Observer.Observe(Node + ' ' + Value, Format(Ok) + ' | ' + GetLastErrorText() + ' | ' + GetLastErrorCode() + ' | ' + XvLog.Take() + ' | ' + RgRows());
        ClearLastError();
    end;

    local procedure RgProbe(XmlPortId: Integer; IsAttribute: Boolean)
    var
        Nodes: List of [Text];
        Node: Text;
    begin
        if IsAttribute then
            Nodes.AddRange('AttrDef', 'AttrNo', 'AttrYes')
        else
            Nodes.AddRange('ElDef', 'ElNo', 'ElYes');
        foreach Node in Nodes do begin
            RgCase(XmlPortId, Node, 'R1', IsAttribute);
            RgCase(XmlPortId, Node, 'NOPE', IsAttribute);
            RgCase(XmlPortId, Node, '', IsAttribute);
        end;
    end;

    [Test]
    procedure RG_FieldAttribute_Relation_DfvTrue_AutoSaveOn()
    begin
        RgProbe(Xmlport::"LT RG Xv True Save", true);
        Observer.Expect('AttrDef R1', 'Yes |  |  | val AttrDef=R1;before insert 1:R1:::::;insert 1; | 1:R1:::::,');
        Observer.Expect('AttrDef NOPE', 'No | The field AttrDef of table LT RG Xv Row contains a value (NOPE) that cannot be found in the related table (LT BJ Xv Rel). | DB:PrimRecordNotFound |  | ');
        Observer.Expect('AttrDef blank', 'Yes |  |  | before insert 1::::::;insert 1; | 1::::::,');
        Observer.Expect('AttrNo R1', 'Yes |  |  | before insert 1::R1::::;insert 1; | 1::R1::::,');
        Observer.Expect('AttrNo NOPE', 'Yes |  |  | before insert 1::NOPE::::;insert 1; | 1::NOPE::::,');
        Observer.Expect('AttrNo blank', 'Yes |  |  | before insert 1::::::;insert 1; | 1::::::,');
        Observer.Expect('AttrYes R1', 'Yes |  |  | val AttrYes=R1;before insert 1:::R1:::;insert 1; | 1:::R1:::,');
        Observer.Expect('AttrYes NOPE', 'No | The field AttrYes of table LT RG Xv Row contains a value (NOPE) that cannot be found in the related table (LT BJ Xv Rel). | DB:PrimRecordNotFound |  | ');
        Observer.Expect('AttrYes blank', 'Yes |  |  | before insert 1::::::;insert 1; | 1::::::,');
        Observer.Verify();
    end;

    [Test]
    procedure RG_FieldElement_Relation_DfvTrue_AutoSaveOn()
    begin
        RgProbe(Xmlport::"LT RG Xv True Save", false);
        Observer.Expect('ElDef R1', 'Yes |  |  | val ElDef=R1;before insert 1::::R1::;insert 1; | 1::::R1::,');
        Observer.Expect('ElDef NOPE', 'No | The field ElDef of table LT RG Xv Row contains a value (NOPE) that cannot be found in the related table (LT BJ Xv Rel). | DB:PrimRecordNotFound |  | ');
        Observer.Expect('ElDef blank', 'Yes |  |  | val ElDef=;before insert 1::::::;insert 1; | 1::::::,');
        Observer.Expect('ElNo R1', 'Yes |  |  | before insert 1:::::R1:;insert 1; | 1:::::R1:,');
        Observer.Expect('ElNo NOPE', 'Yes |  |  | before insert 1:::::NOPE:;insert 1; | 1:::::NOPE:,');
        Observer.Expect('ElNo blank', 'Yes |  |  | before insert 1::::::;insert 1; | 1::::::,');
        Observer.Expect('ElYes R1', 'Yes |  |  | val ElYes=R1;before insert 1::::::R1;insert 1; | 1::::::R1,');
        Observer.Expect('ElYes NOPE', 'No | The field ElYes of table LT RG Xv Row contains a value (NOPE) that cannot be found in the related table (LT BJ Xv Rel). | DB:PrimRecordNotFound |  | ');
        Observer.Expect('ElYes blank', 'Yes |  |  | val ElYes=;before insert 1::::::;insert 1; | 1::::::,');
        Observer.Verify();
    end;

    [Test]
    procedure RG_FieldAttribute_Relation_DfvFalse_AutoSaveOn()
    begin
        RgProbe(Xmlport::"LT RG Xv False Save", true);
        Observer.Expect('AttrDef R1', 'Yes |  |  | before insert 1:R1:::::;insert 1; | 1:R1:::::,');
        Observer.Expect('AttrDef NOPE', 'Yes |  |  | before insert 1:NOPE:::::;insert 1; | 1:NOPE:::::,');
        Observer.Expect('AttrDef blank', 'Yes |  |  | before insert 1::::::;insert 1; | 1::::::,');
        Observer.Expect('AttrNo R1', 'Yes |  |  | before insert 1::R1::::;insert 1; | 1::R1::::,');
        Observer.Expect('AttrNo NOPE', 'Yes |  |  | before insert 1::NOPE::::;insert 1; | 1::NOPE::::,');
        Observer.Expect('AttrNo blank', 'Yes |  |  | before insert 1::::::;insert 1; | 1::::::,');
        Observer.Expect('AttrYes R1', 'Yes |  |  | val AttrYes=R1;before insert 1:::R1:::;insert 1; | 1:::R1:::,');
        Observer.Expect('AttrYes NOPE', 'No | The field AttrYes of table LT RG Xv Row contains a value (NOPE) that cannot be found in the related table (LT BJ Xv Rel). | DB:PrimRecordNotFound |  | ');
        Observer.Expect('AttrYes blank', 'Yes |  |  | before insert 1::::::;insert 1; | 1::::::,');
        Observer.Verify();
    end;

    [Test]
    procedure RG_FieldElement_Relation_DfvFalse_AutoSaveOn()
    begin
        RgProbe(Xmlport::"LT RG Xv False Save", false);
        Observer.Expect('ElDef R1', 'Yes |  |  | before insert 1::::R1::;insert 1; | 1::::R1::,');
        Observer.Expect('ElDef NOPE', 'Yes |  |  | before insert 1::::NOPE::;insert 1; | 1::::NOPE::,');
        Observer.Expect('ElDef blank', 'Yes |  |  | before insert 1::::::;insert 1; | 1::::::,');
        Observer.Expect('ElNo R1', 'Yes |  |  | before insert 1:::::R1:;insert 1; | 1:::::R1:,');
        Observer.Expect('ElNo NOPE', 'Yes |  |  | before insert 1:::::NOPE:;insert 1; | 1:::::NOPE:,');
        Observer.Expect('ElNo blank', 'Yes |  |  | before insert 1::::::;insert 1; | 1::::::,');
        Observer.Expect('ElYes R1', 'Yes |  |  | val ElYes=R1;before insert 1::::::R1;insert 1; | 1::::::R1,');
        Observer.Expect('ElYes NOPE', 'No | The field ElYes of table LT RG Xv Row contains a value (NOPE) that cannot be found in the related table (LT BJ Xv Rel). | DB:PrimRecordNotFound |  | ');
        Observer.Expect('ElYes blank', 'Yes |  |  | val ElYes=;before insert 1::::::;insert 1; | 1::::::,');
        Observer.Verify();
    end;

    [Test]
    procedure RG_FieldAttribute_Relation_DfvTrue_AutoSaveOff()
    begin
        RgProbe(Xmlport::"LT RG Xv True NoSave", true);
        Observer.Expect('AttrDef R1', 'Yes |  |  | val AttrDef=R1;before insert 1:R1:::::; | ');
        Observer.Expect('AttrDef NOPE', 'No | The field AttrDef of table LT RG Xv Row contains a value (NOPE) that cannot be found in the related table (LT BJ Xv Rel). | DB:PrimRecordNotFound |  | ');
        Observer.Expect('AttrDef blank', 'Yes |  |  | before insert 1::::::; | ');
        Observer.Expect('AttrNo R1', 'Yes |  |  | before insert 1::R1::::; | ');
        Observer.Expect('AttrNo NOPE', 'Yes |  |  | before insert 1::NOPE::::; | ');
        Observer.Expect('AttrNo blank', 'Yes |  |  | before insert 1::::::; | ');
        Observer.Expect('AttrYes R1', 'Yes |  |  | val AttrYes=R1;before insert 1:::R1:::; | ');
        Observer.Expect('AttrYes NOPE', 'No | The field AttrYes of table LT RG Xv Row contains a value (NOPE) that cannot be found in the related table (LT BJ Xv Rel). | DB:PrimRecordNotFound |  | ');
        Observer.Expect('AttrYes blank', 'Yes |  |  | before insert 1::::::; | ');
        Observer.Verify();
    end;

    [Test]
    procedure RG_FieldElement_Relation_DfvTrue_AutoSaveOff()
    begin
        RgProbe(Xmlport::"LT RG Xv True NoSave", false);
        Observer.Expect('ElDef R1', 'Yes |  |  | val ElDef=R1;before insert 1::::R1::; | ');
        Observer.Expect('ElDef NOPE', 'No | The field ElDef of table LT RG Xv Row contains a value (NOPE) that cannot be found in the related table (LT BJ Xv Rel). | DB:PrimRecordNotFound |  | ');
        Observer.Expect('ElDef blank', 'Yes |  |  | val ElDef=;before insert 1::::::; | ');
        Observer.Expect('ElNo R1', 'Yes |  |  | before insert 1:::::R1:; | ');
        Observer.Expect('ElNo NOPE', 'Yes |  |  | before insert 1:::::NOPE:; | ');
        Observer.Expect('ElNo blank', 'Yes |  |  | before insert 1::::::; | ');
        Observer.Expect('ElYes R1', 'Yes |  |  | val ElYes=R1;before insert 1::::::R1; | ');
        Observer.Expect('ElYes NOPE', 'No | The field ElYes of table LT RG Xv Row contains a value (NOPE) that cannot be found in the related table (LT BJ Xv Rel). | DB:PrimRecordNotFound |  | ');
        Observer.Expect('ElYes blank', 'Yes |  |  | val ElYes=;before insert 1::::::; | ');
        Observer.Verify();
    end;

    [Test]
    procedure RG_FieldAttribute_Relation_DfvFalse_AutoSaveOff()
    begin
        RgProbe(Xmlport::"LT RG Xv False NoSave", true);
        Observer.Expect('AttrDef R1', 'Yes |  |  | before insert 1:R1:::::; | ');
        Observer.Expect('AttrDef NOPE', 'Yes |  |  | before insert 1:NOPE:::::; | ');
        Observer.Expect('AttrDef blank', 'Yes |  |  | before insert 1::::::; | ');
        Observer.Expect('AttrNo R1', 'Yes |  |  | before insert 1::R1::::; | ');
        Observer.Expect('AttrNo NOPE', 'Yes |  |  | before insert 1::NOPE::::; | ');
        Observer.Expect('AttrNo blank', 'Yes |  |  | before insert 1::::::; | ');
        Observer.Expect('AttrYes R1', 'Yes |  |  | val AttrYes=R1;before insert 1:::R1:::; | ');
        Observer.Expect('AttrYes NOPE', 'No | The field AttrYes of table LT RG Xv Row contains a value (NOPE) that cannot be found in the related table (LT BJ Xv Rel). | DB:PrimRecordNotFound |  | ');
        Observer.Expect('AttrYes blank', 'Yes |  |  | before insert 1::::::; | ');
        Observer.Verify();
    end;

    [Test]
    procedure RG_FieldElement_Relation_DfvFalse_AutoSaveOff()
    begin
        RgProbe(Xmlport::"LT RG Xv False NoSave", false);
        Observer.Expect('ElDef R1', 'Yes |  |  | before insert 1::::R1::; | ');
        Observer.Expect('ElDef NOPE', 'Yes |  |  | before insert 1::::NOPE::; | ');
        Observer.Expect('ElDef blank', 'Yes |  |  | before insert 1::::::; | ');
        Observer.Expect('ElNo R1', 'Yes |  |  | before insert 1:::::R1:; | ');
        Observer.Expect('ElNo NOPE', 'Yes |  |  | before insert 1:::::NOPE:; | ');
        Observer.Expect('ElNo blank', 'Yes |  |  | before insert 1::::::; | ');
        Observer.Expect('ElYes R1', 'Yes |  |  | val ElYes=R1;before insert 1::::::R1; | ');
        Observer.Expect('ElYes NOPE', 'No | The field ElYes of table LT RG Xv Row contains a value (NOPE) that cannot be found in the related table (LT BJ Xv Rel). | DB:PrimRecordNotFound |  | ');
        Observer.Expect('ElYes blank', 'Yes |  |  | val ElYes=;before insert 1::::::; | ');
        Observer.Verify();
    end;
}
