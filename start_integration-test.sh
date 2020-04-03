#!/bin/sh

CFG=/tmp/minetest.conf
MTDIR=/tmp/mt
WORLDDIR=${MTDIR}/worlds/world

cat <<EOF > ${CFG}
 blockexchange.url = http://localhost:8080
 enable_blockexchange_integration_test = true
 secure.http_mods = blockexchange
EOF

mkdir -p ${WORLDDIR}
chmod 777 ${MTDIR} -R
docker run --rm -i \
	-v ${CFG}:/etc/minetest/minetest.conf:ro \
	-v ${MTDIR}:/var/lib/minetest/.minetest \
	-v $(pwd):/var/lib/minetest/.minetest/worlds/world/worldmods/blockexchange \
  --network host \
	registry.gitlab.com/minetest/minetest/server:5.1.0

test -f ${WORLDDIR}/integration_test.json && exit 0 || exit 1
