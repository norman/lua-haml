local lfs       = require 'lfs'
local path      = require 'pl.path'
local dir       = require 'pl.dir'
local telescope = require 'telescope'
local socket    = require 'socket'

local function sleep(n)
  socket.select(nil, nil, n)
end

local function glob(pattern)
  local files = {}
  local my_dir = path.abspath(".")
  for root, _, entries in dir.walk(my_dir) do
    for _, entry in ipairs(dir.filter(entries, pattern)) do
      files[path.abspath(path.join(root, entry))] = 0
    end
  end
  return files
end

local function check_modified(files)
  local return_value = false
  for file, timestamp in pairs(files) do
    local attr = lfs.attributes(file)
    if attr.modification > timestamp then
      files[file] = attr.modification
      return_value = true
    end
  end
  return return_value
end

local function run_tests(files, full_report)
  local contexts = {}
  for file, _ in pairs(files) do
    telescope.load_contexts(file, contexts)
  end
  report_func         = full_report and telescope.test_report or telescope.summary_report
  local results       = telescope.run(contexts)
  local summary, data = report_func(contexts, results)
  local errors        = telescope.error_report(contexts, results)
  return data, summary, errors
end

local function spec()
  local params = tlua.get_params()
  local data, summary, errors = run_tests(glob("*_spec.lua"), params[1] == "-f")
  print(summary)
  if errors then print(errors) end
end

local function test_and_notify(files, test_files)
  if check_modified(files) then
    local data, summary, errors = run_tests(test_files)
    local image = data.errors + data.failed == 0 and "pass" or "fail"
    os.execute(string.format("echo '%s' | growlnotify --name Telescope --image ~/.autotest_images/%s.png", summary, image))
    print(summary)
    if errors then print(errors) end
  end
end

local function autospec()
  local files      = glob("*.lua")
  local test_files = glob("*_spec.lua")
  while(true) do
    pcall(test_and_notify, files, test_files)
    sleep(1)
  end
end

tlua.task("spec", "Run specs", spec)
tlua.task("autospec", "Run specs automatically as files are changed", autospec)
tlua.default_task = "spec"