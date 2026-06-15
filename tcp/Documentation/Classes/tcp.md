# tcp
### Queries TCP port usage on the current machine using the `procs` utility.

> tcp.new (controller : 4D.Class)

| Parameter | Type | | Description |
| --- | --- | --- | --- |
| controller | 4D.Class | -> | Optional custom controller class; must extend `_tcp_Controller` (default: `cs.tcp._tcp_Controller`) |

## Description

`cs.tcp.tcp` extends [`_CLI`](_CLI.md) and wraps [`procs`](https://github.com/dalance/procs), a `ps` replacement written in Rust, to inspect which processes are listening on given TCP ports. It invokes `procs --insert port --json` and parses the JSON output to filter results by port number.

If a class that does not extend `_tcp_Controller` is passed as `controller`, the constructor silently falls back to `cs.tcp._tcp_Controller`.

### Methods

#### get (port : Integer; json : Collection) → Collection

Filters a parsed `procs` JSON result collection to entries that include `port` in their `TCP` field. Returns `Null` if `json` is `Null` or no match is found.

| Parameter | Type | | Description |
| --- | --- | --- | --- |
| port | Integer | -> | TCP port number to search for |
| json | Collection | -> | Parsed JSON output from a `procs --insert port --json` invocation |
| Result | Collection | <- | Matching process entries, or `Null` |

This method is also stored as a `4D.Function` reference on the `data` context object passed to each worker, so it is available inside async response callbacks.

#### check (option : Variant; formula : 4D.Function) → Collection

Runs `procs --insert port --json` for one or more port queries.

| Parameter | Type | | Description |
| --- | --- | --- | --- |
| option | Object \| Collection | -> | A single options object or a collection of options objects (see table below) |
| formula | 4D.Function | -> | If provided, the call is asynchronous and results are delivered to this callback |
| Result | Collection | <- | Collection of raw stdout strings (one per query), or `Null` in async mode |

**option object properties:**

| Property | Type | Description |
| --- | --- | --- |
| port | Integer | TCP port to query |
| output | 4D.File | If present, stdout is directed to this file rather than returned inline |

**Sync mode** (no `formula`): each worker is started and `worker.wait()` is called before moving to the next. `controller.stdOut` is collected into `$results` and `controller.clear()` is called after each command. The method returns a Collection of raw stdout strings.

**Async mode** (with `formula`): workers are started without waiting. The `formula` is stored on the per-command `data` context as `onResponse` and invoked by the controller's response handler. The method returns `Null` immediately.

In both modes a `data` context object is attached to each worker containing:

| Property | Type | Description |
| --- | --- | --- |
| port | Integer | The queried port |
| get | 4D.Function | Reference to `This.get` for use inside callbacks |
| data | Object | The original `option` object |
| onResponse | 4D.Function | The async callback (async mode only) |

## Examples

### Synchronous — check whether a port is in use

```4d
var $tcp : cs.tcp.tcp
$tcp:=cs.tcp.tcp.new()

var $results : Collection
$results:=$tcp.check({port: 8080}; Null)

If ($results#Null) && ($results.length>0)
    var $json : Collection
    $json:=JSON Parse($results[0]; Is collection)
    var $matches : Collection
    $matches:=$tcp.get(8080; $json)
    If ($matches#Null)
        ALERT("Port 8080 is in use by PID "+String($matches[0].PID))
    End if
End if
```

### Asynchronous — check multiple ports

```4d
var $tcp : cs.tcp.tcp
$tcp:=cs.tcp.tcp.new()

var $onResponse : 4D.Function
$onResponse:=Formula(
    var $json : Collection
    $json:=JSON Parse($2.data; Is collection)
    var $matches : Collection
    $matches:=$2.get.call($2; $2.port; $json)
    If ($matches#Null)
        LOG EVENT(Into 4D debug message; "Port "+String($2.port)+" in use")
    End if
)

$tcp.check([\
    {port: 8080}; \
    {port: 8081}; \
    {port: 8082}]; \
    $onResponse)
```

## See also

- [`_CLI`](_CLI.md) — parent class providing executable resolution and shell escaping
- [`_tcp_Controller`](_tcp_Controller.md) — default controller that accumulates stdout/stderr
- [`_CLI_Controller`](_CLI_Controller.md) — base controller providing the command queue
