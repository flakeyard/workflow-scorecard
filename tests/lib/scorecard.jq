# The rules a Scorecard workflow must meet, over the workflow read as JSON.
# Prints one line per violation: "<rule>: <message>". The rules of the
# Scorecard server, which verifies the workflow that signs the results, come
# first (ossf/scorecard-infra, api/app/server/verify_workflow.go); the rules
# of FY-0031 for workflow-scorecard follow.

# The step actions the server allows in the Scorecard job.
def allowed_actions: [
  "actions/checkout",
  "actions/create-github-app-token",
  "ossf/scorecard-action",
  "actions/upload-artifact",
  "github/codeql-action/upload-sarif",
  "step-security/harden-runner"
];
# The oldest GitHub-hosted Ubuntu image the server accepts; labels are "YY.MM",
# so strings compare in numeric order.
def oldest_ubuntu: "22.04";
def ubuntu_runner: "^ubuntu-(?<version>latest|[0-9]{2}\\.[0-9]{2})(-arm)?$";
# The permissions of the Scorecard job, no more and no fewer (FY-0031).
def scorecard_permissions: {
  "actions": "read",
  "contents": "read",
  "id-token": "write",
  "security-events": "write"
};
def pinned_by_commit: "^[^@]+@[0-9a-f]{40}$";

def violation($rule; $message): "\($rule): \($message)";

# The action of a reference action@ref, as the server reads it; a reference
# without @, such as a docker image, has none and is not allowed.
def action_name: if test("@") then sub("@.*$"; "") else "" end;
def steps: .steps // [];
def is_scorecard_job: any(steps[]; (.uses // "") | action_name == "ossf/scorecard-action");
# The id and the job of the first job that runs scorecard-action.
def scorecard_entry: first(.jobs | to_entries[] | select(.value | is_scorecard_job));
def write_scopes: [.permissions | objects | to_entries[] | select(.value == "write") | .key];
# Stricter than the server, which reads only the scope id-token.
def grants_id_token:
  .permissions as $permissions
  | $permissions == "write-all"
    or ($permissions | type == "object" and .["id-token"] == "write");
def runner_labels:
  .["runs-on"]
  | if type == "object" then .labels else . end
  | if type == "array" then . elif type == "string" then [.] else [] end;
def supported_runner:
  test(ubuntu_runner)
  and (capture(ubuntu_runner).version | . == "latest" or . >= oldest_ubuntu);
def references: [.jobs[] | (.uses // empty), (steps[] | .uses // empty)];

# Rules of the server over the workflow.
def top_level_env_or_defaults:
  select(has("env") or has("defaults"))
  | violation("top-level-env-or-defaults"; "env or defaults at the top level");
def top_level_write:
  select(.permissions == "write-all" or (write_scopes | length > 0))
  | violation("top-level-write"; "write permissions at the top level");
def id_token_elsewhere($scorecard_id):
  .jobs | to_entries[]
  | select(.key != $scorecard_id and (.value | grants_id_token))
  | violation("id-token-elsewhere"; "job \(.key) can write id-token");

# Rules of the server over the Scorecard job.
def container_or_services:
  select(has("container") or ((.services // {}) | length > 0))
  | violation("container-or-services"; "the Scorecard job has a container or services");
def runner_count:
  select(runner_labels | length != 1)
  | violation("runner-count"; "\(runner_labels | length) runner labels, not one");
def runner_label:
  select(runner_labels | length == 1) | runner_labels[0]
  | select(supported_runner | not)
  | violation("runner-label"; "runner \(.) is not GitHub-hosted Ubuntu \(oldest_ubuntu) or newer");
def job_env:
  select(has("env")) | violation("job-env"; "the Scorecard job has env");
def job_defaults:
  select(has("defaults")) | violation("job-defaults"; "the Scorecard job has defaults");
def step_uses:
  steps[] | select(has("uses") | not)
  | violation("step-uses"; "a step of the Scorecard job runs no action");
def step_allowed:
  steps[] | .uses // empty | action_name as $action
  | select(allowed_actions | index($action) | not)
  | violation("step-allowed"; "the server does not allow the step \(.)");

# Rules of FY-0031 for the reusable workflow of workflow-scorecard.
def top_level_permissions:
  select(.permissions != {})
  | violation("top-level-permissions"; "the top-level permissions are not {}");
def one_job:
  select(.jobs | length != 1)
  | violation("one-job"; "\(.jobs | length) jobs, not only the Scorecard job");
def pinned:
  references[] | select(test(pinned_by_commit) | not)
  | violation("pinned"; "\(.) is not pinned by full commit SHA");
def job_permissions:
  select(.permissions != scorecard_permissions)
  | violation("job-permissions";
      "the Scorecard job has other permissions than \(scorecard_permissions | tojson)");

def scorecard_job_rules:
  container_or_services, runner_count, runner_label, job_env, job_defaults,
  step_uses, step_allowed, job_permissions;

top_level_env_or_defaults,
top_level_write,
top_level_permissions,
one_job,
pinned,
(scorecard_entry as $entry
  | id_token_elsewhere($entry.key), ($entry.value | scorecard_job_rules)),
(select([scorecard_entry] == [])
  | violation("scorecard-job"; "no job runs ossf/scorecard-action"))
