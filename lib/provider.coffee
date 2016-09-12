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

      if scopeDescriptor.scopes[1] == "keyword.operator.lua" || scopeDescriptor.scopes[1] == "string.quoted.double.lua" || scopeDescriptor.scopes[1] == "string.quoted.single.lua"
        resolve([])

      # Substring up until this position
      line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
      tokens = line.split "."
      previous_token = ""
      previous_token_2 = ""
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

      tokens = line.split "."
      if tokens.length > 2
        previous_token_2 = tokens[tokens.length - 3].trim()
        tokens = previous_token_2.split("(")
        previous_token_2 = tokens[tokens.length - 1].trim()
        tokens = previous_token_2.split("=")
        previous_token_2 = tokens[tokens.length - 1].trim()
        tokens = previous_token_2.split("{")
        previous_token_2 = tokens[tokens.length - 1].trim()
        tokens = previous_token_2.split(",")
        previous_token_2 = tokens[tokens.length - 1].trim()
        tokens = previous_token_2.split(">")
        previous_token_2 = tokens[tokens.length - 1].trim()
        tokens = previous_token_2.split("<")
        previous_token_2 = tokens[tokens.length - 1 ].trim()
        tokens = previous_token_2.split(" ")
        previous_token_2 = tokens[tokens.length - 1].trim()

      #console.log previous_token
      #console.log previous_token_2

      #console.log previous_token.length > 7 && previous_token.substring(0, 7) == "Player["
      #console.log previous_token.substring(0, 7)

      # Global object
      if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "Global") || ((bufferPosition.column >= 8 && editor.getTextInRange([[bufferPosition.row, bufferPosition.column - 7], bufferPosition]) == "Global.") || previous_token == "Global")
        #console.log "FOUND GLOBAL"
        suggestions = [
          # Member Variables
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
            description: 'Returns the Global Lua script.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#script_code' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'script_state'
            displayText: 'script_state' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the Global saved Lua script state.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#script_state' # (optional)
          },
          # Functions
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'call(${1:string}, ${2:Table})'
            displayText: 'call(string function_name, Table parameters)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'variable' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Calls a Lua function owned by the Global Script and passes an optional Table as parameters to the function.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#call' # (optional)
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
        #console.log "FOUND MATH"
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
        #console.log "FOUND COROUTINE"
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
        #console.log "FOUND OS"
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
        #console.log "FOUND CLOCK"
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
        #console.log "FOUND COUNTER"
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
      # Player Colors
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "Player") || ((bufferPosition.column >= 8 && editor.getTextInRange([[bufferPosition.row, bufferPosition.column - 7], bufferPosition]) == "Player.") || previous_token == "Player")
        #console.log "FOUND Player"
        suggestions = [
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'Black'
            displayText: 'Black' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The Black player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'Blue'
            displayText: 'Blue' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The Blue player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'Brown'
            displayText: 'Brown' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The Brown player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'Green'
            displayText: 'Green' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The Green player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'Orange'
            displayText: 'Orange' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The Orange player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'Pink'
            displayText: 'Pink' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The Pink player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'Purple'
            displayText: 'Purple' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The Purple player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'Red'
            displayText: 'Red' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The Red player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'Teal'
            displayText: 'Teal' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The Teal player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'White'
            displayText: 'White' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The White player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'Yellow'
            displayText: 'Yellow' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            leftLabel: 'Player' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The Yellow player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/' # (optional)
          },
        ]
      # Player Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token_2 == "Player") || (previous_token.length > 7 && previous_token.substring(0, 7) == "Player[")
        #console.log "FOUND Player Class"
        suggestions = [
          # Member Variables
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'admin'
            displayText: 'admin' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Is the player currently promoted or hosting the game? Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#admin' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'blindfolded'
            displayText: 'blindfolded' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Is the player blindfolded?' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#blindfolded' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'color'
            displayText: 'color' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The player\'s color. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#color' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'lift_height'
            displayText: 'lift_height' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The player\'s lift height from 0 to 1.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#lift_height' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'promoted'
            displayText: 'promoted' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Is the player currently promoted? Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#promoted' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'seated'
            displayText: 'seated' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Is the player currently seated at the table? Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#seated' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'steam_id'
            displayText: 'steam_id' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'float' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The player\'s Steam ID. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#steam_id' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'steam_name'
            displayText: 'steam_name' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The player\'s Steam name. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#steam_name' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'team'
            displayText: 'team' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The player\'s team. Team names: "None", "Clubs", "Diamonds", "Hearts", "Spades". Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#team' # (optional)
          },
          # Functions
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'attachCameraToObject(${1:Table})'
            displayText: 'attachCameraToObject(Table parameters)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Makes a player\'s camera follow an Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#attachCameraToObject' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'blind()'
            displayText: 'blind()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Puts the blindfold on the player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#blind' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'changeColor(${1:string})'
            displayText: 'changeColor(string new_color)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Changes the player\'s color.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#changeColor' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'changeTeam(${1:string})'
            displayText: 'changeTeam(string new_team)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Changes the player\'s team. Valid team names: "None", "Clubs", "Diamonds", "Hearts", "Spades".' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#changeTeam' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getHandObjects()'
            displayText: 'getHandObjects()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns a Lua Table as a list of all the Cards and Mahjong Tiles in the player\'s hand.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getHandObjects' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getPlayerHand()'
            displayText: 'getPlayerHand()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns a Lua Table with the position and rotation of the given player\'s hand.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getPlayerHand' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getPointerPosition()'
            displayText: 'getPointerPosition()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the position of the given player color\'s pointer.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getPointerPosition' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getPointerRotation()'
            displayText: 'getPointerRotation()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the y-axis rotation of the given player color\'s pointer in degrees.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#getPointerRotation' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'kick()'
            displayText: 'kick()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Kicks the player from the game.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#kick' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'lookAt(${1:Table})'
            displayText: 'lookAt(Table parameters)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Moves the Player\'s camera to look at a specific point.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#lookAt' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'mute()'
            displayText: 'mute()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Mutes or unmutes the player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#mute' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'promote()'
            displayText: 'promote()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Promotes or demotes the player.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#promote' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'unblind()'
            displayText: 'unblind()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Removes the blindfold from the player if she is blindfolded.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player/#unblind' # (optional)
          },
        ]
      # JSON Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "JSON") || ((bufferPosition.column >= 6 && editor.getTextInRange([[bufferPosition.row, bufferPosition.column - 5], bufferPosition]) == "JSON.") || previous_token == "JSON")
        #console.log "FOUND JSON"
        suggestions = [
          # Functions
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'decode(${1:string})'
            displayText: 'decode(string json_string)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'variable' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Decodes a valid JSON string into a Lua string, number, or Table.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/json/#decode' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'encode(${1:variable})'
            displayText: 'encode(variable)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'string' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Encodes a Lua string, number, or Table into a valid JSON string. This will not work with Object references.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/json/#encode' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'encode_pretty(${1:variable})'
            displayText: 'encode_pretty(variable)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'string' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Encodes a Lua string, number, or Table into a valid JSON string formatted with indents (Human readable). This will not work with Object references.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/json/#encode_pretty' # (optional)
          },
        ]
      # Timer Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "Timer") || ((bufferPosition.column >= 7 && editor.getTextInRange([[bufferPosition.row, bufferPosition.column - 6], bufferPosition]) == "Timer.") || previous_token == "Timer")
        #console.log "FOUND Timer"
        suggestions = [
          # Functions
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'create(${1:Table})'
            displayText: 'create(Table parameters)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Creates a Timer. Timers are used for calling functions after a delay or repeatedly.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/timer/#create' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'destroy(${1:string})'
            displayText: 'destroy(string identifier)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Destroys an existing timer.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/timer/#destroy' # (optional)
          },
        ]
      # RPGFigurine Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "RPGFigurine") || ((bufferPosition.column >= 13 && editor.getTextInRange([[bufferPosition.row, bufferPosition.column - 12], bufferPosition]) == "RPGFigurine.") || previous_token == "RPGFigurine")
        #console.log "FOUND RPGFigurine"
        suggestions = [
          # Functions
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'attack()'
            displayText: 'attack()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Plays a random attack animation.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/rpgfigurine/#attack' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'changeMode()'
            displayText: 'changeMode()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Changes the RPG Figurine\'s current mode.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/rpgfigurine/#changeMode' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'die()'
            displayText: 'die()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Plays the death animation. Call die() again to reset the RPG Figurine.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/rpgfigurine/#die' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'onAttack(hit_list)\n\t${0:-- body...}\nend'
            displayText: 'onAttack(Table hit_list)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'This function is called, if it exists in your script, when this RPGFigurine attacks another RPGFigurine.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/rpgfigurine/#onAttack' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'onHit(attacker)\n\t${0:-- body...}\nend'
            displayText: 'onHit(Object attacker)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'This function is called, if it exists in your script, when this RPGFigurine is attacked by another RPGFigurine.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/rpgfigurine/#onHit' # (optional)
          },
        ]
      # TextTool Class
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "TextTool") || ((bufferPosition.column >= 10 && editor.getTextInRange([[bufferPosition.row, bufferPosition.column - 9], bufferPosition]) == "TextTool.") || previous_token == "TextTool")
        #console.log "FOUND TextTool"
        suggestions = [
          # Functions
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getFontColor()'
            displayText: 'getFontColor()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the current font color as a Lua Table keyed as Table[\'r\'], Table[\'g\'], and Table[\'b\'].' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/texttool/#getFontColor' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getFontSize()'
            displayText: 'getFontSize()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the current font size.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/texttool/#getFontSize' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'getValue()'
            displayText: 'getValue()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'string' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the current text.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/texttool/#getValue' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setFontColor(${1:Table})'
            displayText: 'setFontColor(Table color)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Sets the current font color. The Lua Table parameter should be keyed as Table[\'r\'], Table[\'g\'], and Table[\'b\'].' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/texttool/#setFontColor' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setFontSize(${1:int})'
            displayText: 'setFontSize(int font_size)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Sets the current font size.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/texttool/#setFontSize' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'setValue(${1:string})'
            displayText: 'setValue(string text)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Sets the current text.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/texttool/#setValue' # (optional)
          },
        ]
      # Object
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua" || previous_token == "") || not editor.getTextInRange([[bufferPosition.row, 0], bufferPosition]).includes("function")) && editor.getTextInRange([[bufferPosition.row, 0], bufferPosition]).includes(".")
        #console.log "FOUND OBJECT"
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
            snippet: 'auto_raise'
            displayText: 'auto_raise' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Should this Object automatically raise above other Objects when held?' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#auto_raise' # (optional)
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
            snippet: 'interactable'
            displayText: 'interactable' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Can players interact with this Object? If false, only Lua Scripts can interact with this Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#interactable' # (optional)
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
            snippet: 'RPGFigurine'
            displayText: 'RPGFigurine' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'RPGFigurine' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'A reference to the RPGFigurine class attached to this Object. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#RPGFigurine' # (optional)
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
            snippet: 'script_state'
            displayText: 'script_state' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'string' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns the saved Lua script state on the Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#script_state' # (optional)
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
            snippet: 'sticky'
            displayText: 'sticky' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Should Objects on top of this Object stick to this Object when this Object is picked up?' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#sticky' # (optional)
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
            snippet: 'tooltip'
            displayText: 'tooltip' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Should Object show tooltips when hovering over it.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#tooltip' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'TextTool'
            displayText: 'TextTool' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'TextTool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'A reference to the TextTool class attached to this Object. Read only.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#TextTool' # (optional)
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
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'use_grid'
            displayText: 'use_grid' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Should this Object snap to grid points?' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#use_grid' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'use_snap_points'
            displayText: 'use_snap_points' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'property' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Should this Object snap to snap points?' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#use_snap_points' # (optional)
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
            snippet: 'call(${1:string}, ${2:Table})'
            displayText: 'call(string function_name, Table parameters)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'variable' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Calls a Lua function owned by this Object and passes an optional Table as parameters to the function.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#call' # (optional)
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
            snippet: 'clone(${1:Table})'
            displayText: 'clone(Table parameters)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Copies and pastes this Object. Returns a reference to the newly spawned Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/object/#clone' # (optional)
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
            snippet: 'scale(${1:float})'
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
            snippet: 'setPositionSmooth(${1:Table}, ${2:bool}, ${3:bool})'
            displayText: 'setPositionSmooth(Table position, bool Collide, bool Fast)' # (optional)
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
            snippet: 'setRotationSmooth(${1:Table}, ${2:bool}, ${3:bool})'
            displayText: 'setRotationSmooth(Table rotation, bool Collide, bool Fast)' # (optional)
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
            snippet: 'setState(${1:int})'
            displayText: 'setState(int state)' # (optional)
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
        #console.log "FOUND DEFAULT EVENTS"
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
            displayText: 'onDropped(string player_color)' # (optional)
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
            snippet: 'onLoad(save_state)\n\t${0:-- body...}\nend'
            displayText: 'onLoad(string save_state)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Automatically called when a game save is finished loading every Object.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onLoad' # (optional)
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
            snippet: 'onObjectDropped(player_color, dropped_object)\n\t${0:-- body...}\nend'
            displayText: 'onObjectDropped(string player_color, Object dropped_object)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Automatically called when an Object is dropped.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectDropped' # (optional)
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
            snippet: 'onObjectPickedUp(player_color, picked_up_object)\n\t${0:-- body...}\nend'
            displayText: 'onObjectPickedUp(string player_color, Object picked_up_object)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Automatically called when an Object is picked up.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onObjectPickedUp' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'onPickedUp(player_color)\n\t${0:-- body...}\nend'
            displayText: 'onPickedUp(string player_color)' # (optional)
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
            displayText: 'onPlayerChangedColor(string player_color)' # (optional)
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
            snippet: 'onPlayerTurnEnd(player_color_end, player_color_next)\n\t${0:-- body...}\nend'
            displayText: 'onPlayerTurnEnd(string player_color_end, string player_color_next)' # (optional)
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
            snippet: 'onPlayerTurnStart(player_color_start, player_color_previous)\n\t${0:-- body...}\nend'
            displayText: 'onPlayerTurnStart(string player_color_start, string player_color_previous)' # (optional)
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
            snippet: 'onSave()\n\t${0:-- body...}\nend'
            displayText: 'onSave()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            #leftLabel: 'Object' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Automatically called when the game saves (including auto-save for Rewinding).' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#onSave' # (optional)
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
        #console.log "FOUND GLOBALLY ACCESSIBLE FUNCTIONS"
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
            snippet: 'JSON'
            displayText: 'JSON' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            #leftLabel: 'variable' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The JSON class.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/json' # (optional)
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
            snippet: 'Player'
            displayText: 'Player' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            #leftLabel: 'variable' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The Player class.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/player' # (optional)
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
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'Timer'
            displayText: 'Timer' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'constant' # (optional)
            #leftLabel: 'variable' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'The Timer class.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/timer/' # (optional)
          },
          # Global Management Functions
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'addNotebookTab(${1:Table})'
            displayText: 'addNotebookTab(Table parameters)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'int' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Adds a new Tab to the Notebook and returns the index of the newly added Tab.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#addNotebookTab' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'clearPixelPaint()'
            displayText: 'clearPixelPaint()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Clears all pixel paint.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#clearPixelPaint' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'clearVectorPaint()'
            displayText: 'clearVectorPaint()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Clears all vector paint.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#clearVectorPaint' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'copy(${1:Table})'
            displayText: 'copy(Table objects)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Copies a list of Objects.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#copy' # (optional)
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
            snippet: 'editNotebookTab(${1:Table})'
            displayText: 'editNotebookTab(Table parameters)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Edits an existing Tab on the Notebook.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#editNotebookTab' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'broadcastToAll(${1:string}, ${2:Table})'
            displayText: 'broadcastToAll(string message, Table text_color)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Prints a message to the screen and chat window on all connected clients.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#broadcastToAll' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'broadcastToColor(${1:string}, ${2:string}, ${3:Table})'
            displayText: 'broadcastToColor(string message, string player_color, Table text_color)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Prints a private message to the screen and chat window to the player matching the player color.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#broadcastToColor' # (optional)
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
            snippet: 'getNotebookTabs()'
            displayText: 'getNotebookTabs()' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Returns a Table of Tables of all of the Tabs in the Notebook.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#getNotebookTabs' # (optional)
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
            snippet: 'paste(${1:Table})'
            displayText: 'paste(Table parameters)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'Table' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Pastes copied Objects and returns a Table of references to the new Objects.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#copy' # (optional)
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
            snippet: 'removeNotebookTab(${1:int})'
            displayText: 'removeNotebookTab(int index)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'bool' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Removes a Tab from the Notebook at a given index.' # (optional)
            descriptionMoreURL: 'http://berserk-games.com/knowledgebase/api/#removeNotebookTab' # (optional)
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
            displayText: 'stringColorToRGB(string player_color)' # (optional)
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
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'tonumber(${1:e})'
            displayText: 'tonumber(e [, base])' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'number' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'When called with no base, tonumber tries to convert its argument to a number.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-tonumber' # (optional)
          },
          {
            #text: 'getObjectFromGUID()' # OR
            snippet: 'tostring(${1:v})'
            displayText: 'tostring(v)' # (optional)
            #replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'number' # (optional)
            #leftLabelHTML: '' # (optional)
            #rightLabel: '' # (optional)
            #rightLabelHTML: '' # (optional)
            #className: '' # (optional)
            #iconHTML: '' # (optional)
            description: 'Receives a value of any type and converts it to a string in a reasonable format.' # (optional)
            descriptionMoreURL: 'https://www.lua.org/manual/5.2/manual.html#pdf-tostring' # (optional)
          },
        ]
      resolve(suggestions)
