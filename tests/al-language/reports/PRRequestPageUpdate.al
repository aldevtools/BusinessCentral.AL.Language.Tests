// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/requestpage/requestpage-update-method
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced. Other BC versions were not measured.
//
// RequestOptionsPage.Update(...) in request page triggers, read through a TestRequestPage handler (OnOpenPage of the request page runs first):
// - TestRequestPage.Source.Lookup() runs the field's OnLookup (with Text = the current value, '0'); an OnLookup that sets the variable and calls Update(false) and answers
//   false changes the shown value (source 5, derived 50) and ALSO runs the field's OnValidate; another field whose OnLookup sets Text := '7', Update(false), answers true runs
//   its OnValidate with 7 and the shown values follow (picked 7, derived 70); the run then sees source 5, derived 70, picked 7;
// - SetValue(21) on Source runs OnValidate, which sets Derived := 42 and calls Update(true): the handler reads derived 42 and the report runs with 21 / 42.
// Fixtures used: self-contained table 69542, codeunit 69544 (log), report 69544, codeunit 69545 (tests)
// BC versions: 27.5

table 69542 "PR Rp Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69544 "PR Rp Log"
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

report 69544 "PR Rp Report"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "PR Rp Row")
        {
            RequestFilterFields = Id;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Source; SourceValue)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Log: Codeunit "PR Rp Log";
                    begin
                        Log.Add('Source.OnValidate=' + Format(SourceValue));
                        DerivedValue := SourceValue * 2;
                        RequestOptionsPage.Update(true);
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Log: Codeunit "PR Rp Log";
                    begin
                        Log.Add('Source.OnLookup text=[' + Text + ']');
                        SourceValue := 5;
                        DerivedValue := 50;
                        RequestOptionsPage.Update(false);
                        exit(false);
                    end;
                }
                field(Derived; DerivedValue)
                {
                    ApplicationArea = All;
                }
                field(Picked; PickedValue)
                {
                    ApplicationArea = All;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Log: Codeunit "PR Rp Log";
                    begin
                        Log.Add('Picked.OnLookup');
                        Text := '7';
                        DerivedValue := 70;
                        RequestOptionsPage.Update(false);
                        exit(true);
                    end;

                    trigger OnValidate()
                    var
                        Log: Codeunit "PR Rp Log";
                    begin
                        Log.Add('Picked.OnValidate=' + Format(PickedValue));
                    end;
                }
            }
        }

        trigger OnOpenPage()
        var
            Log: Codeunit "PR Rp Log";
        begin
            Log.Add('OnOpenPage');
        end;
    }

    var
        SourceValue: Integer;
        DerivedValue: Integer;
        PickedValue: Integer;

    trigger OnPreReport()
    var
        Log: Codeunit "PR Rp Log";
    begin
        Log.Add('OnPreReport source=' + Format(SourceValue) + ' derived=' + Format(DerivedValue) + ' picked=' + Format(PickedValue));
    end;
}

codeunit 69545 "PR Rp Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure RequestPage_OnLookup_UpdateFalse_ReturnsFalseAndTrue()
    var
        Log: Codeunit "PR Rp Log";
        Rpt: Report "PR Rp Report";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Commit();
        Rpt.Run();
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'OnOpenPage;Source.OnLookup text=[0];after source lookup source=5 derived=50;Picked.OnLookup;Picked.OnValidate=7;after picked lookup picked=7 derived=70;OnPreReport source=5 derived=70 picked=7;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure LookupHandler(var RP: TestRequestPage "PR Rp Report")
    var
        Log: Codeunit "PR Rp Log";
    begin
        RP.Source.Lookup();
        Log.Add('after source lookup source=' + RP.Source.Value() + ' derived=' + RP.Derived.Value());
        RP.Picked.Lookup();
        Log.Add('after picked lookup picked=' + RP.Picked.Value() + ' derived=' + RP.Derived.Value());
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ValidateHandler')]
    procedure RequestPage_OnValidate_UpdateTrue()
    var
        Log: Codeunit "PR Rp Log";
        Rpt: Report "PR Rp Report";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Commit();
        Rpt.Run();
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'OnOpenPage;Source.OnValidate=21;after setvalue source=21 derived=42;OnPreReport source=21 derived=42 picked=0;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ValidateHandler(var RP: TestRequestPage "PR Rp Report")
    var
        Log: Codeunit "PR Rp Log";
    begin
        RP.Source.SetValue(21);
        Log.Add('after setvalue source=' + RP.Source.Value() + ' derived=' + RP.Derived.Value());
        RP.OK().Invoke();
    end;
}
