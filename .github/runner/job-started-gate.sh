#!/bin/bash
# Job-started hook for the self-hosted runner (Droidspaces arch container), installed root-owned to
# /etc/github-actions/job-started-gate.sh. It refuses every job except the ones listed below from
# this repo, so an approved fork PR workflow can't run on (or tamper with) this machine:
#   build-local.yml          a local- tag push, or a manual workflow_dispatch
#   update-submodules.yml    cron or workflow_dispatch; API-only, checks nothing out
#   cleanup-artifacts.yml    same (still on ubuntu-latest, allowed here so flipping it later
#                            needs no reinstall)
# The trust boundary is "anyone with write access to this repo": only they can dispatch, cron runs
# only from main, and GitHub does not let a workflow overwrite the GITHUB_* variables read here.
# What this cannot see is a reusable workflow a listed one might call (GITHUB_WORKFLOW_REF names
# the caller), so none of the listed workflows may ever grow a job-level `uses:`.
# Exiting non-zero fails the job. After editing, reinstall (as bigdihh in the container):
#   gh api 'repos/der-meddler/A137F-A/contents/.github/runner/job-started-gate.sh?ref=main' --jq .content \
#     | base64 -d | sudo tee /etc/github-actions/job-started-gate.sh >/dev/null

deny() {
	echo "job-started gate: refusing $GITHUB_EVENT_NAME of $GITHUB_REF ($GITHUB_WORKFLOW_REF): $1" >&2
	exit 1
}

[ "$GITHUB_REPOSITORY" = der-meddler/A137F-A ] || deny "foreign repository"
# only the exact shape der-meddler/A137F-A/.github/workflows/<file>@<ref> gets as far as the file name
case "$GITHUB_WORKFLOW_REF" in
	der-meddler/A137F-A/.github/workflows/*@*) ;;
	*) deny "malformed workflow ref" ;;
esac
workflow=${GITHUB_WORKFLOW_REF#der-meddler/A137F-A/.github/workflows/}
workflow=${workflow%%@*}
case "$workflow" in
	build-local.yml)
		case "$GITHUB_EVENT_NAME" in
			push) case "$GITHUB_REF" in refs/tags/local-*) ;; *) deny "push but not a local- tag" ;; esac ;;
			workflow_dispatch) ;;
			*) deny "event not allowed" ;;
		esac ;;
	update-submodules.yml|cleanup-artifacts.yml)
		case "$GITHUB_EVENT_NAME" in
			schedule|workflow_dispatch) ;;
			*) deny "event not allowed" ;;
		esac ;;
	*) deny "not an allowed workflow" ;;
esac
exit 0
