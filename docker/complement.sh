#!/bin/bash
set -eo pipefail

BASEDIR=$(dirname "$0")

CI="${CI:-false}"
CI_VERBOSE="${CI_VERBOSE_ENV:-false}"
CI_VERBOSE_ENV="${CI_VERBOSE_ENV:-$CI_VERBOSE}"

default_cargo_profile="test"
default_feat_set="all"
default_rust_toolchain="nightly"
default_rust_target="x86_64-unknown-linux-gnu"
default_sys_name="debian"
default_sys_target="x86_64-v1-linux-gnu"
default_sys_version="testing-slim"

set -a
cargo_profile="${cargo_profile:-$default_cargo_profile}"
feat_set="${feat_set:-$default_feat_set}"
rust_target="${rust_target:-$default_rust_target}"
rust_toolchain="${rust_toolchain:-$default_rust_toolchain}"
sys_name="${sys_name:-$default_sys_name}"
sys_target="${sys_target:-$default_sys_target}"
sys_version="${sys_version:-$default_sys_version}"

runner_name=$(echo $RUNNER_NAME | cut -d"." -f1)
runner_num=$(echo $RUNNER_NAME | cut -d"." -f2)
set +a

###############################################################################

set -x
tester_image="complement-tester--${sys_name}--${sys_version}--${sys_target}"
testee_image="complement-testee--${cargo_profile}--${rust_toolchain}--${rust_target}--${feat_set}--${sys_name}--${sys_version}--${sys_target}"
name="complement_tester__${sys_name}__${sys_version}__${sys_target}"
sock="/var/run/docker.sock"
arg="--name $name -v $sock:$sock --network=host $tester_image ${testee_image}"
set +x

if test "$CI_VERBOSE_ENV" = "true"; then
	date
	env
fi

docker rm -f "$name" 2>/dev/null

trap 'set +x; date; echo -e "\033[1;41;37mERROR\033[0m"' ERR

if test "$CI" = "true"; then
	arg="-d $arg"
	cid=$(docker run $arg)
else
	arg="--rm -a stdout -a stderr $arg"
	docker run $arg
	exit $?
fi

echo -n "$cid" > "$name"

trap 'docker container stop $cid; set +x; date; echo -e "\033[1;41;37mERROR\033[0m"' INT
docker logs -f "$cid"
docker wait "$cid" 2>/dev/null

echo -e "\033[1;42;30mACCEPT\033[0m"
