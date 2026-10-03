#!/bin/bash
# Job-started hook for the self-hosted runner (Droidspaces arch container), installed root-owned to
# /etc/github-actions/job-started-gate.sh. It refuses every job except build-local.yml in this repo,
# started either by a local- tag push or a manual workflow_dispatch (which only a user with repo
# write access can trigger), so an approved fork PR workflow can't run on (or tamper with) this
# machine. Exiting non-zero fails the job.

deny() {
	echo "job-started gate: refusing $GITHUB_EVENT_NAME of $GITHUB_REF ($GITHUB_WORKFLOW_REF): $1" >&2
	exit 1
}

[ "$GITHUB_REPOSITORY" = der-meddler/A137F-A ] || deny "foreign repository"
case "$GITHUB_WORKFLOW_REF" in
	der-meddler/A137F-A/.github/workflows/build-local.yml@*) ;;
	*) deny "not build-local.yml" ;;
esac
case "$GITHUB_EVENT_NAME" in
	push) case "$GITHUB_REF" in refs/tags/local-*) ;; *) deny "push but not a local- tag" ;; esac ;;
	workflow_dispatch) ;; # manual run; GitHub only lets users with repo write access trigger it
	*) deny "event not allowed" ;;
esac
exit 0
