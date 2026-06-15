# _tcp_Controller
### Extends `_CLI_Controller` to accumulate stdout and stderr output from `procs`.

> _tcp_Controller.new (CLI : cs.tcp._CLI)

| Parameter | Type | | Description |
| --- | --- | --- | --- |
| CLI | cs.tcp._CLI | -> | The owning `_CLI` instance |

## Description

`_tcp_Controller` is the default controller used by [`tcp`](tcp.md). It inherits all command-queue and worker-management behaviour from [`_CLI_Controller`](_CLI_Controller.md) and overrides the data event handlers to accumulate the full stdout and stderr output of each `procs` invocation into string buffers. These buffers are available to the caller after `worker.wait()` returns, and can be reset between commands with `clear()`.

### Properties

In addition to properties inherited from `_CLI_Controller`:

| Property | Type | Description |
| --- | --- | --- |
| stdOut | Text | Accumulated stdout text from the last command |
| stdErr | Text | Accumulated stderr text from the last command |

### Methods

#### clear () → cs.tcp._tcp_Controller

Resets `stdOut` and `stdErr` to empty strings. Called automatically by the constructor and should be called between successive synchronous `check` calls to prevent output from one command bleeding into the next.

| Result | Type | Description |
| --- | --- | --- |
| Result | cs.tcp._tcp_Controller | `This` — enables chaining |

### Overridden event callbacks

#### onData ($worker : 4D.SystemWorker; $params : Object)

Appends `$params.data` to `stdOut`.

#### onDataError ($worker : 4D.SystemWorker; $params : Object)

Appends `$params.data` to `stdErr`.

#### onResponse ($worker : 4D.SystemWorker; $params : Object)

No-op; may be overridden in a subclass.

#### onError ($worker : 4D.SystemWorker; $params : Object)

No-op; may be overridden in a subclass.

#### onTerminate ($worker : 4D.SystemWorker; $params : Object)

No-op; may be overridden in a subclass.

## See also

- [`_CLI_Controller`](_CLI_Controller.md) — parent class
- [`tcp`](tcp.md) — attaches this controller by default
