# tcp

A 4D component that tells you which process(es) are listening on a given TCP port, from 4D code, on macOS (Intel and Apple Silicon) and Windows (x64). It returns the PID and process info without you having to know the syntax of `lsof`, `netstat` or `procs`.

It wraps [procs](https://github.com/dalance/procs) (`procs --insert port --json`) through the class `cs.tcp.tcp`, and adds listeners owned by root, other users or `SYSTEM` from `netstat`. See the [class reference](tcp/Documentation/Classes/tcp.md) and the [documentation site](https://miyako.github.io/tcp/).

Synchronous: `check()` returns the JSON output (`Null` if the query failed; see `error` on the option object); filter it with `get()`.

```4d
var $tcp : cs.tcp.tcp
$tcp:=cs.tcp.tcp.new()

var $results : Collection
$results:=$tcp.check({port: 8080})

var $matches : Collection
$matches:=$tcp.get(8080; JSON Parse($results[0]; Is collection))
```

Asynchronous: pass a callback and run in a worker (`CALL WORKER`) so the callback can be processed. The callback receives `$status.success` (`True` when the port is free), `$status.PID`, and `$status.error` if the query failed.

```4d
$tcp.check({port: 8080}; Formula(onResponse))
```

Typical use: after `WEB START SERVER` fails, find out which process holds the port.

## Build procs

The bundled binaries are [procs](https://github.com/dalance/procs) **v0.14.10**, built from the upstream tag without changes.

| binary | architectures | signature | SHA-256 |
|-|-|-|-|
| `tcp/Resources/bin/MacOS/procs` | x86_64, arm64 | Developer ID, notarized | `63fd037ec34c06e174c42d245d59055e8ba26274da719ba87f1f7e186ef0bc28` |
| `tcp/Resources/bin/Windows/procs.exe` | x64 | **unsigned** | `7f2b0bc3fc6c19d8c8b35c2c2c474ed6d36b9f1897dbf7469a054b3ce63444ef` |

The Windows executable is not Authenticode-signed; SmartScreen or antivirus software may flag or block it.

macOS:

```
git clone --branch v0.14.10 https://github.com/dalance/procs && cd procs
cargo build --release --target aarch64-apple-darwin
cargo build --release --target x86_64-apple-darwin
lipo -create -output procs target/aarch64-apple-darwin/release/procs target/x86_64-apple-darwin/release/procs
codesign --force --options runtime --timestamp --sign "Developer ID Application: ..." procs
```

Then notarize it (`xcrun notarytool submit`).

Windows:

```
git clone --branch v0.14.10 https://github.com/dalance/procs && cd procs
rustup default stable-x86_64-pc-windows-msvc --force-non-host
cargo build --release
```

The component passes `--load-config` with `tcp/Resources/procs.toml`, the output of `procs --gen-config` for the bundled version without the `Tty` column, which Windows builds of `procs` reject. Regenerate it the same way, and update the table above, when you update `procs`.

The CI tests (`.github/workflows/test.yml`, `tests/run.sh`) compile the component and check it against real listeners on macOS and Windows with the tool4d version in `package.json`.
