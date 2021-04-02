func goinside() {
	docker exec -ti $1 bash
}
alias goinside="goinside "

alias gbg="git for-each-ref --format='%(upstream:track);%(refname:short)' refs/heads | grep gone | awk -F';' '{ print \$2 }' | xargs git branch -D"

# ------------------------------------
# Docker alias and function
# ------------------------------------

# Get latest container ID
alias dl="docker ps -l -q"

# Get container process
alias dps="docker ps"

# Get process included stop container
alias dpa="docker ps -a"

# Get images
alias di="docker images"

# Get container IP
alias dip="docker inspect --format '{{ .NetworkSettings.IPAddress }}'"

# Run deamonized container, e.g., $dkd base /bin/echo hello
alias dkd="docker run -d -P"

# Run interactive container, e.g., $dki base /bin/bash
alias dki="docker run -i -t -P"

# Execute interactive container, e.g., $dex base /bin/bash
alias dex="docker exec -i -t"

# Stop all containers
dstop() { docker stop $(docker ps -a -q); }

# Remove all containers
drm() { docker rm $(docker ps -a -q); }

# Stop and Remove all containers
alias drmf='docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)'

# Remove all images
dri() { docker rmi $(docker images -q); }

# Dockerfile build, e.g., $dbu tcnksm/test 
dbu() { docker build -t=$1 .; }

# Show all alias related docker
dalias() { alias | grep 'docker' | sed "s/^\([^=]*\)=\(.*\)/\1 => \2/"| sed "s/['|\']//g" | sort; }

# Bash into running container
dbash() { docker exec -it $(docker ps -aqf "name=$1") bash; }

alias dm='docker-machine'
alias dmx='docker-machine ssh'
alias dk='docker'
alias dki='docker images'
alias dks='docker service'
alias dkrm='docker rm'
alias dkl='docker logs'
alias dklf='docker logs -f'
alias dkflush='docker rm `docker ps --no-trunc -aq`'
alias dkflush2='docker rmi $(docker images --filter "dangling=true" -q --no-trunc)'
alias dkt='docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"'
alias dkps="docker ps --format '{{.ID}} ~ {{.Names}} ~ {{.Status}} ~ {{.Image}}'"

dkln() {
  docker logs -f `docker ps | grep $1 | awk '{print $1}'`
}

dkp() {
  if [ ! -f .dockerignore ]; then
    echo "Warning, .dockerignore file is missing."
    read -p "Proceed anyway?"
  fi

  if [ ! -f package.json ]; then
    echo "Warning, package.json file is missing."
    read -p "Are you in the right directory?"
  fi

  VERSION=`cat package.json | jq .version | sed 's/\"//g'`
  NAME=`cat package.json | jq .name | sed 's/\"//g'`
  LABEL="$1/$NAME:$VERSION"

  docker build --build-arg NPM_TOKEN=${NPM_TOKEN} -t $LABEL .

  read -p "Press enter to publish"
  docker push $LABEL
}

dkpnc() {
  if [ ! -f .dockerignore ]; then
    echo "Warning, .dockerignore file is missing."
    read -p "Proceed anyway?"
  fi

  if [ ! -f package.json ]; then
    echo "Warning, package.json file is missing."
    read -p "Are you in the right directory?"
  fi

  VERSION=`cat package.json | jq .version | sed 's/\"//g'`
  NAME=`cat package.json | jq .name | sed 's/\"//g'`
  LABEL="$1/$NAME:$VERSION"

  docker build --build-arg NPM_TOKEN=${NPM_TOKEN} --no-cache=true -t $LABEL .
  read -p "Press enter to publish"
  docker push $LABEL
}

dkpl() {
  if [ ! -f .dockerignore ]; then
    echo "Warning, .dockerignore file is missing."
    read -p "Proceed anyway?"
  fi

  if [ ! -f package.json ]; then
    echo "Warning, package.json file is missing."
    read -p "Are you in the right directory?"
  fi

  VERSION=`cat package.json | jq .version | sed 's/\"//g'`
  NAME=`cat package.json | jq .name | sed 's/\"//g'`
  LATEST="$1/$NAME:latest"

  docker build --build-arg NPM_TOKEN=${NPM_TOKEN} --no-cache=true -t $LATEST .
  read -p "Press enter to publish"
  docker push $LATEST
}

dkclean() {
  docker rm $(docker ps --all -q -f status=exited)
  docker volume rm $(docker volume ls -qf dangling=true)
}

dkprune() {
  docker system prune -af
}

dktop() {
  docker stats --format "table {{.Container}}\t{{.Name}}\t{{.CPUPerc}}  {{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
}

dkstats() {
  if [ $# -eq 0 ]
    then docker stats --no-stream;
    else docker stats --no-stream | grep $1;
  fi
}

dke() {
  docker exec -it $1 /bin/sh
}

dkexe() {
  docker exec -it $1 $2
}

dkreboot() {
  osascript -e 'quit app "Docker"'
  countdown 2
  open -a Docker
  echo "Restarting Docker engine"
  countdown 120
}

dkstate() {
  docker inspect $1 | jq .[0].State
}

dksb() {
  docker service scale $1=0
  sleep 2
  docker service scale $1=$2
}
