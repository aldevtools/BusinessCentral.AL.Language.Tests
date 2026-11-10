// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-extension-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// local object: the page's controls and the page extension's modify() triggers are under test (page 62380, page extension 62381, log 62382).
// Area: OnBeforeValidate and OnAfterValidate in a pageextension modify() of a control bound to a page VARIABLE, on a page with no
//   source table that runs modally and is driven from a ModalPageHandler (al-runner issue 7372: Microsoft's StandardDialog page
//   "Report Layout Lookup", control AddWord, an extension that sets a variable in OnAfterValidate and a control whose Enabled
//   reads that variable).
//   Cells: a Boolean control with its own OnValidate and one without; the order of the three triggers; the value of the variable
//   in each trigger; Enabled and Editable of extension controls that read a variable the extension's trigger set; the value
//   another control shows after the trigger changed its variable; OK and Cancel.
// Already pinned elsewhere: the order extension OnBeforeValidate, page OnValidate, extension OnAfterValidate on a variable-bound
//   Text control of a Card page with a temporary source table opened with OpenEdit (pages/extensions/W2ExtModify.al,
//   Validate_VariableControl and Validate_VariableControlWithoutOwnTrigger).
// BC versions: 27-29
codeunit 62382 "PAG ModVar Log"
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

page 62380 "PAG ModVar Dialog"
{
    PageType = StandardDialog;
    UsageCategory = None;
    Caption = 'ModVar Dialog';

    layout
    {
        area(Content)
        {
            field(AddWord; AddWordValue)
            {
                ApplicationArea = All;
                Caption = 'Add Word';

                trigger OnValidate()
                begin
                    L.Add('page.AddWord(' + Format(AddWordValue) + ')');
                end;
            }
            field(AddRdlc; AddRdlcValue)
            {
                ApplicationArea = All;
                Caption = 'Add Rdlc';
            }
            field(Shown; ShownText)
            {
                ApplicationArea = All;
                Caption = 'Shown';
                Editable = false;
            }
        }
    }

    var
        L: Codeunit "PAG ModVar Log";
        AddWordValue: Boolean;
        AddRdlcValue: Boolean;

    protected var
        ShownText: Text;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        L.Add('page.queryclose(' + Format(CloseAction) + ') word=' + Format(AddWordValue) + ' rdlc=' + Format(AddRdlcValue));
        exit(true);
    end;
}

pageextension 62381 "PAG ModVar Dialog Ext" extends "PAG ModVar Dialog"
{
    layout
    {
        modify(AddWord)
        {
            trigger OnBeforeValidate()
            begin
                ExtLog.Add('ext.before.AddWord enabled=' + Format(MyEnabled));
            end;

            trigger OnAfterValidate()
            begin
                MyEnabled := true;
                ShownText := 'set by AddWord';
                ExtLog.Add('ext.after.AddWord enabled=' + Format(MyEnabled));
            end;
        }
        modify(AddRdlc)
        {
            trigger OnBeforeValidate()
            begin
                ExtLog.Add('ext.before.AddRdlc');
            end;

            trigger OnAfterValidate()
            begin
                MyEditable := true;
                ShownText := 'set by AddRdlc';
                ExtLog.Add('ext.after.AddRdlc');
            end;
        }
        addafter(AddWord)
        {
            field(MyFlag; MyFlag)
            {
                ApplicationArea = All;
                Caption = 'My Flag';
                Enabled = MyEnabled;

                trigger OnValidate()
                begin
                    ExtLog.Add('ext.MyFlag(' + Format(MyFlag) + ')');
                end;
            }
            field(MyNote; MyNote)
            {
                ApplicationArea = All;
                Caption = 'My Note';
                Editable = MyEditable;
            }
        }
    }

    var
        ExtLog: Codeunit "PAG ModVar Log";
        MyFlag: Boolean;
        MyNote: Text;
        MyEnabled: Boolean;
        MyEditable: Boolean;
}

codeunit 62383 "PAG ModVar Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        L: Codeunit "PAG ModVar Log";
        Mode: Integer;

    [TryFunction]
    local procedure TrySetFlag(var Dialog: TestPage "PAG ModVar Dialog")
    begin
        Dialog.MyFlag.SetValue(true);
    end;

    [TryFunction]
    local procedure TrySetNote(var Dialog: TestPage "PAG ModVar Dialog")
    begin
        Dialog.MyNote.SetValue('note');
    end;

    local procedure State(var Dialog: TestPage "PAG ModVar Dialog"): Text
    begin
        exit('flag enabled=' + Format(Dialog.MyFlag.Enabled()) + ' note editable=' + Format(Dialog.MyNote.Editable()) + ' shown=' + Dialog.Shown.Value);
    end;

    // The reporter's shape: the handler sets the Boolean control and presses OK.
    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure ModifyVariableControl_Dialog_SetValueThenOk()
    var
        Result: Action;
    begin
        Mode := 1;
        L.Take();
        Result := Page.RunModal(Page::"PAG ModVar Dialog");
        Observer.Observe('close log', L.Take());
        Observer.Observe('result', Format(Result));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure ModifyVariableControl_Dialog_ControlWithoutOwnTrigger()
    var
        Result: Action;
    begin
        Mode := 2;
        L.Take();
        Result := Page.RunModal(Page::"PAG ModVar Dialog");
        Observer.Observe('close log', L.Take());
        Observer.Observe('result', Format(Result));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure ModifyVariableControl_Dialog_ExtensionControlsBeforeAndAfter()
    var
        Result: Action;
    begin
        Mode := 3;
        L.Take();
        Result := Page.RunModal(Page::"PAG ModVar Dialog");
        Observer.Observe('close log', L.Take());
        Observer.Observe('result', Format(Result));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure ModifyVariableControl_Dialog_SetValueThenCancel()
    var
        Result: Action;
    begin
        Mode := 4;
        L.Take();
        Result := Page.RunModal(Page::"PAG ModVar Dialog");
        Observer.Observe('close log', L.Take());
        Observer.Observe('result', Format(Result));
        Observer.Finish();
    end;

    // The same page opened as a TestPage, not modally.
    [Test]
    procedure ModifyVariableControl_Dialog_OpenEdit()
    var
        Dialog: TestPage "PAG ModVar Dialog";
    begin
        L.Take();
        Dialog.OpenEdit();
        Observer.Observe('state before', State(Dialog));
        Dialog.AddWord.SetValue(true);
        Observer.Observe('set AddWord', L.Take());
        Observer.Observe('state after AddWord', State(Dialog));
        Dialog.AddRdlc.SetValue(true);
        Observer.Observe('set AddRdlc', L.Take());
        Observer.Observe('state after AddRdlc', State(Dialog));
        Dialog.Close();
        Observer.Observe('close log', L.Take());
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure DialogHandler(var Dialog: TestPage "PAG ModVar Dialog")
    begin
        case Mode of
            1:
                begin
                    Dialog.AddWord.SetValue(true);
                    Observer.Observe('set true', L.Take());
                    Dialog.AddWord.SetValue(false);
                    Observer.Observe('set false', L.Take());
                    Dialog.AddWord.SetValue(false);
                    Observer.Observe('set false again', L.Take());
                    Dialog.OK().Invoke();
                end;
            2:
                begin
                    Dialog.AddRdlc.SetValue(true);
                    Observer.Observe('set AddRdlc', L.Take());
                    Observer.Observe('state', State(Dialog));
                    Dialog.OK().Invoke();
                end;
            3:
                begin
                    Observer.Observe('state before', State(Dialog));
                    Observer.Observe('set MyFlag before ok', Format(TrySetFlag(Dialog)));
                    Observer.ObserveError('set MyFlag before');
                    Observer.Observe('set MyNote before ok', Format(TrySetNote(Dialog)));
                    Observer.ObserveError('set MyNote before');
                    L.Take();
                    Dialog.AddWord.SetValue(true);
                    Observer.Observe('set AddWord', L.Take());
                    Observer.Observe('state after AddWord', State(Dialog));
                    Observer.Observe('set MyFlag after ok', Format(TrySetFlag(Dialog)));
                    Observer.ObserveError('set MyFlag after');
                    Observer.Observe('set MyFlag log', L.Take());
                    Dialog.AddRdlc.SetValue(true);
                    Observer.Observe('state after AddRdlc', State(Dialog));
                    Observer.Observe('set MyNote after ok', Format(TrySetNote(Dialog)));
                    Observer.ObserveError('set MyNote after');
                    L.Take();
                    Dialog.OK().Invoke();
                end;
            4:
                begin
                    Dialog.AddWord.SetValue(true);
                    Observer.Observe('set true', L.Take());
                    Dialog.Cancel().Invoke();
                end;
        end;
    end;
}
