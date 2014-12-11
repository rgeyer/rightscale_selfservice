rightscale_selfservice
======================

A rubygem with a self service [API client](#api-client), and buncha useful [CLI](#cli) bits for
RightScale Self Service, including a test harness for Cloud Application Templates

Travis Build Status: [<img src="https://travis-ci.org/rgeyer/rightscale_selfservice.png" />](https://travis-ci.org/rgeyer/rightscale_selfservice)

## Quick Start

```
gem install rightscale_selfservice
```

Setup some [Authentication](#authentication) details

Explore the [CLI](#cli).
```
rightscale_selfservice help
```

Explore the [API Client](#api-client).

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

### Template Includes
For any of the template commands, the template will be preprocessed
to replace any #include:/path/to/another/cat/file with the contents of that file.

This allows for shared libraries to be built and stored along side your CATs.

Example:

Main template
```
name 'cat-with-includes'
rs_ca_ver 20131202
short_description 'has some includes'

#include:../definitions/foo.cat.rb
```

foo.cat.rb
```
define foo() return @clouds do
  @clouds = rs.clouds.get()
end
```

Results in
```
name 'cat-with-includes'
rs_ca_ver 20131202
short_description 'has some includes'

###############################################################################
# BEGIN Include from ../definitions/foo.cat.rb
###############################################################################
define foo() return @clouds do
  @clouds = rs.clouds.get()
end
###############################################################################
# END Include from ../definitions/foo.cat.rb
###############################################################################
```

You can simply run the preprocessor on your CAT and get a file with all the
appropriate includes with the "preprocess" command.

```
rightscale_selfservice template preprocess ~/Code/cat/somecat.cat.rb -o /tmp/processedcat.cat.rb
```

Then maybe check if all your syntax is good by using the API to "compile" your CAT

```
rightscale_selfservice template compile ~/Code/cat/somecat.cat.rb --auth-file=~./.right_api_client/login.yml
```

If that works, maybe start up a Cloud App from it

```
rightscale_selfservice template execute ~/Code/cat/somecat.cat.rb --auth-file=~/.right_api_client/login.yml
```

## API Client
