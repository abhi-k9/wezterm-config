"""Configuration behavior checks using WezTerm's real Lua and schema APIs."""
import itertools
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
WEZTERM = os.environ.get('WEZTERM_BIN') or shutil.which('wezterm')


@unittest.skipUnless(WEZTERM, 'Install WezTerm or set WEZTERM_BIN to its executable')
class ConfigTests(unittest.TestCase):
    def probe(self, *, triple='x86_64-unknown-linux-gnu', local=None,
              expected_error=None, read_failure=False):
        with tempfile.TemporaryDirectory(prefix='wezterm-config-test-') as directory:
            path = Path(directory)
            if local is not None:
                (path / 'wezterm.local.lua').write_text(local, encoding='utf-8')
            quote = lambda value: json.dumps(str(value), ensure_ascii=False)
            script = '''
local w = require 'wezterm'
w.target_triple = TRIPLE
w.config_dir = DIRECTORY
local callbacks, watched = {}, {}
w.on = function(name, callback) callbacks[name] = callback end
w.add_to_config_reload_watch_list = function(value) watched[#watched + 1] = value end
local original_open = io.open
if READ_FAILURE then
  io.open = function(name, mode)
    if name == DIRECTORY .. '/wezterm.local.lua' then
      return nil, 'permission denied', 13
    end
    return original_open(name, mode)
  end
end
local ok, config = pcall(dofile, SOURCE)
io.open = original_open
local result
if not ok then
  result = { error = tostring(config) }
else
  local callback = assert(callbacks['update-status'], 'missing status callback')
  local status, active_table
  local palette = { tab_bar = { active_tab = {
    fg_color = '#181926', bg_color = '#c6a0f6',
  } } }
  local window = {
    active_key_table = function() return active_table end,
    effective_config = function()
      return { resolved_palette = palette }
    end,
    set_left_status = function(_, value) status = value end,
  }
  callback(window)
  assert(status and status:find('APP'), 'APP badge missing on a fresh window')
  active_table = 'wezterm'
  callback(window)
  assert(status:find('WEZ'), 'WEZ badge missing')
  assert(status:find('198:160:246', 1, true), 'effective palette not used')
  active_table = 'wezterm_commands'
  callback(window)
  assert(status:find('CMD'), 'pending command badge missing')
  for _, name in ipairs { 'copy_mode', 'search_mode' } do
    active_table = name
    callback(window)
    assert(status:find('WEZ') and not status:find('APP'), 'WezTerm UI must not show APP')
  end
  palette = { foreground = '#f5a97f', background = '#24273a' }
  callback(window)
  assert(status:find('245:169:127', 1, true), 'theme without tab colors must use terminal palette')
  active_table = nil
  callback(window)
  assert(status:find('APP') and not status:find('WEZ'), 'APP badge must replace WEZ')
  local actions = {}
  window.perform_action = function(_, action) actions[#actions + 1] = action end
  local toggle = assert(callbacks['toggle-input-mode'])
  toggle(window, {})
  active_table = 'wezterm'
  toggle(window, {})
  active_table = 'wezterm_commands'
  toggle(window, {})
  -- A second window has independent table state and enters WEZ, rather than
  -- inheriting the first window's input mode through a global flag.
  toggle({active_key_table=function() return nil end,
          perform_action=window.perform_action}, {})
  result = {
    font_size = config.font_size,
    default_prog = config.default_prog or false,
    launch_menu = config.launch_menu,
    mac_blur = config.macos_window_background_blur or false,
    watched = watched,
    leader = config.leader or false,
    defaults_disabled = config.disable_default_key_bindings,
    keys = config.keys,
    key_tables = config.key_tables,
    toggle_actions = actions,
  }
end
local output = assert(io.open(RESULT, 'w'))
output:write(w.json_encode(result))
output:close()
return ok and config or w.config_builder()
'''
            substitutions = {
                'TRIPLE': quote(triple), 'DIRECTORY': quote(path),
                'READ_FAILURE': 'true' if read_failure else 'false',
                'SOURCE': quote(ROOT / '.wezterm.lua'), 'RESULT': quote(path / 'result.json'),
            }
            # Replace complete tokens in one pass: substituted paths are data,
            # never reinterpreted as template tokens or shell commands.
            import re
            script = re.sub(r'\b(' + '|'.join(substitutions) + r')\b',
                            lambda match: substitutions[match.group()], script)
            wrapper = path / 'probe.lua'
            wrapper.write_text(script, encoding='utf-8')
            completed = subprocess.run(
                [WEZTERM, '--config-file', str(wrapper), 'show-keys', '--lua'],
                text=True, capture_output=True, timeout=20,
            )
            self.assertEqual(completed.returncode, 0, completed.stderr)
            result_path = path / 'result.json'
            # WezTerm can fall back to defaults after a config error and still
            # exit zero. Require this run's assertions and result to complete.
            self.assertTrue(result_path.is_file(), completed.stderr)
            contents = result_path.read_text(encoding='utf-8')
            self.assertTrue(contents, completed.stderr)
            result = json.loads(contents)
            if expected_error:
                self.assertIn(expected_error, result.get('error', ''))
            else:
                self.assertNotIn('error', result, result.get('error'))
            return result

    def test_platform_branches_keep_native_default_shell(self):
        for triple in ['x86_64-unknown-linux-gnu', 'aarch64-apple-darwin',
                       'x86_64-pc-windows-msvc']:
            with self.subTest(triple=triple):
                result = self.probe(triple=triple)
                self.assertIs(result['default_prog'], False)
                menu = result['launch_menu']
                if 'windows' in triple:
                    self.assertEqual([entry['args'][0] for entry in menu],
                                     ['cmd.exe', 'powershell.exe'])
                else:
                    self.assertFalse(menu)
                if 'apple' in triple:
                    self.assertEqual(result['mac_blur'], 0)
                else:
                    self.assertIs(result['mac_blur'], False)
                self.assertTrue(result['watched'][0].endswith('/wezterm.local.lua'))

    def test_local_override_runs_last_and_appends_profile(self):
        result = self.probe(local='''return function(config)
          config.font_size = 19
          table.insert(config.launch_menu, {label='Example', args={'example-command'}})
        end''')
        self.assertEqual(result['font_size'], 19)
        self.assertEqual(result['launch_menu'][0]['label'], 'Example')

    def test_versioned_local_example_is_safe_on_every_platform(self):
        example = (ROOT / 'wezterm.local.lua').read_text(encoding='utf-8')
        for triple in ['x86_64-unknown-linux-gnu', 'aarch64-apple-darwin',
                       'x86_64-pc-windows-msvc']:
            with self.subTest(triple=triple):
                result = self.probe(triple=triple, local=example)
                self.assertEqual(result['font_size'], 14)
                self.assertIs(result['default_prog'], False)
                self.assertEqual(len(result['launch_menu']), 2 if 'windows' in triple else 0)

    def test_local_toggle_customization_keeps_one_global_event(self):
        result = self.probe(local='''return function(config, wezterm)
          config.keys[2].key = 'F11'
          config.keys[2].mods = 'CTRL|ALT'
        end''')
        toggle = result['keys'][1]
        self.assertEqual(toggle['key'], 'F11')
        self.assertEqual(toggle['action']['EmitEvent'], 'toggle-input-mode')
        self.assertEqual(len(result['keys']), 4)

    def test_legacy_overrides_cannot_silently_break_app_mode(self):
        self.probe(local='''return function(config)
          config.leader = {key='Escape', mods='NONE'}
        end''', expected_error='Remove config.leader')
        self.probe(local='''return function(config)
          config.disable_default_key_bindings = false
        end''', expected_error='APP routing requires')

    def test_local_errors_are_visible(self):
        for local, expected in [
            ('return {}', 'must return function'),
            ('return function(', 'wezterm.local.lua'),
            ('return function() error("example failure") end', 'example failure'),
        ]:
            with self.subTest(expected=expected):
                self.probe(local=local, expected_error=expected)
        self.probe(read_failure=True, expected_error='permission denied')

    def test_app_mode_defaults_reserve_only_toggle_fullscreen_and_clipboard(self):
        for triple in ['x86_64-unknown-linux-gnu', 'aarch64-apple-darwin',
                       'x86_64-pc-windows-msvc']:
            with self.subTest(triple=triple):
                result = self.probe(triple=triple)
                self.assertTrue(result['defaults_disabled'])
                self.assertIs(result['leader'], False)
                self.assertEqual(len(result['keys']), 6 if 'apple' in triple else 4)
                self.assertEqual(result['keys'][0], {
                    'key': 'Enter', 'mods': 'ALT', 'action': 'ToggleFullScreen'})
                self.assertEqual(result['keys'][1]['key'], 'F12')
                self.assertEqual(set(result['keys'][1]['mods'].split('|')), {'CTRL', 'SHIFT'})
                self.assertEqual(result['keys'][1]['action']['EmitEvent'], 'toggle-input-mode')
                self.assertEqual(result['keys'][2], {
                    'key': 'C', 'mods': 'CTRL|SHIFT', 'action': {'CopyTo': 'Clipboard'}})
                paste = next(entry for entry in result['keys'] if entry['key'] == 'V')
                self.assertEqual(paste, {
                    'key': 'V', 'mods': 'CTRL|SHIFT', 'action': {'PasteFrom': 'Clipboard'}})
                if 'apple' in triple:
                    self.assertEqual([entry for entry in result['keys'] if entry['mods'] == 'SUPER'], [
                        {'key': 'c', 'mods': 'SUPER', 'action': {'CopyTo': 'Clipboard'}},
                        {'key': 'v', 'mods': 'SUPER', 'action': {'PasteFrom': 'Clipboard'}}])

    def test_app_clipboard_switches_preserve_wez_controls_and_application_keys(self):
        for triple in ['x86_64-unknown-linux-gnu', 'aarch64-apple-darwin',
                       'x86_64-pc-windows-msvc']:
            for enabled, copy, paste in itertools.product([False, True], repeat=3):
                with self.subTest(triple=triple, enabled=enabled, copy=copy, paste=paste):
                    values = [str(value).lower() for value in (enabled, copy, paste)]
                    local = '''return function(config, wezterm, app_shortcuts)
                      app_shortcuts.enabled = %s
                      app_shortcuts.copy = %s
                      app_shortcuts.paste = %s
                    end''' % tuple(values)
                    result = self.probe(triple=triple, local=local)
                    global_keys = {(entry['key'], entry['mods']) for entry in result['keys']}
                    expected = {('Enter', 'ALT'), ('F12', 'CTRL|SHIFT')}
                    if enabled and copy:
                        expected.add(('C', 'CTRL|SHIFT'))
                        if 'apple' in triple:
                            expected.add(('c', 'SUPER'))
                    if enabled and paste:
                        expected.add(('V', 'CTRL|SHIFT'))
                        if 'apple' in triple:
                            expected.add(('v', 'SUPER'))
                    self.assertEqual(global_keys, expected)
                    wez = {(entry['key'], entry['mods']): entry['action']
                           for entry in result['key_tables']['wezterm']}
                    self.assertEqual(wez[('C', 'CTRL|SHIFT')], {'CopyTo': 'Clipboard'})
                    self.assertEqual(wez[('V', 'CTRL|SHIFT')], {'PasteFrom': 'Clipboard'})
                    if 'apple' in triple:
                        self.assertEqual(wez[('c', 'SUPER')], {'CopyTo': 'Clipboard'})
                        self.assertEqual(wez[('v', 'SUPER')], {'PasteFrom': 'Clipboard'})
                    # Ctrl+c remains interrupt; Ctrl+v retains editor/shell behavior.
                    for bindings in [result['keys'], *result['key_tables'].values()]:
                        self.assertFalse(any(entry['key'].lower() in ('c', 'v')
                                             and entry['mods'] == 'CTRL' for entry in bindings))

    def test_app_shortcut_options_require_booleans(self):
        self.probe(local='''return function(config, wezterm, app_shortcuts)
          app_shortcuts.enabled = 'false'
        end''', expected_error='app_shortcuts.enabled must be true or false')

    def test_toggle_is_persistent_and_exits_overlays_on_return(self):
        actions = self.probe()['toggle_actions']
        enter = actions[0]['ActivateKeyTable']
        self.assertEqual(enter['name'], 'wezterm')
        self.assertFalse(enter['one_shot'])
        self.assertFalse(enter['until_unknown'])
        self.assertFalse(enter['prevent_fallback'])
        self.assertEqual(actions[1]['Multiple'], [{'CopyMode': 'Close'}, 'ClearKeyTableStack'])
        self.assertEqual(actions[2], actions[1])
        self.assertEqual(actions[3], actions[0])

    def test_wez_command_workflows_preserve_application_escape_and_f12(self):
        result = self.probe()
        tables = result['key_tables']
        wez = {entry['key']: entry for entry in tables['wezterm']}
        self.assertNotIn('Escape', wez)
        self.assertNotIn('F12', wez)
        prefix = wez[' ']['action']['ActivateKeyTable']
        self.assertEqual(prefix['name'], 'wezterm_commands')
        self.assertTrue(prefix['one_shot'])
        # Modifier key transitions must not cancel shifted commands like |/?.
        self.assertFalse(prefix['until_unknown'])
        self.assertFalse(prefix['prevent_fallback'])
        self.assertEqual(prefix['timeout_milliseconds'], 2000)
        keys = {entry['key']: entry for entry in tables['wezterm_commands']}
        self.assertNotIn('F12', keys)
        self.assertEqual(keys['Escape']['action']['SendKey']['key'], 'Escape')
        self.assertTrue(keys['x']['action']['CloseCurrentPane']['confirm'])
        for direction in ['Left', 'Right', 'Up', 'Down']:
            self.assertEqual(keys[direction + 'Arrow']['action']['AdjustPaneSize'], [direction, 5])
        for index in range(10):
            self.assertEqual(keys[str(index)]['action']['ActivateTab'], index)
        self.assertEqual(keys['c']['action']['SpawnTab'], 'CurrentPaneDomain')
        self.assertIn('WORKSPACES', keys['w']['action']['ShowLauncherArgs']['flags'])
        self.assertEqual(keys['[']['action'], 'ActivateCopyMode')

    def test_mac_close_is_wez_only_and_clipboard_extensions_are_global(self):
        result = self.probe(triple='aarch64-apple-darwin')
        cmd = {entry['key']: entry for entry in result['key_tables']['wezterm']
               if entry['mods'] == 'SUPER'}
        self.assertTrue(cmd['w']['action']['CloseCurrentTab']['confirm'])
        self.assertEqual(cmd['c']['action']['CopyTo'], 'Clipboard')
        self.assertEqual([entry for entry in result['keys'] if entry['mods'] == 'SUPER'], [
            {'key': 'c', 'mods': 'SUPER', 'action': {'CopyTo': 'Clipboard'}},
            {'key': 'v', 'mods': 'SUPER', 'action': {'PasteFrom': 'Clipboard'}}])


if __name__ == '__main__':
    unittest.main()
