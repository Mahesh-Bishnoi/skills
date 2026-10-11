# OpenShell setup

Runs the rest of `/setup` (or later agent work) inside an OpenShell sandbox so an untrusted third-party skill cannot reach beyond an explicit policy. Vendors nothing — upstream moves fast, so this file only detects, asks, and guides install.

Upstream:

- OpenShell safe runtime for autonomous AI agents (Apache-2.0). Docs at https://docs.nvidia.com/openshell/latest/
- Install via the upstream installer, then `openshell sandbox create --name <name>` (a local gateway plus Docker, Podman, or host virtualization). OpenCode is a supported agent inside a sandbox.
- Agent skills for driving OpenShell live upstream and install via `npx skills add NVIDIA/OpenShell` (not vendored here).

Project `AGENTS.md` and existing codebase conventions override this file.

Out of scope (never set up here): Kubernetes/Helm gateway deploys, shared team gateways, production credential stores, SIEM log export. Those need cluster access or shared secrets.

## Step 1 — Detect (read-only, no installs)

Run these checks and report the result before asking anything:

```sh
command -v openshell; openshell --version 2>/dev/null || true
command -v docker; docker --version 2>/dev/null || true
command -v podman; podman --version 2>/dev/null || true
command -v opencode; opencode --version 2>/dev/null || true
ls ./openshell.policy.yaml 2>/dev/null || true
```

Installed means:

- `openshell` CLI present (`openshell --version` prints a version).
- A container runtime present: `podman` (preferred for rootless daemonless runs) or `docker`.
- A baseline `openshell.policy.yaml` reviewed in the project (policy is code — it gets reviewed like code).

If the CLI + a runtime are ready and the user only wants containment for this `/setup` run, skip to Step 3.3. If no runtime is present, go through Step 2.2 before anything else — OpenShell cannot run without one.

## Step 2 — Ask (one question at a time)

Ask only what is missing. Defaults in brackets. Wait for each answer.

1. `Install the OpenShell CLI + local gateway [no]?` Default-off. Present the upstream installer and get an explicit yes. The human runs it if the agent lacks permission.
2. `Install a container runtime (podman preferred, docker alternative) [no]?` Default-off; only asked when neither `podman` nor `docker` is on PATH. Present the exact package-manager command for this OS and get an explicit yes — never install silently. Re-run the Step 1 runtime checks after install before continuing.
3. `Generate a baseline restrictive openshell.policy.yaml for this project [no]?` Default-off. Filesystem limited to the project dir plus a scratch dir, network deny-by-default with an explicit allowlist, no home-directory or credential mounts.
4. `Run the remainder of this /setup inside openshell sandbox create --policy ./openshell.policy.yaml -- opencode [no]?` Default-off. Only offered when CLI + runtime + policy are all ready.
5. `Confirm install?` The agent must never install software silently. Present the exact commands and get an explicit yes. The human runs them if the agent lacks permission.

## Step 3 — Install (on explicit yes only)

OpenShell CLI + local gateway (only if Step 2.1 was yes):

```sh
curl -LsSf https://raw.githubusercontent.com/NVIDIA/OpenShell/main/install.sh | sh
openshell --version
```

Container runtime (only if Step 2.2 was yes — pick one; podman first):

```sh
podman --version
```

When `podman` is missing, offer the OS-native install first and re-check before falling back to Docker docs:

```sh
sudo apt install podman
```

```sh
brew install podman
```

Docker alternative (only when the user explicitly chooses docker over podman): follow the official Docker install docs for this OS, then verify with `docker --version`. Do not script the Docker install here — it varies by distro and licensing.

Baseline policy (only if Step 2.3 was yes) — write `./openshell.policy.yaml`, review it like code, adjust the allowlist to this project:

```yaml
# Baseline: project workspace only, deny-by-default egress.
filesystem:
  read:
    - <project-root>
  write:
    - <project-root>/.opencode/skills
    - <tmp>/agent-workspace
network:
  outbound:
    - host: "registry.npmjs.org"
    - host: "github.com"
    - host: "pypi.org"
```

Keep it minimal: every allowed host must answer "which install step needs this?" Never mount home-directory dotfiles, SSH keys, or cloud credentials into the sandbox. Real credentials stay outside and are bound to approved endpoints via provider profiles.

Contained run (only if Step 2.4 was yes):

```sh
openshell sandbox create --name setup --policy ./openshell.policy.yaml -- opencode
```

Check `openshell sandbox --help` when in doubt — CLI shape is still churning in `0.1.x`. Filesystem/process rules lock at sandbox creation; only network/inference policy hot-reloads. A global policy replaces per-sandbox policy while active, so prefer the per-project policy file above.

If a command fails, report the output verbatim and stop. Common causes: no container runtime, gateway not started, policy path rejected at creation, or unsupported platform (Linux, macOS on Apple Silicon, or Windows with WSL2 experimental).

## Step 4 — Hand off (no duplicate work)

Once installed (or already installed), stop setup and hand off:

- Tell the user the installed entry points: `openshell sandbox create --policy ./openshell.policy.yaml -- opencode`, plus the reviewed policy path.
- Record the choice in the project's `AGENTS.md` skills-in-use section (the `/setup` wizard does this at the end — do not edit `AGENTS.md` here).
- Stop. No feature work in this file.

## Verification

- [ ] Detection ran before any question (CLI, docker/podman, policy file)
- [ ] Questions asked one at a time, defaults stated, no batching
- [ ] Missing runtime triggered the podman/docker install prompt before any sandbox step
- [ ] OpenShell CLI, runtime, and policy each gated on their own explicit yes
- [ ] No install command ran without explicit user yes
- [ ] Policy reviewed as code; no credential mounts or broad home-directory access
- [ ] No upstream files vendored into this repo
- [ ] Hand-off named the sandbox entry point and stopped without analysis
