function prepare-environment() { bash /usr/local/bin/reset-environment $1; source ~/.bashrc.d/workshop-env.bash; }
function use-cluster() { bash /usr/local/bin/use-cluster $1; source ~/.bashrc.d/env.bash; }