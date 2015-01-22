<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [rightscale_selfservice](#rightscale_selfservice)
  - [Quick Start](#quick-start)
  - [Authentication](#authentication)
  - [CLI](#cli)
    - [Template Includes](#template-includes)
  - [Testing](#testing)
    - [Suite](#suite)
    - [Template](#template)
    - [Case](#case)
      - [Compile](#compile)
      - [Execute](#execute)
      - [Operations](#operations)
  - [API Client](#api-client)
    - [Supported Services, Resources and Actions](#supported-services-resources-and-actions)
    - [How it works](#how-it-works)
      - [Href Tokens](#href-tokens)
      - [Automatic Multipart](#automatic-multipart)
    - [Some examples...](#some-examples)
      - [Authentication](#authentication-1)
      - [Service Versions](#service-versions)
      - [Executing Actions](#executing-actions)
        - [List operations](#list-operations)
        - [Show a template](#show-a-template)
        - [Get RestClient::Request Instead of Executing Action](#get-restclientrequest-instead-of-executing-action)
        - [Format Errors](#format-errors)
        - [Multipart Detection](#multipart-detection)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

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

The CLI can use a .yml file containing those properties or have them passed in
on the commandline.  The API Client accepts an input hash with these same
properties.

An example .yml file can be found [here](https://github.com/rightscale/right_api_client/blob/v1.5.24/config/login.yml.example)

A working .yml file might look like;
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

## Testing

Included as a framework for performing functional tests of your Cloud
Application Templates (CATs). Tests are performed as part of a [Suite](#suite)
which contains one or more [Template](#template), which have one or more test
[Case](#case).

### Suite
A suite is currently defined simply by the [glob](http://ruby-doc.org/core-1.9.3/Dir.html#method-c-glob)
you pass either to the [CLI](#cli) or the test suite class.

I might consider creating a config file or other options, but for now the suite
is basically just a container.

The suite will interrogate the files found by the input glob, and create
individual [Template](#template) classes.

### Template
A template is a 1-to-1 match with a CAT file found by the [Suite](#suite).

The template class will interrogate the contents of the CAT and create individual
[Case](#case) classes.

### Case
There are three types of cases, which are defined by comments in the CAT.

#### Compile
Merely checks if the CAT will compile successfully. When a template is tagged
to include a compile test case every other test will be ignored.

To create a test template which will only be tested for successful compile add
the following to the top of the template
```
#test:compile_only=true
```

#### Execute
This checks if the CAT will execute and reach a desired state.

If no tags are added to a template, an execute test case will be automatically
run, with the assumption that it's expected execution_state is "running".

To create a test template with an execute test case which will succeed if the
CAT launches successfully.

```
#test:execution_state=running
```

For the negative test case, where a CAT which launches and fails is actually a
successful test.

```
#test:execution_state=failed
```

There are also scenarios where a successful test should end in a specified state
but because of external issues (system bugs, reusable definitions, etc) the
opposite state is reached. In this case you can specify both the desired state
as the "execution_state" as well as an "execution_alternate_state".

If the CAT launches and reaches the alternate state the test case will be marked
as "FAILED (EXPECTED)", and if it reaches the desired state it will be marked
"FIXED"

```
#test:execution_state=running
#test:execution_alternate_state=failed
```

#### Operations
Once a template has been successfully launched, any operation test cases will
be run.

An example of a CAT with two operations which should be run as test cases;
```
#test:execution_state=running
#test:execution_alternate_state=failed

name "Foo"
rs_ca_ver 20131202
short_description "Foo"

#test_operation:execution_state=completed
#test_operation:execution_alternate_state=failed
#test_operation_param:key=val
#test_operation_param:key1=val1
#test_operation_param:key2=val2
operation "one" do
  description "one"
  definition "foo"
end

#test_operation:execution_state=completed
#test_operation:execution_alternate_state=failed
#test_operation_param:key=val
#test_operation_param:key1=val1
#test_operation_param:key2=val2
operation "two" do
  description "two"
  definition "foo"
end

define foo() do

end
```

This will run the operations named "one" and "two" with the specified
test_operation_param(s) as inputs to the operation. It will evaluate success
or failure based on the "execution_state" specified.

This has the same functionality as [Execute](#execute) in that you can specify
a desired and alternative state.

## API Client

The [CLI](#cli) bits consume the API client which is deployed with this gem. The
goal of this API client is to be as "dumb" and lightweight as is practical.

In practical terms this means that the client doesn't make assumptions about the
return values from the API, and does not attempt to turn them into ruby objects.

In fact, the default "language" of this client is
[Rest Client](http://rubygems.org/gems/rest-client) requests and responses.

The API client does handle some of the more mundane things for you though, such
as authenticating with the API using various means (access_token, refresh_token,
email & password), and assembling the correct URL for a particular resource
action.

### Supported Services, Resources and Actions
The client fetches metadata about the SelfService API using a Rake task which
generates a JSON file which is deployed with the client/gem.  This means that
a given version of the client supports the API interface as it existed at the
time that version of the client/gem was created.

Fear not, supporting the latest functionality is as simple as.

```
rake update_inteface_json
# Bump the gemspec
rake gem
gem push pkg/<new gem file>
```

### How it works
You can access a specific action with the following syntax.

```
client.<service_name>(<optional_service_version>).<resource_name>.<action_name>(<optional_params_hash>,<optional_boolean>)
```

Where;
 * service_name is one of the (currently 3) services listed the [docs](http://support.rightscale.com/12-Guides/Self-Service#Self-Service_API)
 * optional_service_version is a string version of the service
 * resource_name is the resource you'd like to operate on (E.G. template, execution, operation, etc.)
 * action_name is the action you'd like to take (index, show, create, etc.)
 * optional_params_hash is the parameters you wish to pass to that action
 * optional_boolean if not supplied, a RestClient::Request will be created and
    executed and a RestClient::Response will be returned. If supplied and true
    a ready to execute RestClient::Request will be returned

#### Href Tokens
If the Href for a particular action contains tokens, any parameter passed to the
action with the same name as that token will be substituted in the request.

Take a [show](#show-a-template) action on the template resource for example.

The Href is;
```
/collections/:collection_id/templates/:id
```

Which contains the token :id.  In order to specify the template id while calling
the action, put it in as a parameter.

```
client.designer.templates.show(:id => "abc123")
```

The Href will have :id substituted with "abc123", and the id parameter will be
stripped from the body of the request.

#### Automatic Multipart
The client automatically URL encodes parameters and puts them in the body.  But
if you pass any Ruby object which has the methods "path" and "read" (basically
any file or IO resource) it'll assume you're performing a multipart request
and build the RestClient::Request accordingly.

See the [Multipart Detection](#multipart-detection) example..

### Some examples...

#### Authentication
Create the client with email and password
```
client = RightScaleSelfService::Client.new(
  :email => "user@domain.com",
  :password => "password",
  :selfservice_url => "https://selfservice-4.rightscale.com",
  :api_url => "https://us-4.rightscale.com"
)
```

Or with an access token
```
client = RightScaleSelfService::Client.new(
  :access_token => "access_token",
  :selfservice_url => "https://selfservice-4.rightscale.com",
  :api_url => "https://us-4.rightscale.com"
)
```

Or with a refresh token
```
client = RightScaleSelfService::Client.new(
  :refresh_token => "refresh_token",
  :selfservice_url => "https://selfservice-4.rightscale.com",
  :api_url => "https://us-4.rightscale.com"
)
```

#### Service Versions
You can specify which version of a service you want.  If you don't the "newest"
version will be used.

Get version 1.1 (which doesn't presently exist) of the "manager" service
```
client.manager("1.1")
```

Just use the latest version of the "manager" service
```
client.manager
```

#### Executing Actions

##### List operations
```
client.manager.operation.index
```

##### Show a template
```
client.designer.template.show(:id => "abc123")
```

##### Get RestClient::Request Instead of Executing Action
```
request = client.catalog.application.index({}, true)
request.execute
```

##### Format Errors
```
begin
  client.designer.template.compile(:source => some_source_file)
rescue RestClient::ExceptionWithResponse => e
  puts "Failed to compile the template"
  puts RightScaleSelfService::Api::Client.format_error(e)
end
```

##### Multipart Detection
This'll automatically format the payload for RestClient::Request as a multipart
request, rather than a standard request with a URL encoded body.
```
file = File.open("some.cat.rb", "rb")
client.designer.template.create(:source => file)
```
