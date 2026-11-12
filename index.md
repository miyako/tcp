---
layout: default
---

![version](https://img.shields.io/badge/version-20%2B-E23089)
![platform](https://img.shields.io/static/v1?label=platform&message=mac-intel%20|%20mac-arm%20|%20win-64&color=blue)
[![license](https://img.shields.io/github/license/miyako/tcp)](LICENSE)
![downloads](https://img.shields.io/github/downloads/miyako/tcp/total)

# Use procs from 4D

## What it is

`tcp` is a 4D component that tells you which process(es) are listening on a given TCP port, from 4D code, on macOS (Intel and Apple Silicon) and Windows (x64).

It wraps [procs](https://github.com/dalance/procs), a cross-platform `ps` replacement written in Rust, bundled in `Resources/bin`. The class `cs.tcp.tcp` runs `procs --insert port --json`, parses the result and returns the matching process entries (PID, command, …). You don't need to know the syntax of `lsof`, `netstat` or `procs`.

See the [class reference](https://github.com/miyako/tcp/blob/main/tcp/Documentation/Classes/tcp.md) for details.

### Synchronous

Without a callback, `check()` waits for `procs` and returns its raw JSON output (one text per query). Filter it with `get()`:

```4d
var $tcp : cs.tcp.tcp
$tcp:=cs.tcp.tcp.new()

var $results : Collection
$results:=$tcp.check({port: 8080})

var $matches : Collection
$matches:=$tcp.get(8080; JSON Parse($results[0]; Is collection))

If ($matches#Null)
    ALERT("port 8080 is used by process "+$matches.extract("PID").join(","))
End if 
```

### Asynchronous

With a callback, `check()` returns immediately. Run it in a worker (`CALL WORKER`) or another process that stays alive to receive the callback:

```4d
#DECLARE($params : Object)

If (Count parameters=0)
    
    //execute in a worker to process callbacks
    CALL WORKER(1; Current method name; {})
    
Else 
    
    var $tcp : cs.tcp.tcp
    $tcp:=cs.tcp.tcp.new()
    $tcp.check({port: 8080}; Formula(onResponse))
    
End if 
```

The callback receives a status object and the original option object. `$status.success` is `True` when **no** process is listening on the port; otherwise `$status.PID` lists the PIDs:

```4d
//onResponse
#DECLARE($status : Object; $option : Object)

If ($status.success)
    
    ALERT("port "+String($status.port)+" is free")
    
Else 
    
    ALERT("port is already used by process "+$status.PID.join(","))
    
End if 
```

## Tip: checking port availability

`$tcp.check({port: 443})` is the 4D equivalent of:

* macOS: `sudo lsof -nP -iTCP:443 -sTCP:LISTEN`
* Windows: `netstat -ano | findstr :443`

The main use case is a 4D web server (or any other listener) that fails to start because the port is taken. `WEB START SERVER` only tells you the port is in use; `tcp` tells you **who** is using it.

Call it **after** a failed start, not as a pre-check. A "free" result before `WEB START SERVER` can be out of date by the time 4D binds the port (check-then-bind race); a failed start is the definitive answer, and the check then explains it.

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
    Else 
        LOG EVENT(Into 4D debug message; "web server did not start; no listener found on port "+String($port))
    End if 
    
End if 
```

Limits:

* It observes; it does not reserve or block a port. Neither macOS nor Windows offers a per-application port reservation, so the reliable setup is to disable what you don't need (e.g. HTTP if you only serve HTTPS) and remove conflicting listeners.
* On macOS, a 4D process running as a normal user **may** not see sockets owned by other users, such as root daemons or the bundled Apache `httpd` (`_www`). This has not been verified; test once against a root-owned listener before you rely on an empty result.
* On Windows, ports held by HTTP.sys (IIS, WinRM, SSRS, …) show up as `System` with PID `4`. Run `netsh http show servicestate` to identify the actual service.
