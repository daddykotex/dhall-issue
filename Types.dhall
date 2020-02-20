let Zone
    : Type
    = < Prod | Sandbox >

let showZone
    : Zone → Text
    = λ(x : Zone) → merge { Prod = "prod", Sandbox = "sandbox" } x

let isSandbox
    : Zone → Bool
    = λ(x : Zone) → merge { Prod = False, Sandbox = True } x

let Env
    : Type
    = < QA2 | Dev >

let showEnv
    : Env → Text
    = λ(x : Env) → merge { Dev = "dev", QA2 = "qa2" } x

let ZonePath
    : Zone → Text → Text
    =   λ(zone : Zone)
      → λ(name : Text)
      → let zoneT = showZone zone in "${name}-${zoneT}"

let makeServiceHost =
        λ(env : Env)
      → λ(zone : Zone)
      → λ(k8sService : Text)
      → let zoneT = showZone zone

        let envT = showEnv env

        in  "${k8sService}-service.${zoneT}.${envT}.example.org"

let availableInBothZone
    : Zone → Bool
    = λ(zone : Zone) → merge { Prod = True, Sandbox = True } zone

let Service =
      { Type =
          { name : Text
          , k8sService : Text
          , availableIn : Zone → Bool
          , zonedPath : Zone → Text → Text
          }
      , default = { availableIn = availableInBothZone, zonedPath = ZonePath }
      }

let ServiceInstance
    : Type
    = { service : Service.Type, env : Env, zone : Zone }

in  { Service = Service
    , ServiceInstance = ServiceInstance
    , Zone = { Type = Zone, show = showZone, isSandbox = isSandbox }
    , Env = { Type = Env, show = showEnv }
    , makeServiceHost = makeServiceHost
    }
