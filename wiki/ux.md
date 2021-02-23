# UX
This will address the `layout` option of Ido, which you have probably got a glimpse of in [Settings and options](wiki/settings.md).

## How it is documented
`NAME` `DOCUMENTATION`. `TYPE` (`DEFAULT VALUE`)

## Parameters
- `results_start` The UX decoration before the start of the results. String (`"{"`)

- `results_end` The UX decoration after the end of the results. String (`"}"`)

- `suggest_start` The UX decoration before the start of the suggestion. String (`"["`)

- `suggest_end` The UX decoration after the end of the suggestion. String (`"]"`)

- `results_separator` The UX decoration separating the results. String (`" | "`)

- `height` The height of the Ido interface. Number (`2`)

- `dynamic_resize` Whether Ido should dynamically resize to take up the least number of rows limited by `height`. Boolean (`false`)

## Custom layouts
First load the ido module

```lua
local ido = require("ido")
```

### Rules
- The name of the layout cannot be `setup` or `default`

### `ido.layouts.setup()`
There is a helper function called `ido.layouts.setup()` which you can use. Like with the `ido.setup()` function, here are the differences between the two approaches

```lua
-- With ido.layouts.setup()

-- Create a minimalist layout for Ido
ido.layouts.setup("minimal", {
   results_start = "",
   results_end = "",

   height = 1,
})
```

```lua
-- Without ido.layouts.setup()

-- Create a minimalist layout for Ido
-- Here you have to set all the decorations, no automatic fallbacking like in ido.layouts.setup()

ido.layouts.minimal = {
   results_start = "",
   results_end = "",

   suggest_start = "[",
   suggest_end = "]",

   results_separator = " | ",

   height = 1,
   dynamic_resize = false,
}
```

### Use the layout
- Set the `ido.options.layout` option to `ido.layouts.minimal`
- To change the sandboxed option, set the `ido.sandbox.options.layout` option

In the `ido.start()` function it can accept the layout parameter in two ways

- The name of the layout
- The layout as the table itself

```lua
ido.start({
   layout = "minimal" -- The name of the layout

   layout = ido.layouts.minimal -- The layout table itself

   -- Other code
})
```

## Another Example
Let's implement a vertical layout

```lua
ido.layouts.setup("vertical", {
   results_start = "\n -> ",
   results_end = "",

   results_separator = "\n    ",

   height = 10,
})
```

## Change granulated settings in a layout
Wish to change some specific part of a layout without creating a new one? No problem.

Let's make dynamic resize true in our minimal layout

```lua
ido.layouts.minimal.dynamic_resize = true
```

When you define a layout, it essentially creates a table in the `ido.layouts` parent table. Said table contains the decorations and UX settings you provided. Therefore you can change anything at a moment's notice.

Lastly, if you haven't already, read the [Settings and options](wiki/settings.md) documentation.
