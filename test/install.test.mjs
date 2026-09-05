// No live vaults or credentials. Installers run only in disposable synthetic trees.
import { test } from "node:test";
import assert from "node:assert/strict";
import { cpSync, existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, realpathSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const SOURCE = dirname(dirname(fileURLToPath(import.meta.url)));
const manifest = readFileSync(join(SOURCE, "scaffold-files.txt"), "utf8").split(/\r?\n/).filter(s => s && !s.startsWith("#"));
const windows = process.platform === "win32";
const ps = process.env.POWERSHELL_BIN || (windows ? "powershell.exe" : "pwsh");
const shells = windows ? [{ name: "PowerShell", bin: ps }] : [{ name: "Bash", bin: "bash" }, { name: "PowerShell", bin: ps }];

function fixture(t) {
  // Resolve /var -> /private/var on macOS; the PS installer intentionally rejects links.
  const root = mkdtempSync(join(realpathSync(tmpdir()), "vault-install-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const source = join(root, "source"); mkdirSync(source);
  for (const file of [...manifest, "install.sh", "install.ps1", "scaffold-files.txt"]) {
    mkdirSync(dirname(join(source, file)), { recursive: true }); cpSync(join(SOURCE, file), join(source, file));
  }
  const env = { ...process.env,
    GIT_AUTHOR_NAME: "Synthetic Audit", GIT_AUTHOR_EMAIL: "audit@example.invalid",
    GIT_COMMITTER_NAME: "Synthetic Audit", GIT_COMMITTER_EMAIL: "audit@example.invalid",
    GIT_CONFIG_COUNT: "2", GIT_CONFIG_KEY_0: "commit.gpgsign", GIT_CONFIG_VALUE_0: "false",
    GIT_CONFIG_KEY_1: "core.hooksPath", GIT_CONFIG_VALUE_1: join(root, "no-hooks") };
  for (const key of ["GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_OBJECT_DIRECTORY", "GIT_ALTERNATE_OBJECT_DIRECTORIES"]) delete env[key];
  return { root, source, dest: join(root, "vault with spaces"), env };
}
function run(command, args, f, cwd = f.source) {
  return spawnSync(command, args, { cwd, env: f.env, encoding: "utf8", timeout: 30000 });
}
function git(f, cwd, ...args) {
  const r = run("git", args, f, cwd); assert.equal(r.status, 0, r.stderr); return r.stdout.trim();
}
function install(shell, f, skip = false) {
  const args = shell.name === "Bash"
    ? [join(f.source, "install.sh"), f.dest, ...(skip ? ["--skip-git"] : [])]
    : ["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", join(f.source, "install.ps1"), "-Destination", f.dest, ...(skip ? ["-SkipGit"] : [])];
  return run(shell.bin, args, f);
}

for (const shell of shells) {
  const available = spawnSync(shell.bin, shell.name === "Bash" ? ["--version"] : ["-NoProfile", "-Command", "$PSVersionTable.PSVersion.ToString()"], { timeout: 15000 }).status === 0;
  test(`${shell.name}: installer security regression suite`, { skip: !available && !windows }, async t => {
    assert.equal(available, true, "Required installer runtime missing");
    await t.test("fresh vault includes only the scaffold and commits only manifest paths", t => {
      const f = fixture(t);
      writeFileSync(join(f.source, ".env"), "SYNTHETIC_ONLY=sentinel\n");
      writeFileSync(join(f.source, "unrelated-private-note.md"), "Do not copy this");
      const r = install(shell, f); assert.equal(r.status, 0, r.stderr);
      const tracked = git(f, f.dest, "ls-tree", "-r", "--name-only", "HEAD").split("\n");
      assert.deepEqual(tracked.sort(), [...manifest].sort());
      assert.equal(existsSync(join(f.dest, ".env")), false);
      assert.equal(existsSync(join(f.dest, "unrelated-private-note.md")), false);
      assert.equal(git(f, f.dest, "remote"), "");
    });
    await t.test("existing vault preserves files and never stages secrets or initializes history", t => {
      const f = fixture(t); mkdirSync(f.dest);
      writeFileSync(join(f.dest, ".gitignore"), ".DS_Store\n");
      writeFileSync(join(f.dest, ".env"), "SYNTHETIC_ONLY=sentinel\n");
      writeFileSync(join(f.dest, "CLAUDE.md"), "Existing human rules");
      const r = install(shell, f); assert.equal(r.status, 0, r.stderr);
      assert.equal(existsSync(join(f.dest, ".git")), false);
      assert.equal(readFileSync(join(f.dest, "CLAUDE.md"), "utf8"), "Existing human rules");
      assert.equal(readFileSync(join(f.dest, ".gitignore"), "utf8"), ".DS_Store\n");
      assert.match(r.stdout, /CLAUDE\.md/);
    });
    await t.test("an existing Git index and commit remain unchanged", t => {
      const f = fixture(t); mkdirSync(f.dest);
      git(f, f.dest, "init", "-b", "main");
      writeFileSync(join(f.dest, "existing.md"), "Existing");
      git(f, f.dest, "add", "existing.md"); git(f, f.dest, "commit", "-m", "Synthetic existing vault");
      writeFileSync(join(f.dest, "staged.md"), "User-staged synthetic note"); git(f, f.dest, "add", "staged.md");
      const head = git(f, f.dest, "rev-parse", "HEAD"), index = git(f, f.dest, "diff", "--cached");
      const r = install(shell, f); assert.equal(r.status, 0, r.stderr);
      assert.equal(git(f, f.dest, "rev-parse", "HEAD"), head);
      assert.equal(git(f, f.dest, "diff", "--cached"), index);
    });
    await t.test("an empty destination inside a parent repository does not stage or commit there", t => {
      const f = fixture(t);
      git(f, f.root, "init", "-b", "main");
      writeFileSync(join(f.root, "existing.md"), "Existing parent repository");
      git(f, f.root, "add", "existing.md"); git(f, f.root, "commit", "-m", "Synthetic parent");
      const head = git(f, f.root, "rev-parse", "HEAD");
      const r = install(shell, f); assert.equal(r.status, 0, r.stderr);
      assert.equal(existsSync(join(f.dest, ".git")), false);
      assert.equal(git(f, f.root, "rev-parse", "HEAD"), head);
      assert.equal(git(f, f.root, "diff", "--cached"), "");
    });
    await t.test("installing from a real Git worktree never copies its Git pointer", t => {
      const f = fixture(t);
      git(f, f.source, "init", "-b", "main"); git(f, f.source, "add", "."); git(f, f.source, "commit", "-m", "Synthetic template");
      const worktree = join(f.root, "worktree"); git(f, f.source, "worktree", "add", "-b", "fixture", worktree);
      f.source = worktree;
      const head = git(f, f.source, "rev-parse", "HEAD");
      const r = install(shell, f, true); assert.equal(r.status, 0, r.stderr);
      assert.equal(existsSync(join(f.dest, ".git")), false);
      assert.equal(git(f, f.source, "rev-parse", "HEAD"), head);
      assert.equal(existsSync(join(f.dest, ".claude", "commands", "ingest.md")), true);
    });
    await t.test("repeat installs preserve edits and the initial commit", t => {
      const f = fixture(t); assert.equal(install(shell, f).status, 0);
      const head = git(f, f.dest, "rev-parse", "HEAD"); writeFileSync(join(f.dest, "index.md"), "Human edit");
      const r = install(shell, f); assert.equal(r.status, 0, r.stderr);
      assert.equal(readFileSync(join(f.dest, "index.md"), "utf8"), "Human edit");
      assert.equal(git(f, f.dest, "rev-parse", "HEAD"), head);
    });
    await t.test("source overlap is rejected before creating a nested destination", t => {
      const f = fixture(t); f.dest = join(f.source, "new-vault");
      const r = install(shell, f, true); assert.notEqual(r.status, 0);
      assert.equal(existsSync(f.dest), false);
    });
    await t.test("a missing scaffold file fails before creating the destination", t => {
      const f = fixture(t); rmSync(join(f.source, "index.md"));
      const r = install(shell, f, true); assert.notEqual(r.status, 0);
      assert.equal(existsSync(f.dest), false);
    });
    await t.test("linked scaffold parents cannot redirect a write", t => {
      const f = fixture(t); mkdirSync(f.dest);
      const outside = join(f.root, "outside"); mkdirSync(outside);
      symlinkSync(outside, join(f.dest, "wiki"), "junction");
      const r = install(shell, f, true); assert.notEqual(r.status, 0);
      assert.deepEqual(readdirSync(outside), []);
      assert.equal(existsSync(join(f.dest, "CLAUDE.md")), false);
    });
    await t.test("a linked source folder cannot import unrelated files", t => {
      const f = fixture(t); const outside = join(f.root, "outside");
      cpSync(join(f.source, "wiki"), outside, { recursive: true }); rmSync(join(f.source, "wiki"), { recursive: true });
      symlinkSync(outside, join(f.source, "wiki"), "junction");
      const r = install(shell, f, true); assert.notEqual(r.status, 0);
      assert.equal(existsSync(f.dest), false);
    });
  });
}
