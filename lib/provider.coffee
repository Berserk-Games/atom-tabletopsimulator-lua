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

      if scopeDescriptor.scopes[1] == "keyword.operator.lua" || scopeDescriptor.scopes[1] == "string.quoted.double.lua" || scopeDescriptor.scopes[1] == "string.quoted.single.lua"
        resolve([])
        return

      # Substring up until this position
      line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])

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
      this_token_intact = true  # is it just ajphanumerics?
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
      #console.log scopeDescriptor.scopes[1]

      # If we're in the middle of typing a number then suggest nothing on .
      if prefix == "." and previous_token.match(/^[0-9]$/)
        resolve([])
        return

      # Control blocks
      if (line.endsWith(" do"))
        suggestions = [
          {
            snippet: 'do\n\t$1\nend'
            displayText: 'do...end' # (optional)
          },
        ]
      else if (line.endsWith(" then") and not line.includes("elseif"))
        suggestions = [
          {
            snippet: 'then\n\t$1\nend'
            displayText: 'then...end' # (optional)
          },
        ]
      else if (line.endsWith(" repeat"))
        suggestions = [
          {
            snippet: 'repeat\n\t$1\nuntil $2'
            displayText: 'repeat...until' # (optional)
          },
        ]
      else if (line.includes("function") && line.endsWith(")"))
        function_name = this_token.substring(0, this_token.lastIndexOf("("))
        function_name = function_name.substring(function_name.lastIndexOf(" ") + 1)
        function_name = function_name + atom.config.get('tabletopsimulator-lua.style.coroutinePostfix')
        suggestions = [
          {
            snippet: '\n\t$1\nend'
            displayText: 'function...end' # (optional)
          },
          {
            snippet: '\n\tfunction ' + function_name + "()\n\t\t$1\n\t\treturn 1\n\tend\n\tstartLuaCoroutine(self, '" + function_name + "')\nend"
            displayText: 'function...coroutine...end' # (optional)
          },
        ]
      # Short circuit some common lua keywords
      else if (line.endsWith(" else") || line.endsWith(" elseif") || line.endsWith(" end") || line == "end")
        suggestions = []
      # Global object
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "Global") || line.endsWith("Global.") || (previous_token == "Global" && this_token_intact)
        #console.log "FOUND GLOBAL"
        suggestions = [
          # Member Variables
          {
            #text: 'getObjectFromGUID()' # OR
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
            displayText: 'script_state' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            description: 'Returns the Global saved Lua script state.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#script_state' # (optional)
          },
          # Functions
          {
            snippet: 'call(${1:string|function_name}, ${2:Table|parameters})'
            displayText: 'call(string function_name, Table parameters)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'variable' # (optional)
            description: 'Calls a Lua function owned by the Global Script and passes an optional Table as parameters to the function.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#call' # (optional)
          },
          {
            snippet: 'getTable(${1:string|table_name})'
            displayText: 'getTable(string table_name)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Gets a Lua Table for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getTable' # (optional)
          },
          {
            snippet: 'getVar(${1:string|variable_name})'
            displayText: 'getVar(string variable_name)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'variable' # (optional)
            description: 'Gets a Lua variable for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getVar' # (optional)
          },
          {
            snippet: 'setTable(${1:string|table_name}, ${2:Table|table})'
            displayText: 'setTable(string table_name, Table table)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets a Lua Table for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setTable' # (optional)
          },
          {
            snippet: 'setVar(${1:string|variable_name}, ${2:variable|value})'
            displayText: 'setVar(string variable_name, variable value)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets a Lua variable for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setVar' # (optional)
          },
        ]
      # math Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "math") || line.endsWith("math.") || (previous_token == "math" && this_token_intact)
        #console.log "FOUND MATH"
        suggestions = [
          # Member Variables
          {
            snippet: 'huge'
            displayText: 'huge' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'float' # (optional)
            description: 'The value HUGE_VAL, a value larger than or equal to any other numerical value.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.huge' # (optional)
          },
          {
            snippet: 'pi'
            displayText: 'pi' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'float' # (optional)
            description: 'The value of p.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.pi' # (optional)
          },
          # Functions
          {
            snippet: 'abs(${1:float|x})'
            displayText: 'abs(float x)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns the absolute value of x.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.abs' # (optional)
          },
          {
            snippet: 'acos(${1:float|x})'
            displayText: 'acos(float x)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns the arc cosine of x (in radians).' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.acos' # (optional)
          },
          {
            snippet: 'asin(${1:float|x})'
            displayText: 'asin(float x)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns the arc sine of x (in radians).' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.asin' # (optional)
          },
          {
            snippet: 'atan(${1:float|x})'
            displayText: 'atan(float x)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns the arc tangent of x (in radians).' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.atan' # (optional)
          },
          {
            snippet: 'atan2(${1:float|y}, ${2:float|x})'
            displayText: 'atan2(float y, float x)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns the arc tangent of y/x (in radians), but uses the signs of both parameters to find the quadrant of the result.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.atan2' # (optional)
          },
          {
            snippet: 'ceil(${1:float|x})'
            displayText: 'ceil(float x)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            description: 'Returns the smallest integer larger than or equal to x.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.ceil' # (optional)
          },
          {
            snippet: 'cos(${1:float|x})'
            displayText: 'cos(float x)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns the cosine of x (assumed to be in radians).' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.cos' # (optional)
          },
          {
            snippet: 'cosh(${1:float|x})'
            displayText: 'cosh(float x)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns the hyperbolic cosine of x.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.cosh' # (optional)
          },
          {
            snippet: 'deg(${1:float|x})'
            displayText: 'deg(float x)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns the angle x (given in radians) in degrees.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.deg' # (optional)
          },
          {
            snippet: 'exp(${1:float|x})'
            displayText: 'exp(float x)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns the value e^x.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.exp' # (optional)
          },
          {
            snippet: 'floor(${1:float|x})'
            displayText: 'floor(float x)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            description: 'Returns the largest integer smaller than or equal to x.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.floor' # (optional)
          },
          {
            snippet: 'fmod(${1:float|x}, ${2:float|y})'
            displayText: 'fmod(float x, float y)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns the remainder of the division of x by y that rounds the quotient towards zero.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.fmod' # (optional)
          },
          {
            snippet: 'frexp(${1:float|x})'
            displayText: 'frexp(float x)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns m and e such that x = m2^e, e is an integer and the absolute value of m is in the range [0.5, 1) (or zero when x is zero).' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.frexp' # (optional)
          },
          {
            snippet: 'ldexp(${1:float|m}, ${2:int|e})'
            displayText: 'ldexp(float m, int e)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns m2^e (e should be an integer).' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.ldexp' # (optional)
          },
          {
            snippet: 'log(${1:float|x})'
            displayText: 'log(float x [, base])' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns the logarithm of x in the given base.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.log' # (optional)
          },
          {
            snippet: 'max(${1:float|x}, ${2:...})'
            displayText: 'max(float x, ...)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns the maximum value among its arguments.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.max' # (optional)
          },
          {
            snippet: 'min(${1:float|x}, ${2:...})'
            displayText: 'min(float x, ...)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns the minimum value among its arguments.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.min' # (optional)
          },
          {
            snippet: 'modf(${1:float|x})'
            displayText: 'modf(float x)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns two numbers, the integral part of x and the fractional part of x.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.modf' # (optional)
          },
          {
            snippet: 'pow(${1:float|x}, ${2:float|y})'
            displayText: 'pow(float x, float y)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns x^y. (You can also use the expression x^y to compute this value.)' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.pow' # (optional)
          },
          {
            snippet: 'rad(${1:float|x})'
            displayText: 'rad(float x)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns the angle x (given in degrees) in radians.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.rad' # (optional)
          },
          {
            snippet: 'random()'
            displayText: 'random([m [, n]])' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'This function is an interface to the simple pseudo-random generator function rand provided by Standard C.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.random' # (optional)
          },
          {
            snippet: 'randomseed(${1:int|x})'
            displayText: 'randomseed(int x)' # (optional)
            type: 'function' # (optional)
            description: 'Sets x as the "seed" for the pseudo-random generator: equal seeds produce equal sequences of numbers.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.randomseed' # (optional)
          },
          {
            snippet: 'sin(${1:float|x})'
            displayText: 'sin(float x)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns the sine of x (assumed to be in radians).' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.sin' # (optional)
          },
          {
            snippet: 'sinh(${1:float|x})'
            displayText: 'sinh(float x)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns the hyperbolic sine of x.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.sinh' # (optional)
          },
          {
            snippet: 'sqrt(${1:float|x})'
            displayText: 'sqrt(float x)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns the square root of x. (You can also use the expression x^0.5 to compute this value.)' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.sqrt' # (optional)
          },
          {
            snippet: 'tan(${1:float|x})'
            displayText: 'tan(float x)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns the tangent of x (assumed to be in radians).' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.tan' # (optional)
          },
          {
            snippet: 'tanh(${1:float|x})'
            displayText: 'tanh(float x)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Returns the hyperbolic tangent of x.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.tanh' # (optional)
          },
        ]
      # coroutine Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "coroutine") || line.endsWith("coroutine.") || (previous_token == "coroutine" && this_token_intact)
        #console.log "FOUND COROUTINE"
        suggestions = [
          {
            snippet: 'create(${1:function|f})'
            displayText: 'create(function f)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'thread' # (optional)
            description: 'Creates a new coroutine, with body f.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-coroutine.create' # (optional)
          },
          {
            snippet: 'resume(${1:coroutine|co})'
            displayText: 'resume(coroutine co [, val1, ···])' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Starts or continues the execution of coroutine co.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-coroutine.resume' # (optional)
          },
          {
            snippet: 'running()'
            displayText: 'running()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns the running coroutine plus a boolean, true when the running coroutine is the main one.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-coroutine.running' # (optional)
          },
          {
            snippet: 'status(${1:coroutine|co})'
            displayText: 'status(coroutine co)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'string' # (optional)
            description: 'Returns the status of coroutine co, as a string.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-coroutine.status' # (optional)
          },
          {
            snippet: 'wrap(${1:function|f})'
            displayText: 'wrap(function f)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Creates a new coroutine, with body f.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-coroutine.wrap' # (optional)
          },
          {
            snippet: 'yield(${1:int|value})'
            displayText: 'yield(int value)' # (optional)
            type: 'function' # (optional)
            description: 'Suspends the execution of the calling coroutine.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-coroutine.yield' # (optional)
          },
        ]
      # os Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "os") || line.endsWith("os.") || (previous_token == "os" && this_token_intact)
        #console.log "FOUND OS"
        suggestions = [
          {
            snippet: 'clock()'
            displayText: 'clock()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            description: 'Returns an approximation of the amount in seconds of CPU time used by the program.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-os.clock' # (optional)
          },
          {
            snippet: 'date()'
            displayText: 'date([format [, time]])' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns a string or a table containing date and time.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-os.date' # (optional)
          },
          {
            snippet: 'difftime(${1:time|t2}, ${2:time|t1})'
            displayText: 'difftime(t2, t1)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            description: 'Returns the number of seconds from time t1 to time t2.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-os.difftime' # (optional)
          },
          {
            snippet: 'time()'
            displayText: 'time([table])' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns the current time when called without arguments, or a time representing the date and time specified by the given table.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-os.time' # (optional)
          },
        ]
      # Clock Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "Clock") || line.endsWith("Clock.") || (previous_token == "Clock" && this_token_intact)
        #console.log "FOUND CLOCK"
        suggestions = [
          # Member Variables
          {
            snippet: 'paused'
            displayText: 'paused' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'If the Clock’s timer is paused. Setting this value will pause or resume the timer.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/clock/#paused' # (optional)
          },
          # Functions
          {
            snippet: 'getValue()'
            displayText: 'getValue()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            description: 'Returns the current value in stopwatch or timer mode as the number of seconds.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/clock/#getValue' # (optional)
          },
          {
            snippet: 'pauseStart()'
            displayText: 'pauseStart()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Toggle function for pausing and resuming a stopwatch or timer on the Clock.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/clock/#pauseStart' # (optional)
          },
          {
            snippet: 'setValue(${1:int|seconds})'
            displayText: 'setValue(int seconds)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Switches the clock to timer mode and sets the timer to the given value in seconds.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/clock/#setValue' # (optional)
          },
          {
            snippet: 'startStopwatch()'
            displayText: 'startStopwatch()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Switches the Clock to stopwatch mode and begins the stopwatch from 0.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/clock/#startStopwatch' # (optional)
          },
          {
            snippet: 'showCurrentTime()'
            displayText: 'showCurrentTime()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Switches the Clock back to displaying the current time.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/clock/#showCurrentTime' # (optional)
          },
        ]
      # Counter Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "Counter") || line.endsWith("Counter.") || (previous_token == "Counter" && this_token_intact)
        #console.log "FOUND COUNTER"
        suggestions = [
          # Functions
          {
            snippet: 'clear()'
            displayText: 'clear()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Resets the Counter value back to 0.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/counter/#clear' # (optional)
          },
          {
            snippet: 'decrement()'
            displayText: 'decrement()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Decrements the Counter’s value by 1.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/counter/#decrement' # (optional)
          },
          {
            snippet: 'getValue()'
            displayText: 'getValue()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            description: 'Returns the current value of the Counter.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/counter/#getValue' # (optional)
          },
          {
            snippet: 'increment()'
            displayText: 'increment()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Increments the Counter’s value by 1.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/counter/#increment' # (optional)
          },
          {
            snippet: 'setValue(${1:int|seconds})'
            displayText: 'setValue(int seconds)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the current value of the Counter.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/counter/#setValue' # (optional)
          },
        ]
      # Lighting
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "Lighting") || line.endsWith("Lighting.") || (previous_token == "Lighting" && this_token_intact)
        suggestions = [
          {
            snippet: 'ambient_type'
            displayText: 'ambient_type' # (optional)
            type: 'property' # (optional)
            leftLabel: 'int' # (optional)
            description: 'The source of the ambient light. 1 = Background, 2 = Gradient.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-lighting/#ambient_type' # (optional)
          },
          {
            snippet: 'ambient_intensity'
            displayText: 'ambient_intensity' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            description: 'The strength of the ambient light either from the background or gradient. Range is 0-4.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-lighting/#ambient_intensity' # (optional)
          },
          {
            snippet: 'light_intensity'
            displayText: 'light_intensity' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            description: 'The strength of the directional light shining down in the scene. Range is 0-4.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-lighting/#light_intensity' # (optional)
          },
          {
            snippet: 'reflection_intensity'
            displayText: 'reflection_intensity' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            description: 'The strength of the reflections from the background. Range is 0-1.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-lighting/#reflection_intensity' # (optional)
          },
          {
            snippet: 'apply()'
            displayText: 'apply()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Applies all changed made to the Lighting class. This must be called for these changes to take affect.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-lighting/#apply' # (optional)
          },
          {
            snippet: 'getAmbientEquatorColor()'
            displayText: 'getAmbientEquatorColor()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns the Color of the gradient equator.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-lighting/#getAmbientEquatorColor' # (optional)
          },
          {
            snippet: 'getAmbientGroundColor()'
            displayText: 'getAmbientGroundColor()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns the Color of the gradient ground.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-lighting/#getAmbientGroundColor' # (optional)
          },
          {
            snippet: 'getAmbientSkyColor()'
            displayText: 'getAmbientSkyColor()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns the Color of the gradient sky.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-lighting/#getAmbientSkyColor' # (optional)
          },
          {
            snippet: 'getLightColor()'
            displayText: 'getLightColor()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns the Color of the directional light.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-lighting/#getLightColor' # (optional)
          },
          {
            snippet: 'setAmbientEquatorColor(${1:Table|color})'
            displayText: 'setAmbientEquatorColor(Table color)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the Color of the gradient equator.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-physics/#setAmbientEquatorColor' # (optional)
          },
          {
            snippet: 'setAmbientGroundColor(${1:Table|color})'
            displayText: 'setAmbientGroundColor(Table color)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the Color of the ambient ground.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-physics/#setAmbientGroundColor' # (optional)
          },
          {
            snippet: 'setAmbientSkyColor(${1:Table|color})'
            displayText: 'setAmbientSkyColor(Table color)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the Color of the gradient sky.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-physics/#setAmbientSkyColor' # (optional)
          },
          {
            snippet: 'setLightColor(${1:Table|color})'
            displayText: 'setLightColor(Table color)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the Color of the directional light.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-physics/#setLightColor' # (optional)
          },
        ]
      # Physics
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "Physics") || line.endsWith("Physics.") || (previous_token == "Physics" && this_token_intact)
        suggestions = [
          {
            snippet: 'cast(${1:Table|info})'
            displayText: 'cast(Table info)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Casts a shape based on Info and returns a table of multiple Hit.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-physics/#cast' # (optional)
          },
          {
            snippet:
              'cast({\n\t' +
              'origin        = ${1:-- Vector},\n\t' +
              'direction     = ${2:-- Vector},\n\t' +
              'type          = ${3:-- int (1: Ray, 2: Sphere, 3: Box)},\n\t' +
              'size          = ${4:-- Vector},\n\t' +
              'orientation   = ${5:-- Vector},\n\t' +
              'max_distance  = ${6:-- float},\n\t' +
              'debug         = ${7:-- bool (true = visualize cast)},\n' +
              '}) -- returns {{Vector point, Vector normal, float distance, Object hit_object}, ...}'
            displayText: 'cast({Vector origin, Vector direction, int type, Vector size, Vector orientation, float max_distanc, bool debug})' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Casts a shape based on Info and returns a table of multiple Hit.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-physics/#cast' # (optional)
          },
          {
            snippet: 'getGravity()'
            displayText: 'getGravity()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns the gravity Vector.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-physics/#getGravity' # (optional)
          },
          {
            snippet: 'setGravity(${1:Table|vector})'
            displayText: 'setGravity(Table vector)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the gravity Vector.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-physics/#setGravity' # (optional)
          },
        ]
      # Player Colors
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "Player") || line.endsWith("Player.") || (previous_token == "Player" && this_token_intact)
        #console.log "FOUND Player"
        suggestions = [
          {
            snippet: 'Black'
            displayText: 'Black' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            description: 'The Black player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          {
            snippet: 'Blue'
            displayText: 'Blue' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            description: 'The Blue player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          {
            snippet: 'Brown'
            displayText: 'Brown' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            description: 'The Brown player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          {
            snippet: 'Green'
            displayText: 'Green' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            description: 'The Green player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          {
            snippet: 'Orange'
            displayText: 'Orange' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            description: 'The Orange player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          {
            snippet: 'Pink'
            displayText: 'Pink' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            description: 'The Pink player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          {
            snippet: 'Purple'
            displayText: 'Purple' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            description: 'The Purple player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          {
            snippet: 'Red'
            displayText: 'Red' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            description: 'The Red player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          {
            snippet: 'Teal'
            displayText: 'Teal' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            description: 'The Teal player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          {
            snippet: 'White'
            displayText: 'White' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            description: 'The White player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          {
            snippet: 'Yellow'
            displayText: 'Yellow' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            description: 'The Yellow player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          # Functions
          {
            snippet: 'getPlayers()'
            displayText: 'getPlayers()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns a Table of all Players.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getPlayers' # (optional)
          },
          {
            snippet: 'getSpectators()'
            displayText: 'getSpectators()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns a Table of spectator Players.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getSpectators' # (optional)
          },
        ]
      # Player Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token_2 == "Player") ||  previous_token.substring(0, 7) == "Player["
        #console.log "FOUND Player Class"
        suggestions = [
          # Member Variables
          {
            snippet: 'admin'
            displayText: 'admin' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Is the player currently promoted or hosting the game? Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#admin' # (optional)
          },
          {
            snippet: 'blindfolded'
            displayText: 'blindfolded' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Is the player blindfolded?' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#blindfolded' # (optional)
          },
          {
            snippet: 'color'
            displayText: 'color' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            description: 'The player\'s color. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#color' # (optional)
          },
          {
            snippet: 'host'
            displayText: 'host' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Is the player the host?.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#host' # (optional)
          },
          {
            snippet: 'lift_height'
            displayText: 'lift_height' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            description: 'The player\'s lift height from 0 to 1.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#lift_height' # (optional)
          },
          {
            snippet: 'promoted'
            displayText: 'promoted' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Is the player currently promoted? Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#promoted' # (optional)
          },
          {
            snippet: 'seated'
            displayText: 'seated' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            description: 'Is the player currently seated at the table? Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#seated' # (optional)
          },
          {
            snippet: 'steam_id'
            displayText: 'steam_id' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            description: 'The player\'s Steam ID. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#steam_id' # (optional)
          },
          {
            snippet: 'steam_name'
            displayText: 'steam_name' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            description: 'The player\'s Steam name. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#steam_name' # (optional)
          },
          {
            snippet: 'team'
            displayText: 'team' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            description: 'The player\'s team. Team names: "None", "Clubs", "Diamonds", "Hearts", "Spades". Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#team' # (optional)
          },
          # Functions
          {
            snippet: 'attachCameraToObject(${1:Table|parameters})'
            displayText: 'attachCameraToObject(Table parameters)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Makes a player\'s camera follow an Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#attachCameraToObject' # (optional)
          },
          {
            snippet:
              'attachCameraToObject({\n\t' +
              'object = ${1:-- Object},\n\t' +
              'offset = ${2:-- Vector [x=0, y=0, z=0]},\n' +
              '})'
            displayText: 'attachCameraToObject({Object object, Vector offset})' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Makes a player\'s camera follow an Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#attachCameraToObject' # (optional)
          },
          {
            snippet: 'broadcast(${1:string|message})'
            displayText: 'broadcast(string message)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Broadcasts a message to the player. This also sends a message to the top center of the screen.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#broadcast' # (optional)
          },
          {
            snippet: 'broadcast(${1:string|message}, $(2:string|color))'
            displayText: 'broadcast(string message, string color)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Broadcasts a message to the player with Color. This also sends a message to the top center of the screen.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#broadcast' # (optional)
          },
          {
            snippet: 'changeColor(${1:string|new_color})'
            displayText: 'changeColor(string new_color)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Changes the player\'s color.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#changeColor' # (optional)
          },
          {
            snippet: 'getHandObjects()'
            displayText: 'getHandObjects()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns a Lua Table as a list of all the Cards and Mahjong Tiles in the player\'s hand.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getHandObjects' # (optional)
          },
          {
            snippet: 'getHandTransform()'
            displayText: 'getHandTransform()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns the Transform of the player’s hand.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getHandTransform' # (optional)
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
            displayText: 'getHandTransform() -- returns {...' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns the Transform of the player’s hand.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getHandTransform' # (optional)
          },


          {
            snippet: 'getPlayerHand()'
            displayText: 'getPlayerHand()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns a Lua Table with the position and rotation of the given player\'s hand.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getPlayerHand' # (optional)
          },
          {
            snippet: 'getPointerPosition()'
            displayText: 'getPointerPosition()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns the position of the given player color\'s pointer.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getPointerPosition' # (optional)
          },
          {
            snippet: 'getPointerRotation()'
            displayText: 'getPointerRotation()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns the y-axis rotation of the given player color\'s pointer in degrees.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getPointerRotation' # (optional)
          },
          {
            snippet: 'getHoldingObjects()'
            displayText: 'getHoldingObjects()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns a Lua Table representing a list of all the Objects currently held by the player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getHoldingObjects' # (optional)
          },
          {
            snippet: 'getSelectedObjects()'
            displayText: 'getSelectedObjects()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns a Lua Table representing a list of all the Objects currently selected by the player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getPointerRotation' # (optional)
          },
          {
            snippet: 'kick()'
            displayText: 'kick()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Kicks the player from the game.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#kick' # (optional)
          },
          {
            snippet: 'lookAt(${1:Table|parameters})'
            displayText: 'lookAt(Table parameters)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Moves the Player\'s camera to look at a specific point.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#lookAt' # (optional)
          },
          {
            snippet:
              'lookAt({\n\t' +
              'position  = ${1:-- Vector (required)},\n\t' +
              'pitch     = ${2:-- float},\n\t' +
              'yaw       = ${3:-- float},\n\t' +
              'distance  = ${4:-- float},\n' +
              '})'
            displayText: 'lookAt({Vector position, float pitch, float yaw, float distance})' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Moves the Player\'s camera to look at a specific point.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#lookAt' # (optional)
          },
          {
            snippet: 'mute()'
            displayText: 'mute()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Mutes or unmutes the player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#mute' # (optional)
          },
          {
            snippet: 'print(${1:string|message})'
            displayText: 'print(string message)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Prints a message to the player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#print' # (optional)
          },
          {
            snippet: 'print(${1:string|message}, $(2:string|color))'
            displayText: 'print(string message, string color)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Prints a message to the player with Color.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#print' # (optional)
          },
          {
            snippet: 'promote()'
            displayText: 'promote()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Promotes or demotes the player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#promote' # (optional)
          },
          {
            snippet: 'setHandTransform(${1:Table|transform})'
            displayText: 'setHandTransform(Table transform)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the Transform of the player’s hand.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#setHandTransform' # (optional)
          },
          {
            snippet:
              'setHandTransform({\n\t' +
              'position  = ${1:-- Vector},\n\t' +
              'rotation  = ${2:-- Vector},\n\t' +
              'scale     = ${3:-- Vector},\n\t' +
              'forward   = ${4:-- Vector},\n\t' +
              'right     = ${5:-- Vector},\n\t' +
              'up        = ${6:-- Vector},\n' +
              '})'
            displayText: 'setHandTransform({Vector position, Vector rotation, Vector scale, Vector forward, Vector right, Vector up})' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the Transform of the player’s hand.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#setHandTransform' # (optional)
          },

        ]
      # JSON Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "JSON") || line.endsWith("JSON.") || (previous_token == "JSON" && this_token_intact)
        #console.log "FOUND JSON"
        suggestions = [
          # Functions
          {
            snippet: 'decode(${1:string|json_string})'
            displayText: 'decode(string json_string)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'variable' # (optional)
            description: 'Decodes a valid JSON string into a Lua string, number, or Table.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/json/#decode' # (optional)
          },
          {
            snippet: 'encode(${1:variable})'
            displayText: 'encode(variable)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'string' # (optional)
            description: 'Encodes a Lua string, number, or Table into a valid JSON string. This will not work with Object references.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/json/#encode' # (optional)
          },
          {
            snippet: 'encode_pretty(${1:variable})'
            displayText: 'encode_pretty(variable)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'string' # (optional)
            description: 'Encodes a Lua string, number, or Table into a valid JSON string formatted with indents (Human readable). This will not work with Object references.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/json/#encode_pretty' # (optional)
          },
        ]
      # Timer Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "Timer") || line.endsWith("Timer.") || (previous_token == "Timer" && this_token_intact)
        #console.log "FOUND Timer"
        suggestions = [
          # Functions
          {
            snippet: 'create(${1:Table|parameters})'
            displayText: 'create(Table parameters)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Creates a Timer. Timers are used for calling functions after a delay or repeatedly.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/timer/#create' # (optional)
          },
          {
            snippet:
              'create({\n\t' +
              'identifier      = ${1:-- string (must be unique)},\n\t' +
              'function_name   = ${2:-- string},\n\t' +
              'function_owner  = ${3:-- Object},\n\t' +
              'parameters      = ${4:-- Table},\n\t' +
              'delay           = ${5:-- float  [0 seconds]},\n\t' +
              'repetitions     = ${6:-- int    [1] (0 = infinite)},\n' +
              '})'
            displayText: 'create({Vector position, Vector rotation, string callback, Object callback_owner, Table params, bool flip, string guid, int index, bool top})' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Creates a Timer. Timers are used for calling functions after a delay or repeatedly.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/timer/#create' # (optional)
          },
          {
            snippet: 'destroy(${1:string|identifier})'
            displayText: 'destroy(string identifier)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Destroys an existing timer.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/timer/#destroy' # (optional)
          },
        ]
      # RPGFigurine Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "RPGFigurine") || line.endsWith("RPGFigurine.") || (previous_token == "RPGFigurine" && this_token_intact)
        #console.log "FOUND RPGFigurine"
        suggestions = [
          # Functions
          {
            snippet: 'attack()'
            displayText: 'attack()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Plays a random attack animation.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/rpgfigurine/#attack' # (optional)
          },
          {
            snippet: 'changeMode()'
            displayText: 'changeMode()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Changes the RPG Figurine\'s current mode.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/rpgfigurine/#changeMode' # (optional)
          },
          {
            snippet: 'die()'
            displayText: 'die()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Plays the death animation. Call die() again to reset the RPG Figurine.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/rpgfigurine/#die' # (optional)
          },
          {
            snippet: 'onAttack(hit_list)\n\t${0:-- body...}\nend'
            displayText: 'onAttack(Table hit_list)' # (optional)
            type: 'function' # (optional)
            description: 'This function is called, if it exists in your script, when this RPGFigurine attacks another RPGFigurine.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/rpgfigurine/#onAttack' # (optional)
          },
          {
            snippet: 'onHit(attacker)\n\t${0:-- body...}\nend'
            displayText: 'onHit(Object attacker)' # (optional)
            type: 'function' # (optional)
            description: 'This function is called, if it exists in your script, when this RPGFigurine is attacked by another RPGFigurine.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/rpgfigurine/#onHit' # (optional)
          },
        ]
      # TextTool Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "TextTool") || line.endsWith("TextTool.") || (previous_token == "TextTool" && this_token_intact)
        #console.log "FOUND TextTool"
        suggestions = [
          # Functions
          {
            snippet: 'getFontColor()'
            displayText: 'getFontColor()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns the current font color as a Lua Table keyed as Table[\'r\'], Table[\'g\'], and Table[\'b\'].' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/texttool/#getFontColor' # (optional)
          },
          {
            snippet: 'getFontSize()'
            displayText: 'getFontSize()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            description: 'Returns the current font size.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/texttool/#getFontSize' # (optional)
          },
          {
            snippet: 'getValue()'
            displayText: 'getValue()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'string' # (optional)
            description: 'Returns the current text.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/texttool/#getValue' # (optional)
          },
          {
            snippet: 'setFontColor(${1:Table|color})'
            displayText: 'setFontColor(Table color)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the current font color. The Lua Table parameter should be keyed as Table[\'r\'], Table[\'g\'], and Table[\'b\'].' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/texttool/#setFontColor' # (optional)
          },
          {
            snippet: 'setFontSize(${1:int|font_size})'
            displayText: 'setFontSize(int font_size)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the current font size.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/texttool/#setFontSize' # (optional)
          },
          {
            snippet: 'setValue(${1:string|text})'
            displayText: 'setValue(string text)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the current text.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/texttool/#setValue' # (optional)
          },
        ]
      # Object
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua" || (tokens.length > 1 && this_token_intact)))
        #console.log "FOUND OBJECT"
        suggestions = [
          # Member Variables
          {
            snippet: 'angular_drag'
            displayText: 'angular_drag' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            description: 'The Object\'s angular drag.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#angular_drag' # (optional)
          },
          {
            snippet: 'auto_raise'
            displayText: 'auto_raise' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Should this Object automatically raise above other Objects when held?' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#auto_raise' # (optional)
          },
          {
            snippet: 'bounciness'
            displayText: 'bounciness' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            description: 'The Object\'s bounciness.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#bounciness' # (optional)
          },
          {
            snippet: 'Clock'
            displayText: 'Clock' # (optional)
            type: 'property' # (optional)
            leftLabel: 'Clock' # (optional)
            description: 'A reference to the Clock class attached to this Object. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#Clock' # (optional)
          },
          {
            snippet: 'Counter'
            displayText: 'Counter' # (optional)
            type: 'property' # (optional)
            leftLabel: 'Counter' # (optional)
            description: 'A reference to the Counter class attached to this Object. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#Counter' # (optional)
          },
          {
            snippet: 'drag'
            displayText: 'drag' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            description: 'The Object\'s drag.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#drag' # (optional)
          },
          {
            snippet: 'dynamic_friction'
            displayText: 'dynamic_friction' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            description: 'The Object\'s dynamic friction.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#dynamic_friction' # (optional)
          },
          {
            snippet: 'grid_projection'
            displayText: 'grid_projection' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Should the grid project onto this object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#grid_projection' # (optional)
          },
          {
            snippet: 'guid'
            displayText: 'guid' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            description: 'The Object’s guid. This is the same as the getGUID function. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#guid' # (optional)
          },
          {
            snippet: 'held_by_color'
            displayText: 'held_by_color' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            description: 'The color of the Player currently holding the Object. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#held_by_color' # (optional)
          },
          {
            snippet: 'interactable'
            displayText: 'interactable' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Can players interact with this Object? If false, only Lua Scripts can interact with this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#interactable' # (optional)
          },
          {
            snippet: 'mass'
            displayText: 'mass' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            description: 'The Object\'s mass.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#mass' # (optional)
          },
          {
            snippet: 'name'
            displayText: 'name' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            description: 'The Object’s formated name or nickname if applicable. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#name' # (optional)
          },
          {
            snippet: 'resting'
            displayText: 'resting' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Returns true if this Object is not moving. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#resting' # (optional)
          },
          {
            snippet: 'RPGFigurine'
            displayText: 'RPGFigurine' # (optional)
            type: 'property' # (optional)
            leftLabel: 'RPGFigurine' # (optional)
            description: 'A reference to the RPGFigurine class attached to this Object. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#RPGFigurine' # (optional)
          },
          {
            snippet: 'script_code'
            displayText: 'script_code' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            description: 'Returns the Lua script on this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#script_code' # (optional)
          },
          {
            snippet: 'script_state'
            displayText: 'script_state' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            description: 'Returns the saved Lua script state on the Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#script_state' # (optional)
          },
          {
            snippet: 'static_friction'
            displayText: 'static_friction' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            description: 'The Object\'s static friction.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#static_friction' # (optional)
          },
          {
            snippet: 'sticky'
            displayText: 'sticky' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Should Objects on top of this Object stick to this Object when this Object is picked up?' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#sticky' # (optional)
          },
          {
            snippet: 'tag'
            displayText: 'tag' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            description: 'The tag of the Object representing its type. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#tag' # (optional)
          },
          {
            snippet: 'tooltip'
            displayText: 'tooltip' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Should Object show tooltips when hovering over it.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#tooltip' # (optional)
          },
          {
            snippet: 'TextTool'
            displayText: 'TextTool' # (optional)
            type: 'property' # (optional)
            leftLabel: 'TextTool' # (optional)
            description: 'A reference to the TextTool class attached to this Object. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#TextTool' # (optional)
          },
          {
            snippet: 'use_gravity'
            displayText: 'use_gravity' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Does gravity affect this Object?' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#use_gravity' # (optional)
          },
          {
            snippet: 'use_grid'
            displayText: 'use_grid' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Should this Object snap to grid points?' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#use_grid' # (optional)
          },
          {
            snippet: 'use_snap_points'
            displayText: 'use_snap_points' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Should this Object snap to snap points?' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#use_snap_points' # (optional)
          },
          # Functions
          {
            snippet: 'addForce(${1:Table|force_vector}, ${2:int|force_type})'
            displayText: 'addForce(Table force_vector, int force_type)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Adds a force vector to the Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#addForce' # (optional)
          },
          {
            snippet: 'addTorque(${1:Table|torque_vector}, ${2:int|force_type})'
            displayText: 'addTorque(Table torque_vector, int force_type)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Adds a torque vector to the Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#addTorque' # (optional)
          },
          {
            snippet: 'call(${1:string|function_name}, ${2:Table|parameters})'
            displayText: 'call(string function_name, Table parameters)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'variable' # (optional)
            description: 'Calls a Lua function owned by this Object and passes an optional Table as parameters to the function.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#call' # (optional)
          },
          {
            snippet: 'clearButtons()'
            displayText: 'clearButtons()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Clears all 3D UI buttons on this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#clearButtons' # (optional)
          },
          {
            snippet: 'clone(${1:Table|parameters})'
            displayText: 'clone(Table parameters)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Object' # (optional)
            description: 'Copies and pastes this Object. Returns a reference to the newly spawned Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#clone' # (optional)
          },
          {
            snippet:
              'clone({\n\t' +
              'position      = ${1:-- Vector  [x=0, y=3, z=0]},\n\t' +
              'snap_to_grid  = ${2:-- boolean [false]},\n' +
              '})'
            displayText: 'clone({Vector position, bool snap_to_grid})' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Object' # (optional)
            description: 'Copies and pastes this Object. Returns a reference to the newly spawned Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#clone' # (optional)
          },
          {
            snippet: 'createButton(${1:Table|parameters})'
            displayText: 'createButton(Table parameters)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Creates a 3D UI button on this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#createButton' # (optional)
          },
          {
            snippet:
              'createButton({\n\t' +
              'click_function  = ${1:-- string (required)},\n\t' +
              'function_owner  = ${2:-- Object (required)},\n\t' +
              'label           = ${3:-- string},\n\t' +
              'position        = ${4:-- Vector},\n\t' +
              'rotation        = ${5:-- Vector},\n\t' +
              'scale           = ${6:-- Vector},\n\t' +
              'width           = ${7:-- int},\n\t' +
              'height          = ${8:-- int},\n\t' +
              'font_size       = ${9:-- int},\n\t' +
              'color           = ${10:-- Color},\n\t' +
              'font_color      = ${11:-- Color},\n' +
              '})'
            displayText: 'createButton({string click_function, Object function_owner, string label, Vector position, Vector rotation, Vector scale, int width, int height, int font_size, Color color, Color font_color})'
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Creates a 3D UI button on this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#createButton' # (optional)
          },
          {
            snippet: 'cut()'
            displayText: 'cut()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Cuts this Object if it is a Deck or a Stack.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#cut' # (optional)
          },
          {
            snippet: 'dealToAll(${1:int|num_cards})'
            displayText: 'dealToAll(int num_cards)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Deals a number of Cards from a this Deck to all seated players.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#dealToAll' # (optional)
          },
          {
            snippet: 'dealToColor(${1:int|num_cards}, ${2:string|player_color})'
            displayText: 'dealToColor(int num_cards, string player_color)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Deals a number of Cards from this Deck to a specific player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#dealToColor' # (optional)
          },
          {
            snippet: 'dealToColorWithOffset(${1:Table|position}, ${2:bool|flip}, ${3:string|player_color})'
            displayText: 'dealToColorWithOffset(Table position, bool flip, string player_color)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Object' # (optional)
            description: 'Deals a Card to a player with an offset from their hand.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#dealToColorWithOffset' # (optional)
          },
          {
            snippet: 'destruct()'
            displayText: 'destruct()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Destroys this Object. Mainly so you can call self.destruct().' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#destruct' # (optional)
          },
          {
            snippet: 'editButton(${1:Table|parameters})'
            displayText: 'editButton(Table parameters)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Edits a 3D UI button on this Object based on its index.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#editButton' # (optional)
          },
          {
            snippet:
              'editButton({\n\t' +
              'index           = ${1:-- int    (required)},\n\t' +
              'click_function  = ${2:-- string},\n\t' +
              'function_owner  = ${3:-- Object},\n\t' +
              'label           = ${4:-- string},\n\t' +
              'position        = ${5:-- Vector},\n\t' +
              'rotation        = ${6:-- Vector},\n\t' +
              'scale           = ${7:-- Vector},\n\t' +
              'width           = ${8:-- int},\n\t' +
              'height          = ${9:-- int},\n\t' +
              'font_size       = ${10:-- int},\n\t' +
              'color           = ${11:-- Color},\n\t' +
              'font_color      = ${12:-- Color},\n' +
              '})'
            displayText: 'editButton({int index, string click_function, Object function_owner, string label, Vector position, Vector rotation, Vector scale, int width, int height, int font_size, Color color, Color font_color})'
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Edits a 3D UI button on this Object based on its index.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#editButton' # (optional)
          },
          {
            snippet: 'flip()'
            displayText: 'flip()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Flips this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#flip' # (optional)
          },
          {
            snippet: 'getAngularVelocity()'
            displayText: 'getAngularVelocity()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns the current angular velocity vector of the Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getAngularVelocity' # (optional)
          },
          {
            snippet: 'getBounds()'
            displayText: 'getBounds()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns the world space axis aligned Bounds of the Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getBounds' # (optional)
          },
          {
            snippet: 'getBoundsNormalized()'
            displayText: 'getBoundsNormalized()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns the world space axis aligned Bounds of the Object at zero rotation.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getBoundsNormalized' # (optional)
          },
          {
            snippet: 'getButtons()'
            displayText: 'getButtons()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Gets a list of all the 3D UI buttons on this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getButtons' # (optional)
          },
          {
            snippet: 'getButtons() -- returns table:\n\t' +
            '-- {{int index, string click_function, Object function_owner, string label\n\t' +
            '--   Vector position, Vector rotation, Vector scale, int width, int height\n\t' +
            '--   int font_size, Color color, Color font_color}, ...}'
            displayText: 'getButtons() -- returns {{...' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Gets a list of all the 3D UI buttons on this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getButtons' # (optional)
          },
          {
            snippet: 'getColorTint()'
            displayText: 'getColorTint()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns the color tint for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getColorTint' # (optional)
          },
          {
            snippet: 'getCustomObject()'
            displayText: 'getCustomObject()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns the custom parameters on a Custom Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getCustomObject' # (optional)
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
            displayText: 'getCustomObject() -- returns {{...' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns the custom parameters on a Custom Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getCustomObject' # (optional)
          },
          {
            snippet: 'getDescription()'
            displayText: 'getDescription()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'string' # (optional)
            description: 'Gets the description for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getDescription' # (optional)
          },
          {
            snippet: 'getGUID()'
            displayText: 'getGUID()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'string' # (optional)
            description: 'Returns the GUID that belongs to this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getGUID' # (optional)
          },
          {
            snippet: 'getLock()'
            displayText: 'getLock()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Get the lock status of this object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getLock' # (optional)
          },
          {
            snippet: 'getLuaScript()'
            displayText: 'getLuaScript()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'string' # (optional)
            description: 'Returns the Lua script for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getLuaScript' # (optional)
          },
          {
            snippet: 'getName()'
            displayText: 'getName()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'string' # (optional)
            description: 'Returns the nickname for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getName' # (optional)
          },
          {
            snippet: 'getObjects()'
            displayText: 'getObjects()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns all the Objects inside of this container.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getObjects' # (optional)
          },
          {
            snippet: 'getObjects()$1\n\t-- Bag.getObjects() returns {{int index, string guid, string name}, ...}'
            displayText: 'getObjects() -- Bag returns {{int index, string guid, string name}, ...}' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns all the Objects inside of this container.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getObjects' # (optional)
          },
          {
            snippet: 'getObjects()$1\n\t-- Deck.getObjects() returns:\n\t-- {{int index, string nickname, string description, string guid, string lua_script}, ...}'
            displayText: 'getObjects() -- Deck returns {{int index, string nickname, string description, string guid, string lua_script}, ...}' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns all the Objects inside of this container.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getObjects' # (optional)
          },
          {
            snippet: 'getObjects()$1\n\t-- Zone.getObjects() returns {Object, ...}'
            displayText: 'getObjects() -- Zone returns {Object, ...}' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns all the Objects inside of this container.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getObjects' # (optional)
          },
          {
            snippet: 'getPosition()'
            displayText: 'getPosition()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Gets the position for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getPosition' # (optional)
          },
          {
            snippet: 'getQuantity()'
            displayText: 'getQuantity()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            description: 'Returns the number of Objects in a stack.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getQuantity' # (optional)
          },
          {
            snippet: 'getRotation()'
            displayText: 'getRotation()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Gets the rotation of this Object in degrees.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getRotation' # (optional)
          },
          {
            snippet: 'getScale()'
            displayText: 'getScale()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Gets the scale for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getScale' # (optional)
          },
          {
            snippet: 'getStateId()'
            displayText: 'getStateId()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            description: 'Returns id of the active state for this object. Will return -1 if the object has no states.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getStateId' # (optional)
          },
          {
            snippet: 'getStates()'
            displayText: 'getStates()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns a Table with the keys “name”, “guid”, and “id”.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getStates' # (optional)
          },
          {
            snippet: 'getStatesCount()'
            displayText: 'getStatesCount()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            description: 'Returns the number of States on this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getStatesCount' # (optional)
          },
          {
            snippet: 'getTable(${1:string|table_name})'
            displayText: 'getTable(string table_name)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Gets a Lua Table for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getTable' # (optional)
          },
          {
            snippet: 'getTransformForward()'
            displayText: 'getTransformForward()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Gets the forward direction of this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getTransformForward' # (optional)
          },
          {
            snippet: 'getTransformRight()'
            displayText: 'getTransformRight()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Gets the right direction of this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getTransformRight' # (optional)
          },
          {
            snippet: 'getTransformUp()'
            displayText: 'getTransformUp()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Gets the up direction of this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getTransformUp' # (optional)
          },
          {
            snippet: 'getValue()'
            displayText: 'getValue()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            description: 'Returns the value for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getValue' # (optional)
          },
          {
            snippet: 'getVar(${1:string|variable_name})'
            displayText: 'getVar(string variable_name)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'variable' # (optional)
            description: 'Gets a Lua variable for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getVar' # (optional)
          },
          {
            snippet: 'getVelocity()'
            displayText: 'getVelocity()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns the current velocity vector of the Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getVelocity' # (optional)
          },
          {
            snippet: 'highlightOff()'
            displayText: 'highlightOff()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Stop highlighting this object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#highlightOff' # (optional)
          },
          {
            snippet: 'highlightOn(${1:Table|color}, ${2:float|duration})'
            displayText: 'highlightOn(Table color, float duration)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Highlight this object with color for an optional duration. Color values are between 0 and 1.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#highlightOn' # (optional)
          },
          {
            snippet: 'isSmoothMoving()'
            displayText: 'isSmoothMoving()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Is the object smoothly moving from our smooth functions.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#isSmoothMoving' # (optional)
          },
          {
            snippet: 'positionToLocal(${1:Table|vector})'
            displayText: 'positionToLocal(Table vector)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Converts the world position to a local position of this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#positionToLocal' # (optional)
          },
          {
            snippet: 'positionToWorld(${1:Table|vector})'
            displayText: 'positionToWorld(Table vector)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Converts the local position of this Object to a world position.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#positionToWorld' # (optional)
          },
          {
            snippet: 'putObject(${1:Object|object})'
            displayText: 'putObject(Object object)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Add this object to the current object. Works for stacking chips, decks, and bags.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#putObject' # (optional)
          },
          {
            snippet: 'randomize()'
            displayText: 'randomize()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Same as pressing the ‘R’ key on an Object. Shuffles deck/bag, rolls dice/coin, lifts any other object up in the air.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#randomize' # (optional)
          },
          {
            snippet: 'reload()'
            displayText: 'reload()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Reloads this object by destroying and spawning it place. Returns the newly spawned object. Very useful if using setCustomObject().' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#reload' # (optional)
          },
          {
            snippet: 'removeButton(${1:int|index})'
            displayText: 'removeButton(int index)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Removes a 3D UI button from this Object by its index.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#removeButton' # (optional)
          },
          {
            snippet: 'reset()'
            displayText: 'reset()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Resets this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#rest' # (optional)
          },
          {
            snippet: 'roll()'
            displayText: 'roll()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Rolls this Object. Works on Dice and Coins.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#roll' # (optional)
          },
          {
            snippet: 'rotate(${1:Table|rotation})'
            displayText: 'rotate(Table rotation)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Smoothly rotates this Object with the given offset in degrees.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#rotate' # (optional)
          },
          {
            snippet: 'scale(${1:Table|scale})'
            displayText: 'scale(Table scale)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Scales this Object by the given amount.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#scale' # (optional)
          },
          {
            snippet: 'scale(${1:float|scale})'
            displayText: 'scale(float scale)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Scales this Object in all axes by the given amount.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#scaleAllAxes' # (optional)
          },
          {
            snippet: 'setAngularVelocity(${1:Table|vector})'
            displayText: 'setAngularVelocity(Table vector)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the angular velocity of the object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setAngularVelocity' # (optional)
          },
          {
            snippet: 'setColorTint(${1:Table|color})'
            displayText: 'setColorTint(Table color)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the color tint for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setColorTint' # (optional)
          },
          {
            snippet: 'setCustomObject(${1:Table|parameters})'
            displayText: 'setCustomObject(Table parameters)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Used to create a Custom Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setCustomObject' # (optional)
          },
          {
            snippet: 'setDescription(${1:string|description})'
            displayText: 'setDescription(string description)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the description for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setDescription' # (optional)
          },
          {
            snippet: 'setLock(${1:bool|lock})'
            displayText: 'setLock(bool lock)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Set the lock status of an object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setLock' # (optional)
          },
          {
            snippet: 'setLuaScript(${1:string|script})'
            displayText: 'setLuaScript(string script)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the Lua script for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setLuaScript' # (optional)
          },
          {
            snippet: 'setName(${1:string|nickname})'
            displayText: 'setName(string nickname)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the nickname for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setName' # (optional)
          },
          {
            snippet: 'setPosition(${1:Table|position})'
            displayText: 'setPosition(Table position)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the world space position for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setPosition' # (optional)
          },
          {
            snippet: 'setPositionSmooth(${1:Table|position}, ${2:bool|collide}, ${3:bool|fast})'
            displayText: 'setPositionSmooth(Table position, bool collide, bool fast)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Smoothly moves this Object from its current position to a given world space position.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setPositionSmooth' # (optional)
          },
          {
            snippet: 'setRotation(${1:Table|rotation})'
            displayText: 'setRotation(Table rotation)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the rotation of this Object in degrees.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setRotation' # (optional)
          },
          {
            snippet: 'setRotationSmooth(${1:Table|rotation}, ${2:bool|collide}, ${3:bool|fast})'
            displayText: 'setRotationSmooth(Table rotation, bool collide, bool fast)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Smoothly rotates this Object to the given orientation in degrees.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setRotationSmooth' # (optional)
          },
          {
            snippet: 'setScale(${1:Table|scale})'
            displayText: 'setScale(Table scale)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the scale for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setScale' # (optional)
          },
          {
            snippet: 'setState(${1:int|state})'
            displayText: 'setState(int state)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Object' # (optional)
            description: 'Sets the State on this Object and returns reference to the new State.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setState' # (optional)
          },
          {
            snippet: 'setTable(${1:string|table_name}, ${2:Table|table})'
            displayText: 'setTable(string table_name, Table table)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets a Lua Table for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setTable' # (optional)
          },
          {
            snippet: 'setValue(${1:variable|value})'
            displayText: 'setValue(variable value)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the value for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setValue' # (optional)
          },
          {
            snippet: 'setVar(${1:string|variable_name}, ${2:variable|value})'
            displayText: 'setVar(string variable_name, variable value)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets a Lua variable for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setVar' # (optional)
          },
          {
            snippet: 'setVelocity(${1:Table|vector})'
            displayText: 'setVelocity(Table vector)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the velocity of the object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setVelocity' # (optional)
          },
          {
            snippet: 'shuffle()'
            displayText: 'shuffle()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Shuffles this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#shuffle' # (optional)
          },
          {
            snippet: 'shuffleStates()'
            displayText: 'shuffleStates()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Object' # (optional)
            description: 'Shuffles the States on this Object and returns reference to the new State.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#shuffleStates' # (optional)
          },
          {
            snippet: 'takeObject(${1:Table|parameters})'
            displayText: 'takeObject(Table parameters)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Object' # (optional)
            description: 'Takes an Object from this container.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#takeObject' # (optional)
          },
          {
            snippet:
              'takeObject({\n\t' +
              'position        = ${1:-- Vector [container position, x+2]},\n\t' +
              'rotation        = ${2:-- Vector [container rotation]},\n\t' +
              'callback        = ${3:-- string},\n\t' +
              'callback_owner  = ${4:-- Object},\n\t' +
              'params          = ${5:-- Table},\n\t' +
              'flip            = ${6:-- bool},\n\t' +
              'guid            = ${7:-- string},\n\t' +
              'index           = ${8:-- int},\n\t' +
              'top             = ${9:-- bool [true]},\n' +
              '})'
            displayText: 'takeObject({Vector position, Vector rotation, string callback, Object callback_owner, Table params, bool flip, string guid, int index, bool top})' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Object' # (optional)
            description: 'Takes an Object from this container.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#takeObject' # (optional)
          },
          {
            snippet: 'translate(${1:Table|position})'
            displayText: 'translate(Table position)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Smoothly moves this Object from its current position to a given offset.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#translate' # (optional)
          },
        ]
      # Default Events
      else if (line.includes("function") && line.lastIndexOf("function") > line.lastIndexOf("("))
        #console.log "FOUND DEFAULT EVENTS"
        suggestions = [
          {
            snippet: 'fixedUpdate()\n\t${0:-- body...}\nend'
            displayText: 'fixedUpdate()' # (optional)
            type: 'function' # (optional)
            description: 'This function is called, if it exists in your script, every physics tick which happens 90 times a second.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#fixedUpdate' # (optional)
          },
          {
            snippet:
              'onCollisionEnter(collision_info)\n\t' +
              '-- collision_info table:\n\t' +
              '--   collision_object    Object\n\t' +
              '--   contact_points      Table     {Vector, ...}\n\t' +
              '--   relative_velocity   Vector\n\t' +
              '$1\nend'
            displayText: 'onCollisionEnter(Table collision_info)' # (optional)
            type: 'function' # (optional)
            description: 'Automatically called when this Object collides with another Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onCollisionEnter' # (optional)
          },
          {
            snippet:
              'onCollisionExit(collision_info)\n\t' +
              '-- collision_info table:\n\t' +
              '--   collision_object    Object\n\t' +
              '--   contact_points      Table     {Vector, ...}\n\t' +
              '--   relative_velocity   Vector\n\t' +
              '$1\nend'
            displayText: 'onCollisionExit(Table collision_info)' # (optional)
            type: 'function' # (optional)
            description: 'Automatically called when this Object stops touching another Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onCollisionExit' # (optional)
          },
          {
            snippet:
              'onCollisionStay(collision_info)\n\t' +
              '-- collision_info table:\n\t' +
              '--   collision_object    Object\n\t' +
              '--   contact_points      Table     {Vector, ...}\n\t' +
              '--   relative_velocity   Vector\n\t' +
              '$1\nend'
            displayText: 'onCollisionStay(Table collision_info)' # (optional)
            type: 'function' # (optional)
            description: 'Automatically called when this Object is touching another Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onCollisionStay' # (optional)
          },
          {
            snippet: 'onDestroy()\n\t${0:-- body...}\nend'
            displayText: 'onDestroy()' # (optional)
            type: 'function' # (optional)
            description: 'Automatically called when this Object is destroyed.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onDestroy' # (optional)
          },
          {
            snippet: 'onDropped(player_color)\n\t${0:-- body...}\nend'
            displayText: 'onDropped(string player_color)' # (optional)
            type: 'function' # (optional)
            description: 'Automatically called when this Object is dropped.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onDropped' # (optional)
          },
          {
            snippet: 'onLoad(save_state)\n\t${0:-- body...}\nend'
            displayText: 'onLoad(string save_state)' # (optional)
            type: 'function' # (optional)
            description: 'Automatically called when a game save is finished loading every Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onLoad' # (optional)
          },
          {
            snippet: 'onObjectDestroyed(dying_object)\n\t${0:-- body...}\nend'
            displayText: 'onObjectDestroyed(Object dying_object)' # (optional)
            type: 'function' # (optional)
            description: 'Automatically called when an Object is destroyed.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectDestroyed' # (optional)
          },
          {
            snippet: 'onObjectDropped(player_color, dropped_object)\n\t${0:-- body...}\nend'
            displayText: 'onObjectDropped(string player_color, Object dropped_object)' # (optional)
            type: 'function' # (optional)
            description: 'Automatically called when an Object is dropped.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectDropped' # (optional)
          },
          {
            snippet: 'onObjectEnterScriptingZone(zone, enter_object)\n\t${0:-- body...}\nend'
            displayText: 'onObjectEnterScriptingZone(Object zone, Object enter_object)' # (optional)
            type: 'function' # (optional)
            description: 'Automatically called when an Object enters a Scripting Zone.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectEnterScriptingZone' # (optional)
          },
          {
            snippet: 'onObjectLeaveScriptingZone(zone, leave_object)\n\t${0:-- body...}\nend'
            displayText: 'onObjectLeaveScriptingZone(Object zone, Object leave_object)' # (optional)
            type: 'function' # (optional)
            description: 'Automatically called when an Object leaves a Scripting Zone.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectLeaveScriptingZone' # (optional)
          },
          {
            snippet: 'onObjectLoopingEffect(object, index)\n\t${0:-- body...}\nend'
            displayText: 'onObjectLoopingEffect(Object object, int index)' # (optional)
            type: 'function' # (optional)
            description: "Automatically called when an asset Object's loop is started." # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectLoopingEffect' # (optional)
          },
          {
            snippet: 'onObjectPickedUp(player_color, picked_up_object)\n\t${0:-- body...}\nend'
            displayText: 'onObjectPickedUp(string player_color, Object picked_up_object)' # (optional)
            type: 'function' # (optional)
            description: 'Automatically called when an Object is picked up.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectPickedUp' # (optional)
          },
          {
            snippet: 'onObjectRandomize(object, player_color)\n\t${0:-- body...}\nend'
            displayText: 'onObjectRandomize(Object object, string player_color)' # (optional)
            type: 'function' # (optional)
            description: 'Automatically called when an asset Object is randomized by player_color.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectRandomize' # (optional)
          },
          {
            snippet: 'onObjectTriggerEffect(object, index)\n\t${0:-- body...}\nend'
            displayText: 'onObjectTriggerEffect(Object object, int index)' # (optional)
            type: 'function' # (optional)
            description: 'Automatically called when an asset Object is triggered.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectTriggerEffect' # (optional)
          },
          {
            snippet: 'onPickedUp(player_color)\n\t${0:-- body...}\nend'
            displayText: 'onPickedUp(string player_color)' # (optional)
            type: 'function' # (optional)
            description: 'Automatically called when this Object is picked up.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onPickedUp' # (optional)
          },
          {
            snippet: 'onPlayerChangedColor(player_color)\n\t${0:-- body...}\nend'
            displayText: 'onPlayerChangedColor(string player_color)' # (optional)
            type: 'function' # (optional)
            description: 'Automatically called when a Player changes color.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onPlayerChangedColor' # (optional)
          },
          {
            snippet: 'onPlayerTurnEnd(player_color_end, player_color_next)\n\t${0:-- body...}\nend'
            displayText: 'onPlayerTurnEnd(string player_color_end, string player_color_next)' # (optional)
            type: 'function' # (optional)
            description: 'Automatically called at the end of a Player\'s turn.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onPlayerTurnEnd' # (optional)
          },
          {
            snippet: 'onPlayerTurnStart(player_color_start, player_color_previous)\n\t${0:-- body...}\nend'
            displayText: 'onPlayerTurnStart(string player_color_start, string player_color_previous)' # (optional)
            type: 'function' # (optional)
            description: 'Automatically called at the start of a Player\'s turn.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onPlayerTurnStart' # (optional)
          },
          {
            snippet: 'onSave()\n\t${0:-- body...}\nend'
            displayText: 'onSave()' # (optional)
            type: 'function' # (optional)
            description: 'Automatically called when the game saves (including auto-save for Rewinding).' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onSave' # (optional)
          },
          {
            snippet: 'update()\n\t${0:-- body...}\nend'
            displayText: 'update()' # (optional)
            type: 'function' # (optional)
            description: 'Automatically called once every frame.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#update' # (optional)
          },
        ]
      # Globally accessible constants & functions
      else if (not (line.endsWith("}") || line.endsWith(")") || line.endsWith("]"))) and not line.includes("function ") and not this_token.includes("for ") and not this_token.match(/.*[\w ] $/)
        #console.log "FOUND GLOBALLY ACCESSIBLE FUNCTIONS"
        suggestions = [
          # Constants
          {
            snippet: 'coroutine'
            displayText: 'coroutine' # (optional)
            type: 'constant' # (optional)
            description: 'The coroutine class.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#6.2' # (optional)
          },
          {
            snippet: 'Global'
            displayText: 'Global' # (optional)
            type: 'constant' # (optional)
            description: 'A reference to the Global Script.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object' # (optional)
          },
          {
            snippet: 'JSON'
            displayText: 'JSON' # (optional)
            type: 'constant' # (optional)
            description: 'The JSON class.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/json' # (optional)
          },
          {
            snippet: 'Lighting'
            displayText: 'Lighting' # (optional)
            type: 'constant' # (optional)
            description: 'The Lighting class.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-lighting/' # (optional)
          },
          {
            snippet: 'math'
            displayText: 'math' # (optional)
            type: 'constant' # (optional)
            description: 'The math class.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#6.6' # (optional)
          },
          {
            snippet: 'os'
            displayText: 'os' # (optional)
            type: 'constant' # (optional)
            description: 'The os class.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#6.9' # (optional)
          },
          {
            snippet: 'Physics'
            displayText: 'Physics' # (optional)
            type: 'constant' # (optional)
            description: 'The Physics class.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/scripting-physics/' # (optional)
          },
          {
            snippet: 'Player'
            displayText: 'Player' # (optional)
            type: 'constant' # (optional)
            description: 'The Player class.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player' # (optional)
          },
          {
            snippet: 'self'
            displayText: 'self' # (optional)
            type: 'constant' # (optional)
            description: 'A reference to this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object' # (optional)
          },
          {
            snippet: 'Timer'
            displayText: 'Timer' # (optional)
            type: 'constant' # (optional)
            description: 'The Timer class.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/timer/' # (optional)
          },
          # Global Management Functions
          {
            snippet: 'addNotebookTab(${1:Table|parameters})'
            displayText: 'addNotebookTab(Table parameters)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            description: 'Adds a new Tab to the Notebook and returns the index of the newly added Tab.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#addNotebookTab' # (optional)
          },
          {
            snippet:
              'addNotebookTab({\n\t' +
              'title  = ${1:-- string},\n\t' +
              'body   = ${2:-- string (BBcode is allowed)},\n\t' +
              'color  = ${3:-- string [Grey]},\n' +
              '})'
            displayText: 'addNotebookTab({string title, string body, string color})' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            description: 'Adds a new Tab to the Notebook and returns the index of the newly added Tab.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#addNotebookTab' # (optional)
          },
          {
            snippet: 'clearPixelPaint()'
            displayText: 'clearPixelPaint()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Clears all pixel paint.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#clearPixelPaint' # (optional)
          },
          {
            snippet: 'clearVectorPaint()'
            displayText: 'clearVectorPaint()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Clears all vector paint.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#clearVectorPaint' # (optional)
          },
          {
            snippet: 'copy(${1:Table|objects})'
            displayText: 'copy(Table objects)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Copies a list of Objects.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#copy' # (optional)
          },
          {
            snippet: 'destroyObject(${1:Object|obj})'
            displayText: 'destroyObject(Object obj)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Destroys an Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#destroyObject' # (optional)
          },
          {
            snippet: 'editNotebookTab(${1:Table|parameters})'
            displayText: 'editNotebookTab(Table parameters)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Edits an existing Tab on the Notebook.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#editNotebookTab' # (optional)
          },
          {
            snippet:
              'editNotebookTab({\n\t' +
              'index  = ${1:-- int},\n\t' +
              'title  = ${2:-- string},\n\t' +
              'body   = ${3:-- string (BBcode is allowed)},\n\t' +
              'color  = ${4:-- string [Grey]},\n' +
              '})'
            displayText: 'editNotebookTab({int index, string title, string body, string color})' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Edits an existing Tab on the Notebook.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#editNotebookTab' # (optional)
          },
          {
            snippet: 'broadcastToAll(${1:string|message}, ${2:Table|text_color})'
            displayText: 'broadcastToAll(string message, Table text_color)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Prints a message to the screen and chat window on all connected clients.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#broadcastToAll' # (optional)
          },
          {
            snippet: 'broadcastToColor(${1:string|message}, ${2:string|player_color}, ${3:Table|text_color})'
            displayText: 'broadcastToColor(string message, string player_color, Table text_color)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Prints a private message to the screen and chat window to the player matching the player color.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#broadcastToColor' # (optional)
          },
          {
            snippet: 'flipTable()'
            displayText: 'flipTable()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Flip the table in a fit of rage.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#flipTable' # (optional)
          },
          {
            snippet: 'getAllObjects()'
            displayText: 'getAllObjects()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns a Table of all the spawned Objects in the game.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getAllObjects' # (optional)
          },
          {
            snippet: 'getNotebookTabs()'
            displayText: 'getNotebookTabs()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns a Table of Tables of all of the Tabs in the Notebook.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getNotebookTabs' # (optional)
          },
          {
            snippet: 'getNotebookTabs()$1\n\t-- getNotebookTabs returns:\n\t-- {{int index, string title, string body, string color}, ...}'
            displayText: 'getNotebookTabs() -- returns {{int index, string title, string body, string color}, ...}'
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns a Table of Tables of all of the Tabs in the Notebook.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getNotebookTabs' # (optional)
          },
          {
            snippet: 'getNotes()'
            displayText: 'getNotes()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'string' # (optional)
            description: 'Returns the current on-screen notes as a string.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getNotes' # (optional)
          },
          {
            snippet: 'getObjectFromGUID(${1:string|guid})'
            displayText: 'getObjectFromGUID(string guid)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Object' # (optional)
            description: 'Gets a reference to an Object from a GUID. Will return nil if the Object doesn’t exist.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getObjectFromGUID' # (optional)
          },
          {
            snippet: 'getSeatedPlayers()'
            displayText: 'getSeatedPlayers()' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Returns an indexed Lua Table of all the seated Player colors.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getSeatedPlayers' # (optional)
          },
          {
            snippet: 'paste(${1:Table|parameters})'
            displayText: 'paste(Table parameters)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Pastes copied Objects and returns a Table of references to the new Objects.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#copy' # (optional)
          },
          {
            snippet:
              'paste({\n\t' +
              'position      = ${1:-- Vector  [x=0, y=3, z=0]},\n\t' +
              'snap_to_grid  = ${2:-- boolean [false]},\n' +
              '})'
            displayText: 'paste({Vector position, bool snap_to_grid})' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Pastes copied Objects and returns a Table of references to the new Objects.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#copy' # (optional)
          },
          {
            snippet: 'print(${1:string|message})'
            displayText: 'print(string message)' # (optional)
            type: 'function' # (optional)
            description: 'Prints a message to the chatin window only on the host.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#print' # (optional)
          },
          {
            snippet: 'printToAll(${1:string|message}, ${2:Table|text_color})'
            displayText: 'printToAll(string message, Table text_color)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Prints a message to the chat window on all connected clients.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#printToAll' # (optional)
          },
          {
            snippet: 'printToColor(${1:string|message}, ${2:string|player_color}, ${3:Table|text_color})'
            displayText: 'printToColor(string message, string player_color, Table text_color)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Prints a message to the chat window of a specific Player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#printToColor' # (optional)
          },
          {
            snippet: 'removeNotebookTab(${1:int|index})'
            displayText: 'removeNotebookTab(int index)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Removes a Tab from the Notebook at a given index.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#removeNotebookTab' # (optional)
          },
          {
            snippet: 'setNotes(${1:string|notes})'
            displayText: 'setNotes(string notes)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Sets the current on-screen notes. BBCOde is allowed for styling.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#setNotes' # (optional)
          },
          {
            snippet: 'spawnObject(${1:Table|paremeters})'
            displayText: 'spawnObject(Table parameters)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Object' # (optional)
            description: 'Spawns an Object and returns a reference to it.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#spawnObject' # (optional)
          },
          {
            snippet:
              'spawnObject({\n\t' +
              'type            = ${1:-- string},\n\t' +
              'position        = ${2:-- Vector [x=0, y=3, z=0]},\n\t' +
              'rotation        = ${3:-- Vector [x=0, y=0, z=0]},\n\t' +
              'scale           = ${4:-- Vector [x=1, y=1, z=1]},\n\t' +
              'callback        = ${5:-- string},\n\t' +
              'callback_owner  = ${6:-- Object},\n\t' +
              'params          = ${7:-- Table},\n\t' +
              'snap_to_grid    = ${8:-- bool},\n' +
              '})'
            displayText: 'spawnObject({string type, Vector position, Vector rotation, Vector scale, string callback, Object callback_owner, Table params, bool snap_to_grid})' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Object' # (optional)
            description: 'Spawns an Object and returns a reference to it.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#spawnObject' # (optional)
          },
          {
            snippet: 'startLuaCoroutine(${1:Object|func_owner}, ${2:string|func_name})'
            displayText: 'startLuaCoroutine(Object func_owner, string func_name)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            description: 'Starts a Lua function as a coroutine.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#startLuaCoroutine' # (optional)
          },
          {
            snippet: 'stringColorToRGB(${1:string|player_color})'
            displayText: 'stringColorToRGB(string player_color)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            description: 'Converts a color string (player colors) to its RGB values.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#stringColorToRGB' # (optional)
          },
          {
            snippet: 'tonumber(${1:e})'
            displayText: 'tonumber(e [, base])' # (optional)
            type: 'function' # (optional)
            leftLabel: 'number' # (optional)
            description: 'When called with no base, tonumber tries to convert its argument to a number.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-tonumber' # (optional)
          },
          {
            snippet: 'tostring(${1:v})'
            displayText: 'tostring(v)' # (optional)
            type: 'function' # (optional)
            leftLabel: 'number' # (optional)
            description: 'Receives a value of any type and converts it to a string in a reasonable format.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-tostring' # (optional)
          },
        ]
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
                        type: 'function' # (optional)
                        leftLabel: 'Object' # (optional)
                        description: 'Gets a reference to an Object from a GUID. Will return nil if the Object doesn’t exist.' # (optional)
                        descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getObjectFromGUID' # (optional)
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
                            type: 'function' # (optional)
                            leftLabel: 'Object' # (optional)
                            description: 'Gets a reference to an Object from a GUID. Will return nil if the Object doesn’t exist.' # (optional)
                            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getObjectFromGUID' # (optional)
                          }
                    )
              break

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
      resolve(suggestions)

# replacement patterns for autocomplete parameters
parameter_patterns = {
  'type': '$${$1:$2}',
  'name': '$${$1:$3}',
  'both': '$${$1:$2_$3}',
  'none': '$${$1:}',
}

capitalize = (s) ->
  return s.substring(0,1).toUpperCase() + s.substring(1)
