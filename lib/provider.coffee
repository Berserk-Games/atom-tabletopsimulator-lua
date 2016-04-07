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
      #console.log "scopeDescriptor: " + scopeDescriptor
      #console.log scopeDescriptor
      #console.log editor
      #console.log bufferPosition
      #console.log prefix
      suggestions = []

      #if bufferPosition.column >= 8
      #  console.log editor.getTextInRange([[bufferPosition.row, bufferPosition.column - 7], bufferPosition])

      if scopeDescriptor.scopes[1] == "keyword.operator.lua"
        resolve([])

      # Substring up until this position
      line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
      tokens = line.split "."
      previous_token = ""
      if tokens.length > 1
        previous_token = tokens[tokens.length - 2].trim()
        tokens = previous_token.split("(")
        previous_token = tokens[tokens.length - 1].trim()
        tokens = previous_token.split("=")
        previous_token = tokens[tokens.length - 1].trim()
        tokens = previous_token.split("{")
        previous_token = tokens[tokens.length - 1].trim()
        tokens = previous_token.split(",")
        previous_token = tokens[tokens.length - 1].trim()
        tokens = previous_token.split(">")
        previous_token = tokens[tokens.length - 1].trim()
        tokens = previous_token.split("<")
        previous_token = tokens[tokens.length - 1 ].trim()
        tokens = previous_token.split(" ")
        previous_token = tokens[tokens.length - 1].trim()

      #console.log previous_token
      #console.log (prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua")
      #console.log bufferPosition.column >= 8 && editor.getTextInRange([[bufferPosition.row, bufferPosition.column - 7], bufferPosition]) == "Global."
      #console.log previous_token == "Clock"

      #console.log (prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua" || previous_token == "")
      #console.log not editor.getTextInRange([[bufferPosition.row, 0], bufferPosition]).includes("function")

      # Global object
      if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "Global") || ((bufferPosition.column >= 8 && editor.getTextInRange([[bufferPosition.row, bufferPosition.column - 7], bufferPosition]) == "Global.") || previous_token == "Global")
        console.log "FOUND GLOBAL"
        suggestions = [
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getTable(${1:string})'
            displayText: 'getTable(string table_name)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Gets a Lua Table for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getTable' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getVar(${1:string})'
            displayText: 'getVar(string variable_name)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'variable' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Gets a Lua variable for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getVar' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setTable(${1:string}, ${2:Table})'
            displayText: 'setTable(string table_name, Table table)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Sets a Lua Table for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setTable' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setVar(${1:string}, ${2:variable})'
            displayText: 'setVar(string variable_name, variable value)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Sets a Lua variable for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setVar' # (optional)
          },
        ]
      # math Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "math") || ((bufferPosition.column >= 6 && editor.getTextInRange([[bufferPosition.row, bufferPosition.column - 5], bufferPosition]) == "math.") || previous_token == "math")
        console.log "FOUND MATH"
        suggestions = [
          # Member Variables
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'huge'
            displayText: 'huge' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The value HUGE_VAL, a value larger than or equal to any other numerical value.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.huge' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'pi'
            displayText: 'pi' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The value of π.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.pi' # (optional)
          },
          # Functions
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'abs(${1:x})'
            displayText: 'abs(float x)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the absolute value of x.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.abs' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'acos(${1:x})'
            displayText: 'acos(float x)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the arc cosine of x (in radians).' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.acos' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'asin(${1:x})'
            displayText: 'asin(float x)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the arc sine of x (in radians).' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.asin' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'atan(${1:x})'
            displayText: 'atan(float x)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the arc tangent of x (in radians).' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.atan' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'atan2(${1:y}, ${2:x})'
            displayText: 'atan2(float y, float x)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the arc tangent of y/x (in radians), but uses the signs of both parameters to find the quadrant of the result.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.atan2' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'ceil(${1:x})'
            displayText: 'ceil(float x)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the smallest integer larger than or equal to x.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.ceil' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'cos(${1:x})'
            displayText: 'cos(float x)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the cosine of x (assumed to be in radians).' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.cos' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'cosh(${1:x})'
            displayText: 'cosh(float x)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the hyperbolic cosine of x.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.cosh' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'deg(${1:x})'
            displayText: 'deg(float x)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the angle x (given in radians) in degrees.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.deg' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'exp(${1:x})'
            displayText: 'exp(float x)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the value e^x.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.exp' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'floor(${1:x})'
            displayText: 'floor(float x)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the largest integer smaller than or equal to x.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.floor' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'fmod(${1:x}, ${2:y})'
            displayText: 'fmod(float x, float y)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the remainder of the division of x by y that rounds the quotient towards zero.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.fmod' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'frexp(${1:x})'
            displayText: 'frexp(float x)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns m and e such that x = m2^e, e is an integer and the absolute value of m is in the range [0.5, 1) (or zero when x is zero).' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.frexp' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'ldexp(${1:m}, ${2:e})'
            displayText: 'ldexp(float m, int e)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns m2^e (e should be an integer).' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.ldexp' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'log(${1:x})'
            displayText: 'log(float x [, base])' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the logarithm of x in the given base.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.log' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'max(${1:x}, ${2:...})'
            displayText: 'max(float x, ...)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the maximum value among its arguments.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.max' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'min(${1:x}, ${2:...})'
            displayText: 'min(float x, ...)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the minimum value among its arguments.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.min' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'modf(${1:x})'
            displayText: 'modf(float x)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns two numbers, the integral part of x and the fractional part of x.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.modf' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'pow(${1:x}, ${2:y})'
            displayText: 'pow(float x, float y)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns x^y. (You can also use the expression x^y to compute this value.)' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.pow' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'rad(${1:x})'
            displayText: 'rad(float x)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the angle x (given in degrees) in radians.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.rad' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'random()'
            displayText: 'random([m [, n]])' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'This function is an interface to the simple pseudo-random generator function rand provided by Standard C.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.random' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'randomseed(${1:x})'
            displayText: 'randomseed(int x)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Sets x as the "seed" for the pseudo-random generator: equal seeds produce equal sequences of numbers.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.randomseed' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'sin(${1:x})'
            displayText: 'sin(float x)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the sine of x (assumed to be in radians).' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.sin' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'sinh(${1:x})'
            displayText: 'sinh(float x)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the hyperbolic sine of x.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.sinh' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'sqrt(${1:x})'
            displayText: 'sqrt(float x)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the square root of x. (You can also use the expression x^0.5 to compute this value.)' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.sqrt' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'tan(${1:x})'
            displayText: 'tan(float x)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the tangent of x (assumed to be in radians).' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.tan' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'tanh(${1:x})'
            displayText: 'tanh(float x)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the hyperbolic tangent of x.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-math.tanh' # (optional)
          },
        ]
      # coroutine Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "coroutine") || ((bufferPosition.column >= 11 && editor.getTextInRange([[bufferPosition.row, bufferPosition.column - 10], bufferPosition]) == "coroutine.") || previous_token == "coroutine")
        console.log "FOUND COROUTINE"
        suggestions = [
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'create(${1:function})'
            displayText: 'create(function f)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'thread' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Creates a new coroutine, with body f.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-coroutine.create' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'resume(${1:coroutine})'
            displayText: 'resume(coroutine co [, val1, ···])' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Starts or continues the execution of coroutine co.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-coroutine.resume' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'running()'
            displayText: 'running()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the running coroutine plus a boolean, true when the running coroutine is the main one.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-coroutine.running' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'status(${1:coroutine})'
            displayText: 'status(coroutine co)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'string' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the status of coroutine co, as a string.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-coroutine.status' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'wrap(${1:function})'
            displayText: 'wrap(funtion f)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Creates a new coroutine, with body f.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-coroutine.wrap' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'yield(${1:int})'
            displayText: 'yield(int value)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Suspends the execution of the calling coroutine.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-coroutine.yield' # (optional)
          },
        ]
      # os Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "os") || ((bufferPosition.column >= 4 && editor.getTextInRange([[bufferPosition.row, bufferPosition.column - 3], bufferPosition]) == "os.") || previous_token == "os")
        console.log "FOUND OS"
        suggestions = [
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'clock()'
            displayText: 'clock()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns an approximation of the amount in seconds of CPU time used by the program.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-os.clock' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'date()'
            displayText: 'date([format [, time]])' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns a string or a table containing date and time.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-os.date' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'difftime(${1:time2}, ${2:time1})'
            displayText: 'difftime(t2, t1)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the number of seconds from time t1 to time t2.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-os.difftime' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'time()'
            displayText: 'time([table])' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the current time when called without arguments, or a time representing the date and time specified by the given table.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-os.time' # (optional)
          },
        ]
      # Clock Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "Clock") || ((bufferPosition.column >= 7 && editor.getTextInRange([[bufferPosition.row, bufferPosition.column - 6], bufferPosition]) == "Clock.") || previous_token == "Clock")
        console.log "FOUND CLOCK"
        suggestions = [
          # Member Variables
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'paused'
            displayText: 'paused' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'If the Clock’s timer is paused. Setting this value will pause or resume the timer.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/clock/#paused' # (optional)
          },
          # Functions
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getValue()'
            displayText: 'getValue()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the current value in stopwatch or timer mode as the number of seconds.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/clock/#getValue' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'pauseStart()'
            displayText: 'pauseStart()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Toggle function for pausing and resuming a stopwatch or timer on the Clock.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/clock/#pauseStart' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setValue(${1:int})'
            displayText: 'setValue(int seconds)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Switches the clock to timer mode and sets the timer to the given value in seconds.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/clock/#setValue' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'startStopwatch()'
            displayText: 'startStopwatch()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Switches the Clock to stopwatch mode and begins the stopwatch from 0.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/clock/#startStopwatch' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'showCurrentTime()'
            displayText: 'showCurrentTime()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Switches the Clock back to displaying the current time.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/clock/#showCurrentTime' # (optional)
          },
        ]
      # Counter Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "Counter") || ((bufferPosition.column >= 9 && editor.getTextInRange([[bufferPosition.row, bufferPosition.column - 8], bufferPosition]) == "Counter.") || previous_token == "Counter")
        console.log "FOUND COUNTER"
        suggestions = [
          # Functions
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'clear()'
            displayText: 'clear()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Resets the Counter value back to 0.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/counter/#clear' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'decrement()'
            displayText: 'decrement()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Decrements the Counter’s value by 1.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/counter/#decrement' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getValue()'
            displayText: 'getValue()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the current value of the Counter.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/counter/#getValue' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'increment()'
            displayText: 'increment()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Increments the Counter’s value by 1.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/counter/#increment' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setValue(${1:int})'
            displayText: 'setValue(int seconds)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Sets the current value of the Counter.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/counter/#setValue' # (optional)
          },
        ]
      # Player Class. How to do?
      # Object
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua" || previous_token == "") || not editor.getTextInRange([[bufferPosition.row, 0], bufferPosition]).includes("function")) && editor.getTextInRange([[bufferPosition.row, 0], bufferPosition]).includes(".")
        console.log "FOUND OBJECT"
        suggestions = [
          # Member Variables
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'angular_drag'
            displayText: 'angular_drag' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The Object\'s angular drag.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#angular_drag' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'bounciness'
            displayText: 'bounciness' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The Object\'s bounciness.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#bounciness' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'Clock'
            displayText: 'Clock' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'Clock' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'A reference to the Clock class attached to this Object. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#Clock' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'Counter'
            displayText: 'Counter' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'Counter' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'A reference to the Counter class attached to this Object. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#Counter' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'drag'
            displayText: 'drag' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The Object\'s drag.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#drag' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'dynamic_friction'
            displayText: 'dynamic_friction' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The Object\'s dynamic friction.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#dynamic_friction' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'guid'
            displayText: 'guid' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The Object’s guid. This is the same as the getGUID function. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#guid' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'held_by_color'
            displayText: 'held_by_color' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The color of the Player currently holding the Object. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#held_by_color' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'mass'
            displayText: 'mass' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The Object\'s mass.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#mass' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'name'
            displayText: 'name' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The Object’s formated name or nickname if applicable. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#name' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'resting'
            displayText: 'resting' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns true if this Object is not moving. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#resting' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'script_code'
            displayText: 'script_code' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the Lua script on this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#script_code' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'static_friction'
            displayText: 'static_friction' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The Object\'s static friction.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#static_friction' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'tag'
            displayText: 'tag' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The tag of the Object representing its type. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#tag' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'use_gravity'
            displayText: 'use_gravity' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Does gravity affect this Object?' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#use_gravity' # (optional)
          },
          # Functions
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'addForce(${1:Table}, ${2:int})'
            displayText: 'addForce(Table force_vector, int force_type)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Adds a force vector to the Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#addForce' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'addTorque(${1:Table}, ${2:int})'
            displayText: 'addTorque(Table torque_vector, int force_type)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Adds a torque vector to the Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#addTorque' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'clearButtons()'
            displayText: 'clearButtons()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Clears all 3D UI buttons on this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#clearButtons' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'createButton(${1:Table})'
            displayText: 'createButton(Table parameters)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Creates a 3D UI button on this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#createButton' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'cut()'
            displayText: 'cut()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Cuts this Object if it is a Deck or a Stack.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#cut' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'dealToAll(${1:int})'
            displayText: 'dealToAll(int num_cards)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Deals a number of Cards from a this Deck to all seated players.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#dealToAll' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'dealToColor(${1:int}, ${2:string})'
            displayText: 'dealToColor(int num_cards, string player_color)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Deals a number of Cards from this Deck to a specific player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#dealToColor' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'dealToColorWithOffset(${1:Table}, ${2:bool}, ${3:string})'
            displayText: 'dealToColorWithOffset(Table position, bool flip, string player_color)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Deals a Card to a player with an offset from their hand.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#dealToColorWithOffset' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'destruct()'
            displayText: 'destruct()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Destroys this Object. Mainly so you can call self.destruct().' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#destruct' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'editButton(${1:Table})'
            displayText: 'editButton(Table parameters)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Edits a 3D UI button on this Object based on its index.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#editButton' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'flip()'
            displayText: 'flip()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Flips this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#flip' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getAngularVelocity()'
            displayText: 'getAngularVelocity()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the current angular velocity vector of the Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getAngularVelocity' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getButtons()'
            displayText: 'getButtons()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Gets a list of all the 3D UI buttons on this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getButtons' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getColorTint()'
            displayText: 'getColorTint()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the color tint for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getColorTint' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getCustomObject()'
            displayText: 'getCustomObject()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the custom parameters on a Custom Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getCustomObject' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getDescription()'
            displayText: 'getDescription()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'string' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Gets the description for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getDescription' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getGUID()'
            displayText: 'getGUID()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'string' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the GUID that belongs to this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getGUID' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getLuaScript()'
            displayText: 'getLuaScript()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'string' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the Lua script for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getLuaScript' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getName()'
            displayText: 'getName()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'string' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the nickname for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getName' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getObjects()'
            displayText: 'getObjects()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns all the Objects inside of this container.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getObjects' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getPosition()'
            displayText: 'getPosition()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Gets the position for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getPosition' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getQuantity()'
            displayText: 'getQuantity()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the number of Objects in a stack.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getQuantity' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getRotation()'
            displayText: 'getRotation()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Gets the rotation of this Object in degrees.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getRotation' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getScale()'
            displayText: 'getScale()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Gets the scale for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getScale' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getStatesCount()'
            displayText: 'getStatesCount()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the number of States on this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getStatesCount' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getTable(${1:string})'
            displayText: 'getTable(string table_name)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Gets a Lua Table for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getTable' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getValue()'
            displayText: 'getValue()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the value for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getValue' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getVar(${1:string})'
            displayText: 'getVar(string variable_name)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'variable' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Gets a Lua variable for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getVar' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getVelocity()'
            displayText: 'getVelocity()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the current velocity vector of the Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#getVelocity' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'lock()'
            displayText: 'lock()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Locks this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#lock' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'removeButton(${1:int})'
            displayText: 'removeButton(int index)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Removes a 3D UI button from this Object by its index.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#removeButton' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'reset()'
            displayText: 'reset()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Resets this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#rest' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'roll()'
            displayText: 'roll()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Rolls this Object. Works on Dice and Coins.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#roll' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'rotate(${1:Table})'
            displayText: 'rotate(Table rotation)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Smoothly rotates this Object with the given offset in degrees.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#rotate' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'scale(${1:Table})'
            displayText: 'scale(Table scale)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Scales this Object by the given amount.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#scale' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'scaleAllAxes(${1:float})'
            displayText: 'scale(float scale)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Scales this Object in all axes by the given amount.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#scaleAllAxes' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setColorTint(${1:Table})'
            displayText: 'setColorTint(Table color)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Sets the color tint for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setColorTint' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setCustomObject(${1:Table})'
            displayText: 'setCustomObject(Table parameters)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Used to create a Custom Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setCustomObject' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setDescription(${1:string})'
            displayText: 'setDescription(string description)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Sets the description for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setDescription' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setLuaScript(${1:string})'
            displayText: 'setLuaScript(string script)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Sets the Lua script for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setLuaScript' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setName(${1:string})'
            displayText: 'setName(string nickname)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Sets the nickname for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setName' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setPosition(${1:Table})'
            displayText: 'setPosition(Table position)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Sets the world space position for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setPosition' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setPositionSmooth(${1:Table})'
            displayText: 'setPositionSmooth(Table position)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Smoothly moves this Object from its current position to a given world space position.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setPositionSmooth' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setRotation(${1:Table})'
            displayText: 'setRotation(Table rotation)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Sets the rotation of this Object in degrees.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setRotation' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setRotationSmooth(${1:Table})'
            displayText: 'setRotationSmooth(Table rotation)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Smoothly rotates this Object to the given orientation in degrees.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setRotationSmooth' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setScale(${1:Table})'
            displayText: 'setScale(Table scale)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Sets the scale for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setScale' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setState()'
            displayText: 'setState()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Sets the State on this Object and returns reference to the new State.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setState' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setTable(${1:string}, ${2:Table})'
            displayText: 'setTable(string table_name, Table table)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Sets a Lua Table for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setTable' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setValue(${1:value})'
            displayText: 'setValue(variable value)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Sets the value for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setValue' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setVar(${1:string}, ${2:variable})'
            displayText: 'setVar(string variable_name, variable value)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Sets a Lua variable for this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#setVar' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'shuffle()'
            displayText: 'shuffle()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Shuffles this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#shuffle' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'shuffleStates()'
            displayText: 'shuffleStates()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Shuffles the States on this Object and returns reference to the new State.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#shuffleStates' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'takeObject(${1:Table})'
            displayText: 'takeObject(Table parameters)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Takes an Object from this container.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#takeObject' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'translate(${1:Table})'
            displayText: 'translate(Table position)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Smoothly moves this Object from its current position to a given offset.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#translate' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'unlock()'
            displayText: 'unlock()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Unlocks this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#unlock' # (optional)
          }
        ]
      # Default Events
      else if editor.getTextInRange([[bufferPosition.row, 0], bufferPosition]).includes("function")
        console.log "FOUND DEFAULT EVENTS"
        suggestions = [
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'onCollisionEnter(collision_info)\n\t${0:-- body...}\nend'
            displayText: 'onCollisionEnter(Table collision_info)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Automatically called when this Object collides with another Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onCollisionEnter' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'onCollisionExit(collision_info)\n\t${0:-- body...}\nend'
            displayText: 'onCollisionExit(Table collision_info)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Automatically called when this Object stops touching another Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onCollisionExit' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'onCollisionStay(collision_info)\n\t${0:-- body...}\nend'
            displayText: 'onCollisionStay(Table collision_info)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Automatically called when this Object is touching another Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onCollisionStay' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'onDestroy()\n\t${0:-- body...}\nend'
            displayText: 'onDestroy()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Automatically called when this Object is destroyed.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onDestroy' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'onDropped(player_color)\n\t${0:-- body...}\nend'
            displayText: 'onDropped(string color)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Automatically called when this Object is dropped.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onDropped' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'onload()\n\t${0:-- body...}\nend'
            displayText: 'onload()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Automatically called when a game save is finished loading every Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onload' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'onObjectDestroyed(dying_object)\n\t${0:-- body...}\nend'
            displayText: 'onObjectDestroyed(Object dying_object)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Automatically called when an Object is destroyed.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectDestroyed' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'onObjectEnterScriptingZone(zone, enter_object)\n\t${0:-- body...}\nend'
            displayText: 'onObjectEnterScriptingZone(Object zone, Object enter_object)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Automatically called when an Object enters a Scripting Zone.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectEnterScriptingZone' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'onObjectLeaveScriptingZone(zone, leave_object)\n\t${0:-- body...}\nend'
            displayText: 'onObjectLeaveScriptingZone(Object zone, Object leave_object)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Automatically called when an Object leaves a Scripting Zone.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectLeaveScriptingZone' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'onPickedUp(player_color)\n\t${0:-- body...}\nend'
            displayText: 'onPickedUp(string color)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Automatically called when this Object is picked up.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onPickedUp' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'onPlayerChangedColor(player_color)\n\t${0:-- body...}\nend'
            displayText: 'onPlayerChangedColor(string color)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Automatically called when a Player changes color.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onPlayerChangedColor' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'onPlayerTurnEnd(player_color)\n\t${0:-- body...}\nend'
            displayText: 'onPlayerTurnEnd(string color)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Automatically called at the end of a Player\'s turn.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onPlayerTurnEnd' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'onPlayerTurnStart(player_color)\n\t${0:-- body...}\nend'
            displayText: 'onPlayerTurnStart(string color)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Automatically called at the start of a Player\'s turn.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onPlayerTurnStart' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'update()\n\t${0:-- body...}\nend'
            displayText: 'update()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Automatically called once every frame.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#update' # (optional)
          },
        ]
      # Globally accessible constants & functions
      else
        console.log "FOUND GLOBALLY ACCESSIBLE FUNCTIONS"
        suggestions = [
          # Constants
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'coroutine'
            displayText: 'coroutine' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            #leftLabel: 'variable' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The coroutine class.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#6.2' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'Global'
            displayText: 'Global' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            #leftLabel: 'variable' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'A reference to the Global Script.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'math'
            displayText: 'math' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            #leftLabel: 'variable' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The math class.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#6.6' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'os'
            displayText: 'os' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            #leftLabel: 'variable' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The os class.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#6.9' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'self'
            displayText: 'self' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            #leftLabel: 'variable' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'A reference to this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object' # (optional)
          },
          # Global Management Functions
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'callLuaFunctionInOtherScript(${1:Object}, ${2:string})'
            displayText: 'callLuaFunctionInOtherScript(Object func_owner, string func_name)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Starts a Lua function owned by another Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#callLuaFunctionInOtherScript' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'callLuaFunctionInOtherScriptWithParams(${1:Object}, ${2:string}, ${3:Table})'
            displayText: 'callLuaFunctionInOtherScriptWithParams(Object func_owner, string func_name, Table params)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Starts a Lua function owned by another Object with parameters.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#callLuaFunctionInOtherScriptWithParams' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'destroyObject(${1:Object})'
            displayText: 'destroyObject(Object obj)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Destroys an Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#destroyObject' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'flipTable()'
            displayText: 'flipTable()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Flip the table in a fit of rage.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#flipTable' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getAllObjects()'
            displayText: 'getAllObjects()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns a Table of all the spawned Objects in the game.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getAllObjects' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getNotes()'
            displayText: 'getNotes()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'string' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the current on-screen notes as a string.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getNotes' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getObjectFromGUID(${1:string})'
            displayText: 'getObjectFromGUID(string guid)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Gets a reference to an Object from a GUID. Will return nil if the Object doesn’t exist.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getObjectFromGUID' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getPlayer(${1:string})'
            displayText: 'getSeatedPlayers(string player_color)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Player' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns a Player object if someone is seated at the color.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getPlayer' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getSeatedPlayers()'
            displayText: 'getSeatedPlayers()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns an indexed Lua Table of all the seated Player colors.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getSeatedPlayers' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'print(${1:string})'
            displayText: 'print(string message)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Prints a message to the chatin window only on the host.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#print' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'printToAll(${1:string}, ${2:Table})'
            displayText: 'printToAll(string message, Table text_color)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Prints a message to the chat window on all connected clients.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#printToAll' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'printToColor(${1:string}, ${2:string}, ${3:Table})'
            displayText: 'printToColor(string message, string player_color, Table text_color)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Prints a message to the chat window of a specific Player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#printToColor' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setNotes(${1:string})'
            displayText: 'setNotes(string notes)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Sets the current on-screen notes. BBCOde is allowed for styling.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#setNotes' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'spawnObject(${1:Table})'
            displayText: 'spawnObject(Table parameters)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Spawns an Object and returns a reference to it.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#spawnObject' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'startLuaCoroutine(${1:Object}, ${2:string})'
            displayText: 'startLuaCoroutine(Object func_owner, string func_name)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Starts a Lua function as a coroutine.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#startLuaCoroutine' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'stringColorToRGB(${1:string})'
            displayText: 'stringColorToRGB(string color)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Converts a color string (player colors) to its RGB values.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#stringColorToRGB' # (optional)
          },
        ]
      resolve(suggestions)
