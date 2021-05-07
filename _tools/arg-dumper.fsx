// Execute it like:
// dotnet fsi arg-dumper.fsx pass your args here

open System

let author = "Dominik Janiec"
let year = "12021"
let version = Version(1, 0)


type ArgStats =
    { maxLength : int
    ; count : int
    }

type ArgData =
    { value : string
    ; length : int
    ; order : int
    }


let headerLines argv =
    [ ""
    ; sprintf "ArgDumper - %s (%s v. %A)" author year version
    ; String.replicate 69 "="
    ; ""
    ; sprintf "Executed with %d arguments from a path: '%s'"
        <|| (Array.length argv, Environment.CurrentDirectory)
    ]

let makeLine stats data =
    let measure (x: int) =
        let value =
            float (x)
                |> log10
                |> Math.Ceiling

        int (value)

    let toStringPadded x size =
        x.ToString().PadLeft(size)

    let countPart =
        measure stats.count
            |> toStringPadded data.order

    let lenghtPart =
        measure stats.maxLength
            |> toStringPadded data.length

    sprintf
        "   %s. [%s|%d] -> '%s'"
        countPart
        lenghtPart
        stats.maxLength
        data.value

let bodyLines argv =
    let toData idx arg =
        { value = arg
        ; length = String.length arg
        ; order = idx + 1
        }

    let makeStatistics dataItems =
        let maxItemsLength =
            let lengths =
                dataItems
                    |> List.map (fun x -> x.length)

            (-1) :: lengths
                |> List.max

        { maxLength = maxItemsLength
        ; count = List.length dataItems
        }

    let dataItems =
        Array.toList argv
            |> List.mapi toData

    let mapper =
        makeStatistics dataItems
            |> makeLine

    List.map mapper dataItems

let withLastEmptyLine lines =
    match List.rev lines |> List.head with
        | "" -> lines
        | _ -> lines @ [ "" ]


let argv = fsi.CommandLineArgs
headerLines argv @ bodyLines argv
    |> withLastEmptyLine
    |> String.concat Environment.NewLine
    |> printf "%s"

Environment.Exit 0
