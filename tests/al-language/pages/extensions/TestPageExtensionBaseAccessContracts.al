// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68920, codeunit 68921 (log), page 68922, page
//                extensions 68923 and 68924, codeunit 68925 (tests)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins what a page extension can do with the base page's variables and procedures (ADR-023):
//  - READ: the extension's OnOpenPage sees a protected Integer, Text, Boolean and Record variable the base's
//    OnOpenPage set (10, 'base', true, a record with a filter "Id: 1..9"). The base's OnInit runs before; a page
//    extension has no OnInit trigger of its own (AL0162 "'OnInit' is not a valid trigger for this object type").
//  - WRITE: what an extension action writes (Integer, Text, Boolean, the filter of the Record, an entry added to a List and to a
//    Dictionary) is what the base's action and a second extension read next; the List, Dictionary and Record are
//    the base's own objects (counts 2 and 2, filter "Id: 2..3").
//  - CALLS: a public procedure of the base with a return value (PublicFunc(3) answers the new sum), one with a var
//    parameter (X := X + Y + IntV) and one that changes a base variable, all run on the base's state; a base procedure
//    that refreshes the page (CurrPage.Update) and reads CurrPage.Editable and CurrPage.Caption works when called from the
//    extension (Caption is the page name).
//  - NAMES: an extension variable named like a protected base variable is a separate variable (the extension's is 0, the
//    base's keeps 99; no compile error). An extension procedure named like a base procedure is a compile error (AL0440 "The
//    Page 'X' already defines a method called 'Bump' with the same parameter types in ..."). A base variable that is not
//    protected is AL0161 "'Hidden' is inaccessible due to its protection level"; a local procedure of the base is
//    AL0161 "'SecretLocal()' is inaccessible due to its protection level". A protected procedure is callable (68922's Bump,
//    used in handlers/TestPageExtensionBaseMembersContracts.al).
//  - CONTROLS: an extension control whose source is a base protected variable (Integer, Text) or a field of a base
//    protected Record variable reads the value and, with SetValue, writes it back into the base.
// BC versions: 27.5

table 68920 "Probe BA Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 68921 "Probe BA Log"
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

page 68922 "Probe BA Page"
{
    PageType = Card;
    SourceTable = "Probe BA Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Txt; Rec.Txt) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(BaseRead)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    BaLog.Add('base action IntV=' + Format(IntV) + ' TxtV=' + TxtV + ' BolV=' + Format(BolV) + ' RecV=[' + RecV.GetFilters() + '] lst=' + Format(LstV.Count()) + ' dic=' + Format(DicV.Count()) + ' Shadow=' + Format(Shadow) + ' agr=' + Format(AgrIntV));
                end;
            }
        }
    }

    protected var
        IntV: Integer;
        TxtV: Text;
        BolV: Boolean;
        RecV: Record "Probe BA Table";
        LstV: List of [Text];
        DicV: Dictionary of [Text, Text];
        Shadow: Integer;

    var
        AgrIntV: Integer;
        Hidden: Integer;
        BaLog: Codeunit "Probe BA Log";

    trigger OnInit()
    begin
        IntV := 1;
        BaLog.Add('base OnInit IntV=' + Format(IntV));
    end;

    trigger OnOpenPage()
    begin
        IntV := 10;
        TxtV := 'base';
        BolV := true;
        RecV.SetRange(Id, 1, 9);
        LstV.Add('b');
        DicV.Add('k', 'b');
        Shadow := 99;
        RecV.Id := 1;
        RecV.Txt := 'fromrec';
        Hidden := 5;
        BaLog.Add('base OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    begin
        AgrIntV := IntV;
    end;

    procedure PublicFunc(Add: Integer): Integer
    begin
        IntV += Add;
        exit(IntV);
    end;

    procedure WithVar(var X: Integer; Y: Integer)
    begin
        X := X + Y + IntV;
    end;

    procedure ChangesVar()
    begin
        TxtV := 'changed by base proc';
    end;

    procedure RefreshAndLog()
    begin
        CurrPage.Update(false);
        BaLog.Add('base RefreshAndLog editable=' + Format(CurrPage.Editable()) + ' caption=[' + CurrPage.Caption() + ']');
    end;

    local procedure SecretLocal(): Integer
    begin
        exit(1);
    end;
}

pageextension 68923 "Probe BA Ext1" extends "Probe BA Page"
{
    layout
    {
        addlast(Content)
        {
            field(ExtIntV; IntV) { ApplicationArea = All; }
            field(ExtTxtV; TxtV) { ApplicationArea = All; }
            field(ExtRecTxt; RecV.Txt) { ApplicationArea = All; }
            field(ExtRecId; RecV.Id) { ApplicationArea = All; }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(ExtWrite)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    IntV := 20;
                    TxtV := 'ext1';
                    BolV := false;
                    RecV.SetRange(Id, 2, 3);
                    LstV.Add('e1');
                    DicV.Add('k1', 'e1');
                    BaLog.Add('ext1 wrote; own Shadow=' + Format(Shadow));
                    Shadow := 5;
                end;
            }
            action(ExtCalls)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    X: Integer;
                begin
                    X := 1;
                    BaLog.Add('PublicFunc=' + Format(PublicFunc(3)));
                    WithVar(X, 4);
                    BaLog.Add('WithVar X=' + Format(X));
                    ChangesVar();
                    BaLog.Add('TxtV after ChangesVar=' + TxtV);
                    RefreshAndLog();
                end;
            }
        }
    }

    var
        BaLog: Codeunit "Probe BA Log";
        Shadow: Integer;

    trigger OnOpenPage()
    begin
        BaLog.Add('ext1 OnOpenPage IntV=' + Format(IntV) + ' TxtV=' + TxtV + ' BolV=' + Format(BolV) + ' RecV=[' + RecV.GetFilters() + '] Shadow=' + Format(Shadow));
    end;
}

pageextension 68924 "Probe BA Ext2" extends "Probe BA Page"
{
    actions
    {
        addlast(Processing)
        {
            action(Ext2Read)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    BaLog.Add('ext2 reads IntV=' + Format(IntV) + ' TxtV=' + TxtV + ' BolV=' + Format(BolV) + ' RecV=[' + RecV.GetFilters() + '] lst=' + Format(LstV.Count()) + ' dic=' + Format(DicV.Count()) + ' Shadow=' + Format(Shadow));
                end;
            }
        }
    }

    var
        BaLog: Codeunit "Probe BA Log";
}

codeunit 68925 "Probe Page Ext Base Access"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        BaLog: Codeunit "Probe BA Log";

    local procedure Open(var BaPage: TestPage "Probe BA Page")
    var
        BaRec: Record "Probe BA Table";
    begin
        BaRec.DeleteAll();
        BaRec.Id := 1;
        BaRec.Txt := 'row1';
        BaRec.Insert();
        Commit();
        BaLog.Take();
        BaPage.OpenEdit();
    end;

    [Test]
    procedure ExtensionOnOpenPage_ReadsTheBaseVariablesTheBaseSet()
    var
        BaPage: TestPage "Probe BA Page";
    begin
        Open(BaPage);

        Assert.AreEqual(
            'base OnInit IntV=1;base OnOpenPage;ext1 OnOpenPage IntV=10 TxtV=base BolV=Yes RecV=[Id: 1..9] Shadow=0;',
            BaLog.Take(), 'log');
        BaPage.Close();
    end;

    [Test]
    procedure ExtensionWrites_AreSeenByTheBaseAndBySecondExtension_AlsoForReferenceTypes()
    var
        BaPage: TestPage "Probe BA Page";
    begin
        Open(BaPage);
        BaLog.Take();

        BaPage.BaseRead.Invoke();
        BaPage.ExtWrite.Invoke();
        BaPage.Ext2Read.Invoke();
        BaPage.BaseRead.Invoke();

        Assert.AreEqual(
            'base action IntV=10 TxtV=base BolV=Yes RecV=[Id: 1..9] lst=1 dic=1 Shadow=99 agr=10;' +
            'ext1 wrote; own Shadow=0;' +
            'ext2 reads IntV=20 TxtV=ext1 BolV=No RecV=[Id: 2..3] lst=2 dic=2 Shadow=99;' +
            'base action IntV=20 TxtV=ext1 BolV=No RecV=[Id: 2..3] lst=2 dic=2 Shadow=99 agr=20;',
            BaLog.Take(), 'log');
        BaPage.Close();
    end;

    [Test]
    procedure ExtensionCallsOfBaseProcedures_RunOnTheBaseState()
    var
        BaPage: TestPage "Probe BA Page";
    begin
        Open(BaPage);
        BaLog.Take();

        BaPage.ExtCalls.Invoke();

        Assert.AreEqual(
            'PublicFunc=13;WithVar X=18;TxtV after ChangesVar=changed by base proc;base RefreshAndLog editable=Yes caption=[Probe BA Page];',
            BaLog.Take(), 'log');
        BaPage.Close();
    end;

    [Test]
    procedure ExtensionControls_BoundToBaseVariables_ReadAndWriteThem()
    var
        BaPage: TestPage "Probe BA Page";
    begin
        Open(BaPage);
        BaLog.Take();

        Assert.AreEqual('10', BaPage.ExtIntV.Value(), 'Integer variable');
        Assert.AreEqual('base', BaPage.ExtTxtV.Value(), 'Text variable');
        Assert.AreEqual('fromrec', BaPage.ExtRecTxt.Value(), 'field of the base Record variable');
        Assert.AreEqual('1', BaPage.ExtRecId.Value(), 'key field of the base Record variable');

        BaPage.ExtIntV.SetValue(55);
        BaPage.ExtTxtV.SetValue('set by control');
        BaPage.BaseRead.Invoke();

        Assert.AreEqual('base action IntV=55 TxtV=set by control BolV=Yes RecV=[Id: 1..9] lst=1 dic=1 Shadow=99 agr=55;', BaLog.Take(), 'the base sees the control writes');
        BaPage.Close();
    end;
}
