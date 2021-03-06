%%--------------------------------------------------------------------
%% Copyright (c) 2013-2017 EMQ Enterprise, Inc. (http://emqtt.io)
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------
-module (emq_auth_ldap_config).

-include("emq_auth_ldap.hrl").

-export ([register/0, unregister/0]).

register() ->
    clique_config:load_schema([code:priv_dir(?APP)], ?APP),
    register_formatter(),
    register_config().

unregister() ->
    unregister_formatter(),
    unregister_config(),
    clique_config:unload_schema(?APP).

register_formatter() ->
    Ignore = ["auth.ldap.auth_dn", "auth.ldap.password_hash"],
    [clique:register_formatter(cuttlefish_variable:tokenize(Key), fun formatter_callback/2) || Key <- keys() -- Ignore].

formatter_callback([_, _, Key], Params) ->
    proplists:get_value(list_to_atom(Key), Params).

unregister_formatter() ->
    [clique:unregister_formatter(cuttlefish_variable:tokenize(Key)) || Key <- keys()].

register_config() ->
    Keys = keys(),
    [clique:register_config(Key , fun config_callback/2) || Key <- Keys],
    clique:register_config_whitelist(Keys, ?APP).

config_callback([_, _, "auth_dn"], Value) ->
    application:set_env(?APP, auth_dn, Value),
    " successfully\n";
config_callback([_, _, "password_hash"], Value) ->
    application:set_env(?APP, password_hash, Value),
    " successfully\n";

config_callback([_, _, Key0], Value) ->
    Key = list_to_atom(Key0),
    {ok, Env} = application:get_env(?APP, ldap),
    application:set_env(?APP, ldap, lists:keyreplace(Key, 1, Env, {Key, Value})),
    " successfully\n".

unregister_config() ->
    Keys = keys(),
    [clique:unregister_config(Key) || Key <- Keys],
    clique:unregister_config_whitelist(Keys, ?APP).

keys() ->
    ["auth.ldap.servers",
     "auth.ldap.port",
     "auth.ldap.bind_dn",
     "auth.ldap.bind_password",
     "auth.ldap.timeout",
     "auth.ldap.auth_dn",
     "auth.ldap.password_hash"].
