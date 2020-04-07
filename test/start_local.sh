#!/bin/sh

sudo docker run --rm -it \
	-u root:root \
	-v $(pwd)/minetest.conf:/etc/minetest/minetest.conf \
  -v $(pwd)/../:/root/.minetest/worlds/world/worldmods/blockexchange \
	-v blockexchange_world:/root/.minetest/worlds/world/ \
	--network host \
	registry.gitlab.com/minetest/minetest/server:5.1.0
