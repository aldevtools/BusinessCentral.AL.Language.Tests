// @expect AL1039 | The version number '15.0.0.0' for the property 'runtime' does not match the expected format: X.Y where X and Y represent positive integers.
// @appjson {"runtime": "15.0.0.0"}
// app.json "runtime": "15.0.0.0" is rejected (al-runner issue 5506, writer Y10). Recorded with AL 30.0.43.45776-beta.
codeunit 50000 "MNC Codeunit"
{
}
