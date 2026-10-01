#!/bin/bash
# Job-started hook for the self-hosted runner (Droidspaces arch container), installed root-owned to
# /etc/github-actions/job-started-gate.sh. It refuses every job except local-
# tag builds of build-local.yml in this repo, so an approved fork PR workflow
# can't run on (or tamper with) this machine. Exiting non-zero fails the job.

deny() {
	echo "job-started gate: refusing $GITHUB_EVENT_NAME of $GITHUB_REF ($GITHUB_WORKFLOW_REF): $1" >&2
	exit 1
}

[ "$GITHUB_REPOSITORY" = der-meddler/A137F-A ] || deny "foreign repository"
[ "$GITHUB_EVENT_NAME" = push ] || deny "not a push"
case "$GITHUB_REF" in refs/tags/local-*) ;; *) deny "not a local- tag" ;; esac
case "$GITHUB_WORKFLOW_REF" in
	der-meddler/A137F-A/.github/workflows/build-local.yml@*) ;;
	*) deny "not build-local.yml" ;;
esac
exit 0
