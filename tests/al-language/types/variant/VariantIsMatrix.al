// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope. Every Variant.IsXxx method asked of one Variant, for a Variant that holds a value of each kind a Variant can hold
//   (al-runner issue 7963: Variant.IsTransactionType; and the IsXxx methods no probe asks with both a matching and a non-matching value).
//   Each held kind is a matching value for its own method and a non-matching value for every other method. Not held: a SecurityFiltering
//   value (not a type a variable can be declared with: AL0134), DotNet, Automation, File, WideChar and DataClassificationType values
//   (no Cloud declaration); their methods are asked, so only their non-matching side is measured.
// Fixtures used: Probe Observer (69160); self-contained enum 71904, table 71905, codeunit 71906.
// Probe: written for al-runner issue 7963, observed on BC 27.5, 28.5 and 29.0. Every literal asserted below is what BC produced.
// Facts: <held kind> is the list of the Variant.IsXxx methods that returned true for a Variant holding that value, in the order of
//   the AllFlags procedure below (an empty text: no method returned true).
// BC versions: 27, 28, 29

enum 71904 "LT VaM Color"
{
    Extensible = false;
    value(0; Red) { }
    value(1; Green) { }
}

table 71905 "LT VaM Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 71906 "LT VaM Is Matrix"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        SomeLabel: Label 'label text';
        SomeTextConst: TextConst ENU = 'const text';

    local procedure AllFlags(V: Variant): Text
    begin
        exit(FlagsA(V) + FlagsB(V) + FlagsC(V));
    end;

    local procedure FlagsA(V: Variant) R: Text
    begin
        if V.IsAction() then R += 'Action,';
        if V.IsAutomation() then R += 'Automation,';
        if V.IsBigInteger() then R += 'BigInteger,';
        if V.IsBinary() then R += 'Binary,';
        if V.IsBoolean() then R += 'Boolean,';
        if V.IsByte() then R += 'Byte,';
        if V.IsChar() then R += 'Char,';
        if V.IsClientType() then R += 'ClientType,';
        if V.IsCode() then R += 'Code,';
        if V.IsCodeunit() then R += 'Codeunit,';
        if V.IsDataClassification() then R += 'DataClassification,';
        if V.IsDataClassificationType() then R += 'DataClassificationType,';
        if V.IsDate() then R += 'Date,';
        if V.IsDateFormula() then R += 'DateFormula,';
        if V.IsDateTime() then R += 'DateTime,';
        if V.IsDecimal() then R += 'Decimal,';
        if V.IsDefaultLayout() then R += 'DefaultLayout,';
        if V.IsDictionary() then R += 'Dictionary,';
        if V.IsDotNet() then R += 'DotNet,';
        if V.IsDuration() then R += 'Duration,';
        if V.IsExecutionMode() then R += 'ExecutionMode,';
    end;

    local procedure FlagsB(V: Variant) R: Text
    begin
        if V.IsFieldRef() then R += 'FieldRef,';
        if V.IsFile() then R += 'File,';
        if V.IsFilterPageBuilder() then R += 'FilterPageBuilder,';
        if V.IsGuid() then R += 'Guid,';
        if V.IsInStream() then R += 'InStream,';
        if V.IsInteger() then R += 'Integer,';
        if V.IsJsonArray() then R += 'JsonArray,';
        if V.IsJsonObject() then R += 'JsonObject,';
        if V.IsJsonToken() then R += 'JsonToken,';
        if V.IsJsonValue() then R += 'JsonValue,';
        if V.IsList() then R += 'List,';
        if V.IsNotification() then R += 'Notification,';
        if V.IsObjectType() then R += 'ObjectType,';
        if V.IsOption() then R += 'Option,';
        if V.IsOutStream() then R += 'OutStream,';
        if V.IsPromptMode() then R += 'PromptMode,';
        if V.IsRecord() then R += 'Record,';
        if V.IsRecordId() then R += 'RecordId,';
        if V.IsRecordRef() then R += 'RecordRef,';
        if V.IsReportFormat() then R += 'ReportFormat,';
        if V.IsSecurityFiltering() then R += 'SecurityFiltering,';
        if V.IsTableConnectionType() then R += 'TableConnectionType,';
        if V.IsTestPermissions() then R += 'TestPermissions,';
        if V.IsText() then R += 'Text,';
        if V.IsTextBuilder() then R += 'TextBuilder,';
        if V.IsTextConstant() then R += 'TextConstant,';
        if V.IsTextEncoding() then R += 'TextEncoding,';
        if V.IsTime() then R += 'Time,';
        if V.IsTransactionType() then R += 'TransactionType,';
        if V.IsWideChar() then R += 'WideChar,';
    end;

    local procedure FlagsC(V: Variant) R: Text
    begin
        if V.IsXmlAttribute() then R += 'XmlAttribute,';
        if V.IsXmlAttributeCollection() then R += 'XmlAttributeCollection,';
        if V.IsXmlCData() then R += 'XmlCData,';
        if V.IsXmlComment() then R += 'XmlComment,';
        if V.IsXmlDeclaration() then R += 'XmlDeclaration,';
        if V.IsXmlDocument() then R += 'XmlDocument,';
        if V.IsXmlDocumentType() then R += 'XmlDocumentType,';
        if V.IsXmlElement() then R += 'XmlElement,';
        if V.IsXmlNamespaceManager() then R += 'XmlNamespaceManager,';
        if V.IsXmlNameTable() then R += 'XmlNameTable,';
        if V.IsXmlNode() then R += 'XmlNode,';
        if V.IsXmlNodeList() then R += 'XmlNodeList,';
        if V.IsXmlProcessingInstruction() then R += 'XmlProcessingInstruction,';
        if V.IsXmlReadOptions() then R += 'XmlReadOptions,';
        if V.IsXmlText() then R += 'XmlText,';
        if V.IsXmlWriteOptions() then R += 'XmlWriteOptions,';
    end;

    [Test]
    procedure TransactionType_AllValues()
    var
        TT: TransactionType;
        V: Variant;
    begin
        V := TT;
        Observer.Observe('default', AllFlags(V));
        TT := TransactionType::Browse;
        V := TT;
        Observer.Observe('browse', AllFlags(V));
        TT := TransactionType::Snapshot;
        V := TT;
        Observer.Observe('snapshot', AllFlags(V));
        TT := TransactionType::Update;
        V := TT;
        Observer.Observe('update', AllFlags(V));
        TT := TransactionType::UpdateNoLocks;
        V := TT;
        Observer.Observe('updatenolocks', AllFlags(V));
        TT := TransactionType::Report;
        V := TT;
        Observer.Observe('report', AllFlags(V));
        V := TransactionType::Update;
        Observer.Observe('literal', AllFlags(V));
        V := CurrentTransactionType();
        Observer.Observe('current', AllFlags(V));
        V := Format(TransactionType::Update);
        Observer.Observe('formatted', AllFlags(V));
        Observer.Finish();
    end;

    [Test]
    procedure Unassigned_Variant()
    var
        V: Variant;
    begin
        Observer.Observe('unassigned', AllFlags(V));
        Observer.Finish();
    end;

    [Test]
    procedure Simple_Kinds()
    var
        Bo: Boolean;
        I: Integer;
        Bi: BigInteger;
        D: Decimal;
        By: Byte;
        Ch: Char;
        T: Text;
        C: Code[10];
        O: Option A,B;
        E: Enum "LT VaM Color";
        V: Variant;
    begin
        Bo := true;
        V := Bo;
        Observer.Observe('boolean', AllFlags(V));
        I := 7;
        V := I;
        Observer.Observe('integer', AllFlags(V));
        Bi := 7;
        V := Bi;
        Observer.Observe('biginteger', AllFlags(V));
        D := 1.5;
        V := D;
        Observer.Observe('decimal', AllFlags(V));
        By := 7;
        V := By;
        Observer.Observe('byte', AllFlags(V));
        Ch := 'x';
        V := Ch;
        Observer.Observe('char', AllFlags(V));
        T := 'abc';
        V := T;
        Observer.Observe('text', AllFlags(V));
        C := 'ABC';
        V := C;
        Observer.Observe('code', AllFlags(V));
        V := SomeLabel;
        Observer.Observe('label', AllFlags(V));
        V := SomeTextConst;
        Observer.Observe('textconst', AllFlags(V));
        O := O::B;
        V := O;
        Observer.Observe('option', AllFlags(V));
        E := E::Green;
        V := E;
        Observer.Observe('enum', AllFlags(V));
        Observer.Finish();
    end;

    [Test]
    procedure Date_Time_Kinds()
    var
        Dt: Date;
        Tm: Time;
        DtTm: DateTime;
        Du: Duration;
        DF: DateFormula;
        G: Guid;
        V: Variant;
    begin
        Dt := 20240115D;
        V := Dt;
        Observer.Observe('date', AllFlags(V));
        Tm := 101500T;
        V := Tm;
        Observer.Observe('time', AllFlags(V));
        DtTm := CreateDateTime(20240115D, 101500T);
        V := DtTm;
        Observer.Observe('datetime', AllFlags(V));
        Du := 1000;
        V := Du;
        Observer.Observe('duration', AllFlags(V));
        Evaluate(DF, '<1D>');
        V := DF;
        Observer.Observe('dateformula', AllFlags(V));
        G := CreateGuid();
        V := G;
        Observer.Observe('guid', AllFlags(V));
        Observer.Finish();
    end;

    [Test]
    procedure Record_Kinds()
    var
        Row: Record "LT VaM Row";
        RecRef: RecordRef;
        Fld: FieldRef;
        Rid: RecordId;
        Cu: Codeunit "Probe Observer";
        V: Variant;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        V := Row;
        Observer.Observe('record', AllFlags(V));
        Rid := Row.RecordId();
        V := Rid;
        Observer.Observe('recordid', AllFlags(V));
        RecRef.GetTable(Row);
        V := RecRef;
        Observer.Observe('recordref', AllFlags(V));
        Fld := RecRef.Field(2);
        V := Fld;
        Observer.Observe('fieldref', AllFlags(V));
        V := Cu;
        Observer.Observe('codeunit', AllFlags(V));
        Observer.Finish();
    end;

    [Test]
    procedure Stream_Builder_Collection_Kinds()
    var
        Row: Record "LT VaM Row" temporary;
        InS: InStream;
        OutS: OutStream;
        TB: TextBuilder;
        L: List of [Text];
        Dict: Dictionary of [Text, Text];
        N: Notification;
        FPB: FilterPageBuilder;
        V: Variant;
    begin
        Row.Data.CreateOutStream(OutS);
        V := OutS;
        Observer.Observe('outstream', AllFlags(V));
        Row.Data.CreateInStream(InS);
        V := InS;
        Observer.Observe('instream', AllFlags(V));
        TB.Append('x');
        V := TB;
        Observer.Observe('textbuilder', AllFlags(V));
        L.Add('x');
        V := L;
        Observer.Observe('list', AllFlags(V));
        Dict.Add('k', 'v');
        V := Dict;
        Observer.Observe('dictionary', AllFlags(V));
        N.Message('m');
        V := N;
        Observer.Observe('notification', AllFlags(V));
        V := FPB;
        Observer.Observe('filterpagebuilder', AllFlags(V));
        Observer.Finish();
    end;

    [Test]
    procedure Json_Kinds()
    var
        JO: JsonObject;
        JA: JsonArray;
        JV: JsonValue;
        JT: JsonToken;
        V: Variant;
    begin
        JO.Add('a', 1);
        V := JO;
        Observer.Observe('jsonobject', AllFlags(V));
        JA.Add(1);
        V := JA;
        Observer.Observe('jsonarray', AllFlags(V));
        JV.SetValue(1);
        V := JV;
        Observer.Observe('jsonvalue', AllFlags(V));
        JO.Get('a', JT);
        V := JT;
        Observer.Observe('jsontoken', AllFlags(V));
        Observer.Finish();
    end;

    [Test]
    procedure Platform_Option_Kinds()
    var
        Ac: Action;
        Ct: ClientType;
        Dc: DataClassification;
        Dl: DefaultLayout;
        Em: ExecutionMode;
        Ot: ObjectType;
        Rf: ReportFormat;
        Tc: TableConnectionType;
        Tp: TestPermissions;
        Te: TextEncoding;
        Pm: PromptMode;
        V: Variant;
    begin
        V := Ac;
        Observer.Observe('action', AllFlags(V));
        V := Ct;
        Observer.Observe('clienttype', AllFlags(V));
        V := Dc;
        Observer.Observe('dataclassification', AllFlags(V));
        V := Dl;
        Observer.Observe('defaultlayout', AllFlags(V));
        V := Em;
        Observer.Observe('executionmode', AllFlags(V));
        V := Ot;
        Observer.Observe('objecttype', AllFlags(V));
        V := Rf;
        Observer.Observe('reportformat', AllFlags(V));
        V := Tc;
        Observer.Observe('tableconnectiontype', AllFlags(V));
        V := Tp;
        Observer.Observe('testpermissions', AllFlags(V));
        V := Te;
        Observer.Observe('textencoding', AllFlags(V));
        V := Pm;
        Observer.Observe('promptmode', AllFlags(V));
        Observer.Finish();
    end;

    [Test]
    procedure Xml_Kinds_A()
    var
        Doc: XmlDocument;
        El: XmlElement;
        At: XmlAttribute;
        Tx: XmlText;
        Cd: XmlCData;
        Cm: XmlComment;
        Dc: XmlDeclaration;
        Pi: XmlProcessingInstruction;
        V: Variant;
    begin
        Doc := XmlDocument.Create();
        V := Doc;
        Observer.Observe('xmldocument', AllFlags(V));
        El := XmlElement.Create('a');
        V := El;
        Observer.Observe('xmlelement', AllFlags(V));
        At := XmlAttribute.Create('k', 'v');
        V := At;
        Observer.Observe('xmlattribute', AllFlags(V));
        Tx := XmlText.Create('t');
        V := Tx;
        Observer.Observe('xmltext', AllFlags(V));
        Cd := XmlCData.Create('c');
        V := Cd;
        Observer.Observe('xmlcdata', AllFlags(V));
        Cm := XmlComment.Create('c');
        V := Cm;
        Observer.Observe('xmlcomment', AllFlags(V));
        Dc := XmlDeclaration.Create('1.0', 'utf-8', 'yes');
        V := Dc;
        Observer.Observe('xmldeclaration', AllFlags(V));
        Pi := XmlProcessingInstruction.Create('pi', 'd');
        V := Pi;
        Observer.Observe('xmlprocessinginstruction', AllFlags(V));
        Observer.Finish();
    end;

    [Test]
    procedure Xml_Kinds_B()
    var
        El: XmlElement;
        Dt: XmlDocumentType;
        Nd: XmlNode;
        Nl: XmlNodeList;
        Ac: XmlAttributeCollection;
        Nm: XmlNamespaceManager;
        Nt: XmlNameTable;
        Ro: XmlReadOptions;
        Wo: XmlWriteOptions;
        V: Variant;
    begin
        El := XmlElement.Create('a');
        El.Add(XmlElement.Create('b'));
        El.SetAttribute('k', 'v');
        Dt := XmlDocumentType.Create('a');
        V := Dt;
        Observer.Observe('xmldocumenttype', AllFlags(V));
        Nd := El.AsXmlNode();
        V := Nd;
        Observer.Observe('xmlnode', AllFlags(V));
        Nl := El.GetChildNodes();
        V := Nl;
        Observer.Observe('xmlnodelist', AllFlags(V));
        Ac := El.Attributes();
        V := Ac;
        Observer.Observe('xmlattributecollection', AllFlags(V));
        V := Nm;
        Observer.Observe('xmlnamespacemanager', AllFlags(V));
        V := Nt;
        Observer.Observe('xmlnametable', AllFlags(V));
        V := Ro;
        Observer.Observe('xmlreadoptions', AllFlags(V));
        V := Wo;
        Observer.Observe('xmlwriteoptions', AllFlags(V));
        Observer.Finish();
    end;
}
