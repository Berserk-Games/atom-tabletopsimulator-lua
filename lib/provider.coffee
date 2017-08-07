module.exports =
  selector: '.source.tts.lua'
  disableForSelector: '.source.tts.lua .comment'
  filterSuggestions: true

  # This will take priority over the default provider, which has a priority of 0.
  # `excludeLowerPriority` will suppress any providers with a lower priority
  # i.e. The default provider will be suppressed
  inclusionPriority: 2
  excludeLowerPriority: true

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
    new Promise (resolve) ->
      # Find your suggestions here
      suggestions = []

      # Substring up until this position
      line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])

      # Hacks. Make Lua nicer.
      if atom.config.get('tabletopsimulator-lua.hacks.incrementals') != 'off'
        matches = line.match(/^\s*([\w.:\[\]"'#]+)(\s*)([-+*\u002f])=(\s*)(.*)$/)
        if matches
          identifier = matches[1]
          spacing    = matches[2]
          if spacing == '' and atom.config.get('tabletopsimulator-lua.hacks.incrementals') == 'spaced'
            spacing = ' '
          operator   = matches[3]
          postfix    = matches[5]
          if postfix != ''
            postfix += '\n'
          resolve([{
            snippet: spacing + '=' + spacing + identifier + spacing + operator + spacing + postfix + '$1'
            displayText: '=' + spacing + identifier + spacing + operator + spacing + postfix
            replacementPrefix: matches[2] + matches[3] + '=' + matches[4] + matches[5]
            neverFilter: true
          }])
          return

      #console.log scopeDescriptor.scopes[1]
      if scopeDescriptor.scopes[1] == "keyword.operator.lua" || scopeDescriptor.scopes[1] == "string.quoted.double.lua" || scopeDescriptor.scopes[1] == "string.quoted.single.lua"
        resolve([])
        return

      # Are we in the global script or an object script?
      global_script = editor.getPath().endsWith('-1.ttslua')

      # Split line into bracket depths
      depths = {}
      depth = 0
      depths[depth] = ""
      returned_to_depth = ""
      returning_from = ""
      bracket_lookup = {"]":"[]", "}":"{}", ")":"()"}
      for c in line
        if c.match(/[\(\{\[]/) #open bracket
            depth += 1
            if depth of depths
              returned_to_depth = true
              returning_from = " "
            else
              depths[depth] = ""
        else if c.match(/[\)\}\]]/) #close bracket
            depth -= 1
            if depth of depths
              returned_to_depth = true
              returning_from = bracket_lookup[c]
            else
              depths[depth] = ""
        else
          if returned_to_depth
            depths[depth] += returning_from   #indicator of where we just were
            returned_to_depth = false
          depths[depth] += c
      depths[depth] += returning_from

      # Split relevant depth into tokens
      tokens = depths[depth].split(".")
      this_token = ""           # user is currently typing
      this_token_intact = true  # is it just alphanumerics?
      previous_token = ""       # last string before a '.'
      previous_token_2 = ""     # ...and the one before that
      if tokens.length > 0
        this_token = tokens.slice(-1)[0]
        if this_token.match(/[^a-zA-Z0-9_]+/)
          this_token_intact = false
        if tokens.length > 1
          for part in tokens.slice(-2)[0].split(/[^a-zA-Z0-9_\[\]\{\}\(\)]+/).reverse() #find the last alphanumeric string
            if part != ""
              previous_token = part
              break
          if tokens.length > 2
            for part in tokens.slice(-3)[0].split(/[^a-zA-Z0-9_\[\]\{\}\(\)]+/).reverse()
              if part != ""
                previous_token_2 = part
                break

      #console.log tokens
      #console.log this_token, "(", this_token_intact, ") <- ", previous_token, " <- ", previous_token_2

      if prefix == "." and previous_token.match(/^[0-9]$/)
        # If we're in the middle of typing a number then suggest nothing on .
        resolve([])
        return
      else if (line.endsWith(" else") || line.endsWith(" elseif") || line.endsWith(" end") || line == "end")
        # Short circuit some common lua keywords
        resolve([])
        return

      # Section: Control blocks
      if (line.endsWith(" do"))
        suggestions = [
          {
            snippet: 'do\n\t$1\nend'
            displayText: 'do...end'
          },
        ]
      else if (line.endsWith(" then") and not line.includes("elseif"))
        suggestions = [
          {
            snippet: 'then\n\t$1\nend'
            displayText: 'then...end'
          },
        ]
      else if (line.endsWith(" repeat"))
        suggestions = [
          {
            snippet: 'repeat\n\t$1\nuntil $2'
            displayText: 'repeat...until'
          },
        ]
      else if (line.includes("function") && line.endsWith(")"))
        function_name = this_token.substring(0, this_token.lastIndexOf("("))
        function_name = function_name.substring(function_name.lastIndexOf(" ") + 1)
        function_name = function_name + atom.config.get('tabletopsimulator-lua.style.coroutinePostfix')
        suggestions = [
          {
            snippet: '\n\t$1\nend'
            displayText: 'function...end'
          },
          {
            snippet: '\n\tfunction ' + function_name + "()\n\t\t$1\n\t\treturn 1\n\tend\n\tstartLuaCoroutine(self, '" + function_name + "')\nend"
            displayText: 'function...coroutine...end'
          },
        ]

      # Section: Global object
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "Global") || line.endsWith("Global.") || (previous_token == "Global" && this_token_intact)
        suggestions = [
          # Member Variables
          {
            #text: 'script_code' # OR
            snippet: 'script_code'
            displayText: 'script_code' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            description: 'Returns the Global Lua script.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#script_code' # (optional)
            #replacementPrefix: 'so' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
          },
          {
            snippet: 'script_state'
            displayText: 'script_state'
            type: 'property'
            leftLabel: 'string'
            description: 'Returns the Global saved Lua script state.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#script_state'
          },
          # Functions
          {
            snippet: 'call(${1:string|function_name}, ${2:Table|parameters})'
            displayText: 'call(string function_name, Table parameters)'
            type: 'function'
            leftLabel: 'variable'
            description: 'Calls a Lua function owned by the Global Script and passes an optional Table as parameters to the function.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#call'
          },
          {
            snippet: 'getTable(${1:string|table_name})'
            displayText: 'getTable(string table_name)'
            type: 'function'
            leftLabel: 'Table'
            description: 'Gets a Lua Table for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getTable'
          },
          {
            snippet: 'getVar(${1:string|variable_name})'
            displayText: 'getVar(string variable_name)'
            type: 'function'
            leftLabel: 'variable'
            description: 'Gets a Lua variable for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getVar'
          },
          {
            snippet: 'setTable(${1:string|table_name}, ${2:Table|table})'
            displayText: 'setTable(string table_name, Table table)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets a Lua Table for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setTable'
          },
          {
            snippet: 'setVar(${1:string|variable_name}, ${2:variable|value})'
            displayText: 'setVar(string variable_name, variable value)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets a Lua variable for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setVar'
          },
        ]

      # Section: math Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "math") || line.endsWith("math.") || (previous_token == "math" && this_token_intact)
        suggestions = [
          # Member Variables
          {
            snippet: 'huge'
            displayText: 'huge'
            type: 'constant'
            leftLabel: 'float'
            description: 'The value HUGE_VAL, a value larger than or equal to any other numerical value.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.huge'
          },
          {
            snippet: 'pi'
            displayText: 'pi'
            type: 'constant'
            leftLabel: 'float'
            description: 'The value of p.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.pi'
          },
          # Functions
          {
            snippet: 'abs(${1:float|x})'
            displayText: 'abs(float x)'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns the absolute value of x.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.abs'
          },
          {
            snippet: 'acos(${1:float|x})'
            displayText: 'acos(float x)'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns the arc cosine of x (in radians).'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.acos'
          },
          {
            snippet: 'asin(${1:float|x})'
            displayText: 'asin(float x)'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns the arc sine of x (in radians).'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.asin'
          },
          {
            snippet: 'atan(${1:float|x})'
            displayText: 'atan(float x)'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns the arc tangent of x (in radians).'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.atan'
          },
          {
            snippet: 'atan2(${1:float|y}, ${2:float|x})'
            displayText: 'atan2(float y, float x)'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns the arc tangent of y/x (in radians), but uses the signs of both parameters to find the quadrant of the result.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.atan2'
          },
          {
            snippet: 'ceil(${1:float|x})'
            displayText: 'ceil(float x)'
            type: 'function'
            leftLabel: 'int'
            description: 'Returns the smallest integer larger than or equal to x.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.ceil'
          },
          {
            snippet: 'cos(${1:float|x})'
            displayText: 'cos(float x)'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns the cosine of x (assumed to be in radians).'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.cos'
          },
          {
            snippet: 'cosh(${1:float|x})'
            displayText: 'cosh(float x)'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns the hyperbolic cosine of x.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.cosh'
          },
          {
            snippet: 'deg(${1:float|x})'
            displayText: 'deg(float x)'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns the angle x (given in radians) in degrees.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.deg'
          },
          {
            snippet: 'exp(${1:float|x})'
            displayText: 'exp(float x)'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns the value e^x.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.exp'
          },
          {
            snippet: 'floor(${1:float|x})'
            displayText: 'floor(float x)'
            type: 'function'
            leftLabel: 'int'
            description: 'Returns the largest integer smaller than or equal to x.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.floor'
          },
          {
            snippet: 'fmod(${1:float|x}, ${2:float|y})'
            displayText: 'fmod(float x, float y)'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns the remainder of the division of x by y that rounds the quotient towards zero.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.fmod'
          },
          {
            snippet: 'frexp(${1:float|x})'
            displayText: 'frexp(float x)'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns m and e such that x = m2^e, e is an integer and the absolute value of m is in the range [0.5, 1) (or zero when x is zero).'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.frexp'
          },
          {
            snippet: 'ldexp(${1:float|m}, ${2:int|e})'
            displayText: 'ldexp(float m, int e)'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns m2^e (e should be an integer).'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.ldexp'
          },
          {
            snippet: 'log(${1:float|x})'
            displayText: 'log(float x [, base])'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns the logarithm of x in the given base.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.log'
          },
          {
            snippet: 'max(${1:float|x}, ${2:...})'
            displayText: 'max(float x, ...)'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns the maximum value among its arguments.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.max'
          },
          {
            snippet: 'min(${1:float|x}, ${2:...})'
            displayText: 'min(float x, ...)'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns the minimum value among its arguments.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.min'
          },
          {
            snippet: 'modf(${1:float|x})'
            displayText: 'modf(float x)'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns two numbers, the integral part of x and the fractional part of x.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.modf'
          },
          {
            snippet: 'pow(${1:float|x}, ${2:float|y})'
            displayText: 'pow(float x, float y)'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns x^y. (You can also use the expression x^y to compute this value.)'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.pow'
          },
          {
            snippet: 'rad(${1:float|x})'
            displayText: 'rad(float x)'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns the angle x (given in degrees) in radians.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.rad'
          },
          {
            snippet: 'random()'
            displayText: 'random([m [, n]])'
            type: 'function'
            leftLabel: 'float'
            description: 'This function is an interface to the simple pseudo-random generator function rand provided by Standard C.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.random'
          },
          {
            snippet: 'randomseed(${1:int|x})'
            displayText: 'randomseed(int x)'
            type: 'function'
            description: 'Sets x as the "seed" for the pseudo-random generator: equal seeds produce equal sequences of numbers.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.randomseed'
          },
          {
            snippet: 'sin(${1:float|x})'
            displayText: 'sin(float x)'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns the sine of x (assumed to be in radians).'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.sin'
          },
          {
            snippet: 'sinh(${1:float|x})'
            displayText: 'sinh(float x)'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns the hyperbolic sine of x.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.sinh'
          },
          {
            snippet: 'sqrt(${1:float|x})'
            displayText: 'sqrt(float x)'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns the square root of x. (You can also use the expression x^0.5 to compute this value.)'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.sqrt'
          },
          {
            snippet: 'tan(${1:float|x})'
            displayText: 'tan(float x)'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns the tangent of x (assumed to be in radians).'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.tan'
          },
          {
            snippet: 'tanh(${1:float|x})'
            displayText: 'tanh(float x)'
            type: 'function'
            leftLabel: 'float'
            description: 'Returns the hyperbolic tangent of x.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.tanh'
          },
        ]

      # Section: coroutine Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "coroutine") || line.endsWith("coroutine.") || (previous_token == "coroutine" && this_token_intact)
        suggestions = [
          {
            snippet: 'create(${1:function|f})'
            displayText: 'create(function f)'
            type: 'function'
            leftLabel: 'thread'
            description: 'Creates a new coroutine, with body f.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-coroutine.create'
          },
          {
            snippet: 'resume(${1:coroutine|co})'
            displayText: 'resume(coroutine co [, val1, ···])'
            type: 'function'
            leftLabel: 'Table'
            description: 'Starts or continues the execution of coroutine co.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-coroutine.resume'
          },
          {
            snippet: 'running()'
            displayText: 'running()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns the running coroutine plus a boolean, true when the running coroutine is the main one.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-coroutine.running'
          },
          {
            snippet: 'status(${1:coroutine|co})'
            displayText: 'status(coroutine co)'
            type: 'function'
            leftLabel: 'string'
            description: 'Returns the status of coroutine co, as a string.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-coroutine.status'
          },
          {
            snippet: 'wrap(${1:function|f})'
            displayText: 'wrap(function f)'
            type: 'function'
            leftLabel: 'Table'
            description: 'Creates a new coroutine, with body f.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-coroutine.wrap'
          },
          {
            snippet: 'yield(${1:int|value})'
            displayText: 'yield(int value)'
            type: 'function'
            description: 'Suspends the execution of the calling coroutine.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-coroutine.yield'
          },
        ]

      # Section: os Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "os") || line.endsWith("os.") || (previous_token == "os" && this_token_intact)
        suggestions = [
          {
            snippet: 'clock()'
            displayText: 'clock()'
            type: 'function'
            leftLabel: 'int'
            description: 'Returns an approximation of the amount in seconds of CPU time used by the program.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-os.clock'
          },
          {
            snippet: 'date()'
            displayText: 'date([format [, time]])'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns a string or a table containing date and time.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-os.date'
          },
          {
            snippet: 'difftime(${1:time|t2}, ${2:time|t1})'
            displayText: 'difftime(t2, t1)'
            type: 'function'
            leftLabel: 'int'
            description: 'Returns the number of seconds from time t1 to time t2.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-os.difftime'
          },
          {
            snippet: 'time()'
            displayText: 'time([table])'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns the current time when called without arguments, or a time representing the date and time specified by the given table.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-os.time'
          },
        ]

      # Section: Clock Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "Clock") || line.endsWith("Clock.") || (previous_token == "Clock" && this_token_intact)
        suggestions = [
          # Member Variables
          {
            snippet: 'paused'
            displayText: 'paused'
            type: 'property'
            leftLabel: 'bool'
            description: 'If the Clock’s timer is paused. Setting this value will pause or resume the timer.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/clock/#paused'
          },
          # Functions
          {
            snippet: 'getValue()'
            displayText: 'getValue()'
            type: 'function'
            leftLabel: 'int'
            description: 'Returns the current value in stopwatch or timer mode as the number of seconds.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/clock/#getValue'
          },
          {
            snippet: 'pauseStart()'
            displayText: 'pauseStart()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Toggle function for pausing and resuming a stopwatch or timer on the Clock.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/clock/#pauseStart'
          },
          {
            snippet: 'setValue(${1:int|seconds})'
            displayText: 'setValue(int seconds)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Switches the clock to timer mode and sets the timer to the given value in seconds.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/clock/#setValue'
          },
          {
            snippet: 'startStopwatch()'
            displayText: 'startStopwatch()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Switches the Clock to stopwatch mode and begins the stopwatch from 0.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/clock/#startStopwatch'
          },
          {
            snippet: 'showCurrentTime()'
            displayText: 'showCurrentTime()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Switches the Clock back to displaying the current time.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/clock/#showCurrentTime'
          },
        ]

      # Section: Counter Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "Counter") || line.endsWith("Counter.") || (previous_token == "Counter" && this_token_intact)
        suggestions = [
          # Functions
          {
            snippet: 'clear()'
            displayText: 'clear()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Resets the Counter value back to 0.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/counter/#clear'
          },
          {
            snippet: 'decrement()'
            displayText: 'decrement()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Decrements the Counter’s value by 1.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/counter/#decrement'
          },
          {
            snippet: 'getValue()'
            displayText: 'getValue()'
            type: 'function'
            leftLabel: 'int'
            description: 'Returns the current value of the Counter.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/counter/#getValue'
          },
          {
            snippet: 'increment()'
            displayText: 'increment()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Increments the Counter’s value by 1.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/counter/#increment'
          },
          {
            snippet: 'setValue(${1:int|seconds})'
            displayText: 'setValue(int seconds)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the current value of the Counter.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/counter/#setValue'
          },
        ]

      # Section: Lighting
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "Lighting") || line.endsWith("Lighting.") || (previous_token == "Lighting" && this_token_intact)
        suggestions = [
          # Member Variables
          {
            snippet: 'ambient_type'
            displayText: 'ambient_type'
            type: 'property'
            leftLabel: 'int'
            description: 'The source of the ambient light. 1 = Background, 2 = Gradient.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-lighting/#ambient_type'
          },
          {
            snippet: 'ambient_intensity'
            displayText: 'ambient_intensity'
            type: 'property'
            leftLabel: 'float'
            description: 'The strength of the ambient light either from the background or gradient. Range is 0-4.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-lighting/#ambient_intensity'
          },
          {
            snippet: 'light_intensity'
            displayText: 'light_intensity'
            type: 'property'
            leftLabel: 'float'
            description: 'The strength of the directional light shining down in the scene. Range is 0-4.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-lighting/#light_intensity'
          },
          {
            snippet: 'reflection_intensity'
            displayText: 'reflection_intensity'
            type: 'property'
            leftLabel: 'float'
            description: 'The strength of the reflections from the background. Range is 0-1.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-lighting/#reflection_intensity'
          },
          # Functions
          {
            snippet: 'apply()'
            displayText: 'apply()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Applies all changed made to the Lighting class. This must be called for these changes to take affect.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-lighting/#apply'
          },
          {
            snippet: 'getAmbientEquatorColor()'
            displayText: 'getAmbientEquatorColor()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns the Color of the gradient equator.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-lighting/#getAmbientEquatorColor'
          },
          {
            snippet: 'getAmbientGroundColor()'
            displayText: 'getAmbientGroundColor()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns the Color of the gradient ground.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-lighting/#getAmbientGroundColor'
          },
          {
            snippet: 'getAmbientSkyColor()'
            displayText: 'getAmbientSkyColor()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns the Color of the gradient sky.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-lighting/#getAmbientSkyColor'
          },
          {
            snippet: 'getLightColor()'
            displayText: 'getLightColor()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns the Color of the directional light.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-lighting/#getLightColor'
          },
          {
            snippet: 'setAmbientEquatorColor(${1:Table|color})'
            displayText: 'setAmbientEquatorColor(Table color)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the Color of the gradient equator.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-physics/#setAmbientEquatorColor'
          },
          {
            snippet: 'setAmbientGroundColor(${1:Table|color})'
            displayText: 'setAmbientGroundColor(Table color)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the Color of the ambient ground.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-physics/#setAmbientGroundColor'
          },
          {
            snippet: 'setAmbientSkyColor(${1:Table|color})'
            displayText: 'setAmbientSkyColor(Table color)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the Color of the gradient sky.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-physics/#setAmbientSkyColor'
          },
          {
            snippet: 'setLightColor(${1:Table|color})'
            displayText: 'setLightColor(Table color)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the Color of the directional light.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-physics/#setLightColor'
          },
        ]

      # Section: Physics
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "Physics") || line.endsWith("Physics.") || (previous_token == "Physics" && this_token_intact)
        suggestions = [
          # Functions
          {
            snippet: 'cast(${1:Table|info})'
            displayText: 'cast(Table info)'
            type: 'function'
            leftLabel: 'Table'
            description: 'Casts a shape based on Info and returns a table of multiple Hit.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-physics/#cast'
          },
          {
            snippet:
              'cast({\n\t' +
              'origin       = ${1:-- Vector},\n\t' +
              'direction    = ${2:-- Vector},\n\t' +
              'type         = ${3:-- int (1: Ray, 2: Sphere, 3: Box)},\n\t' +
              'size         = ${4:-- Vector},\n\t' +
              'orientation  = ${5:-- Vector},\n\t' +
              'max_distance = ${6:-- float},\n\t' +
              'debug        = ${7:-- bool (true = visualize cast)},\n' +
              '}) -- returns {{Vector point, Vector normal, float distance, Object hit_object}, ...}'
            displayText: 'cast({Vector origin, Vector direction, int type, Vector size, Vector orientation, float max_distanc, bool debug})'
            type: 'function'
            leftLabel: 'Table'
            description: 'Casts a shape based on Info and returns a table of multiple Hit.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-physics/#cast'
          },
          {
            snippet: 'getGravity()'
            displayText: 'getGravity()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns the gravity Vector.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-physics/#getGravity'
          },
          {
            snippet: 'setGravity(${1:Table|vector})'
            displayText: 'setGravity(Table vector)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the gravity Vector.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-physics/#setGravity'
          },
        ]

      # Section: Player Colors
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "Player") || line.endsWith("Player.") || (previous_token == "Player" && this_token_intact)
        suggestions = [
          # Constants
          {
            snippet: 'Black'
            displayText: 'Black'
            type: 'constant'
            leftLabel: 'Player'
            description: 'The Black player.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/'
          },
          {
            snippet: 'Blue'
            displayText: 'Blue'
            type: 'constant'
            leftLabel: 'Player'
            description: 'The Blue player.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/'
          },
          {
            snippet: 'Brown'
            displayText: 'Brown'
            type: 'constant'
            leftLabel: 'Player'
            description: 'The Brown player.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/'
          },
          {
            snippet: 'Green'
            displayText: 'Green'
            type: 'constant'
            leftLabel: 'Player'
            description: 'The Green player.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/'
          },
          {
            snippet: 'Orange'
            displayText: 'Orange'
            type: 'constant'
            leftLabel: 'Player'
            description: 'The Orange player.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/'
          },
          {
            snippet: 'Pink'
            displayText: 'Pink'
            type: 'constant'
            leftLabel: 'Player'
            description: 'The Pink player.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/'
          },
          {
            snippet: 'Purple'
            displayText: 'Purple'
            type: 'constant'
            leftLabel: 'Player'
            description: 'The Purple player.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/'
          },
          {
            snippet: 'Red'
            displayText: 'Red'
            type: 'constant'
            leftLabel: 'Player'
            description: 'The Red player.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/'
          },
          {
            snippet: 'Teal'
            displayText: 'Teal'
            type: 'constant'
            leftLabel: 'Player'
            description: 'The Teal player.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/'
          },
          {
            snippet: 'White'
            displayText: 'White'
            type: 'constant'
            leftLabel: 'Player'
            description: 'The White player.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/'
          },
          {
            snippet: 'Yellow'
            displayText: 'Yellow'
            type: 'constant'
            leftLabel: 'Player'
            description: 'The Yellow player.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/'
          },
          # Functions
          {
            snippet: 'getPlayers()'
            displayText: 'getPlayers()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns a Table of all Players.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getPlayers'
          },
          {
            snippet: 'getSpectators()'
            displayText: 'getSpectators()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns a Table of spectator Players.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getSpectators'
          },
        ]

      # Section: Player Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token_2 == "Player") ||  previous_token.substring(0, 7) == "Player["
        suggestions = [
          # Member Variables
          {
            snippet: 'admin'
            displayText: 'admin'
            type: 'property'
            leftLabel: 'bool'
            description: 'Is the player currently promoted or hosting the game? Read only.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#admin'
          },
          {
            snippet: 'blindfolded'
            displayText: 'blindfolded'
            type: 'property'
            leftLabel: 'bool'
            description: 'Is the player blindfolded?'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#blindfolded'
          },
          {
            snippet: 'color'
            displayText: 'color'
            type: 'property'
            leftLabel: 'string'
            description: 'The player\'s color. Read only.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#color'
          },
          {
            snippet: 'host'
            displayText: 'host'
            type: 'property'
            leftLabel: 'bool'
            description: 'Is the player the host?.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#host'
          },
          {
            snippet: 'lift_height'
            displayText: 'lift_height'
            type: 'property'
            leftLabel: 'float'
            description: 'The player\'s lift height from 0 to 1.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#lift_height'
          },
          {
            snippet: 'promoted'
            displayText: 'promoted'
            type: 'property'
            leftLabel: 'bool'
            description: 'Is the player currently promoted? Read only.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#promoted'
          },
          {
            snippet: 'seated'
            displayText: 'seated'
            type: 'property'
            leftLabel: 'float'
            description: 'Is the player currently seated at the table? Read only.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#seated'
          },
          {
            snippet: 'steam_id'
            displayText: 'steam_id'
            type: 'property'
            leftLabel: 'float'
            description: 'The player\'s Steam ID. Read only.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#steam_id'
          },
          {
            snippet: 'steam_name'
            displayText: 'steam_name'
            type: 'property'
            leftLabel: 'string'
            description: 'The player\'s Steam name. Read only.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#steam_name'
          },
          {
            snippet: 'team'
            displayText: 'team'
            type: 'property'
            leftLabel: 'string'
            description: 'The player\'s team. Team names: "None", "Clubs", "Diamonds", "Hearts", "Spades". Read only.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#team'
          },
          # Functions
          {
            snippet: 'attachCameraToObject(${1:Table|parameters})'
            displayText: 'attachCameraToObject(Table parameters)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Makes a player\'s camera follow an Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#attachCameraToObject'
          },
          {
            snippet:
              'attachCameraToObject({\n\t' +
              'object = ${1:-- Object},\n\t' +
              'offset = ${2:-- Vector [x=0, y=0, z=0]},\n' +
              '})'
            displayText: 'attachCameraToObject({Object object, Vector offset})'
            type: 'function'
            leftLabel: 'bool'
            description: 'Makes a player\'s camera follow an Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#attachCameraToObject'
          },
          {
            snippet: 'broadcast(${1:string|message})'
            displayText: 'broadcast(string message)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Broadcasts a message to the player. This also sends a message to the top center of the screen.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#broadcast'
          },
          {
            snippet: 'broadcast(${1:string|message}, $(2:string|color))'
            displayText: 'broadcast(string message, string color)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Broadcasts a message to the player with Color. This also sends a message to the top center of the screen.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#broadcast'
          },
          {
            snippet: 'changeColor(${1:string|new_color})'
            displayText: 'changeColor(string new_color)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Changes the player\'s color.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#changeColor'
          },
          {
            snippet: 'getHandObjects()'
            displayText: 'getHandObjects()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns a Lua Table as a list of all the Cards and Mahjong Tiles in the player\'s hand.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getHandObjects'
          },
          {
            snippet: 'getHandTransform()'
            displayText: 'getHandTransform()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns the Transform of the player’s hand.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getHandTransform'
          },
          {
            snippet:
              'getHandTransform() -- returns table:\n\t' +
                '-- position     Vector    (World position)\n\t' +
                '-- rotation     Vector    (World rotation)\n\t' +
                '-- scale        Vector    (Local scale)\n\t' +
                '-- forward      Vector    (Forward direction)\n\t' +
                '-- right        Vector    (Right direction)\n\t' +
                '-- up           Vector    (Up direction)'
            displayText: 'getHandTransform() -- returns {...'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns the Transform of the player’s hand.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getHandTransform'
          },
          {
            snippet: 'getPlayerHand()'
            displayText: 'getPlayerHand()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns a Lua Table with the position and rotation of the given player\'s hand.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getPlayerHand'
          },
          {
            snippet: 'getPointerPosition()'
            displayText: 'getPointerPosition()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns the position of the given player color\'s pointer.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getPointerPosition'
          },
          {
            snippet: 'getPointerRotation()'
            displayText: 'getPointerRotation()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns the y-axis rotation of the given player color\'s pointer in degrees.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getPointerRotation'
          },
          {
            snippet: 'getHoldingObjects()'
            displayText: 'getHoldingObjects()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns a Lua Table representing a list of all the Objects currently held by the player.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getHoldingObjects'
          },
          {
            snippet: 'getSelectedObjects()'
            displayText: 'getSelectedObjects()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns a Lua Table representing a list of all the Objects currently selected by the player.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getPointerRotation'
          },
          {
            snippet: 'kick()'
            displayText: 'kick()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Kicks the player from the game.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#kick'
          },
          {
            snippet: 'lookAt(${1:Table|parameters})'
            displayText: 'lookAt(Table parameters)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Moves the Player\'s camera to look at a specific point.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#lookAt'
          },
          {
            snippet:
              'lookAt({\n\t' +
              'position = ${1:-- Vector (required)},\n\t' +
              'pitch    = ${2:-- float},\n\t' +
              'yaw      = ${3:-- float},\n\t' +
              'distance = ${4:-- float},\n' +
              '})'
            displayText: 'lookAt({Vector position, float pitch, float yaw, float distance})'
            type: 'function'
            leftLabel: 'bool'
            description: 'Moves the Player\'s camera to look at a specific point.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#lookAt'
          },
          {
            snippet: 'mute()'
            displayText: 'mute()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Mutes or unmutes the player.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#mute'
          },
          {
            snippet: 'print(${1:string|message})'
            displayText: 'print(string message)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Prints a message to the player.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#print'
          },
          {
            snippet: 'print(${1:string|message}, $(2:string|color))'
            displayText: 'print(string message, string color)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Prints a message to the player with Color.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#print'
          },
          {
            snippet: 'promote()'
            displayText: 'promote()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Promotes or demotes the player.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#promote'
          },
          {
            snippet: 'setHandTransform(${1:Table|transform})'
            displayText: 'setHandTransform(Table transform)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the Transform of the player’s hand.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#setHandTransform'
          },
          {
            snippet:
              'setHandTransform({\n\t' +
              'position = ${1:-- Vector},\n\t' +
              'rotation = ${2:-- Vector},\n\t' +
              'scale    = ${3:-- Vector},\n\t' +
              'forward  = ${4:-- Vector},\n\t' +
              'right    = ${5:-- Vector},\n\t' +
              'up       = ${6:-- Vector},\n' +
              '})'
            displayText: 'setHandTransform({Vector position, Vector rotation, Vector scale, Vector forward, Vector right, Vector up})'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the Transform of the player’s hand.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#setHandTransform'
          },
        ]

      # Section: JSON Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "JSON") || line.endsWith("JSON.") || (previous_token == "JSON" && this_token_intact)
        suggestions = [
          # Functions
          {
            snippet: 'decode(${1:string|json_string})'
            displayText: 'decode(string json_string)'
            type: 'function'
            leftLabel: 'variable'
            description: 'Decodes a valid JSON string into a Lua string, number, or Table.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/json/#decode'
          },
          {
            snippet: 'encode(${1:variable})'
            displayText: 'encode(variable)'
            type: 'function'
            leftLabel: 'string'
            description: 'Encodes a Lua string, number, or Table into a valid JSON string. This will not work with Object references.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/json/#encode'
          },
          {
            snippet: 'encode_pretty(${1:variable})'
            displayText: 'encode_pretty(variable)'
            type: 'function'
            leftLabel: 'string'
            description: 'Encodes a Lua string, number, or Table into a valid JSON string formatted with indents (Human readable). This will not work with Object references.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/json/#encode_pretty'
          },
        ]

      # Section: Timer Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "Timer") || line.endsWith("Timer.") || (previous_token == "Timer" && this_token_intact)
        suggestions = [
          # Functions
          {
            snippet: 'create(${1:Table|parameters})'
            displayText: 'create(Table parameters)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Creates a Timer. Timers are used for calling functions after a delay or repeatedly.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/timer/#create'
          },
          {
            snippet:
              'create({\n\t' +
              'identifier     = ${1:-- string (must be unique)},\n\t' +
              'function_name  = ${2:-- string},\n\t' +
              'function_owner = ${3:-- Object},\n\t' +
              'parameters     = ${4:-- Table},\n\t' +
              'delay          = ${5:-- float  [0 seconds]},\n\t' +
              'repetitions    = ${6:-- int    [1] (0 = infinite)},\n' +
              '})'
            displayText: 'create({Vector position, Vector rotation, string callback, Object callback_owner, Table params, bool flip, string guid, int index, bool top})'
            type: 'function'
            leftLabel: 'bool'
            description: 'Creates a Timer. Timers are used for calling functions after a delay or repeatedly.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/timer/#create'
          },
          {
            snippet: 'destroy(${1:string|identifier})'
            displayText: 'destroy(string identifier)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Destroys an existing timer.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/timer/#destroy'
          },
        ]

      # Section: RPGFigurine Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "RPGFigurine") || line.endsWith("RPGFigurine.") || (previous_token == "RPGFigurine" && this_token_intact)
        suggestions = [
          # Functions
          {
            snippet: 'attack()'
            displayText: 'attack()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Plays a random attack animation.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/rpgfigurine/#attack'
          },
          {
            snippet: 'changeMode()'
            displayText: 'changeMode()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Changes the RPG Figurine\'s current mode.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/rpgfigurine/#changeMode'
          },
          {
            snippet: 'die()'
            displayText: 'die()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Plays the death animation. Call die() again to reset the RPG Figurine.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/rpgfigurine/#die'
          },
          {
            snippet: 'onAttack(hit_list)\n\t${0:-- body...}\nend'
            displayText: 'onAttack(Table hit_list)'
            type: 'function'
            description: 'This function is called, if it exists in your script, when this RPGFigurine attacks another RPGFigurine.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/rpgfigurine/#onAttack'
          },
          {
            snippet: 'onHit(attacker)\n\t${0:-- body...}\nend'
            displayText: 'onHit(Object attacker)'
            type: 'function'
            description: 'This function is called, if it exists in your script, when this RPGFigurine is attacked by another RPGFigurine.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/rpgfigurine/#onHit'
          },
        ]

      # Section: TextTool Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "TextTool") || line.endsWith("TextTool.") || (previous_token == "TextTool" && this_token_intact)
        suggestions = [
          # Functions
          {
            snippet: 'getFontColor()'
            displayText: 'getFontColor()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns the current font color as a Lua Table keyed as Table[\'r\'], Table[\'g\'], and Table[\'b\'].'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/texttool/#getFontColor'
          },
          {
            snippet: 'getFontSize()'
            displayText: 'getFontSize()'
            type: 'function'
            leftLabel: 'int'
            description: 'Returns the current font size.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/texttool/#getFontSize'
          },
          {
            snippet: 'getValue()'
            displayText: 'getValue()'
            type: 'function'
            leftLabel: 'string'
            description: 'Returns the current text.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/texttool/#getValue'
          },
          {
            snippet: 'setFontColor(${1:Table|color})'
            displayText: 'setFontColor(Table color)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the current font color. The Lua Table parameter should be keyed as Table[\'r\'], Table[\'g\'], and Table[\'b\'].'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/texttool/#setFontColor'
          },
          {
            snippet: 'setFontSize(${1:int|font_size})'
            displayText: 'setFontSize(int font_size)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the current font size.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/texttool/#setFontSize'
          },
          {
            snippet: 'setValue(${1:string|text})'
            displayText: 'setValue(string text)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the current text.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/texttool/#setValue'
          },
        ]

      # Section: Object
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua" || (tokens.length > 1 && this_token_intact)))
        suggestions = [
          # Member Variables
          {
            snippet: 'angular_drag'
            displayText: 'angular_drag'
            type: 'property'
            leftLabel: 'float'
            description: 'The Object\'s angular drag.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#angular_drag'
          },
          {
            snippet: 'auto_raise'
            displayText: 'auto_raise'
            type: 'property'
            leftLabel: 'bool'
            description: 'Should this Object automatically raise above other Objects when held?'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#auto_raise'
          },
          {
            snippet: 'bounciness'
            displayText: 'bounciness'
            type: 'property'
            leftLabel: 'float'
            description: 'The Object\'s bounciness.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#bounciness'
          },
          {
            snippet: 'Clock'
            displayText: 'Clock'
            type: 'property'
            leftLabel: 'Clock'
            description: 'A reference to the Clock class attached to this Object. Read only.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#Clock'
          },
          {
            snippet: 'Counter'
            displayText: 'Counter'
            type: 'property'
            leftLabel: 'Counter'
            description: 'A reference to the Counter class attached to this Object. Read only.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#Counter'
          },
          {
            snippet: 'drag'
            displayText: 'drag'
            type: 'property'
            leftLabel: 'float'
            description: 'The Object\'s drag.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#drag'
          },
          {
            snippet: 'dynamic_friction'
            displayText: 'dynamic_friction'
            type: 'property'
            leftLabel: 'float'
            description: 'The Object\'s dynamic friction.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#dynamic_friction'
          },
          {
            snippet: 'grid_projection'
            displayText: 'grid_projection'
            type: 'property'
            leftLabel: 'bool'
            description: 'Should the grid project onto this object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#grid_projection'
          },
          {
            snippet: 'guid'
            displayText: 'guid'
            type: 'property'
            leftLabel: 'string'
            description: 'The Object’s guid. This is the same as the getGUID function. Read only.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#guid'
          },
          {
            snippet: 'held_by_color'
            displayText: 'held_by_color'
            type: 'property'
            leftLabel: 'string'
            description: 'The color of the Player currently holding the Object. Read only.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#held_by_color'
          },
          {
            snippet: 'interactable'
            displayText: 'interactable'
            type: 'property'
            leftLabel: 'bool'
            description: 'Can players interact with this Object? If false, only Lua Scripts can interact with this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#interactable'
          },
          {
            snippet: 'mass'
            displayText: 'mass'
            type: 'property'
            leftLabel: 'float'
            description: 'The Object\'s mass.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#mass'
          },
          {
            snippet: 'name'
            displayText: 'name'
            type: 'property'
            leftLabel: 'string'
            description: 'The Object’s formated name or nickname if applicable. Read only.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#name'
          },
          {
            snippet: 'resting'
            displayText: 'resting'
            type: 'property'
            leftLabel: 'bool'
            description: 'Returns true if this Object is not moving. Read only.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#resting'
          },
          {
            snippet: 'RPGFigurine'
            displayText: 'RPGFigurine'
            type: 'property'
            leftLabel: 'RPGFigurine'
            description: 'A reference to the RPGFigurine class attached to this Object. Read only.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#RPGFigurine'
          },
          {
            snippet: 'script_code'
            displayText: 'script_code'
            type: 'property'
            leftLabel: 'string'
            description: 'Returns the Lua script on this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#script_code'
          },
          {
            snippet: 'script_state'
            displayText: 'script_state'
            type: 'property'
            leftLabel: 'string'
            description: 'Returns the saved Lua script state on the Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#script_state'
          },
          {
            snippet: 'static_friction'
            displayText: 'static_friction'
            type: 'property'
            leftLabel: 'float'
            description: 'The Object\'s static friction.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#static_friction'
          },
          {
            snippet: 'sticky'
            displayText: 'sticky'
            type: 'property'
            leftLabel: 'bool'
            description: 'Should Objects on top of this Object stick to this Object when this Object is picked up?'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#sticky'
          },
          {
            snippet: 'tag'
            displayText: 'tag'
            type: 'property'
            leftLabel: 'string'
            description: 'The tag of the Object representing its type. Read only.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#tag'
          },
          {
            snippet: 'tooltip'
            displayText: 'tooltip'
            type: 'property'
            leftLabel: 'bool'
            description: 'Should Object show tooltips when hovering over it.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#tooltip'
          },
          {
            snippet: 'TextTool'
            displayText: 'TextTool'
            type: 'property'
            leftLabel: 'TextTool'
            description: 'A reference to the TextTool class attached to this Object. Read only.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#TextTool'
          },
          {
            snippet: 'use_gravity'
            displayText: 'use_gravity'
            type: 'property'
            leftLabel: 'bool'
            description: 'Does gravity affect this Object?'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#use_gravity'
          },
          {
            snippet: 'use_grid'
            displayText: 'use_grid'
            type: 'property'
            leftLabel: 'bool'
            description: 'Should this Object snap to grid points?'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#use_grid'
          },
          {
            snippet: 'use_snap_points'
            displayText: 'use_snap_points'
            type: 'property'
            leftLabel: 'bool'
            description: 'Should this Object snap to snap points?'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#use_snap_points'
          },
          # Functions
          {
            snippet: 'addForce(${1:Table|force_vector}, ${2:int|force_type})'
            displayText: 'addForce(Table force_vector, int force_type)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Adds a force vector to the Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#addForce'
          },
          {
            snippet: 'addTorque(${1:Table|torque_vector}, ${2:int|force_type})'
            displayText: 'addTorque(Table torque_vector, int force_type)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Adds a torque vector to the Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#addTorque'
          },
          {
            snippet: 'call(${1:string|function_name}, ${2:Table|parameters})'
            displayText: 'call(string function_name, Table parameters)'
            type: 'function'
            leftLabel: 'variable'
            description: 'Calls a Lua function owned by this Object and passes an optional Table as parameters to the function.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#call'
          },
          {
            snippet: 'clearButtons()'
            displayText: 'clearButtons()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Clears all 3D UI buttons on this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#clearButtons'
          },
          {
            snippet: 'clone(${1:Table|parameters})'
            displayText: 'clone(Table parameters)'
            type: 'function'
            leftLabel: 'Object'
            description: 'Copies and pastes this Object. Returns a reference to the newly spawned Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#clone'
          },
          {
            snippet:
              'clone({\n\t' +
              'position     = ${1:-- Vector  [x=0, y=3, z=0]},\n\t' +
              'snap_to_grid = ${2:-- boolean [false]},\n' +
              '})'
            displayText: 'clone({Vector position, bool snap_to_grid})'
            type: 'function'
            leftLabel: 'Object'
            description: 'Copies and pastes this Object. Returns a reference to the newly spawned Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#clone'
          },
          {
            snippet: 'createButton(${1:Table|parameters})'
            displayText: 'createButton(Table parameters)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Creates a 3D UI button on this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#createButton'
          },
          {
            snippet:
              'createButton({\n\t' +
              'click_function = ${1:-- string (required)},\n\t' +
              'function_owner = ${2:-- Object (required)},\n\t' +
              'label          = ${3:-- string},\n\t' +
              'position       = ${4:-- Vector},\n\t' +
              'rotation       = ${5:-- Vector},\n\t' +
              'scale          = ${6:-- Vector},\n\t' +
              'width          = ${7:-- int},\n\t' +
              'height         = ${8:-- int},\n\t' +
              'font_size      = ${9:-- int},\n\t' +
              'color          = ${10:-- Color},\n\t' +
              'font_color     = ${11:-- Color},\n' +
              '})'
            displayText: 'createButton({string click_function, Object function_owner, string label, Vector position, Vector rotation, Vector scale, int width, int height, int font_size, Color color, Color font_color})'
            type: 'function'
            leftLabel: 'bool'
            description: 'Creates a 3D UI button on this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#createButton'
          },
          {
            snippet: 'cut()'
            displayText: 'cut()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Cuts this Object if it is a Deck or a Stack.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#cut'
          },
          {
            snippet: 'dealToAll(${1:int|num_cards})'
            displayText: 'dealToAll(int num_cards)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Deals a number of Cards from a this Deck to all seated players.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#dealToAll'
          },
          {
            snippet: 'dealToColor(${1:int|num_cards}, ${2:string|player_color})'
            displayText: 'dealToColor(int num_cards, string player_color)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Deals a number of Cards from this Deck to a specific player.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#dealToColor'
          },
          {
            snippet: 'dealToColorWithOffset(${1:Table|position}, ${2:bool|flip}, ${3:string|player_color})'
            displayText: 'dealToColorWithOffset(Table position, bool flip, string player_color)'
            type: 'function'
            leftLabel: 'Object'
            description: 'Deals a Card to a player with an offset from their hand.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#dealToColorWithOffset'
          },
          {
            snippet: 'destruct()'
            displayText: 'destruct()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Destroys this Object. Mainly so you can call self.destruct().'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#destruct'
          },
          {
            snippet: 'editButton(${1:Table|parameters})'
            displayText: 'editButton(Table parameters)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Edits a 3D UI button on this Object based on its index.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#editButton'
          },
          {
            snippet:
              'editButton({\n\t' +
              'index          = ${1:-- int    (required)},\n\t' +
              'click_function = ${2:-- string},\n\t' +
              'function_owner = ${3:-- Object},\n\t' +
              'label          = ${4:-- string},\n\t' +
              'position       = ${5:-- Vector},\n\t' +
              'rotation       = ${6:-- Vector},\n\t' +
              'scale          = ${7:-- Vector},\n\t' +
              'width          = ${8:-- int},\n\t' +
              'height         = ${9:-- int},\n\t' +
              'font_size      = ${10:-- int},\n\t' +
              'color          = ${11:-- Color},\n\t' +
              'font_color     = ${12:-- Color},\n' +
              '})'
            displayText: 'editButton({int index, string click_function, Object function_owner, string label, Vector position, Vector rotation, Vector scale, int width, int height, int font_size, Color color, Color font_color})'
            type: 'function'
            leftLabel: 'bool'
            description: 'Edits a 3D UI button on this Object based on its index.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#editButton'
          },
          {
            snippet: 'flip()'
            displayText: 'flip()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Flips this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#flip'
          },
          {
            snippet: 'getAngularVelocity()'
            displayText: 'getAngularVelocity()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns the current angular velocity vector of the Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getAngularVelocity'
          },
          {
            snippet: 'getBounds()'
            displayText: 'getBounds()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns the world space axis aligned Bounds of the Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getBounds'
          },
          {
            snippet: 'getBoundsNormalized()'
            displayText: 'getBoundsNormalized()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns the world space axis aligned Bounds of the Object at zero rotation.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getBoundsNormalized'
          },
          {
            snippet: 'getButtons()'
            displayText: 'getButtons()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Gets a list of all the 3D UI buttons on this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getButtons'
          },
          {
            snippet: 'getButtons() -- returns table:\n\t' +
            '-- {{int index, string click_function, Object function_owner, string label\n\t' +
            '--   Vector position, Vector rotation, Vector scale, int width, int height\n\t' +
            '--   int font_size, Color color, Color font_color}, ...}'
            displayText: 'getButtons() -- returns {{...'
            type: 'function'
            leftLabel: 'Table'
            description: 'Gets a list of all the 3D UI buttons on this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getButtons'
          },
          {
            snippet: 'getColorTint()'
            displayText: 'getColorTint()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns the color tint for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getColorTint'
          },
          {
            snippet: 'getCustomObject()'
            displayText: 'getCustomObject()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns the custom parameters on a Custom Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getCustomObject'
          },
          {
            snippet:
              'getCustomObject() -- returns table:\n\t' +
                '-- image                  string  (Image URL for Custom Board, Custom Dice, Custom Figurine, Custom Tile, and Custom Token.)\n\t' +
                '-- image_secondary        string  (Secondary / Back Image URL for Custom Figurine or Custom Tile.)\n\t' +
                '-- type                   int     (The number of sides of the Custom Dice, the shape of the Custom Tile, the type of Custom Mesh, or the type of Custom AssetBundle.)\n\t' +
                '-- thickness              float   (Thickness of the Custom Tile or Custom Token.)\n\t' +
                '-- stackable              bool    (Is this Custom Tile or Custom Token stackable?)\n\t' +
                '-- merge_distance         float   (The accuracy of the Custom Tile to it’s base image.)\n\t' +
                '-- mesh                   string  (Mesh URL for the Custom Mesh.)\n\t' +
                '-- diffuse                string  (Diffuse image URL for the Custom Mesh.)\n\t' +
                '-- normal                 string  (Normal image URL for the Custom Mesh.)\n\t' +
                '-- collider               string  (Collider URL for the Custom Mesh.)\n\t' +
                '-- convex                 bool    (Is this Custom Mesh concave?)\n\t' +
                '-- material               int     (The material for the Custom Mesh or Custom AssetBundle.)\n\t' +
                '-- specular_intensity     float   (The specular intensity for the Custom Mesh.)\n\t' +
                '-- specular_color         Color   (The specular color for the Custom Mesh.)\n\t' +
                '-- specular_sharpness     float   (The specular sharpness for the Custom Mesh.)\n\t' +
                '-- fresnel_strength       float   (The fresnel strength for the Custom Mesh.)\n\t' +
                '-- cast_shadows           bool    (Does this Custom Mesh cast shadows?)\n\t' +
                '-- assetbundle            string  (AssetBundle URL for this Custom AssetBundle.)\n\t' +
                '-- assetbundle_secondary  string  (Secondary AssetBundle URL for this Custom AssetBundle.)'
            displayText: 'getCustomObject() -- returns {{...'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns the custom parameters on a Custom Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getCustomObject'
          },
          {
            snippet: 'getDescription()'
            displayText: 'getDescription()'
            type: 'function'
            leftLabel: 'string'
            description: 'Gets the description for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getDescription'
          },
          {
            snippet: 'getGUID()'
            displayText: 'getGUID()'
            type: 'function'
            leftLabel: 'string'
            description: 'Returns the GUID that belongs to this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getGUID'
          },
          {
            snippet: 'getLoopingEffectIndex()'
            displayText: 'getLoopingEffectIndex()'
            type: 'function'
            leftLabel: 'int'
            description: 'Returns the index of the currently looping effect.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/assetbundle/#getLoopingEffectIndex'
          },
          {
            snippet: 'getLoopingEffects()'
            displayText: 'getLoopingEffects()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns a Table with the keys “index” and “name” for each looping effect.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/assetbundle/#getLoopingEffects'
          },
          {
            snippet: 'getLock()'
            displayText: 'getLock()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Get the lock status of this object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getLock'
          },
          {
            snippet: 'getLuaScript()'
            displayText: 'getLuaScript()'
            type: 'function'
            leftLabel: 'string'
            description: 'Returns the Lua script for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getLuaScript'
          },
          {
            snippet: 'getName()'
            displayText: 'getName()'
            type: 'function'
            leftLabel: 'string'
            description: 'Returns the nickname for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getName'
          },
          {
            snippet: 'getObjects()'
            displayText: 'getObjects()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns all the Objects inside of this container.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getObjects'
          },
          {
            snippet: 'getObjects()$1\n\t-- Bag.getObjects() returns {{int index, string guid, string name}, ...}'
            displayText: 'getObjects() -- Bag returns {{int index, string guid, string name}, ...}'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns all the Objects inside of this container.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getObjects'
          },
          {
            snippet: 'getObjects()$1\n\t-- Deck.getObjects() returns:\n\t-- {{int index, string nickname, string description, string guid, string lua_script}, ...}'
            displayText: 'getObjects() -- Deck returns {{int index, string nickname, string description, string guid, string lua_script}, ...}'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns all the Objects inside of this container.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getObjects'
          },
          {
            snippet: 'getObjects()$1\n\t-- Zone.getObjects() returns {Object, ...}'
            displayText: 'getObjects() -- Zone returns {Object, ...}'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns all the Objects inside of this container.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getObjects'
          },
          {
            snippet: 'getPosition()'
            displayText: 'getPosition()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Gets the position for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getPosition'
          },
          {
            snippet: 'getQuantity()'
            displayText: 'getQuantity()'
            type: 'function'
            leftLabel: 'int'
            description: 'Returns the number of Objects in a stack.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getQuantity'
          },
          {
            snippet: 'getRotation()'
            displayText: 'getRotation()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Gets the rotation of this Object in degrees.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getRotation'
          },
          {
            snippet: 'getScale()'
            displayText: 'getScale()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Gets the scale for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getScale'
          },
          {
            snippet: 'getStateId()'
            displayText: 'getStateId()'
            type: 'function'
            leftLabel: 'int'
            description: 'Returns id of the active state for this object. Will return -1 if the object has no states.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getStateId'
          },
          {
            snippet: 'getStates()'
            displayText: 'getStates()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns a Table with the keys “name”, “guid”, and “id”.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getStates'
          },
          {
            snippet: 'getStatesCount()'
            displayText: 'getStatesCount()'
            type: 'function'
            leftLabel: 'int'
            description: 'Returns the number of States on this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getStatesCount'
          },
          {
            snippet: 'getTable(${1:string|table_name})'
            displayText: 'getTable(string table_name)'
            type: 'function'
            leftLabel: 'Table'
            description: 'Gets a Lua Table for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getTable'
          },
          {
            snippet: 'getTransformForward()'
            displayText: 'getTransformForward()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Gets the forward direction of this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getTransformForward'
          },
          {
            snippet: 'getTransformRight()'
            displayText: 'getTransformRight()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Gets the right direction of this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getTransformRight'
          },
          {
            snippet: 'getTransformUp()'
            displayText: 'getTransformUp()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Gets the up direction of this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getTransformUp'
          },
          {
            snippet: 'getTriggerEffects()'
            displayText: 'getTriggerEffects()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns a Table with the keys “index” and “name” for each trigger effect.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/assetbundle/#getTriggerEffects'
          },
          {
            snippet: 'getValue()'
            displayText: 'getValue()'
            type: 'function'
            leftLabel: 'int'
            description: 'Returns the value for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getValue'
          },
          {
            snippet: 'getVar(${1:string|variable_name})'
            displayText: 'getVar(string variable_name)'
            type: 'function'
            leftLabel: 'variable'
            description: 'Gets a Lua variable for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getVar'
          },
          {
            snippet: 'getVelocity()'
            displayText: 'getVelocity()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns the current velocity vector of the Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getVelocity'
          },
          {
            snippet: 'highlightOff()'
            displayText: 'highlightOff()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Stop highlighting this object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#highlightOff'
          },
          {
            snippet: 'highlightOn(${1:Table|color}, ${2:float|duration})'
            displayText: 'highlightOn(Table color, float duration)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Highlight this object with color for an optional duration. Color values are between 0 and 1.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#highlightOn'
          },
          {
            snippet: 'isSmoothMoving()'
            displayText: 'isSmoothMoving()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Is the object smoothly moving from our smooth functions.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#isSmoothMoving'
          },
          {
            snippet: 'playLoopingEffect(${1:int|index})'
            displayText: 'playLoopingEffect(int index)'
            type: 'function'
            leftLabel: 'void'
            description: 'Starts playing a looping effect. Index starts at 0.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/assetbundle/#playLoopingEffect'
          },
          {
            snippet: 'playTriggerEffect(${1:int|index})'
            displayText: 'playTriggerEffect(int index)'
            type: 'function'
            leftLabel: 'void'
            description: 'Starts playing a trigger effect. Index starts at 0.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/assetbundle/#playTriggerEffect'
          },
          {
            snippet: 'positionToLocal(${1:Table|vector})'
            displayText: 'positionToLocal(Table vector)'
            type: 'function'
            leftLabel: 'Table'
            description: 'Converts the world position to a local position of this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#positionToLocal'
          },
          {
            snippet: 'positionToWorld(${1:Table|vector})'
            displayText: 'positionToWorld(Table vector)'
            type: 'function'
            leftLabel: 'Table'
            description: 'Converts the local position of this Object to a world position.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#positionToWorld'
          },
          {
            snippet: 'putObject(${1:Object|object})'
            displayText: 'putObject(Object object)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Add this object to the current object. Works for stacking chips, decks, and bags.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#putObject'
          },
          {
            snippet: 'randomize()'
            displayText: 'randomize()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Same as pressing the ‘R’ key on an Object. Shuffles deck/bag, rolls dice/coin, lifts any other object up in the air.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#randomize'
          },
          {
            snippet: 'reload()'
            displayText: 'reload()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Reloads this object by destroying and spawning it place. Returns the newly spawned object. Very useful if using setCustomObject().'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#reload'
          },
          {
            snippet: 'removeButton(${1:int|index})'
            displayText: 'removeButton(int index)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Removes a 3D UI button from this Object by its index.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#removeButton'
          },
          {
            snippet: 'reset()'
            displayText: 'reset()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Resets this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#rest'
          },
          {
            snippet: 'roll()'
            displayText: 'roll()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Rolls this Object. Works on Dice and Coins.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#roll'
          },
          {
            snippet: 'rotate(${1:Table|rotation})'
            displayText: 'rotate(Table rotation)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Smoothly rotates this Object with the given offset in degrees.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#rotate'
          },
          {
            snippet: 'scale(${1:Table|scale})'
            displayText: 'scale(Table scale)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Scales this Object by the given amount.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#scale'
          },
          {
            snippet: 'scale(${1:float|scale})'
            displayText: 'scale(float scale)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Scales this Object in all axes by the given amount.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#scaleAllAxes'
          },
          {
            snippet: 'setAngularVelocity(${1:Table|vector})'
            displayText: 'setAngularVelocity(Table vector)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the angular velocity of the object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setAngularVelocity'
          },
          {
            snippet: 'setColorTint(${1:Table|color})'
            displayText: 'setColorTint(Table color)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the color tint for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setColorTint'
          },
          {
            snippet: 'setCustomObject(${1:Table|parameters})'
            displayText: 'setCustomObject(Table parameters)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Used to create a Custom Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setCustomObject'
          },
          {
            snippet: 'setDescription(${1:string|description})'
            displayText: 'setDescription(string description)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the description for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setDescription'
          },
          {
            snippet: 'setLock(${1:bool|lock})'
            displayText: 'setLock(bool lock)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Set the lock status of an object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setLock'
          },
          {
            snippet: 'setLuaScript(${1:string|script})'
            displayText: 'setLuaScript(string script)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the Lua script for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setLuaScript'
          },
          {
            snippet: 'setName(${1:string|nickname})'
            displayText: 'setName(string nickname)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the nickname for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setName'
          },
          {
            snippet: 'setPosition(${1:Table|position})'
            displayText: 'setPosition(Table position)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the world space position for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setPosition'
          },
          {
            snippet: 'setPositionSmooth(${1:Table|position}, ${2:bool|collide}, ${3:bool|fast})'
            displayText: 'setPositionSmooth(Table position, bool collide, bool fast)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Smoothly moves this Object from its current position to a given world space position.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setPositionSmooth'
          },
          {
            snippet: 'setRotation(${1:Table|rotation})'
            displayText: 'setRotation(Table rotation)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the rotation of this Object in degrees.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setRotation'
          },
          {
            snippet: 'setRotationSmooth(${1:Table|rotation}, ${2:bool|collide}, ${3:bool|fast})'
            displayText: 'setRotationSmooth(Table rotation, bool collide, bool fast)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Smoothly rotates this Object to the given orientation in degrees.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setRotationSmooth'
          },
          {
            snippet: 'setScale(${1:Table|scale})'
            displayText: 'setScale(Table scale)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the scale for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setScale'
          },
          {
            snippet: 'setState(${1:int|state})'
            displayText: 'setState(int state)'
            type: 'function'
            leftLabel: 'Object'
            description: 'Sets the State on this Object and returns reference to the new State.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setState'
          },
          {
            snippet: 'setTable(${1:string|table_name}, ${2:Table|table})'
            displayText: 'setTable(string table_name, Table table)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets a Lua Table for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setTable'
          },
          {
            snippet: 'setValue(${1:variable|value})'
            displayText: 'setValue(variable value)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the value for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setValue'
          },
          {
            snippet: 'setVar(${1:string|variable_name}, ${2:variable|value})'
            displayText: 'setVar(string variable_name, variable value)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets a Lua variable for this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setVar'
          },
          {
            snippet: 'setVelocity(${1:Table|vector})'
            displayText: 'setVelocity(Table vector)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the velocity of the object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setVelocity'
          },
          {
            snippet: 'shuffle()'
            displayText: 'shuffle()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Shuffles this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#shuffle'
          },
          {
            snippet: 'shuffleStates()'
            displayText: 'shuffleStates()'
            type: 'function'
            leftLabel: 'Object'
            description: 'Shuffles the States on this Object and returns reference to the new State.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#shuffleStates'
          },
          {
            snippet: 'takeObject(${1:Table|parameters})'
            displayText: 'takeObject(Table parameters)'
            type: 'function'
            leftLabel: 'Object'
            description: 'Takes an Object from this container.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#takeObject'
          },
          {
            snippet:
              'takeObject({\n\t' +
              'position       = ${1:-- Vector [container position, x+2]},\n\t' +
              'rotation       = ${2:-- Vector [container rotation]},\n\t' +
              'callback       = ${3:-- string},\n\t' +
              'callback_owner = ${4:-- Object},\n\t' +
              'params         = ${5:-- Table},\n\t' +
              'flip           = ${6:-- bool},\n\t' +
              'guid           = ${7:-- string},\n\t' +
              'index          = ${8:-- int},\n\t' +
              'top            = ${9:-- bool [true]},\n' +
              '})'
            displayText: 'takeObject({Vector position, Vector rotation, string callback, Object callback_owner, Table params, bool flip, string guid, int index, bool top})'
            type: 'function'
            leftLabel: 'Object'
            description: 'Takes an Object from this container.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#takeObject'
          },
          {
            snippet: 'translate(${1:Table|position})'
            displayText: 'translate(Table position)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Smoothly moves this Object from its current position to a given offset.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#translate'
          },
        ]

      # Section: Default Events
      else if (line.startsWith('function') && not line.includes("("))
        suggestions = []
        if not global_script
          suggestions = suggestions.concat [
            {
              snippet:
                'onCollisionEnter(collision_info)\n\t' +
                '-- collision_info table:\n\t' +
                '--   collision_object    Object\n\t' +
                '--   contact_points      Table     {Vector, ...}\n\t' +
                '--   relative_velocity   Vector\n\t' +
                '$1\nend'
              displayText: 'onCollisionEnter(Table collision_info)'
              type: 'function'
              description: 'Automatically called when this Object collides with another Object.'
              descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onCollisionEnter'
            },
            {
              snippet:
                'onCollisionExit(collision_info)\n\t' +
                '-- collision_info table:\n\t' +
                '--   collision_object    Object\n\t' +
                '--   contact_points      Table     {Vector, ...}\n\t' +
                '--   relative_velocity   Vector\n\t' +
                '$1\nend'
              displayText: 'onCollisionExit(Table collision_info)'
              type: 'function'
              description: 'Automatically called when this Object stops touching another Object.'
              descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onCollisionExit'
            },
            {
              snippet:
                'onCollisionStay(collision_info)\n\t' +
                '-- collision_info table:\n\t' +
                '--   collision_object    Object\n\t' +
                '--   contact_points      Table     {Vector, ...}\n\t' +
                '--   relative_velocity   Vector\n\t' +
                '$1\nend'
              displayText: 'onCollisionStay(Table collision_info)'
              type: 'function'
              description: 'Automatically called when this Object is touching another Object.'
              descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onCollisionStay'
            },
            {
              snippet: 'onDestroy()\n\t${0:-- body...}\nend'
              displayText: 'onDestroy()'
              type: 'function'
              description: 'Automatically called when this Object is destroyed.'
              descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onDestroy'
            },
            {
              snippet: 'onDropped(player_color)\n\t${0:-- body...}\nend'
              displayText: 'onDropped(string player_color)'
              type: 'function'
              description: 'Automatically called when this Object is dropped.'
              descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onDropped'
            },
            {
              snippet: 'onLoad(save_state)\n\t${0:-- body...}\nend'
              displayText: 'onLoad(string save_state)'
              type: 'function'
              description: 'Automatically called when a game save is finished loading every Object.'
              descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onLoad'
            },
            {
              snippet: 'onPickedUp(player_color)\n\t${0:-- body...}\nend'
              displayText: 'onPickedUp(string player_color)'
              type: 'function'
              description: 'Automatically called when this Object is picked up.'
              descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onPickedUp'
            },
          ]
        suggestions = suggestions.concat [
          {
            snippet: 'fixedUpdate()\n\t${0:-- body...}\nend'
            displayText: 'fixedUpdate()'
            type: 'function'
            description: 'This function is called, if it exists in your script, every physics tick which happens 90 times a second.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#fixedUpdate'
          },
          {
            snippet: 'onload(save_state)\n\t${0:-- body...}\nend'
            displayText: 'onload(string save_state)'
            type: 'function'
            description: 'Automatically called when a game save is finished loading every Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onLoad'
          },
          {
            snippet: 'onObjectDestroyed(dying_object)\n\t${0:-- body...}\nend'
            displayText: 'onObjectDestroyed(Object dying_object)'
            type: 'function'
            description: 'Automatically called when an Object is destroyed.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectDestroyed'
          },
          {
            snippet: 'onObjectDropped(player_color, dropped_object)\n\t${0:-- body...}\nend'
            displayText: 'onObjectDropped(string player_color, Object dropped_object)'
            type: 'function'
            description: 'Automatically called when an Object is dropped.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectDropped'
          },
          {
            snippet: 'onObjectEnterScriptingZone(zone, enter_object)\n\t${0:-- body...}\nend'
            displayText: 'onObjectEnterScriptingZone(Object zone, Object enter_object)'
            type: 'function'
            description: 'Automatically called when an Object enters a Scripting Zone.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectEnterScriptingZone'
          },
          {
            snippet: 'onObjectLeaveContainer(container, leave_object)\n\t${0:-- body...}\nend'
            displayText: 'onObjectLeaveContainer(Object container, Object leave_object)'
            type: 'function'
            description: 'Automatically called when an Object leaves any container(Deck, Bag, Chip Stack, etc).'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectLeaveContainer'
          },
          {
            snippet: 'onObjectLeaveScriptingZone(zone, leave_object)\n\t${0:-- body...}\nend'
            displayText: 'onObjectLeaveScriptingZone(Object zone, Object leave_object)'
            type: 'function'
            description: 'Automatically called when an Object leaves a Scripting Zone.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectLeaveScriptingZone'
          },
          {
            snippet: 'onObjectLoopingEffect(object, index)\n\t${0:-- body...}\nend'
            displayText: 'onObjectLoopingEffect(Object object, int index)'
            type: 'function'
            description: "Automatically called when an asset Object's loop is started."
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectLoopingEffect'
          },
          {
            snippet: 'onObjectPickedUp(player_color, picked_up_object)\n\t${0:-- body...}\nend'
            displayText: 'onObjectPickedUp(string player_color, Object picked_up_object)'
            type: 'function'
            description: 'Automatically called when an Object is picked up.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectPickedUp'
          },
          {
            snippet: 'onObjectRandomize(object, player_color)\n\t${0:-- body...}\nend'
            displayText: 'onObjectRandomize(Object object, string player_color)'
            type: 'function'
            description: 'Automatically called when an asset Object is randomized by player_color.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectRandomize'
          },
          {
            snippet: 'onObjectSpawn(object)\n\t${0:-- body...}\nend'
            displayText: 'onObjectSpawn(Object object)'
            type: 'function'
            description: 'Automatically called when an Object is spawned.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectSpawn'
          },
          {
            snippet: 'onObjectTriggerEffect(object, index)\n\t${0:-- body...}\nend'
            displayText: 'onObjectTriggerEffect(Object object, int index)'
            type: 'function'
            description: 'Automatically called when an asset Object is triggered.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectTriggerEffect'
          },
          {
            snippet: 'onPlayerChangedColor(player_color)\n\t${0:-- body...}\nend'
            displayText: 'onPlayerChangedColor(string player_color)'
            type: 'function'
            description: 'Automatically called when a Player changes color.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onPlayerChangedColor'
          },
          {
            snippet: 'onPlayerTurnEnd(player_color_end, player_color_next)\n\t${0:-- body...}\nend'
            displayText: 'onPlayerTurnEnd(string player_color_end, string player_color_next)'
            type: 'function'
            description: 'Automatically called at the end of a Player\'s turn.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onPlayerTurnEnd'
          },
          {
            snippet: 'onPlayerTurnStart(player_color_start, player_color_previous)\n\t${0:-- body...}\nend'
            displayText: 'onPlayerTurnStart(string player_color_start, string player_color_previous)'
            type: 'function'
            description: 'Automatically called at the start of a Player\'s turn.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onPlayerTurnStart'
          },
          {
            snippet: 'onSave()\n\t${0:-- body...}\nend'
            displayText: 'onSave()'
            type: 'function'
            description: 'Automatically called when the game saves (including auto-save for Rewinding).'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onSave'
          },
          {
            snippet: 'update()\n\t${0:-- body...}\nend'
            displayText: 'update()'
            type: 'function'
            description: 'Automatically called once every frame.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#update'
          },
        ]

      # Section: Globally accessible constants & functions
      else if (not (line.endsWith("}") || line.endsWith(")") || line.endsWith("]"))) and not line.includes("function ") and not this_token.includes("for ") and line.match(/\w$/)
        suggestions = [
          # Constants
          {
            snippet: 'coroutine'
            displayText: 'coroutine'
            type: 'constant'
            description: 'The coroutine class.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#6.2'
          },
          {
            snippet: 'Global'
            displayText: 'Global'
            type: 'constant'
            description: 'A reference to the Global Script.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object'
          },
          {
            snippet: 'JSON'
            displayText: 'JSON'
            type: 'constant'
            description: 'The JSON class.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/json'
          },
          {
            snippet: 'Lighting'
            displayText: 'Lighting'
            type: 'constant'
            description: 'The Lighting class.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-lighting/'
          },
          {
            snippet: 'math'
            displayText: 'math'
            type: 'constant'
            description: 'The math class.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#6.6'
          },
          {
            snippet: 'os'
            displayText: 'os'
            type: 'constant'
            description: 'The os class.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#6.9'
          },
          {
            snippet: 'Physics'
            displayText: 'Physics'
            type: 'constant'
            description: 'The Physics class.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-physics/'
          },
          {
            snippet: 'Player'
            displayText: 'Player'
            type: 'constant'
            description: 'The Player class.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player'
          },
          {
            snippet: 'self'
            displayText: 'self'
            type: 'constant'
            description: 'A reference to this Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object'
          },
          {
            snippet: 'Timer'
            displayText: 'Timer'
            type: 'constant'
            description: 'The Timer class.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/timer/'
          },
          # Global Management Functions
          {
            snippet: 'addNotebookTab(${1:Table|parameters})'
            displayText: 'addNotebookTab(Table parameters)'
            type: 'function'
            leftLabel: 'int'
            description: 'Adds a new Tab to the Notebook and returns the index of the newly added Tab.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#addNotebookTab'
          },
          {
            snippet:
              'addNotebookTab({\n\t' +
              'title = ${1:-- string},\n\t' +
              'body  = ${2:-- string (BBcode is allowed)},\n\t' +
              'color = ${3:-- string [Grey]},\n' +
              '})'
            displayText: 'addNotebookTab({string title, string body, string color})'
            type: 'function'
            leftLabel: 'int'
            description: 'Adds a new Tab to the Notebook and returns the index of the newly added Tab.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#addNotebookTab'
          },
          {
            snippet: 'clearPixelPaint()'
            displayText: 'clearPixelPaint()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Clears all pixel paint.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#clearPixelPaint'
          },
          {
            snippet: 'clearVectorPaint()'
            displayText: 'clearVectorPaint()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Clears all vector paint.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#clearVectorPaint'
          },
          {
            snippet: 'copy(${1:Table|objects})'
            displayText: 'copy(Table objects)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Copies a list of Objects.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#copy'
          },
          {
            snippet: 'destroyObject(${1:Object|obj})'
            displayText: 'destroyObject(Object obj)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Destroys an Object.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#destroyObject'
          },
          {
            snippet: 'editNotebookTab(${1:Table|parameters})'
            displayText: 'editNotebookTab(Table parameters)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Edits an existing Tab on the Notebook.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#editNotebookTab'
          },
          {
            snippet:
              'editNotebookTab({\n\t' +
              'index = ${1:-- int},\n\t' +
              'title = ${2:-- string},\n\t' +
              'body  = ${3:-- string (BBcode is allowed)},\n\t' +
              'color = ${4:-- string [Grey]},\n' +
              '})'
            displayText: 'editNotebookTab({int index, string title, string body, string color})'
            type: 'function'
            leftLabel: 'bool'
            description: 'Edits an existing Tab on the Notebook.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#editNotebookTab'
          },
          {
            snippet: 'broadcastToAll(${1:string|message}, ${2:Table|text_color})'
            displayText: 'broadcastToAll(string message, Table text_color)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Prints a message to the screen and chat window on all connected clients.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#broadcastToAll'
          },
          {
            snippet: 'broadcastToColor(${1:string|message}, ${2:string|player_color}, ${3:Table|text_color})'
            displayText: 'broadcastToColor(string message, string player_color, Table text_color)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Prints a private message to the screen and chat window to the player matching the player color.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#broadcastToColor'
          },
          {
            snippet: 'flipTable()'
            displayText: 'flipTable()'
            type: 'function'
            leftLabel: 'bool'
            description: 'Flip the table in a fit of rage.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#flipTable'
          },
          {
            snippet: 'getAllObjects()'
            displayText: 'getAllObjects()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns a Table of all the spawned Objects in the game.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getAllObjects'
          },
          {
            snippet: 'getNotebookTabs()'
            displayText: 'getNotebookTabs()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns a Table of Tables of all of the Tabs in the Notebook.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getNotebookTabs'
          },
          {
            snippet: 'getNotebookTabs()$1\n\t-- getNotebookTabs returns:\n\t-- {{int index, string title, string body, string color}, ...}'
            displayText: 'getNotebookTabs() -- returns {{int index, string title, string body, string color}, ...}'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns a Table of Tables of all of the Tabs in the Notebook.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getNotebookTabs'
          },
          {
            snippet: 'getNotes()'
            displayText: 'getNotes()'
            type: 'function'
            leftLabel: 'string'
            description: 'Returns the current on-screen notes as a string.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getNotes'
          },
          {
            snippet: 'getObjectFromGUID(${1:string|guid})'
            displayText: 'getObjectFromGUID(string guid)'
            type: 'function'
            leftLabel: 'Object'
            description: 'Gets a reference to an Object from a GUID. Will return nil if the Object doesn’t exist.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getObjectFromGUID'
          },
          {
            snippet: 'getSeatedPlayers()'
            displayText: 'getSeatedPlayers()'
            type: 'function'
            leftLabel: 'Table'
            description: 'Returns an indexed Lua Table of all the seated Player colors.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getSeatedPlayers'
          },
          {
            snippet: 'paste(${1:Table|parameters})'
            displayText: 'paste(Table parameters)'
            type: 'function'
            leftLabel: 'Table'
            description: 'Pastes copied Objects and returns a Table of references to the new Objects.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#copy'
          },
          {
            snippet:
              'paste({\n\t' +
              'position     = ${1:-- Vector  [x=0, y=3, z=0]},\n\t' +
              'snap_to_grid = ${2:-- boolean [false]},\n' +
              '})'
            displayText: 'paste({Vector position, bool snap_to_grid})'
            type: 'function'
            leftLabel: 'Table'
            description: 'Pastes copied Objects and returns a Table of references to the new Objects.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#copy'
          },
          {
            snippet: 'print(${1:string|message})'
            displayText: 'print(string message)'
            type: 'function'
            description: 'Prints a message to the chat window only on the host.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#print'
          },
          {
            snippet: 'printToAll(${1:string|message}, ${2:Table|text_color})'
            displayText: 'printToAll(string message, Table text_color)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Prints a message to the chat window on all connected clients.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#printToAll'
          },
          {
            snippet: 'printToColor(${1:string|message}, ${2:string|player_color}, ${3:Table|text_color})'
            displayText: 'printToColor(string message, string player_color, Table text_color)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Prints a message to the chat window of a specific Player.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#printToColor'
          },
          {
            snippet: 'removeNotebookTab(${1:int|index})'
            displayText: 'removeNotebookTab(int index)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Removes a Tab from the Notebook at a given index.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#removeNotebookTab'
          },
          {
            snippet: 'setNotes(${1:string|notes})'
            displayText: 'setNotes(string notes)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Sets the current on-screen notes. BBCOde is allowed for styling.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#setNotes'
          },
          {
            snippet: 'spawnObject(${1:Table|paremeters})'
            displayText: 'spawnObject(Table parameters)'
            type: 'function'
            leftLabel: 'Object'
            description: 'Spawns an Object and returns a reference to it.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#spawnObject'
          },
          {
            snippet:
              'spawnObject({\n\t' +
              'type           = ${1:-- string},\n\t' +
              'position       = ${2:-- Vector [x=0, y=3, z=0]},\n\t' +
              'rotation       = ${3:-- Vector [x=0, y=0, z=0]},\n\t' +
              'scale          = ${4:-- Vector [x=1, y=1, z=1]},\n\t' +
              'callback       = ${5:-- string},\n\t' +
              'callback_owner = ${6:-- Object},\n\t' +
              'params         = ${7:-- Table},\n\t' +
              'snap_to_grid   = ${8:-- bool},\n' +
              '})'
            displayText: 'spawnObject({string type, Vector position, Vector rotation, Vector scale, string callback, Object callback_owner, Table params, bool snap_to_grid})'
            type: 'function'
            leftLabel: 'Object'
            description: 'Spawns an Object and returns a reference to it.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#spawnObject'
          },
          {
            snippet: 'startLuaCoroutine(${1:Object|func_owner}, ${2:string|func_name})'
            displayText: 'startLuaCoroutine(Object func_owner, string func_name)'
            type: 'function'
            leftLabel: 'bool'
            description: 'Starts a Lua function as a coroutine.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#startLuaCoroutine'
          },
          {
            snippet: 'stringColorToRGB(${1:string|player_color})'
            displayText: 'stringColorToRGB(string player_color)'
            type: 'function'
            leftLabel: 'Table'
            description: 'Converts a color string (player colors) to its RGB values.'
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#stringColorToRGB'
          },
          {
            snippet: 'tonumber(${1:e})'
            displayText: 'tonumber(e [, base])'
            type: 'function'
            leftLabel: 'number'
            description: 'When called with no base, tonumber tries to convert its argument to a number.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-tonumber'
          },
          {
            snippet: 'tostring(${1:v})'
            displayText: 'tostring(v)'
            type: 'function'
            leftLabel: 'number'
            description: 'Receives a value of any type and converts it to a string in a reasonable format.'
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-tostring'
          },
        ]

        # End of sections!

      # Add smart getObjectFromGUID after static getObjectFromGUID if appropriate
      if this_token.includes('=')
        for suggestion, index in suggestions
          if suggestion.snippet.startsWith('getObjectFromGUID')
            identifier = line.match(/([^\s]+)\s*=[^=]*$/)[1]
            guid_string =  atom.config.get('tabletopsimulator-lua.style.guidPostfix')
            insertion_point = index
            if identifier.match(/.*\w$/)
              insertion_point = insertion_point + 1
              suggestion = identifier + guid_string
              suggestions.splice(insertion_point, 0,
                    {
                      snippet: 'getObjectFromGUID(' + suggestion + ')'
                      displayText: 'getObjectFromGUID(->' +  suggestion + ')'
                      type: 'function'
                      leftLabel: 'Object'
                      description: 'Gets a reference to an Object from a GUID. Will return nil if the Object doesn’t exist.'
                      descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getObjectFromGUID'
                    }
              )
            for c, i in identifier
              if c.match(/[^\w]/)
                pre  = identifier.substring(0, i)
                post = identifier.substring(i)
                if pre.match(/.*\w$/)
                  insertion_point = insertion_point + 1
                  suggestion = pre + guid_string + post
                  suggestions.splice(insertion_point, 0,
                        {
                          snippet: 'getObjectFromGUID(' + suggestion + ')'
                          displayText: 'getObjectFromGUID(->' +  suggestion + ')'
                          type: 'function'
                          leftLabel: 'Object'
                          description: 'Gets a reference to an Object from a GUID. Will return nil if the Object doesn’t exist.'
                          descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getObjectFromGUID'
                        }
                  )
            break

      # Convert function parameters to user desired output
      match_pattern = /\${([0-9]+):([0-9a-zA-Z_]+)\|([0-9a-zA-Z_]+)}/g
      replace_type = atom.config.get('tabletopsimulator-lua.autocomplete.parameterToDisplay')
      if replace_type == 'both'
        replace_pattern = (match, index, parameter_type, parameter_name) ->
          format = atom.config.get('tabletopsimulator-lua.style.parameterFormat')
          format = format.replace("TYPE", parameter_type.toUpperCase())
          format = format.replace("Type", capitalize(parameter_type))
          format = format.replace("type", parameter_type)
          format = format.replace("NAME", parameter_name.toUpperCase())
          format = format.replace("Name", capitalize(parameter_name))
          format = format.replace("name", parameter_name)
          return '${' + index + ':' + format + '}'
      else
        replace_pattern = parameter_patterns[replace_type]
      for suggestion in suggestions
          suggestion.snippet = suggestion.snippet.replace(match_pattern, replace_pattern)

      # Done!
      resolve(suggestions)


# Replacement patterns for autocomplete parameters
parameter_patterns = {
  'type': '$${$1:$2}',
  'name': '$${$1:$3}',
  'both': '$${$1:$2_$3}',
  'none': '$${$1:}',
}

# First letter to caps
capitalize = (s) ->
  return s.substring(0,1).toUpperCase() + s.substring(1)
