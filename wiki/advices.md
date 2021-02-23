# Advices
This is where you go from *"Oh you can change some options and layouts of Ido"* to *"What?! This is practically illegal! No one should hold this much power!"*

Advices are a concept which has its origins in the [Lisp](https://en.wikipedia.org/wiki/Lisp_(programming_language)) programming language. It is essentially a method which allows us to add custom behaviours to specific code inside other functions. The custom behaviour can execute **before** the original behaviour, **after** the original behaviour, and lastly it can **overwrite** the original behaviour.

If that doesn't blow your mind yet, don't worry. There are tons of examples in this document which will attempt to show you the powers this mechanism grants to you.

## Logic
***NOTE:*** This is my implementation of advices, so it differs from the Lisp equivalent.

```
+----------+
|  Advice  |     Modify the         Advice application
|          |  behaviour of Code  +----------------------+
| +------+ | <------------------ | Custom functionality |
| | Code | |                     +----------------------+
| +------+ |
+----------+
```

- There is some code wrapped in an advice.
- You wish to have custom functionality associated with the code without changing the code.
- You *advice* the code to have your custom functionality.
- The code remains unchanged, however the advice wrapped around it does not.
- The advice wrapped around it will listen to your advice.

## The advices API of Ido
First of all load the advices module

```lua
local advice = require("ido.core.advice")
```

There are three functions associated with advices in Ido.

### `advice.setup(NAME, [, ACTION])`
Wrap an advice around some code.

- `NAME` This is the unique name given to the advice which wraps around the code. It is used for identification purposes.

- `ACTION` The code it wraps around. It takes a function as an argument. It defaults to `function () end` (lambda).

***NOTE:*** The name of an advice can *never* be `setup`, `set`, or `clear`.

### `advice.set(TARGET, BEHAVIOUR, ACTION, [, PERMANENT])`
Set the advice.

- `TARGET` The name of the advice wrapper you wish to target.

- `ACTION` The code it wraps around. It takes a function as an argument.

- `BEHAVIOUR` How the advice behaves. It can have one of three values -- `before`, `after` and `overwrite`. Their effect is intuitive. If it is `before`, the `ACTION` will be executed before the code the target of the advice wraps around. For `after`, it executes after. For `overwrite` It overwrites the default code of the target.

- `PERMANENT` Whether the advice is permanent or not. A temporary advice will get removed after Ido exits, a permanent advice won't. Temporary advices take precedence over permanent ones with the same name. Defaults to `true`.

### `advice.clear(TARGET, BEHAVIOUR, [, PERMANENT])`
Clear the advice.

- `TARGET` The name of the advice wrapper you wish to target.

- `BEHAVIOUR` The behaviour you wish to clear. Same as `advice.set()`.

- `PERMANENT` Whether the advice is permanent or not. Same as `advice.set()`.

## Examples
I am bad at explaining things, so most probably you have not understood a single thing from the jargon I put up above. Lots and lots of examples should fix that.

```lua
function sayHello()

   advice.setup(

      -- The unique identifier for the advice wrapper
      "say_hello_to_the_world",

      -- The default function
      function ()
         print("Hello World!")
      end)

   -- Outside the "say_hello_to_the_world" advice
   print("Yeah")
end

sayHello() -- Say hello to the world
```

The output of the code.

```console
$ lua test.lua
Hello World!
Yeah
```

Let's change what the code results in **without** making a *single* change to the `sayHello()` function.

```lua
-- sayHello function definition

-- Custom functionality to execute after the default action
advice.set(

   -- Apply this to the the advice which was setup with the name "say_hello_to_the_world"
   "say_hello_to_the_world",

   -- Apply this function after the default action has executed
   "after",

   -- The action
   function ()
      print("This is after the default action")
   end
)

sayHello() -- Say hello to the world
```

The output of the advised code.

```console
$ lua test.lua
Hello World!
This is after the default action
Yeah
```

Take a step back and understand the consequences of what you just did. You changed what a piece of code does **without changing the code directly**. It didn't change the original functionality. It did print `Hello World!`. However *after* doing that it executed your custom code. Note how it printed `Yeah` after printing `This is after the default action`. This is because the `print("Yeah")` was outside the advice when using `advice.setup()`. Therefore as far as the advice is concerned, that code does not exist.

Let's see what the `before` behaviour does. You probably guessed it by now.

```lua
-- sayHello function definition and the after advice

-- Custom functionality to execute before the default action
advice.set(

   -- Apply this to the the advice which was setup with the name "say_hello_to_the_world"
   "say_hello_to_the_world",

   -- Apply this function before the default action has executed
   "before",

   -- The action
   function ()
      print("I wish to say Hello")
   end
)

sayHello() -- Say hello to the world
```

The output of the new advised code.

```console
$ lua test.lua
I wish to say Hello
Hello World!
This is after the default action
Yeah
```

The most powerful (imo) type of advice you can have is the `overwrite` behaviour. Let's check that out.

```lua
-- sayHello function definition, the after advice and the before advice

-- Custom functionality to overwrite the default action
advice.set(

   -- Apply this to the the advice which was setup with the name "say_hello_to_the_world"
   "say_hello_to_the_world",

   -- Overwrite the default action
   "overwrite",

   -- The action
   function ()
      print("Hello!")
   end
)

sayHello() -- Say hello to the world
```

The output of the new advised code.

```console
$ lua test.lua
I wish to say Hello
Hello!
This is after the default action
Yeah
```

This is cool and all but how do you *remove* an advice? Let's remove the advice **before** the code.

```lua
-- Get rid of the advice before

advice.clear(

   -- Apply this to the the advice which was setup with the name "say_hello_to_the_world"
   "say_hello_to_the_world",

   -- Remove the "before" advice
   "before",
)

sayHello() -- Say hello to the world
```

The output of the new advised code.

```console
$ lua test.lua
Hello!
This is after the default action
Yeah
```

That's how you get rid of an advice. Let's remove all custom functionality just for giggles.

```lua
-- Get rid of the advice before

advice.clear("say_hello_to_the_world", "overwrite") -- Clear the overwrite advice
advice.clear("say_hello_to_the_world", "after") -- Clear the after advice

sayHello() -- Say hello to the world
```

The output of the new advised code.

```console
$ lua test.lua
Hello World!
Yeah
```

Back to normal now!

A thing of concern: Make sure you get the `PERMANENT` flag right! It didn't matter in the code above because everything was permanent. But remember that you can't clear a permanent advice when it is actually a temporary advice, and vice versa.

I really hope all of these helped you wrap (hehe) your head around the concept of advices. Even if you don't fully understand at the moment, there is no need to fret. You will get the hang of it after you *try out* the advice module **for yourself**.

## Further information
- See the [Standard library](wiki/stdlib.md) and the [Main module](wiki/main.md) documentation to find out the way to *really* customize Ido and make its experience your own.
- Learn Lisp. Advices were originally created in Lisp. Trust me when I say my implementation is an ad-hoc solution. Use Lisp for the true experience.
