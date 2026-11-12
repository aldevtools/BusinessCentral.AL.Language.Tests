// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability-overview
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained objects 99010 to 99016
// Probe: from al-runner issue 7832 (a [WithEvents] DotNet variable used in code that never makes the object raise an event).
// Area: a global [WithEvents] System.Timers.Timer variable of a helper codeunit:
//   - with an Elapsed trigger and no Disposed trigger (the report's shape), with no trigger at all, and with a Disposed trigger;
//   - assigned once by its constructor, assigned a second time, read with a property (Interval, Enabled), and cleared;
//   - the helper used through a local codeunit variable whose instance ends at the end of the procedure;
//   - the same variable on a page (assigned in OnOpenPage, page opened through a TestPage), on a table (a procedure called on two
//     record variables) and on a ProcessingOnly report (assigned in OnPreReport, read in OnAfterGetRecord), each with an Elapsed trigger.
//   Each case observes the return values and the trigger counts the helpers keep in a SingleInstance codeunit.
// The constructor is called without an argument, then Interval is set: Timer(1000) (the issue's shape) and Timer(D) with a Decimal D do
//   not compile with the CI compiler (AL0196, ambiguous between Timer(System.Double) and Timer(System.TimeSpan)).
// Already pinned elsewhere, not repeated: Disposed raised by Dispose() and by SuppressDispose (AcDnAttributes.al).
// Facts (measured by the corpus CI on 27.5, 28.5 and 29.0, the same on all three):
//   - No case raises an error. The variable is null before its first assignment and not null after it; Interval and Enabled read back
//     (Enabled No: the timer is never started). Clear makes it null again.
//   - No Elapsed trigger runs in any case (the timer never starts). A Disposed trigger runs when the variable that holds an object is
//     assigned a new object (1) and when it is cleared (2); not when it is cleared while null, nor on the first assignment.
//   - Page: OnOpenPage assigns and reads the variable. Table: the global is kept per record variable (a second call on the same variable
//     sees it assigned, another variable sees it null). Report: Run completes; GetShown() on the report variable after Run returns ''.
// BC versions: 27.5, 28.5, 29.0
dotnet
{
    assembly("System")
    {
        type("System.Timers.Timer"; N4WeTimer) { }
        type("System.Timers.ElapsedEventArgs"; N4WeElapsedArgs) { }
    }
    assembly("mscorlib")
    {
        type("System.EventArgs"; N4WeEventArgs) { }
    }
}

// A page, a table and a report with a global [WithEvents] timer and an Elapsed trigger. They come before the first codeunit (the
// SingleInstance fixture-owner gate counts what follows a codeunit as used by it).
page 99014 "N4 WE Page"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(ShownField; Shown)
            {
                ApplicationArea = All;
                Caption = 'Shown';
            }
        }
    }

    var
        [WithEvents]
        Timer: DotNet N4WeTimer;
        Counter: Codeunit "N4 WE Counter";
        Shown: Text;

    trigger OnOpenPage()
    begin
        Shown := Format(IsNull(Timer));
        Timer := Timer.Timer();
        Timer.Interval := 1500;
        Shown += '|' + Format(IsNull(Timer)) + '|' + Format(Timer.Interval) + '|' + Format(Timer.Enabled);
    end;

    trigger Timer::Elapsed(sender: Variant; e: DotNet N4WeElapsedArgs)
    begin
        Counter.AddElapsed();
    end;
}

table 99015 "N4 WE Table"
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

    var
        [WithEvents]
        Timer: DotNet N4WeTimer;
        Counter: Codeunit "N4 WE Counter";

    procedure Touch(): Text
    var
        Shown: Text;
    begin
        Shown := Format(IsNull(Timer));
        Timer := Timer.Timer();
        Timer.Interval := 2500;
        exit(Shown + '|' + Format(IsNull(Timer)) + '|' + Format(Timer.Interval) + '|' + Format(Timer.Enabled));
    end;

    trigger Timer::Elapsed(sender: Variant; e: DotNet N4WeElapsedArgs)
    begin
        Counter.AddElapsed();
    end;
}

report 99016 "N4 WE Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(One; Integer)
        {
            DataItemTableView = where(Number = const(1));

            trigger OnAfterGetRecord()
            begin
                Shown += '|row:' + Format(Timer.Interval);
            end;
        }
    }

    var
        [WithEvents]
        Timer: DotNet N4WeTimer;
        Counter: Codeunit "N4 WE Counter";
        Shown: Text;

    trigger OnPreReport()
    begin
        Shown := Format(IsNull(Timer));
        Timer := Timer.Timer();
        Timer.Interval := 3500;
        Shown += '|' + Format(IsNull(Timer)) + '|' + Format(Timer.Interval) + '|' + Format(Timer.Enabled);
    end;

    procedure GetShown(): Text
    begin
        exit(Shown);
    end;

    trigger Timer::Elapsed(sender: Variant; e: DotNet N4WeElapsedArgs)
    begin
        Counter.AddElapsed();
    end;
}

codeunit 99010 "N4 WE Counter"
{
    SingleInstance = true;

    var
        Elapsed: Integer;
        Disposed: Integer;

    procedure Reset()
    begin
        Elapsed := 0;
        Disposed := 0;
    end;

    procedure AddElapsed()
    begin
        Elapsed += 1;
    end;

    procedure AddDisposed()
    begin
        Disposed += 1;
    end;

    procedure Shown(): Text
    begin
        exit('elapsed=' + Format(Elapsed) + ';disposed=' + Format(Disposed));
    end;
}

codeunit 99011 "N4 WE Elapsed Only"
{
    var
        [WithEvents]
        Timer: DotNet N4WeTimer;
        Counter: Codeunit "N4 WE Counter";

    procedure Touch(): Integer
    begin
        Timer := Timer.Timer();
        Timer.Interval := 1000;
        exit(1);
    end;

    procedure Props(): Text
    begin
        exit(Format(Timer.Interval) + '|' + Format(Timer.Enabled));
    end;

    procedure Reassign()
    begin
        Timer := Timer.Timer();
        Timer.Interval := 2000;
    end;

    procedure ClearIt()
    begin
        Clear(Timer);
    end;

    procedure IsNullNow(): Boolean
    begin
        exit(IsNull(Timer));
    end;

    trigger Timer::Elapsed(sender: Variant; e: DotNet N4WeElapsedArgs)
    begin
        Counter.AddElapsed();
    end;
}

codeunit 99012 "N4 WE No Trigger"
{
    var
        [WithEvents]
        Timer: DotNet N4WeTimer;

    procedure Touch(): Integer
    begin
        Timer := Timer.Timer();
        Timer.Interval := 1000;
        exit(1);
    end;

    procedure Props(): Text
    begin
        exit(Format(Timer.Interval) + '|' + Format(Timer.Enabled));
    end;

    procedure Reassign()
    begin
        Timer := Timer.Timer();
        Timer.Interval := 2000;
    end;

    procedure ClearIt()
    begin
        Clear(Timer);
    end;

    procedure IsNullNow(): Boolean
    begin
        exit(IsNull(Timer));
    end;
}

codeunit 99013 "N4 WE With Disposed"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        [WithEvents]
        Timer: DotNet N4WeTimer;
        Counter: Codeunit "N4 WE Counter";
        Observer: Codeunit "Probe Observer";

    trigger Timer::Disposed(sender: Variant; e: DotNet N4WeEventArgs)
    begin
        Counter.AddDisposed();
    end;

    local procedure UseElapsedOnly(): Integer
    var
        H: Codeunit "N4 WE Elapsed Only";
    begin
        exit(H.Touch());
    end;

    local procedure UseNoTrigger(): Integer
    var
        H: Codeunit "N4 WE No Trigger";
    begin
        exit(H.Touch());
    end;

    [Test]
    procedure N4_WithEvents_ElapsedOnly_Helper()
    var
        H: Codeunit "N4 WE Elapsed Only";
    begin
        Counter.Reset();
        Observer.Observe('null_before', Format(H.IsNullNow()));
        Observer.Observe('touch', Format(H.Touch()));
        Observer.Observe('null_after', Format(H.IsNullNow()));
        Observer.Observe('props', H.Props());
        H.Reassign();
        Observer.Observe('props_reassigned', H.Props());
        H.ClearIt();
        Observer.Observe('null_cleared', Format(H.IsNullNow()));
        Observer.Observe('counts', Counter.Shown());
        Observer.Observe('local_instance', Format(UseElapsedOnly()));
        Observer.Observe('counts_after_local', Counter.Shown());
        Observer.Expect('null_before', 'Yes');
        Observer.Expect('touch', '1');
        Observer.Expect('null_after', 'No');
        Observer.Expect('props', '1,000|No');
        Observer.Expect('props_reassigned', '2,000|No');
        Observer.Expect('null_cleared', 'Yes');
        Observer.Expect('counts', 'elapsed=0;disposed=0');
        Observer.Expect('local_instance', '1');
        Observer.Expect('counts_after_local', 'elapsed=0;disposed=0');
        Observer.Verify();
    end;

    [Test]
    procedure N4_WithEvents_NoTrigger_Helper()
    var
        H: Codeunit "N4 WE No Trigger";
    begin
        Counter.Reset();
        Observer.Observe('null_before', Format(H.IsNullNow()));
        Observer.Observe('touch', Format(H.Touch()));
        Observer.Observe('null_after', Format(H.IsNullNow()));
        Observer.Observe('props', H.Props());
        H.Reassign();
        Observer.Observe('props_reassigned', H.Props());
        H.ClearIt();
        Observer.Observe('null_cleared', Format(H.IsNullNow()));
        Observer.Observe('local_instance', Format(UseNoTrigger()));
        Observer.Observe('counts', Counter.Shown());
        Observer.Expect('null_before', 'Yes');
        Observer.Expect('touch', '1');
        Observer.Expect('null_after', 'No');
        Observer.Expect('props', '1,000|No');
        Observer.Expect('props_reassigned', '2,000|No');
        Observer.Expect('null_cleared', 'Yes');
        Observer.Expect('local_instance', '1');
        Observer.Expect('counts', 'elapsed=0;disposed=0');
        Observer.Verify();
    end;

    [Test]
    procedure N4_WithEvents_DisposedTrigger_AssignReassignClear()
    begin
        Counter.Reset();
        Clear(Timer);
        Observer.Observe('after_first_clear', Counter.Shown());
        Timer := Timer.Timer();
        Timer.Interval := 1000;
        Observer.Observe('after_assign', Counter.Shown());
        Observer.Observe('props', Format(Timer.Interval) + '|' + Format(Timer.Enabled));
        Timer := Timer.Timer();
        Timer.Interval := 2000;
        Observer.Observe('after_reassign', Counter.Shown());
        Clear(Timer);
        Observer.Observe('after_clear', Counter.Shown());
        Observer.Observe('null_after_clear', Format(IsNull(Timer)));
        Observer.Expect('after_first_clear', 'elapsed=0;disposed=0');
        Observer.Expect('after_assign', 'elapsed=0;disposed=0');
        Observer.Expect('props', '1,000|No');
        Observer.Expect('after_reassign', 'elapsed=0;disposed=1');
        Observer.Expect('after_clear', 'elapsed=0;disposed=2');
        Observer.Expect('null_after_clear', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure N4_WithEvents_Page_OnOpenPage()
    var
        TP: TestPage "N4 WE Page";
    begin
        Counter.Reset();
        TP.OpenView();
        Observer.Observe('shown', TP.ShownField.Value());
        TP.Close();
        Observer.Observe('counts', Counter.Shown());
        Observer.Expect('shown', 'Yes|No|1,500|No');
        Observer.Expect('counts', 'elapsed=0;disposed=0');
        Observer.Verify();
    end;

    [Test]
    procedure N4_WithEvents_Table_Procedure()
    var
        Rec: Record "N4 WE Table";
        Other: Record "N4 WE Table";
    begin
        Counter.Reset();
        Observer.Observe('first', Rec.Touch());
        Observer.Observe('second_same_var', Rec.Touch());
        Observer.Observe('other_var', Other.Touch());
        Observer.Observe('counts', Counter.Shown());
        Observer.Expect('first', 'Yes|No|2,500|No');
        Observer.Expect('second_same_var', 'No|No|2,500|No');
        Observer.Expect('other_var', 'Yes|No|2,500|No');
        Observer.Expect('counts', 'elapsed=0;disposed=0');
        Observer.Verify();
    end;

    [Test]
    procedure N4_WithEvents_Report_OnPreReport()
    var
        R: Report "N4 WE Report";
    begin
        Counter.Reset();
        R.UseRequestPage(false);
        R.Run();
        Observer.Observe('shown', R.GetShown());
        Observer.Observe('counts', Counter.Shown());
        Observer.Expect('shown', '');
        Observer.Expect('counts', 'elapsed=0;disposed=0');
        Observer.Verify();
    end;
}
