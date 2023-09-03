# SPDX-FileCopyrightText: 2023 Simen Strange <https://github.com/dxlr8r/kube.acme.sh>
# SPDX-License-Identifier: MIT

{
  dx: import 'vendor/lib/dxsonnet/main.libsonnet'
}
+
{
  targetPort(port)::
    std.parseInt(self.dx.array.firstEl(std.split(std.toString(port), ":"))),
  svcPort(port)::
    std.parseInt(self.dx.array.lastEl(std.split(std.toString(port), ":"))),
}
