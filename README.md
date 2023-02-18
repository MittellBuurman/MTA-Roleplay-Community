# SourPatch MTA Roleplay Community Edition

This repository is the [69th fork](https://github.com/OwlGamingCommunity/MTA/network/members) of the [OwlGaming MTA codebase](https://github.com/OwlGamingCommunity/MTA) for [Multi Theft Auto](https://multitheftauto.com/).

## Project Scope

With over a decade of development, and the eventual shutdown of OwlGaming, the current codebase has various issues, which takes an experienced developer to debug and painstakingly make their best effort to get the gamemode working.

Therefore the scope of this project is to make the gamemode more user-friendly and accessible, as well as extensive debugging before making improvements.

~The recommended way to deploy the code is using a docker image.~

## Credits

The code in this repository comes from various sources from probably nearly a decade of development. Thank you to everyone who contributed over the years.

## Building for release

- Build the image `docker build -t owlgaming-mta .`
- Refer to the environment variable below and deploy using your MySQL Database
```shell
docker run -p 22003:22003 -p 22005:22005 -p 22126:22126/udp -e MTA_DATABASE_NAME=... owlgaming-mta~
```
- You can grab the latest structures for your database from `mods/deathmatch/data`

## Logs

Logs are written to `mods/deathmatch/resources/logs/logs` as they are created in game. It's recommended to pick these up using Filebeat with Elasticsearch to make them searchable.

## Quick Links

* [Coding Conventions](coding_conventions.md)
* [Useful Functions](useful_functions.md)

## Docker Build Environment Variables

### MTASERVER.CONF
- `SERVER_IP`
- `SHOULD_BROADCAST`
- `OWNER_EMAIL_ADDRESS`

### SETTINGS.XML
- `PRODUCTION_SERVER`
- `MTA_DATABASE_NAME`
- `MTA_DATABASE_USERNAME`
- `MTA_DATABASE_PASSWORD`
- `MTA_DATABASE_HOST`
- `MTA_DATABASE_PORT`

- `CORE_DATABASE_NAME`
- `CORE_DATABASE_USERNAME`
- `CORE_DATABASE_PASSWORD`
- `CORE_DATABASE_HOST`
- `CORE_DATABASE_PORT`

- `FORUMS_API_KEY`
- `IMGUR_API_KEY`
