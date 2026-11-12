# usage: listen.py <port> <pidfile> - listen on 0.0.0.0:<port>, write own pid, sleep
import json, os, socket, sys, time
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("0.0.0.0", int(sys.argv[1])))
s.listen(1)
with open(sys.argv[2], "w") as f:
    json.dump({"pid": os.getpid()}, f)
time.sleep(int(os.environ.get("LISTEN_SECONDS", "600")))
