#!/bin/bash
# integration test


# setup
docker network create bx_net
docker run -d --name blockexchange_pg --rm \
 -e POSTGRES_PASSWORD=enter \
 --network bx_net \
 postgres:12

sleep 10

docker pull blockexchange/blockexchange
docker run -d --name blockexchange_server --rm \
  -e PGUSER=postgres \
  -e PGPASSWORD=enter \
  -e PGHOST=blockexchange_pg \
  -e PGDATABASE=postgres \
  -e PGPORT=5432 \
  -e BLOCKEXCHANGE_KEY=blah \
  --network bx_net \
  blockexchange/blockexchange

function cleanup {
	# cleanup
	docker stop blockexchange_server
	docker stop blockexchange_pg
}

trap cleanup EXIT

sleep 10

# insert test data
docker exec -i blockexchange_pg psql -U postgres -c "insert into public.user(id,created,name,hash,type) values(666,0,'test','','LOCAL');"
docker exec -i blockexchange_pg psql -U postgres -c "insert into access_token(user_id,created,expires,name,token) values(666,0,2925191383506,'default','xyz');"

CFG=/tmp/minetest.conf
MTDIR=/tmp/mt
WORLDDIR=${MTDIR}/worlds/world

cat <<EOF > ${CFG}
 blockexchange.url = http://blockexchange_server:8080
 blockexchange.enable_integration_test = true
 secure.http_mods = blockexchange
EOF

mkdir -p ${WORLDDIR}
chmod 777 ${MTDIR} -R
docker run --rm -i \
	-v ${CFG}:/etc/minetest/minetest.conf:ro \
	-v ${MTDIR}:/var/lib/minetest/.minetest \
  -v $(pwd)/:/var/lib/minetest/.minetest/worlds/world/worldmods/blockexchange \
  --network bx_net \
	registry.gitlab.com/minetest/minetest/server:5.4.0

test -f ${WORLDDIR}/integration_test.json && exit 0 || exit 1
