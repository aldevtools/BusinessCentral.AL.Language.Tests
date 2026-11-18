// Shared fixture: tells two service-tier builds of one BC major apart at run time, for a fact that changed inside a major.
// Microsoft republished BC 27.5 and 28.5 on .NET 10 in November 2026. Corpus CI of 2026-11-17 resolved the new artifacts: Base Application
// "Application System Constants".PlatformFileVersion() gave 27.0.58331.0 and 28.0.58336.0. The builds before ran on .NET 8 and gave
// 27.0.54968.56214 and 28.0.54946.56347. BC 29.0 runs on .NET 10. A preprocessor symbol (BC28PLUS, BC29PLUS) is per major, so it cannot
// tell the two builds of 27.5 or 28.5 apart. A test that asserts a fact that changed with the new build holds both values:
//   if PlatformBuild.IsNet10Build() then Observer.Expect(Key, NewValue) else Observer.Expect(Key, OldValue);
codeunit 50997 "ALT Platform Build"
{
    // True on a service tier of BC 29 or later, and on a BC 27 or 28 build whose platform file version is at least the first measured
    // .NET 10 build of that major (27.0.58331, 28.0.58336).
    procedure IsNet10Build(): Boolean
    var
        AppConstants: Codeunit "Application System Constants";
        Parts: List of [Text];
        Major: Integer;
        Build: Integer;
    begin
        Parts := AppConstants.PlatformFileVersion().Split('.');
        Evaluate(Major, Parts.Get(1));
        Evaluate(Build, Parts.Get(3));
        case Major of
            27:
                exit(Build >= 58331);
            28:
                exit(Build >= 58336);
        end;
        exit(Major >= 29);
    end;
}
