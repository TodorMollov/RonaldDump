CRITICAL LOOP PREVENTION RULES (MANDATORY)

When running tests:

1. Maximum retry attempts: 2
   - Initial run
   - One repair attempt
   - STOP after that

2. If tests fail after the second run:
   - DO NOT attempt further fixes
   - DO NOT rerun tests again

3. Instead, output a structured FAILURE REPORT containing:
   - Failing test name(s)
   - File path(s) and line number(s)
   - First error message only
   - Root cause classification (choose one):
     a) Code defect
     b) Test defect
     c) Environment / tooling issue
     d) Ambiguous / insufficient information

4. If the failure is NOT a clear code defect:
   - Do not modify code
   - Do not retry tests
   - Explain exactly what human action or decision is required

5. Never enter an infinite loop.
   - If uncertainty exists, stop and report.

Acknowledgement required before proceeding.
