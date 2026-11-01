// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 93307-93314 (SingleInstance log 93314 is used only by test codeunit 93313)
// Probe (writer Y64, al-runner issue 6651): an extension declares a local procedure with the name of a local procedure of its base object.
//   Report 93308 / extension 93308 is the reporter's shape: the extension's request page declares its own local MyProc and calls it from a
//   modify() OnAfterValidate trigger and from the request page OnOpenPage. Report 93309 / extension 93309 adds an extension-level local MyProc
//   next to the request page one and a request page local Pub with the name of a public procedure of the base report. Page 93310 / page
//   extension 93310 and table 93311 / table extension 93311 are the page and table forms. The log says which body ran.
// Compile facts (AL compiler 30, BC 27-29): a request page local procedure is visible only inside the request page; from a data item or report
//   trigger of the extension the name binds to the base report's local procedure: AL0161 (must-not-compile 2623); calling a base local procedure
//   that the extension does not redeclare: AL0161 (2622 for a request page, 0041 for a report trigger); an extension-level local procedure with
//   the name of a public base procedure: the call is ambiguous, AL0196 (2624; the page form is 2239).
// BC versions: 27-29

table 93307 "LT Y64 LP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 93314 "LT Y64 LP Log"
{
    SingleInstance = true;

    var
        Entries: Text;

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
}

report 93308 "LT Y64 LP Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT Y64 LP Row")
        {
            trigger OnPreDataItem()
            begin
                MyProc('base predataitem');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(MyField; MyOption)
                {
                    ApplicationArea = All;
                    Caption = 'My field';
                    trigger OnValidate()
                    begin
                        MyProc('base validate');
                    end;
                }
            }
        }

        trigger OnOpenPage()
        begin
            MyProc('base rp open');
        end;
    }

    var
        MyOption: Boolean;

    local procedure MyProc(Where: Text)
    var
        Log: Codeunit "LT Y64 LP Log";
    begin
        Log.Add('base MyProc<-' + Where);
    end;
}

reportextension 93308 "LT Y64 LP Report Ext" extends "LT Y64 LP Report"
{
    requestpage
    {
        layout
        {
            modify(MyField)
            {
                trigger OnAfterValidate()
                begin
                    MyProc('ext aftervalidate');
                end;
            }
        }

        trigger OnOpenPage()
        begin
            MyProc('ext rp open');
        end;

        local procedure MyProc(Where: Text)
        var
            Log: Codeunit "LT Y64 LP Log";
        begin
            Log.Add('ext rp MyProc<-' + Where);
        end;
    }
}

report 93309 "LT Y64 LP Report 2"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT Y64 LP Row")
        {
            trigger OnPreDataItem()
            begin
                MyProc('base predataitem');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(MyField; MyOption)
                {
                    ApplicationArea = All;
                    Caption = 'My field';
                    trigger OnValidate()
                    begin
                        MyProc('base validate');
                        Pub('base validate');
                    end;
                }
            }
        }

        trigger OnOpenPage()
        begin
            MyProc('base rp open');
        end;
    }

    trigger OnPreReport()
    begin
        MyProc('base prereport');
    end;

    var
        MyOption: Boolean;

    local procedure MyProc(Where: Text)
    var
        Log: Codeunit "LT Y64 LP Log";
    begin
        Log.Add('base MyProc<-' + Where);
    end;

    procedure Pub(Where: Text)
    var
        Log: Codeunit "LT Y64 LP Log";
    begin
        Log.Add('base Pub<-' + Where);
    end;
}

reportextension 93309 "LT Y64 LP Report 2 Ext" extends "LT Y64 LP Report 2"
{
    dataset
    {
        modify(Row)
        {
            trigger OnBeforePreDataItem()
            begin
                MyProc('ext beforepredataitem');
            end;
        }
    }

    requestpage
    {
        layout
        {
            modify(MyField)
            {
                trigger OnAfterValidate()
                begin
                    MyProc('ext aftervalidate');
                    Pub('ext aftervalidate');
                end;
            }
        }

        trigger OnOpenPage()
        begin
            MyProc('ext rp open');
            Pub('ext rp open');
        end;

        local procedure MyProc(Where: Text)
        var
            Log: Codeunit "LT Y64 LP Log";
        begin
            Log.Add('ext rp MyProc<-' + Where);
        end;

        local procedure Pub(Where: Text)
        var
            Log: Codeunit "LT Y64 LP Log";
        begin
            Log.Add('ext rp Pub<-' + Where);
        end;
    }

    trigger OnPreReport()
    begin
        MyProc('ext prereport');
    end;

    local procedure MyProc(Where: Text)
    var
        Log: Codeunit "LT Y64 LP Log";
    begin
        Log.Add('ext MyProc<-' + Where);
    end;
}

page 93310 "LT Y64 LP Card"
{
    PageType = Card;
    SourceTable = "LT Y64 LP Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Name; Rec.Name)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    MyProc('base validate');
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(BaseAction)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    MyProc('base action');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        MyProc('base open');
    end;

    local procedure MyProc(Where: Text)
    var
        Log: Codeunit "LT Y64 LP Log";
    begin
        Log.Add('base MyProc<-' + Where);
    end;
}

pageextension 93310 "LT Y64 LP Card Ext" extends "LT Y64 LP Card"
{
    layout
    {
        modify(Name)
        {
            trigger OnAfterValidate()
            begin
                MyProc('ext aftervalidate');
            end;
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(ExtAction)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    MyProc('ext action');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        MyProc('ext open');
    end;

    local procedure MyProc(Where: Text)
    var
        Log: Codeunit "LT Y64 LP Log";
    begin
        Log.Add('pageext MyProc<-' + Where);
    end;
}

table 93311 "LT Y64 LP Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30])
        {
            trigger OnValidate()
            begin
                TLoc('base validate');
            end;
        }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    begin
        TLoc('base insert');
    end;

    local procedure TLoc(Where: Text)
    var
        Log: Codeunit "LT Y64 LP Log";
    begin
        Log.Add('base TLoc<-' + Where);
    end;
}

tableextension 93311 "LT Y64 LP Table Ext" extends "LT Y64 LP Table"
{
    fields
    {
        modify(Name)
        {
            trigger OnAfterValidate()
            begin
                TLoc('ext aftervalidate');
            end;
        }
    }

    trigger OnAfterInsert()
    begin
        TLoc('ext afterinsert');
    end;

    local procedure TLoc(Where: Text)
    var
        Log: Codeunit "LT Y64 LP Log";
    begin
        Log.Add('tableext TLoc<-' + Where);
    end;
}

codeunit 93313 "LT Y64 LP Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y64 LP Log";

    local procedure Seed()
    var
        Row: Record "LT Y64 LP Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Log.Take();
    end;

    [RequestPageHandler]
    procedure SetFieldHandler(var RequestPage: TestRequestPage "LT Y64 LP Report")
    begin
        RequestPage.MyField.SetValue(true);
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure SetFieldHandler2(var RequestPage: TestRequestPage "LT Y64 LP Report 2")
    begin
        RequestPage.MyField.SetValue(true);
        RequestPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SetFieldHandler')]
    procedure Y64_ReportExt_RequestPageLocal_ReporterShape()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.RunModal(Report::"LT Y64 LP Report", true);
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y64_ReportExt_RequestPageLocal_NoRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT Y64 LP Report";
    begin
        Seed();
        Rep.UseRequestPage(false);
        Rep.RunModal();
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('SetFieldHandler2')]
    procedure Y64_ReportExt_RequestPageAndExtensionLocals()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT Y64 LP Report 2";
    begin
        Seed();
        Report.RunModal(Report::"LT Y64 LP Report 2", true);
        Observer.Observe('log', Log.Take());
        Rep.Pub('test');
        Observer.Observe('public call from a report variable', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y64_PageExt_LocalSameName()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT Y64 LP Card";
    begin
        Seed();
        Card.OpenEdit();
        Observer.Observe('open', Log.Take());
        Card.Name.SetValue('two');
        Observer.Observe('validate', Log.Take());
        Card.BaseAction.Invoke();
        Observer.Observe('base action', Log.Take());
        Card.ExtAction.Invoke();
        Observer.Observe('ext action', Log.Take());
        Card.Close();
        Log.Take();
        Observer.Finish();
    end;

    [Test]
    procedure Y64_TableExt_LocalSameName()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT Y64 LP Table";
    begin
        T.DeleteAll();
        Log.Take();
        T.Id := 1;
        T.Insert(true);
        Observer.Observe('insert', Log.Take());
        T.Validate(Name, 'x');
        Observer.Observe('validate', Log.Take());
        Observer.Finish();
    end;
}
