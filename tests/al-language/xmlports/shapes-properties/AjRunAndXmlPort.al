// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); own table 79005 (declared in types/lt-aj-probes/AjMisc.al), codeunits 79003 79004 79020, xmlports 79008 79009 79010; writer QS: xmlports 87357, 87358 (tests QS_*)
// Facts: this.Run() inside a codeunit (with OnRun code, with an empty OnRun, with an OnRun that raises an error, with a record parameter); what an XmlPort import leaves in a table element's temporary table and in the real table for UseTemporary = true with AutoSave = false, UseTemporary = true with AutoSave left on, and AutoSave = false without UseTemporary.
// BC versions: 27.5+

codeunit 79003 "LT AJ Run Plain"
{
    var
        RunCount: Integer;

    trigger OnRun()
    begin
        RunCount += 1;
    end;

    procedure CallThisRun(): Boolean
    begin
        exit(this.Run());
    end;

    procedure CallThisRunAsStatement()
    begin
        this.Run();
    end;

    procedure GetCount(): Integer
    begin
        exit(RunCount);
    end;
}

codeunit 79004 "LT AJ Run Empty"
{
    trigger OnRun()
    begin
    end;

    procedure CallThisRun(): Boolean
    begin
        exit(this.Run());
    end;
}

codeunit 79021 "LT AJ Run Error"
{
    trigger OnRun()
    begin
        Error('boom from OnRun');
    end;

    procedure CallThisRun(): Boolean
    begin
        exit(this.Run());
    end;

    procedure CallThisRunAsStatement()
    begin
        this.Run();
    end;
}

codeunit 79020 "LT AJ Run Rec"
{
    TableNo = "LT AJ Item";

    var
        RunCount: Integer;

    trigger OnRun()
    begin
        RunCount += 1;
        Rec.Txt := 'ran ' + Format(RunCount);
        Rec.Id += 100;
    end;

    procedure CallThisRun(var R: Record "LT AJ Item"): Boolean
    begin
        exit(this.Run(R));
    end;

    procedure GetCount(): Integer
    begin
        exit(RunCount);
    end;
}

codeunit 79002 "LT AJ This Run"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ThisRun_WithOnRunCode()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Codeunit "LT AJ Run Plain";
        Ok: Boolean;
    begin
        Ok := Plain.CallThisRun();
        Observer.Observe('first call', Format(Ok) + '|' + Format(Plain.GetCount()));
        Ok := Plain.CallThisRun();
        Observer.Observe('second call', Format(Ok) + '|' + Format(Plain.GetCount()));
        Plain.CallThisRunAsStatement();
        Observer.Observe('statement', Format(Plain.GetCount()));
        Ok := Plain.Run();
        Observer.Observe('outside Run', Format(Ok) + '|' + Format(Plain.GetCount()));
        Observer.Expect('first call', 'Yes|1');
        Observer.Expect('second call', 'Yes|2');
        Observer.Expect('statement', '3');
        Observer.Expect('outside Run', 'Yes|4');
        Observer.Verify();
    end;

    [Test]
    procedure ThisRun_EmptyOnRun()
    var
        Observer: Codeunit "Probe Observer";
        Empty: Codeunit "LT AJ Run Empty";
        Ok: Boolean;
    begin
        Ok := Empty.CallThisRun();
        Observer.Observe('empty OnRun', Format(Ok));
        Observer.Expect('empty OnRun', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ThisRun_OnRunRaisesError()
    var
        Observer: Codeunit "Probe Observer";
        Failing: Codeunit "LT AJ Run Error";
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := Failing.CallThisRun();
        Observer.Observe('error returned', Format(Ok));
        Observer.ObserveError('error returned');
        asserterror Failing.CallThisRunAsStatement();
        Observer.ObserveError('error statement');
        Observer.Expect('error returned', 'No');
        Observer.Expect('error returned|text', 'boom from OnRun');
        Observer.Expect('error returned|code', 'Dialog');
        Observer.Expect('error statement|text', 'boom from OnRun');
        Observer.Expect('error statement|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ThisRun_WithRecordParameter()
    var
        Observer: Codeunit "Probe Observer";
        WithRec: Codeunit "LT AJ Run Rec";
        Item: Record "LT AJ Item";
        Ok: Boolean;
    begin
        Item.Id := 1;
        Item.Txt := 'before';
        Ok := WithRec.CallThisRun(Item);
        Observer.Observe('first', Format(Ok) + '|' + Format(Item.Id) + '|' + Item.Txt + '|' + Format(WithRec.GetCount()));
        Ok := WithRec.CallThisRun(Item);
        Observer.Observe('second', Format(Ok) + '|' + Format(Item.Id) + '|' + Item.Txt + '|' + Format(WithRec.GetCount()));
        Observer.Expect('first', 'Yes|101|ran 1|1');
        Observer.Expect('second', 'Yes|201|ran 2|2');
        Observer.Verify();
    end;

    // Writer QZ: the bare forms Run() and Run(Rec) inside a codeunit (fixtures in QzBareRun.al).
    [Test]
    procedure QZ_BareRun_WithOnRunCode()
    var
        Observer: Codeunit "Probe Observer";
        Bare: Codeunit "LT QZ Bare Run";
        Ok: Boolean;
    begin
        Ok := Bare.CallBareRun();
        Observer.Observe('first call', Format(Ok) + '|' + Format(Bare.GetCount()));
        Ok := Bare.CallBareRun();
        Observer.Observe('second call', Format(Ok) + '|' + Format(Bare.GetCount()));
        Bare.CallBareRunAsStatement();
        Observer.Observe('statement', Format(Bare.GetCount()));
        Observer.Observe('in if', Bare.CallBareRunInIf() + '|' + Format(Bare.GetCount()));
        Ok := Bare.Run();
        Observer.Observe('outside Run', Format(Ok) + '|' + Format(Bare.GetCount()));
        Observer.Expect('first call', 'Yes|1');
        Observer.Expect('second call', 'Yes|2');
        Observer.Expect('statement', '3');
        Observer.Expect('in if', 'if true|4');
        Observer.Expect('outside Run', 'Yes|5');
        Observer.Verify();
    end;

    [Test]
    procedure QZ_BareRun_OnRunRaisesError()
    var
        Observer: Codeunit "Probe Observer";
        Failing: Codeunit "LT QZ Bare Run Error";
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := Failing.CallBareRun();
        Observer.Observe('error returned', Format(Ok));
        Observer.ObserveError('error returned');
        asserterror Failing.CallBareRunAsStatement();
        Observer.ObserveError('error statement');
        Observer.Expect('error returned', 'No');
        Observer.Expect('error returned|text', 'LT QZ bare run failed');
        Observer.Expect('error returned|code', 'Dialog');
        Observer.Expect('error statement|text', 'LT QZ bare run failed');
        Observer.Expect('error statement|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure QZ_BareRunRec_IfNotRun()
    var
        Observer: Codeunit "Probe Observer";
        WithRec: Codeunit "LT QZ Bare Run Rec";
        Item: Record "LT AJ Item";
        Ok: Boolean;
    begin
        Item.Id := 1;
        Item.Txt := 'before';
        Ok := WithRec.CallBareRunRec(Item);
        Observer.Observe('first', Format(Ok) + '|' + Format(Item.Id) + '|' + Item.Txt + '|' + Format(WithRec.GetCount()));
        WithRec.CallBareRunRecAsStatement(Item);
        Observer.Observe('statement', Format(Item.Id) + '|' + Item.Txt + '|' + Format(WithRec.GetCount()));
        Item.Txt := 'fail';
        ClearLastError();
        Ok := WithRec.CallBareRunRec(Item);
        Observer.Observe('failing', Format(Ok) + '|' + Format(Item.Id) + '|' + Item.Txt + '|' + Format(WithRec.GetCount()));
        Observer.ObserveError('failing');
        Observer.Expect('first', 'Yes|11|qz ran 1|1');
        Observer.Expect('statement', '21|qz ran 2|2');
        Observer.Expect('failing', 'No|21|fail|3');
        Observer.Expect('failing|text', 'LT QZ bare run rec failed');
        Observer.Expect('failing|code', 'Dialog');
        Observer.Verify();
    end;
}

xmlport 79008 "LT AJ Xp Temp No Save"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Item; "LT AJ Item")
            {
                UseTemporary = true;
                AutoSave = false;
                XmlName = 'Row';

                fieldelement(Id; Item.Id) { }
                fieldelement(Txt; Item.Txt) { }

                trigger OnAfterInsertRecord()
                begin
                    Log += 'afterInsert temp=' + Format(Item.Count()) + ' real=' + Format(Real.Count()) + ' isTemp=' + Format(Item.IsTemporary()) + ';';
                end;
            }
        }
    }

    var
        Real: Record "LT AJ Item";
        Log: Text;

    trigger OnPostXmlPort()
    begin
        Log += 'post temp=' + Format(Item.Count()) + ' real=' + Format(Real.Count()) + ';';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 79009 "LT AJ Xp Temp Auto Save"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Item; "LT AJ Item")
            {
                UseTemporary = true;
                XmlName = 'Row';

                fieldelement(Id; Item.Id) { }
                fieldelement(Txt; Item.Txt) { }

                trigger OnAfterInsertRecord()
                begin
                    Log += 'afterInsert temp=' + Format(Item.Count()) + ' real=' + Format(Real.Count()) + ';';
                end;
            }
        }
    }

    var
        Real: Record "LT AJ Item";
        Log: Text;

    trigger OnPostXmlPort()
    begin
        Log += 'post temp=' + Format(Item.Count()) + ' real=' + Format(Real.Count()) + ';';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 79010 "LT AJ Xp Real No Save"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Item; "LT AJ Item")
            {
                AutoSave = false;
                XmlName = 'Row';

                fieldelement(Id; Item.Id) { }
                fieldelement(Txt; Item.Txt) { }

                trigger OnAfterInsertRecord()
                begin
                    Log += 'afterInsert count=' + Format(Item.Count()) + ';';
                end;
            }
        }
    }

    var
        Log: Text;

    trigger OnPostXmlPort()
    begin
        Log += 'post count=' + Format(Item.Count()) + ';';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

// Writer QS: VariableText import into a temporary Integer table element with AutoSave = false (the trigger log shows what each
// trigger sees); the same with a manual Insert in OnBeforeInsertRecord; an Xml import into a temporary table element with
// AutoSave = false whose OnBeforeInsertRecord inserts the row itself.
xmlport 87357 "LT QS Xp Text Temp No Save"
{
    Direction = Import;
    Format = VariableText;
    FieldDelimiter = '"';
    FieldSeparator = '|';
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Tmp; Integer)
            {
                AutoSave = false;
                XmlName = 'tmpImport';
                UseTemporary = true;
                textelement(shelf) { }
                textelement(itemcode) { }

                trigger OnAfterInitRecord()
                begin
                    Log += 'init n=' + Format(Tmp.Number) + ' count=' + Format(Tmp.Count()) + ';';
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'before shelf=' + shelf + ' itemcode=' + itemcode + ' n=' + Format(Tmp.Number) + ' count=' + Format(Tmp.Count()) + ' temp=' + Format(Tmp.IsTemporary()) + ';';
                    if ManualInsert then begin
                        Counter += 1;
                        Tmp.Number := Counter;
                        Tmp.Insert();
                    end;
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log += 'after n=' + Format(Tmp.Number) + ' count=' + Format(Tmp.Count()) + ';';
                end;
            }
        }
    }

    var
        Log: Text;
        ManualInsert: Boolean;
        Counter: Integer;

    trigger OnPreXmlPort()
    begin
        Log += 'pre count=' + Format(Tmp.Count()) + ';';
    end;

    trigger OnPostXmlPort()
    begin
        Log += 'post count=' + Format(Tmp.Count()) + ';';
    end;

    procedure SetManualInsert(NewManualInsert: Boolean)
    begin
        ManualInsert := NewManualInsert;
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;

    procedure Rows() Result: Text
    begin
        if Tmp.FindSet() then
            repeat
                Result += Format(Tmp.Number) + ';';
            until Tmp.Next() = 0;
        Result := 'count=' + Format(Tmp.Count()) + ' rows=' + Result;
    end;
}

xmlport 87358 "LT QS Xp Xml Temp Manual"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Item; "LT AJ Item")
            {
                UseTemporary = true;
                AutoSave = false;
                XmlName = 'Row';

                fieldelement(Id; Item.Id) { }
                fieldelement(Txt; Item.Txt) { }

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'before id=' + Format(Item.Id) + ' txt=' + Item.Txt + ' temp=' + Format(Item.Count()) + ';';
                    if ManualInsert then
                        Item.Insert();
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log += 'after id=' + Format(Item.Id) + ' temp=' + Format(Item.Count()) + ' real=' + Format(Real.Count()) + ';';
                end;
            }
        }
    }

    var
        Real: Record "LT AJ Item";
        Log: Text;
        ManualInsert: Boolean;

    procedure SetManualInsert(NewManualInsert: Boolean)
    begin
        ManualInsert := NewManualInsert;
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;

    procedure Rows() Result: Text
    begin
        if Item.FindSet() then
            repeat
                Result += Format(Item.Id) + ':' + Item.Txt + ';';
            until Item.Next() = 0;
        Result := 'count=' + Format(Item.Count()) + ' rows=' + Result;
    end;
}

codeunit 79011 "LT AJ XmlPort Temp"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Source(var Tmp: Codeunit "Temp Blob"; var Ins: InStream)
    var
        Outs: OutStream;
    begin
        Tmp.CreateOutStream(Outs);
        Outs.WriteText('<Root><Row><Id>1</Id><Txt>one</Txt></Row><Row><Id>2</Id><Txt>two</Txt></Row></Root>');
        Tmp.CreateInStream(Ins);
    end;

    [Test]
    procedure XmlPort_UseTemporary_AutoSaveFalse_Import()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Codeunit "Temp Blob";
        Ins: InStream;
        Xp: XmlPort "LT AJ Xp Temp No Save";
        Real: Record "LT AJ Item";
    begin
        Real.DeleteAll();
        Source(Tmp, Ins);
        Xp.SetSource(Ins);
        Xp.Import();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('real after', Format(Real.Count()));
        Observer.Expect('log', 'afterInsert temp=0 real=0 isTemp=Yes;afterInsert temp=0 real=0 isTemp=Yes;post temp=0 real=0;');
        Observer.Expect('real after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure XmlPort_UseTemporary_AutoSaveDefault_Import()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Codeunit "Temp Blob";
        Ins: InStream;
        Xp: XmlPort "LT AJ Xp Temp Auto Save";
        Real: Record "LT AJ Item";
    begin
        Real.DeleteAll();
        Source(Tmp, Ins);
        Xp.SetSource(Ins);
        Xp.Import();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('real after', Format(Real.Count()));
        Observer.Expect('log', 'afterInsert temp=1 real=0;afterInsert temp=2 real=0;post temp=2 real=0;');
        Observer.Expect('real after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure XmlPort_RealTable_AutoSaveFalse_Import()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Codeunit "Temp Blob";
        Ins: InStream;
        Xp: XmlPort "LT AJ Xp Real No Save";
        Real: Record "LT AJ Item";
    begin
        Real.DeleteAll();
        Source(Tmp, Ins);
        Xp.SetSource(Ins);
        Xp.Import();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('real after', Format(Real.Count()));
        Observer.Expect('log', 'afterInsert count=0;afterInsert count=0;post count=0;');
        Observer.Expect('real after', '0');
        Observer.Verify();
    end;

    local procedure QsTextSource(var Tmp: Codeunit "Temp Blob"; var Ins: InStream)
    var
        Outs: OutStream;
        CrLf: Text[2];
    begin
        CrLf[1] := 13;
        CrLf[2] := 10;
        Tmp.CreateOutStream(Outs);
        Outs.WriteText('"S1"|"ITEM-A"' + CrLf + '"S2"|"ITEM-B"' + CrLf);
        Tmp.CreateInStream(Ins);
    end;

    [Test]
    procedure QS_VariableText_TempInteger_AutoSaveFalse()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Codeunit "Temp Blob";
        Ins: InStream;
        Xp: XmlPort "LT QS Xp Text Temp No Save";
    begin
        QsTextSource(Tmp, Ins);
        Xp.SetSource(Ins);
        Xp.Import();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('rows', Xp.Rows());
        Observer.Expect('log', 'pre count=0;init n=0 count=0;before shelf=S1 itemcode=ITEM-A n=0 count=0 temp=Yes;after n=0 count=0;init n=0 count=0;before shelf=S2 itemcode=ITEM-B n=0 count=0 temp=Yes;after n=0 count=0;post count=0;');
        Observer.Expect('rows', 'count=0 rows=');
        Observer.Verify();
    end;

    [Test]
    procedure QS_VariableText_TempInteger_AutoSaveFalse_ManualInsert()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Codeunit "Temp Blob";
        Ins: InStream;
        Xp: XmlPort "LT QS Xp Text Temp No Save";
    begin
        QsTextSource(Tmp, Ins);
        Xp.SetSource(Ins);
        Xp.SetManualInsert(true);
        Xp.Import();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('rows', Xp.Rows());
        Observer.Expect('log', 'pre count=0;init n=0 count=0;before shelf=S1 itemcode=ITEM-A n=0 count=0 temp=Yes;after n=1 count=1;init n=0 count=1;before shelf=S2 itemcode=ITEM-B n=0 count=1 temp=Yes;after n=2 count=2;post count=2;');
        Observer.Expect('rows', 'count=2 rows=1;2;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Xml_TempTable_AutoSaveFalse_Values()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Codeunit "Temp Blob";
        Ins: InStream;
        Xp: XmlPort "LT QS Xp Xml Temp Manual";
        Real: Record "LT AJ Item";
    begin
        Real.DeleteAll();
        Source(Tmp, Ins);
        Xp.SetSource(Ins);
        Xp.Import();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('rows', Xp.Rows());
        Observer.Observe('real after', Format(Real.Count()));
        Observer.Expect('log', 'before id=1 txt=one temp=0;after id=1 temp=0 real=0;before id=2 txt=two temp=0;after id=2 temp=0 real=0;');
        Observer.Expect('rows', 'count=0 rows=');
        Observer.Expect('real after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Xml_TempTable_AutoSaveFalse_ManualInsert()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Codeunit "Temp Blob";
        Ins: InStream;
        Xp: XmlPort "LT QS Xp Xml Temp Manual";
        Real: Record "LT AJ Item";
    begin
        Real.DeleteAll();
        Source(Tmp, Ins);
        Xp.SetSource(Ins);
        Xp.SetManualInsert(true);
        Xp.Import();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('rows', Xp.Rows());
        Observer.Observe('real after', Format(Real.Count()));
        Observer.Expect('log', 'before id=1 txt=one temp=0;after id=1 temp=1 real=0;before id=2 txt=two temp=1;after id=2 temp=2 real=0;');
        Observer.Expect('rows', 'count=2 rows=1:one;2:two;');
        Observer.Expect('real after', '0');
        Observer.Verify();
    end;
}
