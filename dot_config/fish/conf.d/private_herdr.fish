function __herdr_repo_session
    set -l repo_root (command git rev-parse --show-toplevel 2>/dev/null)
    or return 1

    path basename "$repo_root"
end

function __hnew_ensure_server --argument-names session
    command herdr --session "$session" workspace list >/dev/null 2>&1
    and return 0

    command herdr --session "$session" server >/dev/null 2>&1 &
    set -l server_pid $last_pid
    disown $server_pid

    for _attempt in (seq 100)
        command herdr --session "$session" workspace list >/dev/null 2>&1
        and return 0
        sleep 0.05
    end

    echo "hnew: Herdr session '$session' did not start" >&2
    return 1
end

function __hnew_codex_thread --argument-names workspace_name workspace_cwd
    command node -e '
const { spawn } = require("node:child_process");
const readline = require("node:readline");

const workspaceName = process.argv[1];
const workspaceCwd = process.argv[2];
const runtimeWorkspaceRoots = [...new Set(process.argv.slice(3))];
const server = spawn("codex", ["app-server", "--stdio"], {
  stdio: ["pipe", "pipe", "inherit"],
});

let complete = false;
let failed = false;
let threadId;

function send(message) {
  server.stdin.write(JSON.stringify(message) + "\n");
}

function fail(message) {
  if (failed || complete) return;
  failed = true;
  process.exitCode = 1;
  console.error("hnew: " + message);
  server.kill();
}

server.on("error", (error) => fail("could not start Codex app-server: " + error.message));
server.on("exit", (code, signal) => {
  if (!complete && !failed) {
    fail("Codex app-server exited before naming the thread (" + (signal || code) + ")");
  }
  process.exitCode = failed ? 1 : 0;
});

const lines = readline.createInterface({ input: server.stdout });
lines.on("line", (line) => {
  let message;
  try {
    message = JSON.parse(line);
  } catch {
    fail("Codex app-server returned invalid JSON");
    return;
  }

  if (message.id === undefined) return;
  if (message.error) {
    fail(message.error.message || JSON.stringify(message.error));
    return;
  }

  if (message.id === 1) {
    send({ method: "initialized" });
    send({
      id: 2,
      method: "thread/start",
      params: { cwd: workspaceCwd, runtimeWorkspaceRoots },
    });
    return;
  }

  if (message.id === 2) {
    threadId = message.result && message.result.thread && message.result.thread.id;
    if (!threadId) {
      fail("thread/start did not return thread.id");
      return;
    }
    send({
      id: 3,
      method: "thread/name/set",
      params: { threadId, name: workspaceName },
    });
    return;
  }

  if (message.id === 3) {
    complete = true;
    process.stdout.write(threadId + "\n");
    server.stdin.end();
  }
});

send({
  id: 1,
  method: "initialize",
  params: {
    clientInfo: { name: "hnew", version: "1.0.0" },
    capabilities: { experimentalApi: true },
  },
});
' -- "$workspace_name" "$workspace_cwd" $argv[3..-1]
end

function __hnew_close_workspace --argument-names session workspace_id
    command herdr --session "$session" workspace close "$workspace_id" >/dev/null 2>&1
end

function hrepo --description 'Open the Herdr session for the current Git repository'
    set -l session (__herdr_repo_session)
    or begin
        echo 'hrepo: not inside a Git repository' >&2
        return 1
    end

    command herdr --session "$session" $argv
end

function hnew --description 'Create a Herdr workspace with Agent and dev tabs'
    set -l usage 'usage: hnew [--codex | --claude] <workspace name> [extra root ...]'
    argparse --exclusive codex,claude codex claude -- $argv
    or begin
        echo $usage >&2
        return 2
    end

    if test (count $argv) -eq 0
        echo $usage >&2
        return 2
    end

    set -l agent codex
    set -q _flag_claude
    and set agent claude

    set -l workspace_name $argv[1]
    set -l extra_roots $argv[2..-1]
    if string match --quiet --regex '^\s*$' "$workspace_name"
        echo 'hnew: workspace name cannot be empty' >&2
        return 2
    end

    set -l session (__herdr_repo_session)
    or begin
        echo 'hnew: not inside a Git repository' >&2
        return 1
    end

    __hnew_ensure_server "$session"
    or return

    set -l workspace_json (command herdr --session "$session" workspace create \
        --cwd "$PWD" \
        --label "$workspace_name" \
        --no-focus)
    or begin
        echo "hnew: could not create workspace '$workspace_name'" >&2
        return 1
    end

    set -l workspace_id (printf '%s\n' "$workspace_json" | command jq --exit-status --raw-output '.result.workspace.workspace_id')
    set -l agent_tab_id (printf '%s\n' "$workspace_json" | command jq --exit-status --raw-output '.result.tab.tab_id')
    set -l agent_pane_id (printf '%s\n' "$workspace_json" | command jq --exit-status --raw-output '.result.root_pane.pane_id')
    if not string match --quiet --regex '^w[0-9]+$' "$workspace_id"
        echo 'hnew: Herdr returned an incomplete workspace response' >&2
        return 1
    end
    if not string match --quiet --regex '^w[0-9]+:t[0-9]+$' "$agent_tab_id"
        __hnew_close_workspace "$session" "$workspace_id"
        echo 'hnew: Herdr returned an incomplete workspace response' >&2
        return 1
    end
    if not string match --quiet --regex '^w[0-9]+:p[0-9]+$' "$agent_pane_id"
        __hnew_close_workspace "$session" "$workspace_id"
        echo 'hnew: Herdr returned an incomplete workspace response' >&2
        return 1
    end

    command herdr --session "$session" tab rename "$agent_tab_id" Agent >/dev/null
    or begin
        __hnew_close_workspace "$session" "$workspace_id"
        echo 'hnew: could not rename the Agent tab' >&2
        return 1
    end

    command herdr --session "$session" tab create \
        --workspace "$workspace_id" \
        --cwd "$PWD" \
        --label dev \
        --no-focus >/dev/null
    or begin
        __hnew_close_workspace "$session" "$workspace_id"
        echo 'hnew: could not create the dev tab' >&2
        return 1
    end

    set -l extra_roots \
        "$HOME/code/upstart-web-frontend" \
        "$HOME/code/upstart_web" \
        $extra_roots

    if test $agent = claude
        set -l claude_cmd claude --name "$workspace_name"
        for root in $extra_roots
            set -a claude_cmd --add-dir "$root"
        end

        command herdr --session "$session" pane run "$agent_pane_id" (string join -- ' ' (string escape -- $claude_cmd)) >/dev/null
        or begin
            __hnew_close_workspace "$session" "$workspace_id"
            echo 'hnew: could not start Claude in Herdr' >&2
            return 1
        end
    else
        set -l thread_id (__hnew_codex_thread "$workspace_name" "$PWD" "$PWD" $extra_roots)
        or begin
            __hnew_close_workspace "$session" "$workspace_id"
            return 1
        end

        command herdr --session "$session" pane run "$agent_pane_id" "codex resume $thread_id" >/dev/null
        or begin
            echo "hnew: Codex thread $thread_id was named, but could not be started in Herdr" >&2
            return 1
        end
    end

    command herdr --session "$session" workspace focus "$workspace_id" >/dev/null
    command herdr --session "$session" tab focus "$agent_tab_id" >/dev/null

    if not set -q HERDR_ENV
        command herdr --session "$session"
    end
end
