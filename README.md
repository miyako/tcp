# tcp

A 4D component that tells you which process(es) are listening on a given TCP port, from 4D code, on macOS (Intel and Apple Silicon) and Windows (x64). It returns the PID and process info without you having to know the syntax of `lsof`, `netstat` or `procs`.

It wraps [procs](https://github.com/dalance/procs) (`procs --insert port --json`) through the class `cs.tcp.tcp`. See the [class reference](tcp/Documentation/Classes/tcp.md) and the [documentation site](https://miyako.github.io/tcp/).

Synchronous: `check()` returns the raw JSON output; filter it with `get()`.

```4d
var $tcp : cs.tcp.tcp
$tcp:=cs.tcp.tcp.new()

var $results : Collection
$results:=$tcp.check({port: 8080})

var $matches : Collection
$matches:=$tcp.get(8080; JSON Parse($results[0]; Is collection))
```

Asynchronous: pass a callback and run in a worker (`CALL WORKER`) so the callback can be processed. The callback receives `$status.success` (`True` when the port is free) and `$status.PID`.

```4d
$tcp.check({port: 8080}; Formula(onResponse))
```

Typical use: after `WEB START SERVER` fails, find out which process holds the port.

## Build procs

[procs](https://github.com/dalance/procs)

```
cargo build --release --target aarch64-apple-darwin
cargo build --release --target x86_64-apple-darwin

```


```
rustup default stable-x86_64-pc-windows-msvc --force-non-host
cargo build --release
```
