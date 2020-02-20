let types = ./Types.dhall

let services = ./Services.dhall

let Text/concatSep =
      https://prelude.dhall-lang.org/Text/concatSep sha256:e4401d69918c61b92a4c0288f7d60a6560ca99726138ed8ebc58dca2cd205e58

let map =
      https://prelude.dhall-lang.org/List/map sha256:dd845ffb4568d40327f2a817eb42d1c6138b929ca758d50bc33112ef3c885680

let concatMap =
      https://prelude.dhall-lang.org/List/concatMap sha256:3b2167061d11fda1e4f6de0522cbe83e0d5ac4ef5ddf6bb0b2064470c5d3fb64

let variables = ./Variables.dhall

let makeServiceBackendName
    : types.ServiceInstance → Text
    =   λ(instance : types.ServiceInstance)
      → let zone = types.Zone.show instance.zone

        in  "${instance.service.name}-${zone}-service"

let makeServiceBackend
    : types.ServiceInstance → Text
    =   λ(instance : types.ServiceInstance)
      → let backendName = makeServiceBackendName instance

        let serviceHost =
              types.makeServiceHost
                instance.env
                instance.zone
                instance.service.name

        let zonedPath =
              instance.service.zonedPath instance.zone instance.service.name

        in  ''
            backend ${backendName}
                mode http
                option httpchk GET /admin/health HTTP/1.1\r\nHost:\ ${serviceHost}
                # k8s service will dispatch based on the Host header
                # so we set it to the server name, which is the host
                http-request set-header Host ${serviceHost}

                #rewrite the path to remove the service prefix
                http-request set-path %[path,regsub(^/${zonedPath}/?,/)]

                server ${serviceHost} ${serviceHost}:80 check
            ''

let makeServiceFrontend
    : Natural → List types.ServiceInstance → Text
    =   λ(hostPort : Natural)
      → λ(instances : List types.ServiceInstance)
      → let useParts
            : List Text
            = map
                types.ServiceInstance
                Text
                (   λ(instance : types.ServiceInstance)
                  → let backendName = makeServiceBackendName instance

                    in  "    use_backend ${backendName} if { path_beg /${instance.service.name}/ }"
                )
                instances

        let allUsePart
            : Text
            = Text/concatSep "\n" useParts

        let begin =
              ''
              frontend frontend-proxy
                  bind :${Natural/show hostPort}
                  mode http
                  option httplog''

        in  ''
            ${begin}
            ${allUsePart}
            ''

let makeMysql
    : Natural → Text → Natural → Text
    =   λ(hostPort : Natural)
      → λ(host : Text)
      → λ(port : Natural)
      → ''
        listen mysql-server
            bind :${Natural/show hostPort}
            mode tcp
            server mysql-1 ${host}:${Natural/show port} check
        ''

let general =
      ''
      # this file is generated with `dhall`

      global
          log stdout  format raw  local0  debug

      defaults
          log global
          retries 2
          timeout connect 3000
          timeout server 5000
          timeout client 5000
      ''

let buildHAProxyCfg =
        λ(env : types.Env.Type)
      → let zones = [ types.Zone.Type.Prod, types.Zone.Type.Sandbox ]

        let instances =
              concatMap
                types.Zone.Type
                types.ServiceInstance
                (   λ(zone : types.Zone.Type)
                  → services.toServiceInstances env zone
                )
                zones

        let envT = types.Env.show env

        let mysql =
              makeMysql
                variables.MySQLHostPort
                "dbhost.prod.${envT}.example.org"
                3306

        let backends
            : Text
            = let useParts
                  : List Text
                  = map types.ServiceInstance Text makeServiceBackend instances

              in  Text/concatSep "\n" useParts

        let frontend = makeServiceFrontend variables.ServicesHostPort instances

        let config =
              ''
              ${general}
              ${mysql}
              ${frontend}
              ${backends}
              ''

        in  config

in  buildHAProxyCfg
