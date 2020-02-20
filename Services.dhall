let types = ./Types.dhall

let filter =
      https://prelude.dhall-lang.org/List/filter sha256:8ebfede5bbfe09675f246c33eb83964880ac615c4b1be8d856076fdbc4b26ba6

let map =
      https://prelude.dhall-lang.org/List/map sha256:dd845ffb4568d40327f2a817eb42d1c6138b929ca758d50bc33112ef3c885680

let availableInProd =
      λ(zone : types.Zone.Type) → merge { Prod = True, Sandbox = False } zone

let availableInSandbox =
      λ(zone : types.Zone.Type) → merge { Prod = False, Sandbox = True } zone

let bulkImport =
        types.Service::{
        , name = "bulkimport"
        , k8sService = "bulkimport-fileloader"
        }
      ⫽ { availableIn = availableInSandbox }

let aiotService =
      types.Service::{
      , name = "aiotservice"
      , k8sService = "aiot-studio-service"
      }

let services
    : List types.Service.Type
    = [ types.Service::{ name = "admintool", k8sService = "admintool-service" }
      , types.Service::{
        , name = "aiotservice"
        , k8sService = "aiot-studio-service"
        }
      , types.Service::{
        , name = "authentication"
        , k8sService = "authentication-service"
        }
      , types.Service::{ name = "billing", k8sService = "billing-service" }
      , types.Service::{ name = "blobstore", k8sService = "blob-store-service" }
      , bulkImport
      , types.Service::{
        , name = "contractenforcement"
        , k8sService = "contract-enforcement-service"
        }
      , types.Service::{
        , name = "customerlog"
        , k8sService = "customer-log-service"
        }
      , types.Service::{
        , name = "dashboardreporting"
        , k8sService = "dashboard-reporting-service"
        }
      , types.Service::{
        , name = "dashboards"
        , k8sService = "dashboards-service"
        }
      , types.Service::{ name = "goto", k8sService = "goto-service" }
      , types.Service::{ name = "ingestion", k8sService = "ingestion-service" }
      , types.Service::{ name = "kpis", k8sService = "kpis-service" }
      ,   types.Service::{ name = "modeler", k8sService = "modeler-service" }
        ⫽ { availableIn = availableInProd }
      , aiotService ⫽ { name = "parametrizeddatasets" }
      , types.Service::{
        , name = "connectors"
        , k8sService = "pluggable-connectors-service"
        }
      , types.Service::{
        , name = "restitution"
        , k8sService = "restitution-service"
        }
      , types.Service::{
        , name = "scheduledanalytics"
        , k8sService = "scheduled-analytics-service"
        }
      , types.Service::{
        , name = "labeleddataset"
        , k8sService = "labeled-datasets-service"
        }
      , types.Service::{ name = "sparkservice", k8sService = "spark-service" }
      , types.Service::{ name = "toggle", k8sService = "toggle-service" }
      ]

let serviceInstances
    : types.Env.Type → types.Zone.Type → List types.ServiceInstance
    =   λ(env : types.Env.Type)
      → λ(zone : types.Zone.Type)
      → let zoneMatch
            : types.Service.Type → Bool
            = λ(service : types.Service.Type) → service.availableIn zone

        let filtered
            : List types.Service.Type
            = filter types.Service.Type zoneMatch services

        let instances =
              map
                types.Service.Type
                types.ServiceInstance
                (   λ(service : types.Service.Type)
                  → { service = service, zone = zone, env = env }
                )
                filtered

        in  instances

in  { services = services, toServiceInstances = serviceInstances }
