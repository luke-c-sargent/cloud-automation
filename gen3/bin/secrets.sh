#!/bin/bash
#
# Organize gen3 secrets into a local git repo to track history of changes.
# Each service has its own folder, so that automation can automatically
# mount all secrets in the folder.
#

source "${GEN3_HOME}/gen3/lib/utils.sh"
gen3_load "gen3/lib/kube-setup-init"


gen3_secrets_init() {
  local secretsDir
  secretsDir="$WORKSPACE/$vpc_name/gen3_secrets"
  if [[ ! -d "$secretsDir" ]]; then
    (
      set -e
      mkdir -p -m 0770 "$secretsDir"
      cd "$secretsDir"
      git init .
      mkdir fence peregrine sheepdog indexd
    )
    return $?
  else
    echo -e "$(red_color "Ignoring gen3_secrets_init - $WORKSPACE/$vpc_name already exists")"
  fi
  return 0
}
