minetest blockexchange mod

![](https://github.com/blockexchange/blockexchange/workflows/luacheck/badge.svg)
![](https://github.com/blockexchange/blockexchange/workflows/integration-test/badge.svg)
[![License](https://img.shields.io/badge/License-MIT%20and%20CC%20BY--SA%203.0-green.svg)](license.txt)
[![Download](https://img.shields.io/badge/Download-ContentDB-blue.svg)](https://content.minetest.net/packages/BuckarooBanzay/blockexchange)

State: **WIP**

# Overview

The `blockexchange` mod allows you to share and use your builds across different worlds.
It uses a central (configurable) server to exchange schemas (builds) of near infinite size.

The server part lives at https://github.com/blockexchange/blockexchange_server and can be self-hosted.

Schemas can be browsed and administered on the central server: https://blockexchange.minetest.land

# Basic usage

## Download / Search

* Start your minetest app
* Download the `blockexchange` mod in the "Content" tab from the ContentDB.
* Add the `blockexchange` mod to the secure HTTP-Mods settings (search for "http" in the "settings" tab)
* Create a new world and activate the mod
* Grant yourself the needed privs with `/grantme blockexchange`
* Search for an empty place and mark it with `/bx_pos1`
* Browse for a schema with `/bx_search <keywords>`
* Load the schema with the "Load" button (**WARNING**: this may place the schema over existing builds!)
* Have fun!

## Upload

* Start your minetest app
* Download the `blockexchange` mod in the "Content" tab from the ContentDB.
* Add the `blockexchange` mod to the secure HTTP-Mods settings (search for "http" in the "settings" tab)
* Create a new world and activate the mod
* Grant yourself the needed privs with `/grantme blockexchange`
* Build a thing
* Set positions on the opposite corners with `/bx_pos1` and `/bx_pos2`
* Register an account with `/bx_register <username> <password>`
* **OR** Login with an existing account: `/bx_login <username> <password>`
* Save the schematic with `/bx_save <name> <description>`

# Chat commands

## Read-only

* **/bx_info**
* **/bx_pos1**
* **/bx_pos2**
* **/bx_search [keywords]** search a schema by keywords
* **/bx_load [username] [schemaname]**
* **/bx_load_here [username] [schemaname]**
* **/bx_allocate [username] [schemaname]**
* **/bx_login [username] [password]**
* **/bx_register [username] [password] [mail?]**

## Write (needs a login)

* **/bx_save [schemaname] [description]**
* **/bx_logout** logs out
* **/bx_login** shows the login status

# Privileges

* **blockexchange** can use the blockexchange commands

# Settings

* **blockexchange.url** URL to the central server

The mod also needs the http api:
```
secure.http_mods = blockexchange
```

# License

* Code: MIT
* Textures: CC-BY-SA 3.0
