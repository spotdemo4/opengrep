# Changelog

## [1.0.0](https://github.com/opengrep/opengrep/releases/tag/v1.0.0) - 18-03-2025

### Highlights

- Windows support is now in beta, without any restrictions and with full parallelism enabled.
- Self-contained binaries for x86 Linux, arm64 Mac and x86 Windows.
- SARIF output has been re-enabled.
- Fingerprint and metavars fields are exposed again.

### Improvements

- Transitioned to OCaml 5.3.0, making use of the new multicore features.
- Timeouts and memory limits have been re-implemented and now they also work on Windows.
- Reduced memory footprint thanks to several optimisations.

### Contributors

@dimitris-m @mbacarella @madelinelawren @pritchyspritch @nir-valtman @maciejpirog @jesse-merhi @hansott @Kirill89 @HenriqueOCabral @willem-delbare

