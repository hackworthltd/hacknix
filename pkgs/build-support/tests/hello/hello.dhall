let types = ./types.dhall

in  let int = 3 : types.Int

	in  let str = "Hi" : types.Str in { str = str, int = int }