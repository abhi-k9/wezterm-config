"""Configuration behavior checks using WezTerm's real Lua and schema APIs."""
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
  local status
  local palette = { tab_bar = { active_tab = {
    fg_color = '#181926', bg_color = '#c6a0f6',
  } } }
  local window = {
    leader_is_active = function() return true end,
    effective_config = function()
      return { resolved_palette = palette }
    end,
    set_left_status = function(_, value) status = value end,
  }
  callback(window)
  assert(status and status:find('LEADER'), 'leader badge missing')
  assert(status:find('198:160:246', 1, true), 'effective palette not used')
  palette = { foreground = '#f5a97f', background = '#24273a' }
  callback(window)
  assert(status:find('245:169:127', 1, true), 'theme without tab colors must use terminal palette')
  window.leader_is_active = function() return false end
  callback(window)
  assert(status == '', 'inactive leader status must clear')
  result = {
    font_size = config.font_size,
    default_prog = config.default_prog or false,
    launch_menu = config.launch_menu,
    mac_blur = config.macos_window_background_blur or false,
    watched = watched,
    leader = config.leader,
    keys = config.keys,
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

    def test_modifier_leader_example_updates_forwarding_binding(self):
        result = self.probe(local='''return function(config, wezterm)
          config.leader = {key='a', mods='CTRL', timeout_milliseconds=1000}
          config.keys[1] = {
            key='a', mods='LEADER|CTRL',
            action=wezterm.action.SendKey {key='a', mods='CTRL'},
          }
        end''')
        self.assertEqual(result['leader']['key'], 'a')
        first = result['keys'][0]
        self.assertEqual(first['key'], 'a')
        self.assertIn('CTRL', first['mods'])
        self.assertEqual(first['action']['SendKey']['mods'], 'CTRL')

    def test_local_errors_are_visible(self):
        for local, expected in [
            ('return {}', 'must return function'),
            ('return function(', 'wezterm.local.lua'),
            ('return function() error("example failure") end', 'example failure'),
        ]:
            with self.subTest(expected=expected):
                self.probe(local=local, expected_error=expected)
        self.probe(read_failure=True, expected_error='permission denied')

    def test_key_workflows(self):
        result = self.probe()
        keys = {entry['key']: entry for entry in result['keys'] if 'LEADER' in entry['mods']}
        self.assertEqual(result['leader']['key'], 'Escape')
        self.assertEqual(keys['Escape']['action']['SendKey']['key'], 'Escape')
        self.assertTrue(keys['x']['action']['CloseCurrentPane']['confirm'])
        for direction in ['Left', 'Right', 'Up', 'Down']:
            self.assertEqual(keys[direction + 'Arrow']['action']['AdjustPaneSize'], [direction, 5])
        for index in range(10):
            self.assertEqual(keys[str(index)]['action']['ActivateTab'], index)
        self.assertEqual(keys['c']['action']['SpawnTab'], 'CurrentPaneDomain')
        self.assertIn('WORKSPACES', keys['w']['action']['ShowLauncherArgs']['flags'])
        self.assertEqual(keys['[']['action'], 'ActivateCopyMode')


if __name__ == '__main__':
    unittest.main()
