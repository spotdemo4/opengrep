<br />
<p align="center">
  <a href="https://github.com/opengrep">
    <picture>
      <source media="(prefers-color-scheme: light)" srcset="images/opengrep-github-banner.svg">
      <source media="(prefers-color-scheme: dark)" srcset="images/opengrep-github-banner.svg">
      <img src="https://raw.githubusercontent.com/opengrep/opengrep/main/images/opengrep-github-banner.svg" width="100%" alt="Opengrep logo"/>
    </picture>
  </a>
</p>

### Welcome to Opengrep, a fork of Semgrep, under the LGPL 2.1 license

Opengrep is a fork of Semgrep, created by Semgrep Inc. Opengrep is not affiliated with or endorsed by Semgrep Inc.

Open-source license changes by private vendors are no small matter, often leading to disruption and uncertainty for contributors and users of those projects. In such cases, the future of the community hangs in doubt as community members must work to continue and protect an open future. As Semgrep clamps down on its open source projects, we unite behind Opengrep to ensure that discovering security issues remains accessible to all. 

Opengrep stands to empower every developer with open and transparent static code analysis. Let's make secure software development a shared standard.

To learn more, read the manifesto at [opengrep.dev](https://opengrep.dev/). Opengrep is initiated by a collective of AppSec organizations, including: Aikido.dev, Arnica, Amplify, Endor, Jit, Kodem, Mobb, and Orca. To join as a sponsor, open an [issue](https://github.com/opengrep/opengrep/issues). 

Opengrep is open to any individual or organization to leverage and contribute, [join the open roadmap sessions](https://lu.ma/opengrep).

# Opengrep: Fast and Powerful Code Pattern Search

Opengrep is an ultra-fast static analysis tool for searching code patterns with the power of semantic grep. Analyze large code bases at the speed of thought with intuitive pattern matching and customizable rules. Find and fix security vulnerabilities, fast – ship more secure code.

Opengrep supports 30+ languages, including:

Apex · Bash · C · C++ · C# · Clojure · Dart · Dockerfile · Elixir · HTML · Go · Java · JavaScript · JSX · JSON · Julia · Jsonnet · Kotlin · Lisp · Lua · OCaml · PHP · Python · R · Ruby · Rust · Scala · Scheme · Solidity · Swift · Terraform · TypeScript · TSX · YAML · XML · Generic (ERB, Jinja, etc.)

## Installation

Get started in seconds with our pre-built packages. Requires Python 3.9+.

```bash
# For macOS (Apple Silicon)
pip install opengrep --find-links https://github.com/opengrep/opengrep/releases/download/v1.0.0-alpha.1/opengrep-1.0.0a1-cp39.cp310.cp311.py39.py310.py311-none-macosx_11_0_arm64.whl
```

```bash
# For Linux (x86_64)
pip install opengrep --find-links https://github.com/opengrep/opengrep/releases/download/v1.0.0-alpha.1/opengrep-1.0.0a1-cp39.cp310.cp311.py39.py310.py311-none-musllinux_1_0_x86_64.manylinux2014_x86_64.whl
```
 
## Getting started

Create a file with a rule as follows: 

```bash
───────┬──────────────────────────────────────────────────────────────────
       │ File: rules/demo-rust-unwrap.yaml
───────┼──────────────────────────────────────────────────────────────────
   1   │ rules:
   2   │ - id: unwrapped-result
   3   │   pattern: $VAR.unwrap()
   4   │   message: "Unwrap detected - potential panic risk"
   5   │   languages: [rust]
   6   │   severity: WARNING
───────┴──────────────────────────────────────────────────────────────────
```

and a file to check: 

```rust
───────┬──────────────────────────────────────────────────────────────────
       │ File: code/rust/main.rs
───────┼──────────────────────────────────────────────────────────────────
   1   │ fn divide(a: i32, b: i32) -> Result<i32, String> {
   2   │     if b == 0 {
   3   │         return Err("Division by zero".to_string());
   4   │     }
   5   │     Ok(a / b)
   6   │ }
   7   │
   8   │ fn main() {
   9   │     let result = divide(10, 0).unwrap(); // Risky unwrap!
  10   │     println!("Result: {}", result);
  11   │ }
───────┴──────────────────────────────────────────────────────────────────
```

You should now have: 

``` shell
.
├── code
│   └── rust
│       └── main.rs
└── rules
    └── demo-rust-unwrap.yaml
```

Now run: 

```bash
❯ opengrep scan -f rules code/rust

┌──────────────┐
│ Opengrep CLI │
└──────────────┘


Scanning 1 file (only git-tracked) with 1 Code rule:

  CODE RULES
  Scanning 1 file.

  PROGRESS

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100% 0:00:00


┌────────────────┐
│ 1 Code Finding │
└────────────────┘

    code/rust/main.rs
    ❯❯ rules.unwrapped-result
          Unwrap detected - potential panic risk

            9┆ let result = divide(10, 0).unwrap(); // Risky unwrap!



┌──────────────┐
│ Scan Summary │
└──────────────┘

Ran 1 rule on 1 file: 1 finding.
```

To obtain SARIF output: 

```bash
❯ opengrep scan --sarif-output=sarif.json -f rules code
  ...
❯ cat sarif.json | jq
{
  "version": "2.1.0",
  "runs": [
    {
      "invocations": [
        {
          "executionSuccessful": true,
          "toolExecutionNotifications": []
        }
      ],
      "results": [
        {
          "fingerprints": {
            "matchBasedId/v1": "a0ff5ed82149206a74ee7146b075c8cb9e79c4baf86ff4f8f1c21abea6ced504e3d33bb15a7e7dfa979230256603a379edee524cf6a5fd000bc0ab29043721d8_0"
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "code/rust/main.rs",
                  "uriBaseId": "%SRCROOT%"
                },
                "region": {
                  "endColumn": 40,
                  "endLine": 9,
                  "snippet": {
                    "text": "    let result = divide(10, 0).unwrap(); // Risky unwrap!"
                  },
                  "startColumn": 18,
                  "startLine": 9
                }
              }
            }
          ],
          "message": {
            "text": "Unwrap detected - potential panic risk"
          },
          "properties": {},
          "ruleId": "rules.unwrapped-result"
        }
      ],
      "tool": {
        "driver": {
          "name": "Opengrep OSS",
          "rules": [
            {
              "defaultConfiguration": {
                "level": "warning"
              },
              "fullDescription": {
                "text": "Unwrap detected - potential panic risk"
              },
              "help": {
                "markdown": "Unwrap detected - potential panic risk",
                "text": "Unwrap detected - potential panic risk"
              },
              "id": "rules.unwrapped-result",
              "name": "rules.unwrapped-result",
              "properties": {
                "precision": "very-high",
                "tags": []
              },
              "shortDescription": {
                "text": "Opengrep Finding: rules.unwrapped-result"
              }
            }
          ],
          "semanticVersion": "1.100.0"
        }
      }
    }
  ],
  "$schema": "https://docs.oasis-open.org/sarif/sarif/v2.1.0/os/schemas/sarif-schema-2.1.0.json"
}
```

## More

- [Contributing](CONTRIBUTING.md)
- [Build instructions for developers](INSTALL.md)
- [License (LGPL-2.1)](LICENSE)
