#!/usr/bin/env bash
# usage: tests/run.sh <tool4d executable>
# starts listeners, copies the TEST_ci methods into the project, runs them and checks tcp/ci_result.json
set -euo pipefail
TOOL4D=$1
cd "$(dirname "$0")/.."
PY=$(command -v python3 || command -v python)
export USER_PORT=${USER_PORT:-18190} ROOT_PORT=${ROOT_PORT:-18192} FREE_PORT=${FREE_PORT:-18191}
export LISTEN_SECONDS=${LISTEN_SECONDS:-300}

cleanup() {
	rm -f tcp/Project/Sources/Methods/TEST_ci*.4dm tcp/ci.json tcp/ci_*.json
	if [ "${RUNNER_ENVIRONMENT:-}" = github-hosted ]; then rm -f "$HOME/.procs.toml"; fi
}
trap cleanup EXIT

case "$(uname -s)" in
	Darwin)
		PROCS=tcp/Resources/bin/MacOS/procs
		PROJECT=$PWD/tcp/Project/tcp.4DProject
		#a listener owned by root: procs can't see it without the netstat fallback
		if sudo -n true 2>/dev/null; then sudo -n "$PY" tests/listen.py $ROOT_PORT tcp/ci_root.json & fi
		;;
	*)
		PROCS=tcp/Resources/bin/Windows/procs.exe
		PROJECT=$(cygpath -w "$PWD/tcp/Project/tcp.4DProject")
		;;
esac
"$PY" tests/listen.py $USER_PORT tcp/ci_user.json &

for _ in $(seq 50); do [ -f tcp/ci_user.json ] && break; sleep 0.2; done
sleep 1

"$PY" - <<'PY'
import json, os, re, subprocess, sys
listeners = []
def add(label, port, file):
    if os.path.exists(file):
        listeners.append({"label": label, "port": port, "pid": json.load(open(file))["pid"]})
add("user", int(os.environ["USER_PORT"]), "tcp/ci_user.json")
add("root", int(os.environ["ROOT_PORT"]), "tcp/ci_root.json")
if sys.platform == "win32":
    #SMB (445) is owned by System (PID 4), which procs can't open
    out = subprocess.run(["netstat", "-ano", "-p", "TCP"], capture_output=True, text=True).stdout
    m = re.search(r"^\s*TCP\s+0\.0\.0\.0:445\s+\S+\s+\S+\s+(\d+)\s*$", out, re.M)
    if m:
        listeners.append({"label": "system", "port": 445, "pid": int(m.group(1))})
if not listeners:
    sys.exit("no listener started")
json.dump({"listeners": listeners, "free": int(os.environ["FREE_PORT"])}, open("tcp/ci.json", "w"), indent=1)
print(json.dumps(listeners))
PY

if [ "${RUNNER_ENVIRONMENT:-}" = github-hosted ]; then
	#a broken user config must not affect tcp (it passes --load-config)
	echo 'broken = [' > "$HOME/.procs.toml"
	if "$PROCS" --json >/dev/null 2>&1; then echo "procs ignored ~/.procs.toml; the user config test is void"; exit 1; fi
fi

cp tests/TEST_ci*.4dm tcp/Project/Sources/Methods/
perl -e 'alarm 300; exec @ARGV' "$TOOL4D" "$PROJECT" --startup-method=TEST_ci --skip-onstartup --dataless || true

if [ ! -f tcp/ci_result.json ]; then echo "tool4d did not write ci_result.json"; exit 1; fi
cat tcp/ci_result.json
"$PY" -c 'import json,sys; sys.exit(0 if json.load(open("tcp/ci_result.json"))["success"] else 1)'
