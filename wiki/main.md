# Main module
This document will explain the API of the `ido.core.main` module.

First of all
```lua
-- Not really needed, however it is refered in this document so include it
local ido = require("ido")

-- The main module
local main = require("ido.core.main")
```

## Async
The event loop of Ido is partially asynchronous. Specifically the code which deals with the filtering of items.

### `main.timer`
The Libuv timer which grants us asynchronous powers in Neovim. (`:h vim.loop`)

### `main.async(ACTION)`
The helper function which abstracts away the asynchronous mechanisms behind a simple interface.

- `ACTION` The function which will be executed asynchronously

## `main.get_results()`
Acts as a wrapper around the customized `fzy.filter()` function.

It is generally recommended to call this function as `main.async(main.get_results)` whenever you can. The reason it is not non-blocking by default is because the `main.accept_suggestion()` functions requires a blocking filtering in a non-advice manner.

There are several [advices](advices.md) in this function

- `filter_on_get_results` Filter the items when this function is called

- `get_results_for_empty_query` Called if the query is empty

- `none_found_after_get_results` Called if no results were found after filtering the items

- `single_result_after_get_results` Called if there is only one result after filtering the items

- `render_after_get_results` Render after getting the results

## `main.accept_selected()`
Accept the selected item (if any).

Advices in this function

- `no_results_on_accept_selected` Called if there are no results to accept

- `exit_on_accept_selected` Exit after selecting the result

- `clear_query_after_accept_selected` Clear the query and suggestion after accepting the result

## `main.accept_suggestion`
Accept the suggestion (if any).

Advices in this function

- `no_suggestion_on_accept_suggestion` Called if there is no suggestion

- `single_result_on_accept_suggestion` Called if there is only one suggestion

- `fuse_query_on_accept_suggestion` Fuse the suggestion with the query

- `get_results_after_accept_suggestion` Get the results after accepting the suggestion

- `single_result_after_accept_suggestion` Called if there is one result after accepting the suggestion

## `main.insert(STRING)`
Insert `STRING` at the cursor.

Advices in this function

- `insert_string` Insert the string

- `get_results_after_insert_string` Get results after inserting the string

## `main.loop()`
The event loop of Ido.

What it does:
- Take a key as input. (`:h getchar()`)
- Check if the key is bound to anything
- Execute that mapping
- If a mapping was not found, insert the key (`main.insert()`)
- Loop while `ido.sandbox.variables.looping` is "truthy"

## `main.define_keys(KEYS)`
Define keys as given in the `KEYS` table

See the [Options and variables](settings.md) for more information on keybindings.

## `main.exit()`
Stop the event loop of Ido, and get rid of the Ido UI.

## `main.start(OPTIONS)`
The main API to Ido. It starts the Ido interface.

`OPTIONS` The table of options and variables supplied to Ido. It will go through each and every key in the table. If said key is a variable, change the value of the variable in the sandbox. Same goes for if it were an option. Basically it acts as a common interface for both variables and options, since there are no common names between them.

It returns the selected item or `""`.

### What is `ido.start()` then?
This is just an alias to the `main.start()` function. It is there because I envision the `lua/ido.lua` file to be the goto file for anybody wishing to use Ido. Also it is much shorter to type.

```lua
require("ido").start({
   -- Blah blah blah
})

require("ido.core.main").start({
   -- Blah blah blah
})
```

## Further information
At this point there is not much left which you need to know to just use Ido. However if you went through the advices documentation, I would recommned going though the documentation for the [Standard library of Ido](stdlib.md), considering you seem to be in the mood of *really* customizing Ido to your liking. The standard library won't teach you anything about customization per-say, but it will be useful to have in your arsenal, **especially** if you read up on advices.
