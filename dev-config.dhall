let types = ./Types.dhall

let buildConfig = ./Configuration.dhall

in  buildConfig types.Env.Type.Dev
