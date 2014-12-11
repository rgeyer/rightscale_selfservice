rightscale_selfservice
======================

A rubygem with a self service [API client](./#api-client), and buncha useful [CLI](./#cli) bits for
RightScale Self Service, including a test harness for Cloud Application Templates

Travis Build Status: [<img src="https://travis-ci.org/rgeyer/rightscale_selfservice.png" />](https://travis-ci.org/rgeyer/rightscale_selfservice)

## Quick Start

```
gem install rightscale_selfservice
```

Setup some [Authentication](./#authentication) details

Explore the [CLI](./#cli).
```
rightscale_selfservice help
```

Explore the [API Client](./#api-client).

## Authentication

rightscale_selfservice can authenticate with the APIs using (roughly) the same
properties as [right_api_client](https://github.com/rightscale/right_api_client).

The only additional required property is "selfservice_url".

The CLI can use a \*.yml file containing those properties or have them passed in
on the commandline.  The API Client accepts an input hash with these same
properties.

An example \*.yml file can be found [here](https://github.com/rightscale/right_api_client/blob/v1.5.24/config/login.yml.example)

A working \*.yml file might look like;
```
:account_id: 12345
:email: user@domain.com
:password: password
:api_url: https://us-4.rightscale.com
:selfservice_url: https://selfservice-4.rightscale.com
```

## CLI

Main Commands
```
rightscale_selfservice help
Commands:
  rightscale_selfservice execution       # Self Service Execution Commands
  rightscale_selfservice help [COMMAND]  # Describe available commands or one specific command
  rightscale_selfservice operation       # Self Service Operation Commands
  rightscale_selfservice template        # Self Service Template Commands

Options:
  [--auth-hash=<auth-hash>]      # A hash of auth parameters in the form (email:foo@bar.baz password:password account_id:12345)
  [--auth-file=<auth-filepath>]  # A yaml file containing auth parameters to use for authentication
```

Execution Commands
```
rightscale_selfservice execution help
Commands:
  rightscale_selfservice execution help [COMMAND]  # Describe subcommands or one specific subcommand
  rightscale_selfservice execution list            # List all executions (CloudApps)

Options:
  [--auth-hash=<auth-hash>]      # A hash of auth parameters in the form (email:foo@bar.baz password:password account_id:12345)
  [--auth-file=<auth-filepath>]  # A yaml file containing auth parameters to use for authentication
```

Operation Commands
```
rightscale_selfservice operation help
Commands:
  rightscale_selfservice operation create <operation_name> <execution_id_or_href>  # Creates a new operation with the name <operation_name> on the ex...
  rightscale_selfservice operation help [COMMAND]                                  # Describe subcommands or one specific subcommand

Options:
  [--auth-hash=<auth-hash>]      # A hash of auth parameters in the form (email:foo@bar.baz password:password account_id:12345)
  [--auth-file=<auth-filepath>]  # A yaml file containing auth parameters to use for authentication
```

Template Commands
```
rightscale_selfservice template help
Commands:
  rightscale_selfservice template compile <filepath>     # Uploads <filepath> to SS, validating the syntax. Will report errors if any are found.
  rightscale_selfservice template execute <filepath>     # Create a new execution (CloudApp) from a template. Optionally supply parameter values
  rightscale_selfservice template help [COMMAND]         # Describe subcommands or one specific subcommand
  rightscale_selfservice template list                   # Lists all templates
  rightscale_selfservice template preprocess <filepath>  # Processes <filepath>, #include:/path/to/file statements with file contents. Will create a ...
  rightscale_selfservice template publish <filepath>     # Update and publish a template (based on name)
  rightscale_selfservice template upsert <filepath>      # Upload <filepath> to SS as a new template or updates an existing one (based on name)

Options:
  [--auth-hash=<auth-hash>]      # A hash of auth parameters in the form (email:foo@bar.baz password:password account_id:12345)
  [--auth-file=<auth-filepath>]  # A yaml file containing auth parameters to use for authentication
```

## API Client
