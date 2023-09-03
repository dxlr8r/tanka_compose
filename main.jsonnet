# SPDX-FileCopyrightText: 2023 Simen Strange <https://github.com/dxlr8r/kube.acme.sh>
# SPDX-License-Identifier: MIT

local lib      = import 'lib.jsonnet';
local mod      = import 'mod.jsonnet';
local default  = import 'default.jsonnet';
local manifest = import 'manifest.jsonnet';

function(context='default', config={}, patch=function(c,l,m)m)
{
  config:: default + config + { context: context },
  apiVersion: 'tanka.dev/v1alpha1',
  kind: 'Environment',
  metadata: {
    name: 'environments/default'
  },
  spec: {
    namespace: $.config.namespace,
    contextNames: [ context ]
  },
  data: (patch($.config, lib, manifest($.config, lib, mod)))
}
