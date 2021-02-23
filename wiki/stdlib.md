# The Standard Library of Ido
> The ultra-extensible narrowing framework for Neovim. Originally inspired by the Emacs mode, Ido aims to make interactive matching a pleasure.

Ido is a narrowing *framework*, a library if you will. Therefore it comes with a standard library of commonly used functions which all users can agree on. And even if you don't agree on them, there are [advices](wiki/advices.md). ;)

First of all load the standard library module

```lua
local stdlib = require("ido.core.stdlib")
```

## `stdlib.cursor.increment_possible()`
Check if the current cursor position can be incremented. Return a boolean value based on whether it is possible or not.

## `stdlib.cursor.decrement_possible()`
Check if the current cursor position can be decremented. Return a boolean value based on whether it is possible or not.

## `stdlib.cursor.forward()`
Move the cursor forward a character

Advices in this function

- `shift_text_on_cursor_forward` Shift the text before and after the cursor to emulate a cursor movement

- `render_on_cursor_forward` After shifting the cursor, render

- `cursor_forward_impossible` Called if the cursor movement is impossible

## `stdlib.cursor.backward()`
Move the cursor backward a character

Advices in this function

- `shift_text_on_cursor_backward` Shift the text before and after the cursor to emulate a cursor movement

- `render_on_cursor_backward` After shifting the cursor, render

- `cursor_backward_impossible` Called if the cursor movement is impossible

## `stdlib.cursor.forward_word()`
Move the cursor forward a word

Advices in this function

- `shift_text_on_cursor_forward_word` Shift the text before and after the cursor to emulate a cursor movement

- `render_on_cursor_forward_word` After shifting the cursor, render

- `cursor_forward_word_impossible` Called if the cursor movement is impossible

## `stdlib.cursor.backward_word()`
Move the cursor backward a word

Advices in this function

- `shift_text_on_cursor_backward_word` Shift the text before and after the cursor to emulate a cursor movement

- `render_on_cursor_backward_word` After shifting the cursor, render

- `cursor_backward_word_impossible` Called if the cursor movement is impossible

## `stdlib.cursor.line_start()`
Move the cursor to the start of the query line

Advices in this function

- `shift_text_on_cursor_line_start` Shift the text before and after the cursor to emulate a cursor movement

- `render_on_cursor_line_start` After shifting the cursor, render

- `cursor_line_start_impossible` Called if the cursor movement is impossible

## `stdlib.cursor.line_end()`
Move the cursor to the end of the query line

Advices in this function

- `shift_text_on_cursor_line_end` Shift the text before and after the cursor to emulate a cursor movement

- `render_on_cursor_line_end` After shifting the cursor, render

- `cursor_line_end_impossible` Called if the cursor movement is impossible

## `stdlib.delete.forward()`
Delete a character forwards

Advices in this function

- `delete_forward_character` Emulate the deletion by changing the text after the cursor

- `get_results_on_delete_forward_character` After deleting the character, get the results

- `delete_forward_impossible` Called if the deletion is impossible

## `stdlib.delete.backward()`
Delete a character backwards

Advices in this function

- `delete_backward_character` Emulate the deletion by changing the text before the cursor

- `get_results_on_delete_backward_character` After deleting the character, get the results

- `delete_backward_impossible` Called if the deletion is impossible

## `stdlib.items.next()`
Switch the selected item to the next item and wrap around if needed

Advices in this function

- `next_item_not_found` There are less than two items/results

- `switch_to_next_item` Switch to the next item and wrap around the ends if needed

- `render_on_next_item` After switching to the next item, render

## `stdlib.items.prev()`
Switch the selected item to the previous item and wrap around if needed

Advices in this function

- `previous_item_not_found` There are less than two items/results

- `switch_to_previous_item` Switch to the previous item and wrap around the ends if needed

- `render_on_previous_item` After switching to the previous item, render
