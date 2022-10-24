from ruamel.yaml import YAML
import json

with open('api.yaml') as f:
    yaml = YAML(typ='safe')
    api = yaml.load(f)

coffee = {}
json_structure = {}

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

def add_properties(output, items, label, json_output):
    for item in items:
        assert len(item) == 4
        name, _type, description, url = item
        start_section(output, 0)
        add_output(output, 1, 'snippet', name)
        add_output(output, 1, 'displayText', name)
        add_output(output, 1, 'type', label)
        add_output(output, 1, 'leftLabel', _type)
        add_output(output, 1, 'description', description)
        add_output(output, 1, 'descriptionMoreURL', get_url(url))
        end_section(output, 0)

        json_segment = json_member(name, label, _type, description, get_url(url))
        json_output.append(json_segment)


def format_snippet_param(param, i):
    assert len(param) == 2, f"Expected [name, type], but got: {param}"
    return f"${{{i+1}:{param[1]}|{param[0]}}}"

def format_displayText_param(param, i):
    assert len(param) == 2, f"Expected [name, type], but got: {param}"
    return f"{param[1]} {param[0]}"

def format_event_snippet_param(param, i):
    assert len(param) == 2, f"Expected [name, type], but got: {param}"
    return param[0]

def format_table_snippet_param(param, i):
    assert len(param) == 2 or len(param) == 3, f"Expected [name, type] or [name, type, note], but got: {param}"
    if len(param) == 2:
        return "\\n\\t' +\n'" + f"{param[0].ljust(25)} = ${{{i+1}:-- {param[1]}}}"
    else:
        return "\\n\\t' +\n'" + f"{param[0].ljust(25)} = ${{{i+1}:-- {param[1].ljust(8)} {param[2]}}}"

def format_event_table_snippet_param(param, i):
    assert len(param) == 2 or len(param) == 3, f"Expected [name, type] or [name, type, note], but got: {param}"
    if len(param) == 2:
        return "\\n\\t' +\n'" + f"--    {param[0].ljust(25)} {param[1]}"
    else:
        comment = param[2].replace("'", "\\'")
        return "\\n\\t' +\n'" + f"--    {param[0].ljust(25)} {param[1].ljust(8)} {comment}}}"

def format_function_table_snippet_param(param, i):
    return param[0]

def format_table_displayText_param(param, i):
    assert len(param) == 2 or len(param) == 3, f"Expected [name, type] or [name, type, note], but got: {param}"
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
                assert param == 'return'
                table_name = 'return'
                if not table_formatter:
                    continue
                else:
                    assert len(table_params) > 0
                    assert type(table_params == list)
                    header = "{"
                    if single_line:
                        footer = "}"
                    else:
                        footer = "\\n' +\n'}"
                    if type(table_params[0]) == dict:
                        assert len(table_params) == 1
                        table_params = table_params[0]
                        assert len(table_params) > 0
                        assert list(table_params.keys())[0] == 'items'
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
                    assert len(table_params) > 0
                    assert type(table_params == list)
                    header = "{"
                    if single_line:
                        footer = "}"
                    else:
                        footer = "\\n' +\n'}"
                    if type(table_params[0]) == dict:
                        assert len(table_params) == 1
                        table_params = table_params[0]
                        assert len(table_params) > 0
                        assert list(table_params.keys())[0] == 'items'
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


def json_member(name, kind, property_type, description, url):
    return {'name': name, 'kind': kind, 'type': property_type, 'description': description, 'url': url}


def json_add_params(segment, params):
    segment_parameters = []

    def json_add_param(parameter_list, param):
        assert len(param) == 2 or len(param) == 3, f'Expected [name, type] or [name, type, description]: {param}'
        if len(param) == 2:
            param_name, param_type = param
            parameter_list.append({'name': param_name, 'type': param_type})
        elif len(param) == 3:
            param_name, param_type, param_note = param
            parameter_list.append({'name': param_name, 'type': param_type, 'description': param_note})
        else:
            assert False

    for param in params:
        if type(param) == dict:
            assert len(param) == 1
            key = list(param.keys())[0]
            items = list(param.values())[0]
            if type(key) == str:
                assert key == 'return'
                if len(items) == 1 and type(items[0]) == dict:
                    subkey = list(items[0].keys())[0]
                    assert subkey == 'items'
                    subitems = list(items[0].values())[0]
                    segment['return_table_items'] = []
                    for subitem in subitems:
                        json_add_param(segment['return_table_items'], subitem)
                else:
                    segment['return_table'] = []
                    for item in items:
                        json_add_param(segment['return_table'], item)
            else:
                assert len(key) == 2
                json_add_param(segment_parameters, key)
                name, kind = key
                if name == 'callback_function' and kind == 'function':
                    callback_parameters = segment_parameters[-1]['parameters'] = []
                    for item in items:
                        json_add_param(callback_parameters, item)
                else:
                    assert kind == 'table'
                    if len(items) == 1 and type(items[0]) == dict:
                        subkey = list(items[0].keys())[0]
                        assert subkey == 'items'
                        subitems = list(items[0].values())[0]
                        table_parameters = segment_parameters[-1]['table_items'] = []
                        for subitem in subitems:
                            json_add_param(table_parameters, subitem)
                    else:
                        table_parameters = segment_parameters[-1]['parameters'] = []
                        for item in items:
                            json_add_param(table_parameters, item)
        else:
            json_add_param(segment_parameters, param)

    if segment_parameters:
        segment['parameters'] = segment_parameters


def add_functions(indent, output, items, is_event, json_output):
    indentplus = indent + 1
    for item in items:
        if type(item) == dict:
            assert len(item) == 1
            params = list(item.values())[0]
            signature = list(item.keys())[0]
            assert len(signature) == 4, f"Expected [name, type, note, url], but got: {signature}"
            assert params is not None, f'function signature has no children: {signature[0]}. (is there an extraneous `:` at the end of the line?)'
            name, _type, description, url = signature

            json_segment = json_member(name, 'event' if is_event else 'function', _type, description, get_url(url))
            json_add_params(json_segment, params)

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
                add_output(output, indentplus, 'leftLabel', 'bool' if _type== 'void' else _type)
                add_output(output, indentplus, 'description', description)
                add_output(output, indentplus, 'descriptionMoreURL', get_url(url))
                end_section(output, indent)

            if is_table:
                start_section(output, indent)
                if is_event or is_table == 'return':
                    snippet_params, _ = format_params(params, format_event_snippet_param, format_event_table_snippet_param)
                    if is_table == 'return':
                        i = snippet_params.find('{')
                        assert i >= 0
                        snippet_params = snippet_params[i:]
                        snippet_joined = f"'{name}({snippet_text})" + "\\n\\t' +\n'-- returns " + snippet_params
                    else:
                        snippet_joined = f"'{name}({snippet_text})" + "\\n\\t' +\n'-- " + is_table + " is " + snippet_params
                    if snippet_joined.endswith('}}'):
                        snippet_joined = snippet_joined[:-2] + "\\t-- }}"
                    else:
                        assert snippet_joined.endswith('}')
                        snippet_joined = snippet_joined[:-1] + "\\t-- }"
                    if is_event:
                        snippet_joined += "\\n\\t$1\\nend'"
                    else:
                        snippet_joined += "'"
                    add_output(output, indentplus, 'snippet', snippet_joined, False)
                elif is_table == 'callback_function':
                    snippet_params, _ = format_params(params, format_snippet_param, format_function_table_snippet_param)
                    stub = "\\n' +\n'}"
                    assert snippet_params.endswith(stub)
                    i = snippet_params.rfind('{')
                    snippet_params = snippet_params[i+1:-len(stub)].split(',')
                    j = snippet_text.find('function|callback_function')
                    assert j >= 0
                    while snippet_text[j] != ' ': j -= 1
                    snippet_joined = f"'{name}({snippet_text[:j]}" + "\\n\\t' +\n'function (" + ', '.join(snippet_params) + ")\\n\\t\\t\\n\\tend\\n)'"
                    add_output(output, indentplus, 'snippet', snippet_joined, False)
                else:
                    snippet_params, _ = format_params(params, format_snippet_param, format_table_snippet_param)
                    add_output(output, indentplus, 'snippet', f"\n'{name}(" + snippet_params + ")'", False)

                if is_event:
                    displayText_params = format_params(params, format_displayText_param)[0]
                elif is_table == 'callback_function':
                    displayText_params = format_params(params, format_displayText_param, format_table_displayText_param, True)[0]
                    i = displayText_params.find("{")
                    assert i >= 0
                    displayText_params = displayText_params[:i] + ' function (...)'
                else:
                    displayText_params = format_params(params, format_displayText_param, format_table_displayText_param, True)[0]

                add_output(output, indentplus, 'displayText', f'{name}(' + displayText_params + ')')
                add_output(output, indentplus, 'type', 'event' if is_event else 'function')
                add_output(output, indentplus, 'leftLabel', 'bool' if _type== 'void' else _type)
                add_output(output, indentplus, 'description', description)
                add_output(output, indentplus, 'descriptionMoreURL', get_url(url))
                end_section(output, indent)

        elif type(item) == tuple or type(item) == list:
            assert len(item) == 4, f"Expected [name, type, note, url], but got: {item}"
            name, _type, description, url = item
            start_section(output, indent)
            add_output(output, indentplus, 'snippet', f'{name}()')
            add_output(output, indentplus, 'displayText', f'{name}()')
            add_output(output, indentplus, 'type', 'event' if is_event else 'function')
            add_output(output, indentplus, 'leftLabel', 'bool' if _type == 'void' else _type)
            add_output(output, indentplus, 'description', description)
            add_output(output, indentplus, 'descriptionMoreURL', get_url(url))
            end_section(output, indent)

            json_segment = json_member(name, 'event' if is_event else 'function', _type, description, get_url(url))

        else:
            assert False, f'Unexpected item type; {type(item)}'

        json_output.append(json_segment)


version = behaviors = None
json_sections = json_structure['sections'] = {}
for class_name in api:
    if class_name == 'header':
        assert 'version' in api[class_name]
        assert 'behaviors' in api[class_name]
        version = api[class_name]['version']
        behaviors = api[class_name]['behaviors']
        json_structure['version'] = version
        json_structure['behaviors'] = behaviors
        continue
    #if class_name not in indents:
    #    print("Warning: class in YAML not present in template:", class_name)
    #    continue
    snippets = coffee[class_name] = []
    json_sections[class_name] = []
    for section_name in api[class_name]:
        if section_name == 'constants':
            add_properties(snippets, api[class_name][section_name], 'constant', json_sections[class_name])
        elif section_name == 'properties':
            add_properties(snippets, api[class_name][section_name], 'property', json_sections[class_name])
        elif section_name == 'functions':
            add_functions(0, snippets, api[class_name][section_name], False, json_sections[class_name])
        elif section_name == 'events':
            add_functions(0, snippets, api[class_name][section_name], True, json_sections[class_name])
        else:
            assert False, f'Unrecognized section name: {section_name}'

assert version is not None
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
            assert class_name in coffee, f"Class referenced in template not found in YAML: {class_name}"
            found_class_names.add(class_name)
            indent_space_count = line.find('#')
            for snippet in coffee[class_name]:
                assert type(snippet) == str
                for line in snippet.split('\n'):
                    f.write(indent_spaces[:indent_space_count])
                    f.write(line)
                    f.write('\n')
        else:
            f.write(line)

with open('api.json', 'w') as f:
    f.write(json.dumps(json_structure))

errors = 0
for class_name in coffee:
    if class_name not in found_class_names:
        errors += 1
        print(f"api.yaml contains definitions for `{class_name}`, but it is has no #insert in provider.template.coffee")

if errors == 0:
    print("Done!")
