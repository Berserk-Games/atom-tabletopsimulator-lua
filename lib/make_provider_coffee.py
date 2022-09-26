from ruamel.yaml import YAML

with open('api.yaml') as f:
    yaml = YAML(typ='safe')
    api = yaml.load(f)

coffee = {}

indent_spaces = "                                            "

def quoted(s):
    s = s.replace("'", "\\'")
    return f"'{s}'"

def get_url(url):
    if url.startswith('/'):
        return f'https://api.tabletopsimulator.com{url}'
    else:
        return url

def add_output(output, indent, key, value, quote=True):
    spaces = indent_spaces[:indent*2]
    if quote:
        output.append(f"{spaces}{key}: {quoted(value)}")
    else:
        indented_spaces = indent_spaces[:(indent + 1)*2]
        value = value.replace('\n', '\n'+indented_spaces)
        output.append(f"{spaces}{key}: {value}")

def start_section(output, indent):
    output.append(f"{indent_spaces[:indent*2]}{{")

def end_section(output, indent):
    output.append(f"{indent_spaces[:indent*2]}}},")

def add_property(output, items, label):
    for item in items:
        assert(len(item) == 4)
        name, kind, description, url = item
        start_section(output, 5)
        add_output(output, 6, 'snippet', name)
        add_output(output, 6, 'displayText', name)
        add_output(output, 6, 'type', label)
        add_output(output, 6, 'leftLabel', kind)
        add_output(output, 6, 'description', description)
        add_output(output, 6, 'descriptionMoreURL', get_url(url))
        end_section(output, 5)

def format_snippet_param(param, i):
    assert(len(param) == 2)
    return f"${{{i+1}:{param[1]}|{param[0]}}}"

def format_displayText_param(param, i):
    assert(len(param) == 2)
    return f"{param[1]} {param[0]}"

def format_event_snippet_param(param, i):
    assert(len(param) == 2)
    return param[0]

def format_table_snippet_param(param, i):
    assert(len(param) == 2 or len(param) == 3)
    if len(param) == 2:
        return "\\n\\t' +\n'" + f"{param[0].ljust(25)} = ${{{i+1}:-- {param[1]}}}"
    else:
        return "\\n\\t' +\n'" + f"{param[0].ljust(25)} = ${{{i+1}:-- {param[1].ljust(8)} {param[2]}}}"

def format_event_table_snippet_param(param, i):
    assert(len(param) == 2 or len(param) == 3)
    if len(param) == 2:
        return "\\n\\t' +\n'" + f"--    {param[0].ljust(25)} {param[1]}"
    else:
        comment = param[2].replace("'", "\\'")
        return "\\n\\t' +\n'" + f"--    {param[0].ljust(25)} {param[1].ljust(8)} {comment}}}"

def format_table_displayText_param(param, i):
    assert(len(param) == 2 or len(param) == 3)
    return f"{param[1]} {param[0]}"

def format_params(params, formatter, table_formatter = None, single_line = False):
    l = []
    i = 0
    table_name = ""
    for param in params:
        formatted = None
        if type(param) == dict:
            table_params = list(param.values())[0]
            param = list(param.keys())[0]
            if type(param) == str:
                assert(param == 'return')
                table_name = 'return'
                if not table_formatter:
                    continue
                else:
                    assert(len(table_params) > 0)
                    assert(type(table_params == list))
                    header = "{"
                    if single_line:
                        footer = "}"
                    else:
                        footer = "\\n' +\n'}"
                    if type(table_params[0]) == dict:
                        assert(len(table_params) == 1)
                        table_params = table_params[0]
                        assert(len(table_params) > 0)
                        assert(list(table_params.keys())[0] == 'items')
                        table_params = list(table_params.values())[0]
                        header = "{{"
                        if single_line:
                            footer = "}}"
                        else:
                            footer = "\\n' +\n'}}"
                    tl = []
                    for table_param in table_params:
                        tl.append(table_formatter(table_param, i))
                        i += 1
                    if single_line:
                        formatted = header + ", ".join(tl) + footer
                    else:
                        formatted = header + ",".join(tl) + footer
            else:
                table_name = param[0]
                if table_formatter:
                    assert(len(table_params) > 0)
                    assert(type(table_params == list))
                    header = "{"
                    if single_line:
                        footer = "}"
                    else:
                        footer = "\\n' +\n'}"
                    if type(table_params[0]) == dict:
                        assert(len(table_params) == 1)
                        table_params = table_params[0]
                        assert(len(table_params) > 0)
                        assert(list(table_params.keys())[0] == 'items')
                        table_params = list(table_params.values())[0]
                        header = "{{"
                        if single_line:
                            footer = "}}"
                        else:
                            footer = "\\n' +\n'}}"
                    tl = []
                    for table_param in table_params:
                        tl.append(table_formatter(table_param, i))
                        i += 1
                    if single_line:
                        formatted = header + ", ".join(tl) + footer
                    else:
                        formatted = header + ",".join(tl) + footer
        if formatted:
            l.append(formatted)
        else:
            l.append(formatter(param, i))
        i += 1
    return ', '.join(l), table_name


def add_function(indent, output, items, is_event):
    indentplus = indent + 1
    for item in items:
        if type(item) == dict:
            assert(len(item) == 1)
            params = list(item.values())[0]
            signature = list(item.keys())[0]
            assert(len(signature) == 4)
            name, kind, description, url = signature

            if is_event:
                snippet_text, is_table = format_params(params, format_event_snippet_param)
            else:
                snippet_text, is_table = format_params(params, format_snippet_param)
            if not (is_event and is_table):
                start_section(output, indent)
                if is_event:
                    add_output(output, indentplus, 'snippet', f'{name}({snippet_text})' + '\\n\\t${0: -- body...}\\nend')
                else:
                    add_output(output, indentplus, 'snippet', f'{name}({snippet_text})')
                add_output(output, indentplus, 'displayText', f'{name}({format_params(params, format_displayText_param)[0]})')
                add_output(output, indentplus, 'type', 'function')
                add_output(output, indentplus, 'leftLabel', 'bool' if kind== 'void' else kind)
                add_output(output, indentplus, 'description', description)
                add_output(output, indentplus, 'descriptionMoreURL', get_url(url))
                end_section(output, indent)

            if is_table:
                start_section(output, indent)
                if is_event or is_table == 'return':
                    snippet_params = format_params(params, format_event_snippet_param, format_event_table_snippet_param)[0]
                    if is_table == 'return':
                        i = snippet_params.find('{')
                        assert(i >= 0)
                        snippet_params = snippet_params[i:]
                        snippet_joined = f"'{name}({snippet_text})" + "\\n\\t' +\n'-- returns " + snippet_params
                    else:
                        snippet_joined = f"'{name}({snippet_text})" + "\\n\\t' +\n'-- " + is_table + " is " + snippet_params
                    if snippet_joined.endswith('}}'):
                        snippet_joined = snippet_joined[:-2] + "\\t-- }}"
                    else:
                        assert(snippet_joined.endswith('}'))
                        snippet_joined = snippet_joined[:-1] + "\\t-- }"
                    if is_event:
                        snippet_joined += "\\n\\t$1\\nend'"
                    else:
                        snippet_joined += "'"
                    add_output(output, indentplus, 'snippet', snippet_joined, False)
                else:
                    snippet_params = format_params(params, format_snippet_param, format_table_snippet_param)[0]
                    add_output(output, indentplus, 'snippet', f"\n'{name}(" + snippet_params + ")'", False)
                if is_event:
                    displayText_params = format_params(params, format_displayText_param)[0]
                else:
                    displayText_params = format_params(params, format_displayText_param, format_table_displayText_param, True)[0]
                add_output(output, indentplus, 'displayText', f'{name}(' + displayText_params + ')')
                add_output(output, indentplus, 'type', 'event' if is_event else 'function')
                add_output(output, indentplus, 'leftLabel', 'bool' if kind== 'void' else kind)
                add_output(output, indentplus, 'description', description)
                add_output(output, indentplus, 'descriptionMoreURL', get_url(url))
                end_section(output, indent)

        elif type(item) == tuple or type(item) == list:
            assert(len(item) == 4)
            name, kind, description, url = item
            start_section(output, indent)
            add_output(output, indentplus, 'snippet', f'{name}()')
            add_output(output, indentplus, 'displayText', f'{name}()')
            add_output(output, indentplus, 'type', 'event' if is_event else 'function')
            add_output(output, indentplus, 'leftLabel', 'bool' if kind== 'void' else kind)
            add_output(output, indentplus, 'description', description)
            add_output(output, indentplus, 'descriptionMoreURL', get_url(url))
            end_section(output, indent)
        else:
            print(type(item))
            assert(False)


indents = {}
for line in open('provider.template.coffee'):
    stripped = line.strip()
    if stripped.startswith('#insert'):
        class_name = stripped.split(' ')[-1]
        assert(class_name not in indents)
        indents[class_name] = line.find('#') // 2

version = None
for class_name in api:
    if class_name == 'version':
        version = api[class_name]
        continue
    snippets = coffee[class_name] = []
    for section_name in api[class_name]:
        if section_name == 'constants':
            add_property(snippets, api[class_name][section_name], 'constant')
        elif section_name == 'properties':
            add_property(snippets, api[class_name][section_name], 'property')
        elif section_name == 'functions':
            add_function(indents[class_name], snippets, api[class_name][section_name], False)
        elif section_name == 'events':
            add_function(indents[class_name], snippets, api[class_name][section_name], True)
        else:
            print(section_name)
            assert(False)

assert(version is not None)
found_class_names = set()

with open('provider.coffee', 'w') as f:
    f.write('# API Version: ')
    f.write(version)
    f.write('\n\n# This file is generated by `make_provider_coffee.py`')
    f.write('\n#   from `provider.template.coffee` and `api.yaml`')
    f.write('\n\n# DO NOT HAND EDIT THIS FILE!\n\n')
    for line in open('provider.template.coffee'):
        stripped = line.strip()
        if stripped.startswith('#insert'):
            class_name = stripped.split(' ')[-1]
            found_class_names.add(class_name)
            for snippet in coffee[class_name]:
                assert(type(snippet) == str)
                f.write(snippet)
                f.write('\n')
        else:
            f.write(line)

errors = 0
for class_name in coffee:
    if class_name not in found_class_names:
        errors += 1
        print(f"api.yaml contains definitions for `{class_name}`, but it is has no #insert in provider.template.coffee")

if errors == 0:
    print("Done!")
