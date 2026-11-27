local EXEC_TIMEOUT = 20
local REPOS_PRUNED = { "node_modules", "worktrees", ".*" }
local REPOS_MAX_DEPTH = 3
local NAME_ADJECTIVES = {
  "able", "agile", "amber", "ashen", "azure", "bold", "brave", "breezy", "bright", "brisk",
  "calm", "clean", "clever", "coral", "cozy", "crisp", "dapper", "deft", "dusky", "eager",
  "fair", "fleet", "frosty", "gentle", "gilded", "glad", "golden", "grand", "hazy", "humble",
  "ideal", "ivory", "jolly", "keen", "kind", "lively", "lucky", "lunar", "mellow", "misty",
  "mossy", "nimble", "noble", "ochre", "opal", "optic", "plucky", "proud", "quiet", "rapid",
  "rosy", "rustic", "silky", "smart", "snowy", "solar", "sturdy", "sunny", "swift", "teal",
  "tidy", "vivid", "warm", "wild", "wise", "witty", "zesty",
}
local NAME_NOUNS = {
  "acorn", "alder", "arbor", "aspen", "badger", "bay", "birch", "bison", "brook", "canyon",
  "cedar", "cliff", "comet", "cove", "crane", "creek", "delta", "drum", "dune", "falcon",
  "fern", "finch", "fjord", "fox", "glade", "grove", "harbor", "hawk", "heron", "hill",
  "iris", "lake", "larch", "lark", "lotus", "lynx", "maple", "marsh", "meadow", "mesa",
  "moss", "oak", "orchid", "oriole", "otter", "owl", "peak", "pebble", "pine", "plover",
  "pond", "quail", "raven", "reef", "ridge", "river", "robin", "sage", "sparrow", "spruce",
  "summit", "sycamore", "thistle", "tulip", "valley", "violet", "willow", "wren", "yarrow", "zephyr",
}

local repos_root = os.getenv("HOME") .. "/Developer"
local login_shell_path = assert(rex.exec({ "/bin/zsh", "-lc", 'printf %s "$PATH"' })).stdout
local actions = {}

local function action(opts)
  table.insert(actions, opts)
  rex.action(opts)
end

local function exec(argv, opts)
  opts = opts or {}

  local r, err = rex.exec(argv, {
    cwd = opts.cwd,
    timeout = EXEC_TIMEOUT,
    env = { PATH = login_shell_path }
  })

  if r == nil then
    error(err, 0)
  end

  if not r.ok then
    error(r.timed_out and argv[1] .. " timed out" or r.stderr ~= "" and r.stderr or r.stdout, 0)
  end

  return (r.stdout:gsub("\n+$", ""))
end


local function exec_in_new_window(argv, opts)
  opts = opts or {}

  local w, err = rex.session.new_window {
    window_label = opts.label,
    focus = false,
    layout = rex.layout.block {
      flavor = "com.superlogical.terminal.shell",
      options = {
        cwd = opts.cwd,
        command = argv,
        exit = opts.keep_open and { on_completion = false } or nil,
      },
    },
  }

  if w == nil then
    error(err, 0)
  end

  return w
end

local function process_foreground_cwd(ctx)
  local p, err = rex.block.call("com.superlogical.terminal", "process", {
    block_id = ctx.block_id,
  })

  if p == nil then
    error(err, 0)
  end

  local cwd = p.foreground and p.foreground.cwd

  if cwd == nil then
    error("can't tell the focused pane's directory", 0)
  end

  return cwd
end

local function find_outermost_repos()
  local argv = {
    "find",
    repos_root,
    "-maxdepth",
    tostring(REPOS_MAX_DEPTH + 1),
    "(",
    "-name",
    ".git",
    "-print",
  }

  for _, name in ipairs(REPOS_PRUNED) do
    table.insert(argv, "-o")
    table.insert(argv, "-name")
    table.insert(argv, name)
  end

  table.insert(argv, ")")
  table.insert(argv, "-prune")

  local is_repo = {}

  for git in exec(argv):gmatch("[^\n]+") do
    is_repo[git:sub(1, -6)] = true
  end

  local outermost = {}

  for repo in pairs(is_repo) do
    local ancestor = repo:match("^(.+)/[^/]+$")

    while ancestor and not is_repo[ancestor] do
      ancestor = ancestor:match("^(.+)/[^/]+$")
    end

    if ancestor == nil then
      table.insert(outermost, repo)
    end
  end

  table.sort(outermost, function(a, b) return a:lower() < b:lower() end)

  return outermost
end

local function checkout_label(path)
  local repo, name = path:match("/worktrees/([^/]+)/([^/]+)/[^/]+$")

  return repo and repo .. "-" .. name or path:match("[^/]+$")
end

local function worktree_items(repo)
  local items = {}
  local worktrees = exec({ "git", "worktree", "list", "--porcelain" }, { cwd = repo })

  for line in worktrees:gmatch("[^\n]+") do
    local path = line:match("^worktree (.+)")

    if path then
      table.insert(items,
        {
          id = path,
          title = checkout_label(path),
          subtitle = path,
          detail = "detached",
          icon = "branch"
        }
      )
    elseif line:match("^branch ") then
      items[#items].detail = line:match("^branch refs/heads/(.+)")
    elseif line:match("^prunable") then
      table.remove(items)
    end
  end

  return items
end

local function free_worktree_name(worktrees)
  local taken = {}

  for _, item in ipairs(worktrees) do
    taken[item.title] = true
  end

  local prefix = checkout_label(worktrees[1].id) .. "-"
  local base = NAME_ADJECTIVES[math.random(#NAME_ADJECTIVES)] .. "-" .. NAME_NOUNS[math.random(#NAME_NOUNS)]
  local name, n = base, 1

  while taken[prefix .. name] do
    n = n + 1
    name = base .. "-" .. n
  end

  return name
end

local function session_find(label)
  local list, err = rex.call("session.list", {})

  if list == nil then
    error(err, 0)
  end

  for _, s in ipairs(list.sessions or {}) do
    if s.label == label then
      return s
    end
  end
end

local function session_create(label, cwd, initial_input)
  local session, err = session_find(label)

  if session == nil then
    session, err = rex.call("session.create", {
      label = label,
      initial_windows = {
        {
          layout = rex.layout.block {
            flavor = "com.superlogical.terminal.shell",
            options = { cwd = cwd, initial_input = initial_input },
          }
        },
      },
    })

    if session == nil then
      error(err, 0)
    end
  end

  rex.client.queue("session.select", { session_id = session.session_id })
end

local function worktree_create(worktrees)
  local repo = worktrees[1].id
  local name = free_worktree_name(worktrees)

  session_create(checkout_label(repo) .. "-" .. name, repo, 'cd "$(git worktree-create ' .. name .. ')" && claude\n')
end

local function checkout_open(repo, checkout)
  local is_worktree = checkout ~= repo

  session_create(checkout_label(checkout), checkout, is_worktree and "claude --continue\n" or "claude\n")
end

local function worktree_open(worktrees)
  local repo = worktrees[1].id

  table.insert(worktrees, { id = ":new", title = "Create Worktree…", icon = "plus" })

  local checkout = rex.ui.pick {
    title = checkout_label(repo),
    placeholder = "Filter worktrees",
    items = worktrees,
  }

  if checkout == nil then
    return
  end

  if checkout == ":new" then
    table.remove(worktrees)

    return worktree_create(worktrees)
  end

  checkout_open(repo, checkout)
end

rex.action {
  name  = "actions",
  title = "Actions…",
  run   = function(ctx)
    local items, action_by_name = {}, {}

    for _, a in ipairs(actions) do
      table.insert(items, { id = a.name, title = a.title })
      action_by_name[a.name] = a
    end

    local name = rex.ui.pick {
      title = "Actions",
      placeholder = "Filter actions",
      items = items,
    }

    if name then
      return action_by_name[name].run(ctx, {})
    end
  end,
}

action {
  name  = "zed_open",
  title = "Open in Zed",
  run   = function(ctx)
    local cwd = process_foreground_cwd(ctx)
    local ok, root = pcall(exec, { "git", "rev-parse", "--show-toplevel" }, {
      cwd = cwd,
    })

    exec({ "zed", ok and root or cwd })
  end,
}

action {
  name  = "smerge_open",
  title = "Open in Sublime Merge",
  run   = function(ctx)
    local cwd = process_foreground_cwd(ctx)

    exec({ "smerge", cwd })
  end,
}

action {
  name  = "browser_open",
  title = "Open Browser",
  run   = function(ctx)
    local ok, err = rex.call("session.new_split", {
      session_id = ctx.session_id,
      anchor_id = ctx.block_id,
      direction = "horizontal",
      side = "after",
      focus = true,
      layout = rex.layout.block {
        flavor = "com.superlogical.terminal.shell",
        options = { command = { "terminal-browser", "open", "about:blank" } },
      },
    })

    if ok == nil then
      error(err, 0)
    end
  end,
}

action {
  name  = "claude_open",
  title = "Open Claude",
  run   = function(ctx)
    local cwd = process_foreground_cwd(ctx)
    local w, err = rex.session.new_window {
      window_label = "Claude",
      layout = rex.layout.block {
        flavor = "com.superlogical.terminal.shell",
        options = { cwd = cwd, initial_input = "claude\n" },
      },
    }

    if w == nil then
      error(err, 0)
    end
  end,
}

action {
  name  = "repo_open",
  title = "Open Repository…",
  run   = function()
    local items = {}

    for _, repo in ipairs(find_outermost_repos()) do
      table.insert(items, { id = repo, title = repo:sub(#repos_root + 2), icon = "folder" })
    end

    local repo = rex.ui.pick {
      title = "Open repository",
      placeholder = "Filter repositories",
      items = items,
    }

    if repo == nil then
      return
    end

    local worktrees = worktree_items(repo)

    if #worktrees > 1 then
      return worktree_open(worktrees)
    end

    checkout_open(repo, repo)
  end,
}

action {
  name  = "worktree_create",
  title = "Create Worktree…",
  run   = function(ctx)
    local cwd = process_foreground_cwd(ctx)
    local worktrees = worktree_items(cwd)

    worktree_create(worktrees)
  end,
}

action {
  name  = "worktree_open",
  title = "Open Worktree…",
  run   = function(ctx)
    local cwd = process_foreground_cwd(ctx)
    local worktrees = worktree_items(cwd)

    worktree_open(worktrees)
  end,
}

action {
  name  = "worktree_remove",
  title = "Remove Worktree…",
  run   = function(ctx)
    local cwd = process_foreground_cwd(ctx)
    local worktrees = worktree_items(cwd)
    local repo = table.remove(worktrees, 1).id

    if #worktrees == 0 then
      error("no worktrees besides the main checkout", 0)
    end

    local path = rex.ui.pick {
      title = "Remove worktree",
      placeholder = "Filter worktrees",
      items = worktrees,
    }

    if path == nil then
      return
    end

    local argv = { "git", "worktree-remove", path }
    local branch = exec({ "git", "branch", "--show-current" }, { cwd = path })
    local losses = {}

    if branch ~= "" then
      local unpushed = tonumber(exec({ "git", "rev-list", "--count", branch, "--not", "--remotes" }, { cwd = path }))

      if unpushed > 0 then
        table.insert(losses, unpushed .. " commit(s) not on any remote")
      end
    end

    if exec({ "git", "status", "--porcelain" }, { cwd = path }) ~= "" then
      table.insert(losses, "uncommitted changes")
    end

    if #losses > 0 then
      local answer = rex.ui.pick {
        title = checkout_label(path) .. " has " .. table.concat(losses, " and "),
        items = {
          { id = "delete", title = "Delete anyway" },
          { id = "cancel", title = "Cancel" },
        },
      }

      if answer ~= "delete" then
        return
      end

      argv = { "git", "worktree-remove", "--force", path }
    end

    local windows_to_close = {}
    local worktree_session = session_find(checkout_label(path))
    local in_worktree_session = worktree_session ~= nil and worktree_session.session_id == ctx.session_id

    if in_worktree_session then
      local view, err = rex.call("session.view", { session_id = ctx.session_id })

      if view == nil then
        error(err, 0)
      end

      windows_to_close = view.windows
    elseif worktree_session then
      local ok, err = rex.call("session.destroy", { session_id = worktree_session.session_id })

      if ok == nil then
        error(err, 0)
      end
    end

    local cleanup = in_worktree_session and 'rex kill "' .. ctx.session_id .. '"' or 'rex block close "$REX_BLOCK"'

    exec_in_new_window({ "sh", "-c", '"$@" && ' .. cleanup, "sh", unpack(argv) }, {
      cwd = repo,
      label = "Remove " .. checkout_label(path),
      keep_open = true,
    })

    for _, window in ipairs(windows_to_close) do
      rex.call("session.close_window", { session_id = ctx.session_id, window_id = window.window_id })
    end
  end,
}

rex.exec({ "sh", "-c", 'pkill -f "^caffeinate -di -w $PPID$"; caffeinate -di -w "$PPID" >/dev/null 2>&1 &' })

rex.bind("shift+cmd+r", "actions")
