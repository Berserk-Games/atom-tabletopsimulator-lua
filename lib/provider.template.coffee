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
          #if postfix != ''
          #  postfix += '\n'
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
      else if (line.match(/(^|\s)else$/) || line.match(/(^|\s)elseif$/) || line.match(/(^|\s)end$/) || line == "end")
        # Short circuit some common lua keywords
        resolve([])
        return

      match_exact = (name) ->
        return ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == name) || line.endsWith(name + ".") || (previous_token == name && this_token_intact)

      match_ending = (name) ->
        return ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token.endsWith(name)) || line.endsWith(name + ".") || (previous_token.endsWith(name) && this_token_intact)


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
          {
            snippet: '\n\tfunction ' + function_name + "()\n\t\trepeat\n\t\t\tcoroutine.yield(0)\n\t\tuntil $1\n\t\treturn 1\n\tend\n\tstartLuaCoroutine(self, '" + function_name + "')\nend"
            displayText: 'function...coroutine...repeat...end'
          },
        ]

      else if match_exact("Action")
        suggestions = [
          #insert Action
        ]

      else if match_exact("AssetBundle")
        suggestions = [
          #insert AssetBundle
        ]

      else if match_exact("Backgrounds")
        suggestions = [
          #insert Backgrounds
        ]

      else if match_exact("bit32")
        suggestions = [
          #insert bit32
        ]

      else if match_exact("Book")
        suggestions = [
          #insert Book
        ]

      else if match_exact("Browser")
        suggestions = [
          #insert Browser
        ]

      else if match_exact("Clock")
        suggestions = [
          #insert Clock
        ]

      else if match_exact("Color")
        suggestions = [
          #insert Color
        ]

      else if match_exact("Container")
        suggestions = [
          #insert Container
        ]

      else if match_exact("coroutine")
        suggestions = [
          #insert coroutine
        ]

      else if match_exact("Counter")
        suggestions = [
          #insert Counter
        ]

      else if match_exact("dynamic")
        suggestions = [
          #insert dynamic
        ]

      else if match_exact("Global")
        suggestions = [
          #insert Global
        ]

      else if match_exact("Grid")
        suggestions = [
          #insert Grid
        ]

      else if match_exact("Hands")
        suggestions = [
          #insert Hands
        ]

      else if match_exact("Info")
        suggestions = [
          #insert Info
        ]

      else if match_exact("JSON")
        suggestions = [
          #insert JSON
        ]

      else if match_exact("LayoutZone")
        suggestions = [
          #insert LayoutZone
        ]

      else if match_exact("Lighting")
        suggestions = [
          #insert Lighting
        ]

      else if match_exact("math")
        suggestions = [
          #insert math
        ]

      else if match_exact("MusicPlayer")
        suggestions = [
          #insert MusicPlayer
        ]

      else if match_exact("Notes")
        suggestions = [
          #insert Notes
        ]

      else if match_exact("os")
        suggestions = [
          #insert os
        ]

      else if match_exact("Player")
        suggestions = [
          #insert PlayerManager
        ]

      else if match_exact("Physics")
        suggestions = [
          #insert Physics
        ]

      else if match_exact("RPGFigurine")
        suggestions = [
          #insert RPGFigurine
        ]

      else if match_exact("string")
        suggestions = [
          #insert string
        ]

      else if match_exact("table")
        suggestions = [
          #insert table
        ]

      else if match_exact("Tables")
        suggestions = [
          #insert Tables
        ]

      else if match_exact("TextTool")
        suggestions = [
          #insert TextTool
        ]

      else if match_exact("Time")
        suggestions = [
          #insert Time
        ]

      else if match_exact("Turns")
        suggestions = [
          #insert Turns
        ]

      else if match_exact("UI")
        suggestions = [
          #insert UI
        ]

      else if match_exact("Vector")
        suggestions = [
          #insert Vector
        ]

      else if match_exact("Wait")
        suggestions = [
          #insert Wait
        ]

      else if match_exact("WebRequest")
        suggestions = [
          #insert WebRequest
        ]

      else if match_exact("Zone") # Zone Behaviour (has all Zone members)
        suggestions = [
          #insert Zone
        ]

      # PlayerInstance
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token_2 == "Player") ||  previous_token.substring(0, 7) == "Player["
        suggestions = [
          #insert PlayerInstance
        ]

      # Component
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua") && previous_token == "getComponent") || match_ending("component")
        suggestions = [
          #insert Component
        ]

      # GameObject
      else if match_ending("game_object")
        suggestions = [
          #insert GameObject
        ]

      # Material
      else if match_ending("material")
        suggestions = [
          #insert Material
        ]

      # Object
      else if ((prefix == "." || scopeDescriptor.scopes[1] == "variable.other.lua" || (tokens.length > 1 && this_token_intact)))
        # Prefix with behaviour if variable looks likely
        if match_ending("bundle")
          suggestions = [
            #insert AssetBundle
          ]
        else if match_ending("book")
          suggestions = [
            #insert Book
          ]
        else if match_ending("browser")
          suggestions = [
            #insert Browser
          ]
        else if match_ending("clock")
          suggestions = [
            #insert Clock
          ]
        else if match_ending("counter")
          suggestions = [
            #insert Counter
          ]
        else if match_ending("figurine")
          suggestions = [
            #insert RPGFigurine
          ]
        else if match_ending("layout_zone")
          suggestions = [
            #insert LayoutZone
          ]
        else if match_ending("text_tool")
          suggestions = [
            #insert TextTool
          ]
        else if match_ending("zone")
          suggestions = [
            #insert Zone
          ]

        suggestions = suggestions.concat [
          #insert Object
        ]

      # Section: Default Events
      else if (line.startsWith('function') && not line.includes("("))
        suggestions = []
        if not global_script
          suggestions = suggestions.concat [
            #insert ObjectEvents
          ]
        suggestions = suggestions.concat [
          #insert GlobalEvents
        ]

      # Section: Globally accessible constants & functions
      else if (not (line.endsWith("}") || line.endsWith(")") || line.endsWith("]"))) and not line.includes("function ") and not this_token.includes("for ") and line.match(/\w$/)
        suggestions = [
          #insert /
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
                      type: 'function'
                      leftLabel: 'Object'
                      description: 'Gets a reference to an Object from a GUID. Will return nil if the Object doesn’t exist.'
                      descriptionMoreURL: 'https://api.tabletopsimulator.com/base/#getobjectfromguid'
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
                          descriptionMoreURL: 'https://api.tabletopsimulator.com/base/#getobjectfromguid'
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
