let types = ./Types.dhall

let services = ./Services.dhall

let variables = ./Variables.dhall

let Text/concatSep =
      https://prelude.dhall-lang.org/Text/concatSep sha256:e4401d69918c61b92a4c0288f7d60a6560ca99726138ed8ebc58dca2cd205e58

let map =
      https://prelude.dhall-lang.org/List/map sha256:dd845ffb4568d40327f2a817eb42d1c6138b929ca758d50bc33112ef3c885680

let makeUrls =
        λ(env : types.Env.Type)
      → λ(zone : types.Zone.Type)
      → let instances = services.toServiceInstances env zone

        let toUrl =
                λ(instance : types.ServiceInstance)
              → let port = Natural/show variables.ServicesHostPort

                let zonedPath =
                      instance.service.zonedPath
                        instance.zone
                        instance.service.name

                in  "  ${instance.service.name}.base_url = \"http://${variables.FAIHostServer}:${port}/${zonedPath}\""

        in  map types.ServiceInstance Text toUrl instances

let buildZoneConfig =
        λ(env : types.Env.Type)
      → λ(zone : types.Zone.Type)
      → let sandboxUrls = makeUrls env zone

        let rawEnvT = types.Env.show env

        let zoneT = types.Zone.show zone

        let envT =
                    if types.Zone.isSandbox zone

              then  "${rawEnvT}-${zoneT}"

              else  rawEnvT

        in  ''
            ${envT} = {
            ${Text/concatSep "\n" sandboxUrls}
            }
            ''

let buildConfig =
        λ(env : types.Env.Type)
      → let sandbox = buildZoneConfig types.Env.Type.Dev types.Zone.Type.Sandbox

        let prod = buildZoneConfig types.Env.Type.Dev types.Zone.Type.Prod

        in  ''
            ${prod}
            ${sandbox}
            ''

in  buildConfig
