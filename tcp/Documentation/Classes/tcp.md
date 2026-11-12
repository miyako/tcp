# tcp
### Queries TCP port usage on the current machine using the `procs` utility.

> tcp.new (controller : 4D.Class)

| Parameter | Type | | Description |
| --- | --- | --- | --- |
| controller | 4D.Class | -> | Optional custom controller class (default: `cs.tcp._tcp_Controller`); see note below |

## Description

`cs.tcp.tcp` extends [`_CLI`](_CLI.md) and wraps [`procs`](https://github.com/dalance/procs), a `ps` replacement written in Rust, to inspect which processes are listening on given TCP ports. It invokes `procs --insert port --json` and parses the JSON output to filter results by port number.

The command does not filter by port: each query lists all processes with their TCP ports, and the filtering is done in 4D by `get()`.

`controller` must be `cs._tcp_Controller` or a subclass of it; any other class (or none) falls back to `cs.tcp._tcp_Controller`. The constructor always sets the controller's `onResponse` to the internal response handler.

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
| output | 4D.File | If present, the raw `procs` JSON is written to this file (sync and async), and the corresponding entry in the sync result is `Null` instead of the stdout text |

**Sync mode** (no `formula`): each worker is started and `worker.wait()` is called before moving to the next. `controller.stdOut` is collected into `$results` and `controller.clear()` is called after each command. The method returns a Collection of raw stdout strings.

**Async mode** (with `formula`): workers are started without waiting. The `formula` is stored on the per-command `data` context as `onResponse` and invoked by the controller's response handler (`_onResponse`), which then calls `controller.clear()` so `stdOut` does not grow across queries. The method returns `Null` immediately. The calling process must stay alive to process callbacks, e.g. a worker started with `CALL WORKER`.

`formula` is called with two parameters:

| Parameter | Type | Description |
| --- | --- | --- |
| $1 | Object | Status object (see below) |
| $2 | Object | The original `option` object |

**status object properties:**

| Property | Type | Description |
| --- | --- | --- |
| success | Boolean | `True` if **no** process is listening on `port` (the port is free) |
| PID | Collection | PIDs of the processes listening on `port`; empty if `success` is `True` |
| port | Integer | The queried port |

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

Run in a worker so that the callbacks are processed:

```4d
#DECLARE($params : Object)

If (Count parameters=0)
    
    CALL WORKER(1; Current method name; {})
    
Else 
    
    var $tcp : cs.tcp.tcp
    $tcp:=cs.tcp.tcp.new()
    
    $tcp.check([\
        {port: 8080}; \
        {port: 8081}; \
        {port: 8082}]; \
        Formula(onResponse))
    
End if 
```

The callback is called once per port:

```4d
//onResponse
#DECLARE($status : Object; $option : Object)

If (Not($status.success))
    LOG EVENT(Into 4D debug message; "Port "+String($status.port)+" in use by PID "+$status.PID.join(","))
End if 
```

## Tip: checking port availability

`$tcp.check({port: 443})` is the 4D equivalent of `sudo lsof -nP -iTCP:443 -sTCP:LISTEN` on macOS or `netstat -ano | findstr :443` on Windows.

The main use case is a 4D web server (or any other listener) that fails to start because the port is taken. `WEB START SERVER` only tells you the port is in use; `check()` tells you **who** is using it.

Call it **after** a failed start, not as a pre-check: a "free" result can be out of date by the time 4D binds the port (check-then-bind race).

```4d
WEB START SERVER

If (Not(WEB Is server running))
    
    var $port : Integer
    WEB GET OPTION(Web HTTPS port ID; $port)
    
    var $tcp : cs.tcp.tcp
    $tcp:=cs.tcp.tcp.new()
    
    var $results : Collection
    $results:=$tcp.check({port: $port})
    
    var $owners : Collection
    $owners:=$tcp.get($port; JSON Parse($results[0]; Is collection))
    
    If ($owners#Null)
        LOG EVENT(Into 4D debug message; "port "+String($port)+" is held by: "+JSON Stringify($owners))
    End if 
    
End if 
```

> [!IMPORTANT]
> * It observes; it does not reserve or block a port.
> * On macOS, a 4D process running as a normal user **may** not see sockets owned by other users, such as root daemons or the bundled Apache `httpd` (`_www`). This has not been verified; test once against a root-owned listener before you rely on an empty result.
> * On Windows, ports held by HTTP.sys (IIS, WinRM, SSRS, …) show up as `System` with PID `4`. Run `netsh http show servicestate` to identify the actual service.

## See also

- [`_CLI`](_CLI.md) — parent class providing executable resolution and shell escaping
- [`_tcp_Controller`](_tcp_Controller.md) — default controller that accumulates stdout/stderr
- [`_CLI_Controller`](_CLI_Controller.md) — base controller providing the command queue
