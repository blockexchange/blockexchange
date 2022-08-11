minetest blockexchange mod

![](https://github.com/blockexchange/blockexchange/workflows/luacheck/badge.svg)
![](https://github.com/blockexchange/blockexchange/workflows/busted/badge.svg)
![](https://github.com/blockexchange/blockexchange/workflows/ldoc/badge.svg)
[![License](https://img.shields.io/badge/License-MIT%20and%20CC%20BY--SA%203.0-green.svg)](license.txt)
[![Download](https://img.shields.io/badge/Download-ContentDB-blue.svg)](https://content.minetest.net/packages/BuckarooBanzay/blockexchange)

# Overview

The `blockexchange` mod allows you to share and use your builds across different worlds.
It uses a central (configurable) server to exchange schemas (builds) of near infinite size.

The server part lives at https://github.com/blockexchange/blockexchange_server and can be self-hosted.

Schemas can be browsed and administered on the central server: https://blockexchange.minetest.land

<img src="./blockexchange.png"/>

# Basic usage

## Download

* Start your minetest app
* Download the `blockexchange` mod in the "Content" tab from the ContentDB.
* Add the `blockexchange` mod to the secure HTTP-Mods settings (search for "http" in the "settings" tab)
* Create a new world and activate the mod
* Grant yourself the needed privs with `/grantme blockexchange`
* Search for an empty place and mark it with `/bx_pos1`
* Browse online for a schema at https://blockexchange.minetest.land
* Load the schema with the `/bx_load <username> <schemaname>` command (**WARNING**: this may place the schema over existing builds!)
* Have fun!

## Upload

* Start your minetest app
* Download the `blockexchange` mod in the "Content" tab from the ContentDB.
* Add the `blockexchange` mod to the secure HTTP-Mods settings (search for "http" in the "settings" tab)
* Create a new world and activate the mod
* Grant yourself the needed privs with `/grantme blockexchange`
* Build a thing
* Set positions on the opposite corners with `/bx_pos1` and `/bx_pos2`
* Login with an access token generated from https://blockexchange.minetest.land: `/bx_login [username] [access_token]`
* Save the schematic with `/bx_save <name>`

# Chat commands

## Offline

Local commands, they don't need the http-api and make no calls "home"

* **/bx_pos1** mark position 1
* **/bx_pos2** mark position 2
* **/bx_emerge** emerge the selected area
* **/bx_save_local [schemaname]** saves a local schema to `<worldmods>/bxschems`
* **/bx_load_local [schemaname]** loads a local schema from `<worldmods>/bxschems`
* **/bx_allocate_local [schemaname]** allocates a local schema

## Online

Online commands, they call the remote-server with the http api

### Read-only

* **/bx_info** shows infos about the connected blockexchange server
* **/bx_license** sets or displays the license of your uploaded schematics (defaults to CC0)
* **/bx_load [username] [schemaname]** load a schema by name onto pos1
* **/bx_allocate [username] [schemaname]** allocates a schema by name
* **/bx_login [username] [access_token]** logs in with the username and token
* **/bx_cancel** Cancels an active job

### Write (needs a login)

* **/bx_save [schemaname]** Saves/uploads the selected area as a new schema
* **/bx_logout** logs out
* **/bx_login** shows the login status

# Privileges

* **blockexchange** can use the blockexchange commands (admin)
* **blockexchange_protected_upload** can upload self-protected areas (survival-compatible)

# Settings

* **blockexchange.url** URL to the central server

The mod also needs the http api:
```
secure.http_mods = blockexchange
```

# Api docs

See: https://blockexchange.github.io/blockexchange/

# License

* Code: MIT
* Textures: CC-BY-SA 3.0 (http://www.small-icons.com/packs/16x16-free-application-icons.htm)
